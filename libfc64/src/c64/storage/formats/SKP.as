/*
 * Copyright notice
 *
 * (c) 2010 Robert Eaglestone.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */
package c64.storage.formats
/*
   SKiP file format.  This is a custom format, designed because I want to design one.

   The SKP image divides into 256 byte sectors.  The first sector is always the Header.
   After that come chained Files, in no fixed order.  Data is addressed in absolute Track,Sector
   offsets from the beginning of the file; thus, the Header sector is always 0,0, and the
   maximum image size is 256 x 256 x 256 bytes.

   The SKP format is designed to grow; instead of allocating its full length, it is only as
   large as it needs to be to accommodate its data.  As data is added, the image size grows.
   To some extent, when data is deleted the image size can even shrink.


   The HEADER contains crucial information about the image.

   $00-03: Signature "LDAv", where v is the version (0-9 and then A-Z).
   $04   : $A0
   $05-14: Image name, $A0 padded
   $15   : $A0
   $16-17: Image ID (similar to a D64 Disk ID, here "4A")
   $18   : $A0
   $19-1A: Image type (similar to DOS/Disk version, here "1S")
   $1B   : $A0
   $1C-1D: FAS: T,S location of the First Available Sector (0,0 = none)
   $1E   : Blocks of extended data (00 = no extra blocks)
   $1F   : Blocks of error bytes (00 = no error bytes stored)

   $20-7F: Comments, $A0 padded
   $80-FF: Reserved

   (Note: the header used to contain a T,S reference to the Highest T,S position
   allocated, but was removed since this is a computable value)

   Extended data blocks are multiple-use reserved data blocks, stored immediately
   after the header.

   Sectors for error bytes, if present, are stored immediately after the Header and
   extended blocks.  They are treated for all intents and purposes like the D64 error
   bytes: one byte per sector.  Thus error bytes for emulating a D64 image would require
   3 sectors.

   The first sector following the header and error bytes is the first Directory sector.

   All data following this is in chained files: the first two bytes of every block
   is a Track/Sector link to the next block in the file, with a (0,0) marking the last
   block of a file.  There are four kinds of files: Directory, Data, Error, and FAS.


   The DIRECTORY is a chained file of directory sectors.
   Directory sectors are 256-byte blocks with a 2-byte T/S header, and contain up to 7 entries.

   Bytes: $00-01: Track/Sector location of next directory sector
   02-1F: Reserved
   20-3F: First directory entry
   40-5F: 2nd directory entry
   60-7F: 3rd directory entry
   80-9F: 4th directory entry
   A0-BF: 5th directory entry
   C0-DF: 6th directory entry
   E0-FF: 7th directory entry

   Each directory entry has the following format:

   Bytes: $00-1F: Directory Entry
   00: File type.
   Typical values for this location are:
   $00 - Scratched (deleted file entry)
   80 - DEL
   81 - SEQ
   82 - PRG
   83 - USR
   84 - REL
   85 - CBM
   01-02: Track/Sector location of first sector of DATA file
   03-04: Track/Sector location of first sector of ERROR file (0,0 if none)
   05-14: 16 character filename (in PETASCII, padded with $A0)
   15-16: Track/Sector location of first SIDE SECTOR block
   (REL file only)
   17: REL file record length (REL file only); otherwise LSU.
   18-1D: Unused
   1E-1F: File or partition size in  sectors,  low/high  byte  order
   ($1E+$1F*256). The exact file size in bytes is (#sectors-1)*254 + LSU.

   (Note: the T/S location of the LAST sector of the file used to be in the spec;
   I removed it to conserve space, since this sector is discoverable and
   only used in deletes).


   DATA sectors are 256-byte blocks with a 2-byte T/S header, as used by the D64.
   Sectors of deleted files are returned to the FAS; thus deleting a file also
   recycles the sectors.  Updating a file may allocate sectors from the FAS, or
   may add sectors back to the FAS.  In this way memory is managed.


   ERROR sectors are 256-byte blocks with a 2-byte T/S header, similar to data sectors.
   ERROR sectors contain error bytes for each DATA sector, and provides basic copy
   protection support for D64-related files which use it.  The error file is optional.


   FAS sectors are 256-byte blocks with a 2-byte T/S header, similar to data sectors.
   Like the directory, there is only one FAS in an image.  It points to the First
   Available Sector, which is the head of the free sectors list.


   Usage

   Here's how it all comes together.  When a new SKP file is created, the boot
   sector is all there is.  When the first file is added, the application
   calculates how many sectors are needed:

   If there are no free directory entries, then a sector is needed for Dir space.
   [File size]/254 sectors, rounded up, are also needed.

   These sectors are then allocated.  	When allocating a sector, the system checks
   the FAS free sectors; if none are found, then sectors are created.  If sectors cannot
   be created, the process fails with an error code.

   If a new directory sector is allocated, the current directory tail is pointed to it.

   The file is broken up into sector-sized chunks and written as usual.  If there is
   error data, it is broken up and stored in the same way.

   The location of the first sector, last sector, and other file information are written
   into the directory.

   SKP has no BAM.  Instead, it has a T/S link to the "First Available Sector" (FAS).
   Unallocated sectors are linked in a chain starting with this sector; when a sector is needed,
   it is allocated from the front of this list and the FAS is updated.  If the FAS is empty its
   value is 0,0.

   Hence the process of deleting a file is: its file type is set to "0", the T,S link of
   the last sector in the file (at locations 1C and 1D in the directory) is pointed to the head
   of the FAS, and the FAS is updated to point to the start of the file.  In short, the file's sectors
   are added to the front of the FAS list.

 */
{
	import c64.storage.CMD;
	import c64.storage.CommodoreImage;
	import c64.storage.LByteArray;
	
	public class SKP extends CMD implements Storable
	{
		public function SKP( fn:String=null )
		{
			super(fn);
			
			DOS_TYPE    = "SKP";
			DOS_VERSION = "0";
		}
		
		
		/*
		   $00-03: Signature "LDAv", where v is the version (0-9 and then A-Z).
		   $04   : $A0
		   $05-14: Image name, $A0 padded
		   $15   : $A0
		   $16-17: Image ID (similar to a D64 Disk ID, here "4A")
		   $18   : $A0
		   $19-1A: Image type (similar to DOS/Disk version, here "1S")
		   $1B   : $A0
		   $1C-1D: Directory: T,S location of the first directory sector
		   $1E-1F: FAS: T,S location of the First Available Sector (0,0 = none)
		   $20-7F: Comments, $A0 padded
		   $80-FF: Reserved
		 */
		public function read( data:LByteArray ):Object
		{
			var hdrString:Array = data.toString().split( /\xa0/ );
			var sig:String  = hdrString[0];
			var name:String = hdrString[1];
			var id:String   = hdrString[2];
			var type:String = hdrString[3];
			
			data.position = 0x1c;
			var dt:int = data.readByte() & 0xff;
			var ds:int = data.readByte() & 0xff;
			var ft:int = data.readByte() & 0xff;
			var fs:int = data.readByte() & 0xff;
			
			data.position = 0x20;
			var commentsData:LByteArray = new LByteArray();
			data.writeBytes( commentsData, 0, 0x60 );
			var comments:String = commentsData.toString();
			
			var trackList:Array = breakIntoTracks( data );
			var directory:Array = readDirectory( dt, ds, trackList );
			
			return null;
		}
		
		public function breakIntoTracks( data:LByteArray ):Array
		{
			var tracks:Array = new Array();
			var sectors:Array = new Array();
			data.position = 0;
			
			while( data.bytesAvailable > 0 )
			{
				var sec:LByteArray = new LByteArray();
				var len:int = data.bytesAvailable;
				if ( len > 256 ) len = 256;
				
				data.writeBytes( sec, 0, len );
				sectors.push( sec );
				
				if ( sectors.length == 256 )
				{
					tracks.push( sectors );
					sectors = new Array();
				}
			}
			
			return tracks;
		}
		
		public function readDirectory( t:int, s:int, trackList:Array ):Array
		{
			return null;
		}
		
		
		public function write( source:CommodoreImage ):LByteArray
		{
			var image:LByteArray = createNewImage( source );
			writeDirectory( image, source );
			return image;
		}
		
		public function createNewImage( source:CommodoreImage ):LByteArray
		{
			var image:LByteArray = new LByteArray();
			// write header
			return image;
		}
		
		public function writeDirectory( image:LByteArray, source:CommodoreImage ):void
		{
			// for each directory entry
			// 
		}
		
		public function writeFile( image:LByteArray, source:CommodoreImage ):void
		{
		
		}
		
		//
		//  SHOULD be writeHeader() instead
		//  OR ...
		//
		override public function initializeImage():LByteArray 
		{
			throw new Error( "SKP: need to initialize image here!" );
		}
		public function createEmpty( imageName:String="TEST IMAGE", diskID:String="1S" ):LByteArray
		{
			var image:LByteArray = new LByteArray();
			
			writeString( image, DOS_TYPE + DOS_VERSION, 5 );  // Signature + $A0
			writeString( image, imageName, 18 );              // name + $A0 + $A0
			writeString( image, diskID );                     // two bytes
			image.writeByte( 0x0a );                          // position $19
			writeString( image, DOS_VERSION + "0" );          // v + 0 ?
			image.writeByte( 0 ); 	 	// FAS track
			image.writeByte( 0 ); 	 	// FAS sector
			image.writeByte( 0 ); 	 	// High track
			image.writeByte( 0 ); 	 	// High sector
			image.writeByte( 0xa0 ); 	// unused
			
			writeString( image, "COMMENTS SECTION", 32 );  // 0x20
			writeString( image, "", 32 );                  // 0x40
			writeString( image, "", 32 );                  // 0x60
			
			writeString( image, "", 128, 0 );       // 0x80-0xFF (dir)
			
			//dump( image );
			
			return image;
		}
	}
}



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
package storage.formats
/*
	LDA (Legacy Data Archive) Format

	This format, designed by Rob Eaglestone in 2010, is an image for efficiently storing and 
	transmitting legacy programs, which can be converted to Commodore floppy disk images (or 
	loaded into emulators) with a minimum of fuss.  It is intended to combine the strengths 
	of T64, D64, LNX, and ARK, while avoiding some of their weaknesses.

	Rationale: Many D64 images contain more than one file, but use half or less of their full 
	capacity.  It seems reasonable in these cases to use a "non-image" format in many of these 
	cases. 	LNX, T64, and ARK serve this purpose, but eash has its own quirks or limitations.  
	LDA seeks to be as efficient as LNX, T64, and ARK for storage and transmission, while at
	the same time being less quirky.

	Structure
	
	The LDA image consists of 256-byte data blocks, indexed by a two-byte address, effectively 
	behaving like it has tracks and sectors.  An image requires only one block, at Track 0, 
	Sector 0, which is the Header block.  Thus the size of a minimal valid LDA image is 256 bytes.
	Subsequent blocks are Directory Blocks, Data Blocks, or Error Blocks.  The maximum valid LDA 
	image size is 2^16 blocks, or 2^24 bytes.  Since the Header is the only required overhead block, 
	the theoretical maximum possible file size is (2^16-1) * 254, or 16,645,890, bytes.  The smallest
	allocation size is 1 block, so the theoretical maximum possible number of files is:

		 5 blocks for the first 4 files (header + 4 data blocks)
	   + 9 blocks for every 8 files thereafter (8 data blocks and one directory block)
	
		= 4 + [ 8/9 x (2^16 - 5) ] = 58,253 files.
	
		Overview

    	* 256-byte blocks, addressed in a pseudo T/S notation.
    	* A Signature block with a signature, a Commodore-like header, and the first 4 directory entries.
    	* Directory blocks are chained (pseudo-T/S links), and can be anywhere.
    	* Directory entries mimic the Commodore format.
    	* Files are grouped in contiguous blocks.

		File blocks contain a "T/S link" in the first two bytes.  They're always set to 0,0 in file 
		blocks, except in the last block, in which case the "sector" byte is the LSU.
	
	Header
	
  	It has a 256-byte header  at  the  beginning  of  the  file  used  for  file signature, image
  	header information (mimicking the D81's disk header), and the first four directory entries.
	
	Here is a HEX dump of the first block of an LDA file:
	
        00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f         ASCII     
        ------------------------------------------------   ----------------
000000: 4C 44 41 30 A0 54 45 53  54 44 49 53 4B A0 A0 A0   LDA0.TESTDISK...
000010: A0 A0 A0 A0 A0 A0 34 41  A0 4C 44 A0 A0 A0 00 00   ......4A.LD.....
000020: 4C 44 41 20 46 4D 54 20  42 59 20 52 4F 42 20 45   LDA FMT BY ROB E
000030: 41 47 4C 45 53 54 4F 4E  45 20 36 20 32 30 31 30   AGLESTONE 6 2010
000040: 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
000050: 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
000060: 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
000070: 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................

        00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f         ASCII     
        ------------------------------------------------   ----------------
000080: 00 08 82 00 01 54 45 53  54 44 49 52 A0 A0 A0 A0   .....TESTDIR....
000090: A0 A0 A0 A0 A0 00 00 B3  00 00 00 00 00 00 00 01   ................
0000a0: 00 00 82 00 02 54 45 53  54 44 49 52 32 A0 A0 A0   .....TESTDIR2...
0000b0: A0 A0 A0 A0 A0 00 00 61  00 00 00 00 00 00 00 01   .......a........
0000c0: 00 00 82 00 03 54 45 53  54 44 49 52 33 A0 A0 A0   .....TESTDIR3...
0000d0: A0 A0 A0 A0 A0 00 00 B0  00 00 00 00 00 00 00 01   ................
0000e0: 00 00 82 00 04 54 45 53  54 44 49 52 34 A0 A0 A0   .....TESTDIR4...
0000f0: A0 A0 A0 A0 A0 00 00 A4  00 00 00 00 00 00 00 01   ................

	The HEADER contains crucial information about the image, as well as the first 
	4 directory	entries.
	
			$00-03: Signature "LDAv", where v is the version (0-9 and then A-Z).
			$04   : $A0
			$05-14: Image name, $A0 padded
			$15   : $A0
			$16-17: Image ID (similar to a D64 Disk ID, here "4A")
			$18   : $A0
            $19-1A: Image type (usually "LD")
            $1B   : $A0
            $1C-1D: Reserved for SKP up-conversion (otherwise $00)
            $1E   : Blocks of extended data (00 = no extra blocks)
            $1F   : Blocks of error bytes (00 = no error bytes stored)
            
            $20-3F: Comments, $A0 padded ("LDA FORMAT BY ROB EAGLESTONE 6 2010")
            
            $40-7F: reserved

            $80-9F: directory entry 1
            $A0-BF: directory entry 2
            $C0-DF: directory entry 3
            $E0-FF: directory entry 4

	Extended data blocks are multiple-use reserved data blocks, stored immediately
	after the header.
	
	Sectors for error bytes, if present, are stored immediately after the Header and
	extended blocks.  They are treated for all intents and purposes like the D64 error 
	bytes: one byte per sector.  Thus error bytes for emulating a D64 image would require 
	3 sectors.
	
	The first direcory entry has the T/S pointing to the first full DIRECTORY sector; 
	if it points to 0,0 then there are currently no full directory sectors.  	
	
	Individual directory entries are 32 bytes long:
	
        00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F        ASCII
        -----------------------------------------------   ----------------
000000: 00 08 82 00 01 54 45 53  54 44 49 52 A0 A0 A0 A0   .....TESTDIR....
000010: A0 A0 A0 A0 A0 00 00 B3  00 00 00 00 00 00 00 01   ................

	The format of the **header block's** directory entries are as follows:
	
  Bytes: $80-9F: First directory entry
          80-81: Track/Sector location of next directory block
             82: File type.
                 Typical values for this location are:
                   $00 - Scratched (deleted file entry)
                    80 - DEL
                    81 - SEQ
                    82 - PRG
                    83 - USR
                    84 - REL
                    85 - CBM
                 
                 If file type & 0x10 is 1, then there is also error data
                 attached immediately after the end of the file.  In this case, 
                 there is one error block per 254 blocks of data.
                 
          83-84: Track/sector location of first sector of file or partition
          85-94: 16 character filename (in PETASCII, padded with $A0)
          95-96: Track/Sector location of first SIDE SECTOR block
                 (REL file only)
             97: LSU, or REL file record length
          98-9D: Unused
          9E-9F: File or partition size in  sectors,  low/high  byte  order
                 ($1E+$1F*256). The  approx.  file  size  in  bytes  is  <=
                 #sectors * 254
          A0-BF: Second dir entry. From now on the first two bytes of  each
                 entry in this  sector  should  be  $00/$00,  as  they  are
                 unused.
          C0-DF: Third dir entry
          E0-FF: Fourth dir entry

	'Regular' directory blocks have the following format:

  Bytes: $00-1F: First directory entry
          00-01: Track/Sector location of next directory sector
             02: File type.
          03-04: Track/sector location of first sector of file or partition
          05-14: 16 character filename (in PETASCII, padded with $A0)
          15-16: Track/Sector location of first SIDE SECTOR block
                 (REL file only)
             17: LSU, or REL file record length (REL file only)
          18-1D: Unused
          1E-1F: File or partition size in  sectors,  low/high  byte  order
                 ($1E+$1F*256). The  approx.  file  size  in  bytes  is  <=
                 #sectors * 254
          20-3F: Second dir entry. From now on the first two bytes of  each
                 entry in this  sector  should  be  $00/$00,  as  they  are
                 unused.
          40-5F: Third dir entry
          60-7F: Fourth dir entry
          80-9F: Fifth dir entry
          A0-BF: Sixth dir entry
          C0-DF: Seventh dir entry
          E0-FF: Eighth dir entry

	Following after the end of the header comes either data for the first file, or a directory 
	block.  Each directory entry includes the information of where its data starts in the file (a 
	block offset), as well as the length of the file in blocks and bytes.  Each file is stored as
	a consecutive set of blocks: files are not scattered about.  All blocks are 256 bytes long, but 
	in Data blocks the header (the first two bytes) is reserved, so each Data block holds 254 bytes 
	of program data.

	If there is error data attached to a file, it follows immediately after the file data.  Its
	offset and length is computed based on the file size and starting position.  Unlike data, an
	error block uses all 256 of its bytes purely for error data, so each error block holds error
	bytes for 256 sectors.
	
	The LDA file is intended to be a load-only image.  Like T64, LNX and ARK, the format has no
	BAM, and files are stored in contiguous blocks.  
	
	Strengths
	
	* supports the standard 16 character filename
	* filenames padded with the standard $A0 character
	* has a verifiable file signature
	* has a well-laid-out, easy to use header
	* has a description field in the header
	* multiple-block chained directory allows directory blocks anywhere in the file (unlike LNX and ARK)
	* directory entries are structurally similar to the D64's, including the fixed 32-byte length
	* LSU is stored in directory entry, so actual file size is simply computable
	* allows for directory customization -- zero length files are allowed
	* special file attribute bits are stored
	* it is easy to re-write the header and extend the directory
	* supports REL files
	* supports multi-load programs
	* all data, including files, are block-aligned (like LNX and ARK)
	* can hold over 58,000 files and 16 megabytes
	* has a relatively low amount of wasted space
	* has support for *basic* copy-protection
	
	Weaknesses
	
	* Can't easily re-write contained files as they are blocked in by the files around them.
	* Since files are stored in standard block sizes, each stored file has some extra lost space.
	* Doesn't provide for error bytes for directory blocks.
	

	FORMAT UPCONVERT
	
	Because the LDA format is architecturally different to the SKP format, it cannot 
	read SKP files; nor can a SKP reader read in LDA files.
	
	However, because the LDA format is structurally identical to the SKP format, an LDA image
	can with a little effort be upconverted into a SKP file.  The steps to promote an LDA
	to SKP are:
	
		* chain the files
		* chain all unallocated sectors
		* set directory pointers as needed
		
	The reverse is not true.  LDA requires files to be in a contiguous group of sectors.
	This would require reading in an SKP image and building an output LDA image from scratch.
*/
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import storage.CommodoreImage;
	import storage.LByteArray;

	public class LDA extends CommodoreImage implements Storable
	{
		private var startingTrack:int  = 0;
		private var startingSector:int = 1;
		private var trackList:Array    = new Array();
		private var extendedBlocks:int = 0;
		private var errorBlocks:int    = 0;
		private var totalSectors:int   = 0;
		
		public function LDA(fn:String=null)
		{
			super(fn);
			
			this.setImageVersion( 0 );
			this.setImageName( "TEST IMAGE" );
			this.setImageID( toBytes("4A") );
			this.setImageType( toBytes("LD") );
		}

		public function readImage( data:ByteArray ):Boolean
		{
			data.endian = Endian.LITTLE_ENDIAN;
//			trace( dump( data ) );
			trackList = buildTracks( data );
			this.image[ 'info' ] = readHeader( data );
			this.setDirectory( readDir( trackList ) );
			return true;
		}

		override public function getImageDetails():String
		{
			return "Extension:  LDA ('Legacy Data Archive')\n"
			     + "Image ver:  " + this.getImageVersion() + "\n"
			     + "Image name: " + this.getImageName() + "\n"
			     + "Image ID:   " + this.getImageID().toString() + "\n"
			     + "Image type: " + this.getImageType().toString() + "\n"
			     + "Tracks:     " + trackList.length + "\n"
			     + "Sectors:    " + totalSectors + "\n"
			     + (this.errorBlocks?    "           Error bytes present\n":'')
			     + (this.extendedBlocks? "           Extended data present\n":'')
			     + "Header:    " + "0/0" + ", image name offset 5\n"
			     + "Directory: " + this.getDirectory().length + " entries\n";
		}
		
		public function getSector( t:int, s:int ):LByteArray
		{
			if ( trackList == null ) return null;
			if ( trackList.length < t ) return null;
			if ( trackList[t] == null ) return null;
			if ( trackList[t].length < s ) return null;
			return trackList[t][s];
		}

		/*
			$00-03: Signature "LDAv", where v is the version (0-9 and then A-Z).
			$04   : $A0
			$05-14: Image name, $A0 padded  ("TEST IMAGE")
			$15   : $A0
			$16-17: Image ID (similar to a D64 Disk ID, here "4A")
			$18   : $A0
            $19-1A: Image type (usually "LD")
            $1B   : $A0
            $1C-1D: Reserved for SKP up-conversion (otherwise $00)
            $1E   : Blocks of extended data (00 = no extra blocks)
            $1F   : Blocks of error bytes (00 = no error bytes stored)
            
            $20-3F: Comments, $A0 padded ("LDA FMT BY ROB EAGLESTONE 6 2010")
		*/
		private function readHeader( hdr:ByteArray ):Object
		{
//			trace( dump( hdr ) );
			var info:Object = new Object();
			
			hdr.position = 0;
//			var sigb:LByteArray = new LByteArray();
//			hdr.readBytes(sigb, 0, 3 );
			info[ 'signature' ]    = this.readString( hdr, 3 ); // sigb.toString();
			info[ 'imageVersion' ] = String.fromCharCode(hdr.readByte());
			
			hdr.position = 0x05;
//			var imgb:LByteArray = new LByteArray();
//			hdr.readBytes( imgb, 0, 16 );
			info[ 'imageName' ] = this.readString( hdr, 16 ); // imgb.toString();
			
			hdr.position = 0x16;
			var imgId:LByteArray  = new LByteArray();
			hdr.readBytes( imgId, 0, 2 );
			info[ 'imageID' ] = imgId;
			
			hdr.position = 0x19;
			var imgType:LByteArray = new LByteArray();
			hdr.readBytes( imgType, 0, 2 );
			info[ 'imageType' ] = imgType;
			
			hdr.position = 0x1e;
			this.extendedBlocks = hdr.readByte() & 0xff;
			this.errorBlocks    = hdr.readByte() & 0xff;
			
			if ( extendedBlocks > 0 )
			{
				var extendedData:LByteArray = new LByteArray();
				hdr.position = 0x100;
				hdr.readBytes( extendedData, 0, extendedBlocks * 0x100 );
				setExtendedData( extendedData );
			}
			
			if ( errorBlocks > 0 )
			{
				var errorData:LByteArray = new LByteArray();
				hdr.position = 0x100 + extendedBlocks * 0x100;
				hdr.readBytes( errorData, 0, errorBlocks * 0x100 );
				setErrorBytes( errorData );
			}
			
			return info;
		}
		
		private function readDir( tracks:Array ):Array
		{
			var directory:Array = new Array();
			
			var sectorZero:LByteArray = tracks[0][0];
			sectorZero.position = 0x80; // halfway thru
			
			var t:uint = sectorZero.readByte();
			var s:uint = sectorZero.readByte();
			sectorZero.position = 0x80; // reset read position
			
			// read 1st four entries
			for (var i:int=0; i<4; i++ )
			{
				var eo:Object = buildDirectoryEntry( sectorZero, tracks );
				if ( eo != null )
					directory.push( eo );
			}
			
			var sectorList:Array = readChainedFile( t, s, tracks );
			for each (var sector:LByteArray in sectorList)
			{
				for (var j:int=0; j<8; j++ )
				{
					var entry:Object = buildDirectoryEntry( sector, tracks );
					if ( entry != null ) 
						directory.push( entry );
				}
			}
			
			return directory;
		}
		
		private function buildDirectoryEntry( source:LByteArray, trackList:Array ):Object
		{
			var bytes:LByteArray = new LByteArray();
			source.readBytes( bytes, 0, 32 );
			return readDirectoryEntry( bytes, trackList );
		}
		
/*
          80-81: Track/Sector location of next directory block
             82: File type.
                 Typical values for this location are:
                   $00 - Scratched (deleted file entry)
                    80 - DEL
                    81 - SEQ
                    82 - PRG
                    83 - USR
                    84 - REL
                    85 - CBM

                 If file type & 0x10 is 1, then there is also error data
                 attached immediately after the end of the file.  In this case, 
                 there is one error block per 254 blocks of data.

          83-84: Track/sector location of first sector of file or partition
          85-94: 16 character filename (in PETASCII, padded with $A0)
          95-96: Track/Sector location of first SIDE SECTOR block
                 (REL file only)
             97: LSU, or REL file record length (REL file only)
          98-9D: Unused
          9E-9F: File or partition size in  sectors,  low/high  byte  order
                 ($1E+$1F*256). The  approx.  file  size  in  bytes  is  <=
                 #sectors * 254
*/
		private function readDirectoryEntry( entry:LByteArray, trackList:Array ):Object
		{
			entry.position = 0x00;			
//			trace( dump( entry ) );
			var dt:int = entry.readByte() & 255;
			var ds:int = entry.readByte() & 255;
			var fileType:int = entry.readByte() & 255;
			
			if ( fileType == 0x00 ) // nonexistent; not even a scratched file
			   return null;
			
			var errorBytesPresent:Boolean = ( fileType & 0x10 ) > 0;
			
			var ft:int = entry.readByte() & 255;
			var fs:int = entry.readByte() & 255;
//			var fileNameBytes:LByteArray = new LByteArray();
//			entry.readBytes( fileNameBytes, 0, 16 );
			var filename:String = this.readString( entry, 16 ); // fileNameBytes.toString();
			var tss:int = entry.readByte() & 255; // for REL
			var sss:int = entry.readByte() & 255; // for REL
			var lsu:int = entry.readByte() & 255;
			
			entry.position = 0x1e;
			var st:int = entry.readByte() & 255;
			var ss:int = entry.readByte() & 255;
			var filesizeInSectors:int = st * 256 + ss;
			var sizeActual:int    = (filesizeInSectors - 1) * 254 + lsu;
			
			if ( sizeActual < 0 ) 
				sizeActual = 0;
			
			var prg:LByteArray = new LByteArray();
			
			var fileEntry:Array = readFile( ft, fs, filesizeInSectors, lsu, trackList );
			if ( fileEntry != null && fileEntry.length > 0 )
			{
				prg = joinFile( fileEntry );
			}
			
            var item:Object = 
                    {
                       	'name': filename,
                       	'sizeInSectors': filesizeInSectors,
                       	'sizeActual': sizeActual,
                       	'type': fileType,
                       	'typeLabel': fileTypeLabel[ fileType & 0x07 ],
                       	'flags': fileType >> 5,
                       	'lsu': lsu,
                     	'data':fileEntry,
                     	'prg': prg
                    };

			if ( errorBytesPresent )
			{
				var ERROR_BYTES_PER_BLOCK:int = 256;
				
				var numBlocks:int = 1 + filesizeInSectors / ERROR_BYTES_PER_BLOCK;
				var errTrack:int  = ft + (fs + filesizeInSectors)/ERROR_BYTES_PER_BLOCK;
				var errSector:int = (fs + filesizeInSectors) % ERROR_BYTES_PER_BLOCK;
				
				var errorByteArray:Array  = readFile( errTrack, errSector, numBlocks, 0, trackList );
				var errorBytes:LByteArray = joinFile( errorByteArray, 256 );
				item[ 'errorBytes' ] = errorBytes;
			}
			
			return item;
		}
		
		/*
		 *   Used for chained directories, chained files, etc.
		 */
		private function readChainedFile( track:uint, sector:uint, trackList:Array ):Array
		{
			if ( track == 0 && sector == 0 )
				return null;
			
			var file:Array = new Array();
			while( track > 0 && sector > 0 )
			{
				var sec:LByteArray = trackList[track][sector];
				file.push( sec );
				track = sec[0];
				sector = sec[1];				
			}
			
			return file;
		}
		
		// file is chunked together, all in one place, in 256-byte blocks
		private function readFile( track:int, sector:int, lengthInSectors:int, lsu:int, trackList:Array ):Array
		{
			if ( lengthInSectors == 0 )	return null;
			
			if ( track == 0 && sector == 0 ) return null;
				
			var file:Array = new Array();
			while( lengthInSectors-- > 0 )
			{
				file.push( { 'bytes': trackList[track][sector], 'track':track, 'sector':sector } );
				sector++;
				if ( sector > 255 )
				{
					sector = 0;
					track++;
				}
/* 				if ( lengthInSectors == 0 ) // truncate?  nah.
				{
					file[ file.length - 1 ].length = lsu;
				}
 */			}
			return file;
		}


        //
        //  Takes a raw LDA image and returns an array of
        //  tracks, each of which is an array of sectors in
        //  LByteArray format.
        //
        public function buildTracks( bytes:ByteArray ):Array
        {
   			var disk:Array = new Array(); // zero-th track is valid
   			var Tracks:int = int(bytes.length / (256*256));
   			var MaxSectorsInTrack:int = 256;
   			totalSectors = 0;
   			
   			if ( Tracks == 0 )
   			{
   				MaxSectorsInTrack = int(bytes.length / 256 );
   			}
   			
   			for ( var trackNum:int=0; trackNum <= Tracks; trackNum++ )
   			{
        		var trackData:Array = new Array();
        		var sectorCount:int = MaxSectorsInTrack;
        		
        		for ( var sectorNum:int=0; sectorNum<sectorCount && bytes.bytesAvailable > 0; sectorNum++ )
        		{
            		var sectorData:LByteArray = new LByteArray();
            		var length:int = 256;
            		
            		if ( bytes.bytesAvailable < 256 )
            		{
            			length = bytes.bytesAvailable;
//            			throw new Error( "Image data stops at Track " + trackNum + ", Sector " + sectorNum );
            		}
            		bytes.readBytes( sectorData, 0, length );
            		trackData.push( sectorData );
            		totalSectors++;
        		}
        		disk.push( trackData );
   			}
            return disk;
        }
        		
		/*
			$00-03: Signature "LDAv", where v is the version (0-9 and then A-Z).
			$04   : $A0
			$05-14: Image name, $A0 padded  ("TEST IMAGE")
			$15   : $A0
			$16-17: Image ID (similar to a D64 Disk ID, here "4A")
			$18   : $A0
            $19-1A: Image type (usually "LD")
            $1B   : $A0
            $1C-1D: Reserved for SKP up-conversion (otherwise $00)
            $1E   : Blocks of extended data (00 = no extra blocks)
            $1F   : Blocks of error bytes (00 = no error bytes stored)
            
            $20-3F: Comments, $A0 padded ("LDA FMT BY ROB EAGLESTONE 6 2010")
		*/
		public function writeImage():LByteArray
		{
			// header
			var image:LByteArray = new LByteArray();
			image.length = 256;
			
			var extendedData:LByteArray = this.getExtendedData();
			var errorBytes:LByteArray   = this.getErrorBytes();
			
			extendedBlocks = extendedData.length / 256;
			if ( (extendedData.length % 256) > 0 ) extendedBlocks++;
			
			errorBlocks = errorBytes.length / 256;
			if ( (errorBytes.length % 256) > 0 ) errorBlocks++;
			 
			writeString( image, "LDA" + getImageVersion(), 5 );
			writeString( image, getImageName(), 17 );
			
			image.writeBytes( getImageID(), 0, 2 );
			image.writeByte( 0xa0 );

			image.writeBytes( getImageType(), 0, 2 );
			
			image.writeByte( 0xa0 ); // 0x1b
			image.writeByte( 0x00 ); // 0x1c
			image.writeByte( 0x00 ); // 0x1d
			image.writeByte( extendedBlocks ); // 0x1e
			image.writeByte( errorBlocks );    // 0x1f
			
			writeString( image, "LDA FMT BY ROB EAGLESTONE 6 2010", 0x20, 0xa0 );
			
			// store entries
			var dir:Array = this.getDirectory();
			var data:Array;

			var s:int = startingSector + extendedBlocks + errorBlocks;
			var t:int = startingTrack;

			// adjust offsets
			t += s/256;
			s %= 256;
									
			for each ( var entry:Object in dir )
			{
				if ( entry[ 'sizeInSectors' ] == 0 )
					continue;

				// store the next sector
				entry[ 'firstTrack'  ] = t;
				entry[ 'firstSector' ] = s; 

				// Join together the program data
				data = entry[ 'data' ]; // join !
				
				// position the write head
				image.position = t * 256 * 256 + s * 256;
				
				// Then write it to the image buffer...
				for each ( var dat:Object in data )
				{
					var b:LByteArray = dat[ 'bytes' ];
					b.length = 256;
					image.writeBytes( b, 0, b.length );
					
					s++;
					if ( s > 255 ) t++;
					s %= 256;
				}
			}

			// Now create the directory
			createDirectory( image, t, s );
		
//			trace( dump( image ) );
			
			return image;
		}
		
		private function createDirectory( image:LByteArray, t:int, s:int ):void
		{
			var dir:Array = this.getDirectory();
			var index:int = 4; // i.e. 4, 5, 6, 7 for t,s=0,0
			var track:int = 0;
			var sector:int = 0;
			
			var oldDirTrack:int = 0;
			var oldDirSector:int = 0;
			
			for each ( var entry:Object in dir )
			{
				// get name and starting t,s etc
				var flags:int         = entry[ 'flags' ];
				var lsu:int           = entry[ 'lsu'   ];
				var name:String       = entry[ 'name'  ];
				var sizeActual:int    = entry[ 'sizeActual' ];
				var sizeInSectors:int = entry[ 'sizeInSectors' ];
				var type:int          = entry[ 'type' ];
				var ft:int            = entry[ 'firstTrack' ];
				var fs:int            = entry[ 'firstSector' ];
				
				writeDirectoryEntry( image, track, sector, index, ft, fs, flags, lsu, name, sizeActual, sizeInSectors, type );
				
				index++;
				if ( index > 7 )
				{
					// allocate new directory sector
					oldDirTrack = track;
					oldDirSector = sector;
					index = 0;

					if ( track == 0 && sector == 0 )
					{
						track  = t;
						sector = s;						
					}
					else
					{
						sector++;
						if ( sector > 255 )
						{
							track++;
							sector %= 256;
						}
					}
					image.length = track * 256 * 256 + sector * 256 + 256;

					// link new dir t,s to previous one
					image.position = oldDirTrack * 256 * 256 + oldDirSector * 256;
					if ( oldDirTrack == 0 && oldDirSector == 0 )
					{
						image.position += 4 * 32;
					}
					image.writeByte( track  ); // next track 
					image.writeByte( sector ); // next sector
				}
			}
		}
		
/*
          80-81: Track/Sector location of next directory block
             82: File type.
                 Typical values for this location are:
                   $00 - Scratched (deleted file entry)
                    80 - DEL
                    81 - SEQ
                    82 - PRG
                    83 - USR
                    84 - REL
                    85 - CBM
          83-84: Track/sector location of first sector of file or partition
          85-94: 16 character filename (in PETASCII, padded with $A0)
          95-96: Track/Sector location of first SIDE SECTOR block
                 (REL file only)
             97: LSU, or REL file record length (REL file only)
          98-9D: Unused
          9E-9F: File or partition size in  sectors,  low/high  byte  order
                 ($1E+$1F*256). The  approx.  file  size  in  bytes  is  <=
                 #sectors * 254
*/
		private function writeDirectoryEntry( image:LByteArray, 
											  track:int,
											  sector:int,
											  index:int, 
											  ft:int,
											  fs:int,
											  flags:int, 
											  lsu:int, 
											  name:String, 
											  sizeActual:int, 
											  sizeInSectors:int, 
											  type:int ):void
		{
			image.position = track * 256 * 256 + sector * 256 + index * 32;
			image.writeByte( 0 ); // t
			image.writeByte( 0 ); // s
			image.writeByte( type );
			image.writeByte( ft );
			image.writeByte( fs );
			writeString( image, name, 16 );
			image.writeByte( 0 ); // TODO: REL t
			image.writeByte( 0 ); // TODO: REL s
			image.writeByte( lsu );
			
			for( var i:uint=0x98; i<=0x9d; i++ )
				image.writeByte( 0 );
			
			var st:uint = sizeInSectors / 256;
			var ss:uint = sizeInSectors % 256;
			image.writeByte( st );
			image.writeByte( ss );
		}
	}
}
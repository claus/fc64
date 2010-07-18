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
   This is a flexible format for Commodore data.

   The IMAGE HEADER is the most important part of this disk.
   It is the first 64 bytes of the image.  If ERROR_SECTORS is non-zero, then the header includes
   that number of 256-byte blocks.

   00-02		SIGNATURE				     = 'R64'
   03			VERSION (0..9, A..Z)
   04			$A0
   05-28       Label/Comments, $A0 padded
   29          $A0

   2A          ERROR_SECTORS				 = 0;  // number of error sectors attached to header
   2B          DOUBLE_SIDED                 = 0;  // 1 = zones repeat, doubling the tracks and sectors.

   2C-2D       Zone 1: number of tracks, sectors per track.
   2E-2F       Zone 2: number of tracks, sectors per track.
   30-31       Zone 3: number of tracks, sectors per track.
   32-33       Zone 4: number of tracks, sectors per track.

   34  		HEADER_TRACK                 = 40;         // HEADER SECTOR is always 0
   35  	    HEADER_DISK_NAME_BYTE_OFFSET = 0x04;
   36			FILE_INTERLEAVE    			 = 1;

   37  		DIRECTORY_TRACK              = 40;
   38  		DIRECTORY_SECTOR             = 3;
   39			DIRECTORY_INTERLEAVE 	     = 1;

   3A  		BAM_TRACK        			 = 40;
   3B			Reserved ($00)
   3C			BAM_BYTE_OFFSET              = 0x06;
   3D          BAM_INTERLEAVE               = 1;  // or 3.  whatever.

   3E			BAM_POINTS_TO_DIRECTORY      = 0;
   0 = the final BAM entry points to 0x00,0xff.
   1 = the final BAM entry points to the T,S of the first directory entry
   (similar to how the 8250 works).
   bits 2-7 are reserved.

   3F			PRE_INTERLEAVE_BAM    		 = 0;
   1 = interleave is applied as initial sector position
   bits 2-7 are reserved.


   CALCULATIONS:
 * Zone data yields total number of sectors
 * Zone data yields Sectors in track array
 * Zone data yields track offset array
 * Zone data yields track write order
 * Total number of sectors yields sector offset array
 * Total number of sectors yields BAM SECTOR BYTES PER TRACK
 * Total number of sectors yileds BAM sector to track mapping
 * If error bytes are present, then error sectors = round up ( total sectors / 256 ) -- usually 3.
 */
{
	import flash.utils.ByteArray;
	
	import c64.storage.CMD;
	import c64.storage.LByteArray;
	
	public class R64 extends CMD implements Storable
	{
		public function R64(fn:String=null)
		{
			super(fn);
			
			EXTENSION 					 = 'R64';
			DOS_VERSION                  = 'R';
			DOS_TYPE                     = '0R';
		}
		
		public function test():void
		{
			configure();
		}
		
		override public function initializeReading( bytes:ByteArray ):ByteArray
		{
			// here is where we strip off the R64 disk configuration
			// first, read off the R64 disk configuration and initialize
			var len:int = readImageConfiguration( bytes );
			
			var disk:ByteArray = new LByteArray();
			bytes.position = len;
			disk.length = bytes.bytesAvailable;
			disk.writeBytes( bytes, len );
			disk.position = 0;
			
			return disk;
		}
		
		override public function finalizeWriting( data:LByteArray ):LByteArray
		{
			// here is where we prepend the R64 disk configuration
			var image:LByteArray = writeImageConfiguration();
			image.length += data.length;
			image.writeBytes( data );
			
			return image;
		}
		
		/**
		 *
		 * returns the number of bytes in the configuration
		 *
		 **/
		public function readImageConfiguration( dat:ByteArray ):int
		{
			dat.position = 0x00;
			var sig:String = readString( dat, 3 );            // 00-02
			var ver:String = readString( dat );               // 03
			dat.readByte();                                   // 04
			var label:String = readString( dat, 0x24 );       // 05-28
			dat.readByte();                                   // 29
			
			var errorSectors:int = dat.readByte(); 		      // 2A
			ERROR_BYTES_PRESENT = errorSectors > 0;
			DOUBLE_SIDED = dat.readByte() > 0;                // 2B
			
			ZONES = new Array();
			for( var i:int=0; i<4; i++ )                      // 2C-33
			{
				var t:int = dat.readByte();
				var spt:int = dat.readByte();
				ZONES[i] = [t,spt];
			}
			
			HEADER_TRACK         = dat.readByte() & 0xff;            // 34
			HEADER_DISK_NAME_BYTE_OFFSET = dat.readByte() & 0xff;    // 35
			FILE_INTERLEAVE      = dat.readByte() & 0xff;            // 36
			DIRECTORY_TRACK      = dat.readByte() & 0xff;			  // 37
			DIRECTORY_SECTOR     = dat.readByte() & 0xff; 		      // 38
			DIRECTORY_INTERLEAVE = dat.readByte() & 0xff;            // 39
			BAM_TRACK            = dat.readByte() & 0xff;            // 3A
			dat.readByte();                                   // 3B
			BAM_BYTE_OFFSET      = dat.readByte() & 0xff;            // 3C
			BAM_INTERLEAVE       = dat.readByte() & 0xff;            // 3D
			BAM_POINTS_TO_DIRECTORY = dat.readByte() != 0;     // 3E
			BAM_PREPEND_INTERLEAVE = dat.readByte() != 0;      // 3F
			
			errorSectors = countErrorSectors();
			dat.writeBytes( ERROR_BYTES, 0, errorSectors * 0x100 ); // read in error sectors
			
			var cfgLength:int = 0x40 + errorSectors * 0x100; 
			
			setZones( ZONES );
			
			return cfgLength;
		}
		
		public function writeImageConfiguration():LByteArray
		{
			var cfg:LByteArray = new LByteArray();
			
			writeString( cfg, "R640", 5 );        // 00-04
			writeString( cfg, "", 37 );           // 05-29
			
			var errorSectors:int = countErrorSectors();
			
			cfg.writeByte( errorSectors );        // 2A
			cfg.writeByte( DOUBLE_SIDED? 1:0 );   // 2B
			
			for each ( var zone:Array in ZONES )  // 2C-33 in pairs (T, S per T)
			{
				cfg.writeByte( zone[0] );
				cfg.writeByte( zone[1] );
			}
			
			cfg.writeByte( HEADER_TRACK );        // 34
			cfg.writeByte( HEADER_DISK_NAME_BYTE_OFFSET ); // 35
			cfg.writeByte( FILE_INTERLEAVE );     // 36
			cfg.writeByte( DIRECTORY_TRACK );     // 37
			cfg.writeByte( DIRECTORY_SECTOR );    // 38
			cfg.writeByte( DIRECTORY_INTERLEAVE );// 39
			cfg.writeByte( BAM_TRACK );           // 3A
			cfg.writeByte( 0x00 );                // 3B
			cfg.writeByte( BAM_BYTE_OFFSET );     // 3C
			cfg.writeByte( BAM_INTERLEAVE );      // 3D
			cfg.writeByte( BAM_POINTS_TO_DIRECTORY? 1:0 ); // 3E
			cfg.writeByte( BAM_PREPEND_INTERLEAVE? 1:0 );      // 3F
			
			cfg.length = 0x40 + errorSectors * 0x100; // make room for error sectors
			
			return cfg;
		}
		
		private function countErrorSectors():int
		{
			if ( ERROR_BYTES_PRESENT == false )
				return 0;
			else 
				if ( DOUBLE_SIDED )
					return 6;
			
			return 3;
		}
	
	}
}


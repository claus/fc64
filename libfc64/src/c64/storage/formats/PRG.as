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
   PRG and P00 formats.

   PRG is a two-byte load address + data.  That's it.
   If the file doesn't have the P00 "magic constant", assume it's a PRG.


   P00 format

   The *.P00 format is a flexible file format, that is able to support all common types
   of C64 files. As it has a magic constant at the head of the file it also enables the
   emulator to make sure that no invalid files are used. This makes it the recommended
   file format for single files.

   typedef struct
   {
   Byte P00Magic[8];    // $00 - $07
   Byte OrigFName[17];  // $08 - $18
   Byte RecordSize;     // $19
   Byte Data[n];        // $1A - ...
   } P00File;

   P00Magic	- Magic constant 'C64File' = {$43, $36, $34, $46, $69, $6C, $65, $00}
   OrigFName	- Original C64 filename (CBM Charset)
   RecordSize	- Record size for RELative files
   Data	- The actual data

   This file format was first used by Wolfgang Lorenz in PC64. Note that the extension *.P00 is
   not a fixed field. rather the 'P' stands for 'PRG' and can become an 'S' for 'SEQ', or 'R'
   for 'REL'. Furthermore the '00' can be used count to '01','02','03'... to resolve name conflicts
   caused by truncation a 16 character C64 filename to a 8+3 MS-DOS name. Of course this is not
   relevant on a Macintosh, it's just a hint if you should ever happen to run across a *.P01 file.
 */
{
	import flash.utils.ByteArray;
	
	import c64.storage.LByteArray;
	import c64.storage.Tape;
	
	public class PRG extends Tape implements Storable
	{
		public function PRG( fn:String=null )
		{
			super( fn );
		}
		
		public function readImage(data:ByteArray):Boolean
		{
			var offset:int = 2;
			data.position = 0;
			
			var loadAddress:int = 0;
			
			// check for magic constant
			if ( data[0] == 0x43 && data[1] == 0x36 && data[2] == 0x34 ) // "C64" = P00 file
			{
				var name:LByteArray  = new LByteArray();
				name.writeBytes( data, 8, 17 );
				filename = name.toString();
				offset = 26;
			}
			else
			{
				var lb:int = data[0]; // load address low byte
				var hb:int = data[1]; // load address hi byte
				loadAddress = lb + hb * 256;
			}
			
			var len:int = data.length - offset;
			
			// parcel data into 254-byte blocks, and store in 256-byte blocks.
			var dataArray:Array = breakIntoSectors( data, offset );
			var lsu:int = getLSU( dataArray );
			
			var prg:LByteArray = new LByteArray();
			data.writeBytes( prg, offset, prg.length - offset );
			
			var entry:Object = 
				{ 
					'type': 0x82,
					'typeLabel': 'PRG',
					'load address': loadAddress,
					'name': filename,
					'sizeActual': len,
					'sizeInSectors': dataArray.length,	
					'data': dataArray,
					'lsu': lsu,
					'prg': prg
				};
			
			addEntry( entry );
			return true;
		}
		
		public function writeImage():LByteArray
		{
			return null;
		}				
	}
}


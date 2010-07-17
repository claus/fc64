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
package storage
{
	import flash.utils.ByteArray;
	
	public class CommodoreImage
	{
		public var filename:String = '';
		public var image:Object = 
		{
			'dir': [],
			'info': {}			
		};
		public var fileTypeLabel:Array = [ 'DEL', 'SEQ', 'PRG', 'USR', 'REL', 'CBM', '???', '???' ];

		public function CommodoreImage( fn:String=null )
		{
			filename = fn;
			newImage();
		}

		public function newImage():Object
		{
			image = 
			{
				'dir': [],
				'info': {}			
			};
			return image;
		}
  
  		public function getImageDetails():String
  		{
  			return "No image details available";
  		}
 
		/*****************************************************************************************************
		 *
		 *   HANDY UTILITY METHODS
		 *
		 */
		public function toBytes( str:String ):LByteArray
		{
			var out:LByteArray = new LByteArray();

			for( var i:int=0; i<str.length; i++ )
			{
				out.writeByte( str.charCodeAt(i) );
			}
			return out;
		}
		
		public function writeString( bytes:LByteArray, str:String, pad:int=0, padVal:int=0xa0 ):LByteArray
		{
			for( var i:int=0; i<str.length; i++ )
			{
				bytes.writeByte( str.charCodeAt(i) );
				pad--;
			}
			
			while( pad-- > 0 )
			{
				bytes.writeByte( padVal );
			}	
			return bytes;
		}
		
		public function readString( src:ByteArray, len:int=1 ):String
		{
			var ba:ByteArray = new LByteArray();
			src.readBytes( ba, 0, len );
			var s:String = ba.toString().replace( /\s+$/, '' );
			return s;
		}

		public function dump( image:ByteArray, offset:int=0, len:int=256 ):String
		{
			image.position = offset;
			var hdr:String = "        00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f         ASCII     \n"
                           + "        ------------------------------------------------   ----------------\n";
                              
            var out:String = "";
			var txt:String = "";
			var asc:String = "";

			for( var i:int=0; i<len; i++ )
			{
				if ( i % 8 == 0 ) 
				{
					txt += " ";

					if ( i % 16 == 0 ) 
					{
						if ( i > 0 )
						{
					   	txt += "  " + asc + "\n";
						}
						if ( i % 256 == 0 ) 
						{
							txt += "\n" + hdr;
						}
						txt += hex(i,6) + ":";
						asc = '';
					}
				}

				var byte:int = image.readByte() & 0xff;
				var str:String = hex(byte).toUpperCase();
				txt += " " + str;
				if ( byte > 31 && byte < 130 )
				{
					asc += String.fromCharCode(byte);
				}
				else
				{
					asc += '.';
				}
			}
			txt += "   " + asc + "\n";

			image.position = 0; // reset read position
			return out + txt;
		}

		public function hex( val:int, precision:int=2 ):String
		{
			var out:String = val.toString(16);
			for( var i:int=out.length; i<precision; i++ )
			{
				out = "0" + out;
			}
			return out;
		}	

		/*
		 *  Breaks up a byte array into 256-byte blocks, with the first
		 *  two bytes being reserved (for potential use as T/S link data).
		 */
		public function breakIntoSectors( prg:ByteArray, offset:int=0 ):Array
		{
			var out:Array  = new Array();
			var len:int    = prg.length - offset;
			var blocks:int = len / 254;
			
			prg.position   = offset;
			for( var i:int=0; i<blocks; i++ )
			{
				var block:LByteArray = new LByteArray();
				prg.readBytes( block, 2, 254 );
				out.push( { 'bytes':block, 't':0, 's':0 } );
			}
			
			if ( prg.length % 254 > 0 )
			{
				var last:LByteArray = new LByteArray();
				var lsu:int = prg.length % 254
				prg.readBytes( last, 2, lsu );
				out.push( { 'bytes':last, 't':0, 's':lsu } );
				last.length = 256; // top off the block
			}
			return out;
		}

		/*
		 *  Takes a 256-byte-block chain and returns the LSU
		 *  (by definition, the 2nd byte of the final sector).
		 */
	    public function getLSU( chain:Array ):int
	    {
	    	var lastSector:LByteArray = chain[ chain.length - 1 ];
	    	var lsu:int = lastSector[1] & 0xff;
	    	return lsu;
	    }
	    
        /*
         * Takes an array of sectors and returns
         *  just the program data.
         */
        public function joinFile( chain:Array, numberOfBytes:int=254 ):LByteArray
        {
        	var result:LByteArray = new LByteArray();
        	for each (var entry:Object in chain)
        	{
        		var sec:LByteArray = entry[ 'bytes' ];
        		var t:int = sec.readByte() & 0xff;
        		var s:int = sec.readByte() & 0xff;
        		
        		if ( t == 0 ) // lsu
        			sec.readBytes( result, result.length, s );
        		else
        			sec.readBytes( result, result.length, numberOfBytes );
        	}
        	return result;
        }
        
        public function getProgram( directoryEntry:Object ):LByteArray
        {
        	var prg:LByteArray;
        	
        	if ( directoryEntry[ 'prg' ] != null )
        	{
        		prg = directoryEntry[ 'prg' ];
        	}
        	else
        	{
        		var chain:Array = directoryEntry[ 'data' ];
        		prg = joinFile( chain );
        	}
        	return prg;
        }

		/*
		 *
		 *   ** END ** HANDY UTILITY METHODS
		 *
		 ***************************************************************************************************/
		
		public function getImageName():String
		{
			return image[ 'info' ][ 'imageName' ] || "";
		}
		
		public function setImageName(name:String):void
		{
			image[ 'info' ][ 'imageName' ] = name;
		}
		
		public function getImageType():LByteArray
		{
			return image[ 'info' ][ 'imageType' ];
		}
		
		public function setImageType(arg:LByteArray):void
		{
			image['info'][ 'imageType' ] = arg;
		}
		
		public function getImageID():LByteArray
		{
			return image[ 'info' ][ 'imageID' ];
		}
		
		public function setImageID(arg:LByteArray):void
		{
			image['info']['imageID'] = arg;
		}
		
		public function getImageVersion():int
		{
			return image[ 'info' ][ 'imageVersion' ];
		}
		
		public function setImageVersion(arg:int):void
		{
			image['info']['imageVersion'] = arg;
		}		 

		public function getDirectory():Array
		{
			return image[ 'dir' ];
		}

		public function getDirectoryEntry( index:int ):Object
		{
			return (image[ 'dir' ] as Array)[index];
		}
		
		public function setDirectory( dir:Array ):Boolean
		{
			image[ 'dir' ] = dir;
			return true;
		}

		public function addEntry(entry:Object):Boolean
		{
			image[ 'dir' ].push( entry );
			return true;
		}
		
		public function delEntry( index:int ):void
		{
			image[ 'dir' ] = (image[ 'dir' ] as Array).splice( index, 1 );
		}		
		
		public function setErrorBytes( b:LByteArray ):void
		{
			image[ 'errorBytes' ] = b;
		}
		
		public function getErrorBytes():LByteArray
		{
			return image[ 'errorBytes' ] || new LByteArray();
		}
		
		public function setExtendedData( b:LByteArray ):void
		{
			image[ 'extendedData' ] = b;
		}
		
		public function getExtendedData():LByteArray
		{
			return image[ 'extendedData' ] || new LByteArray();
		}
	}
}
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
package c64.storage
{
	import flash.utils.ByteArray;
	
	public class Tape extends CommodoreImage
	{
		public var data:ByteArray;
		public var fileExt:String;
		public var fileSig:String; 
		
		/*
		 *   P H Y S I C A L   D A T A
		 */
		public var EXTENSION:String;
		
		public var SIGNATURE_OFFSET:int = 0;
		public var SIGNATURE_LENGTH:int = 0;
		
		public var VERSION_OFFSET:int = 0;
		public var VERSION_LENGTH:int = 0;
		
		public var IMAGE_NAME_OFFSET:int = 0;
		public var IMAGE_NAME_LENGTH:int = 0;		
		/*
		 *   END   P H Y S I C A L   D A T A
		 */
		
		public function Tape( fn:String=null )
		{
			super( fn );
		}		
		
		public function getSector( t:int, s:int ):LByteArray
		{
			// just return a 256-byte block at a computed offset [t * 256 + s]
			var offset:uint = t * 256 + s;
			
			return null;
		}
	}
}


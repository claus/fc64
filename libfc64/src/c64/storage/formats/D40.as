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
/**
 *
 *   D40 format
 * 
 * This is a test format using programmatic configuration.  
 * 
 * Its configuration has a BAM which can address the largest possible storage 
 * space and still fit into the header sector: a 228 byte BAM, addressing 25 
 * tracks of 64 sectors each, for a total of 1600 sectors, or 400kb.
 * 
 * Its header, directory, and BAM are all on track 18, the BAM shares sector 0
 * with the header, and the directory begins on sector 1, just like the D64.  
 * All interleaves are 1, the disk name offset is 0x04, and the BAM data starts
 * at 0x1C.
 */
{
	import storage.CMD;
	
	public class D40 extends CMD implements Storable
	{
		public function D40(fn:String=null)
		{
			super(fn);
			
			var zones:Array = [[25,64]];
			configure( zones );
		}	
	}
}
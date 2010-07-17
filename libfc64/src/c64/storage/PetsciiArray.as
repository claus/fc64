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
	public class PetsciiArray extends LByteArray
	{
		public function PetsciiArray()
		{
			super();
		}

/*
cbm_petscii2ascii_c(char Character)
00066 {
00067     switch (Character & 0xff) {
00068       case 0x0a:
00069       case 0x0d:
00070           return '\n';
00071       case 0x40:
00072       case 0x60:
00073         return Character;
00074       case 0xa0:                                // shifted space
00075       case 0xe0:
00076         return ' ';
00077       default:
00078         switch (Character & 0xe0) {
00079           case 0x40: // 41 - 7E 
00080           case 0x60:
00081             return (Character ^ 0x20);
00082 
00083           case 0xc0: // C0 - DF 
00084             return (Character ^ 0x80);
00085 
00086       }
00087     }
00088 
00089     return ((isprint(Character) ? Character : '.'));
00090 }


//
//  Conversion PETSCII->ASCII
//

uint8 D64Drive::conv_from_64(uint8 c, bool map_slash)
{
	if ((c >= 'A') && (c <= 'Z') || (c >= 'a') && (c <= 'z'))
		return c ^ 0x20;
	if ((c >= 0xc1) && (c <= 0xda))
		return c ^ 0x80;
	if ((c == '/') && map_slash && ThePrefs.MapSlash)
		return '\\';
	return c;
}

*/		
		override public function toString():String
		{
			var ascii:String = "";
			var data:LByteArray = this;
			for( var i:int=0; i<data.length; i++ )
			{
				if ( ( data[i] >= 0x40 && data[i] <= 0x60 )
				  || ( data[i] >= 0xa0 && data[i] <= 0xe0 ) )
				   ascii += (data[i] ^ 0x20).toString();
				else
				if ( data[i] >= 0xc1 && data[i] <= 0xda )
				   ascii += (data[i] ^ 0x80).toString();
				else
				   ascii += data[i].toString();
			}
			return ascii;
		}				
				/*
				switch( data[i] & 0xff )
				{
					case 0x0a:
					case 0x0d:
						ascii += "\n";
						break;
					case 0x40:
					case 0x60:
						ascii += data[i].toString();
						break;
					case 0xa0:
					case 0xe0:
						ascii += ' ';
						break;
					default:
						switch( data[i] & 0xe0 )
						{
							case 0x40: // 41 - 7E
							case 0x60:
								ascii += (data[i] ^ 0x20).toString();
								break;
							case 0xc0: // C0 - DF
								ascii += (data[i] ^ 0x80).toString();
								break;
							default:
								if ( data[i] > 0x0c && data[i] < 225 )
									ascii += data[i].toString();
								else
									ascii += '.'; // i.e. non-printable
							
						}
						break;
				}*/		
	}
}
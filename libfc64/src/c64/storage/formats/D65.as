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
Extends the D81; though the Commodore 65's DOS is based on the IEEE 8250 Pet-era disk drive,
yet the sample disks and drive that came with known units appears to be a 1581.


	TODO: Subsume this class completely as a parametric instance of an R64


*/
{
	import storage.LByteArray;

	public class D65 extends D81
	{
		public function D65( fn:String=null )
		{
			super(fn);
			
			EXTENSION   				 = 'D65';
			DOS_VERSION                  = 'E';
			DOS_TYPE                     = '3E';

			// C65 = 0x60 tracks, 0x50 sectors per track.
			// ZONES                     = [[0x60,0x50]];
			TRACKS 					     = 96;      
			TOTAL_SECTORS                = 96 * 80; // = 7680;
			
			HEADER_TRACK                 = 40;   // Same as D81
			HEADER_SECTOR                = 0;    // Same as D81
		    HEADER_DISK_NAME_BYTE_OFFSET = 0x04; // Same as D81

			BAM_TRACK                    = 40;   // Same as D81
		    BAM_BYTE_OFFSET    		     = 0x10; // Same as D81
			BAM_BYTES_PER_TRACK          = 11;   // at 20 tracks per BAM sector, that's 5 BAM sectors
			BAM_SECTOR_BYTES_PER_TRACK   = 10; 
			BAM_SECTOR_TO_TRACK_MAPPING  = [ [ 1, 1, 20 ], [ 2, 21, 40 ], [ 3, 41, 60 ], [ 4, 61, 80 ], [ 5, 81, 96 ] ];
			// BAM_INTERLEAVE = 1
			// BAM_PREPEND_INTERLEAVE = 1

			DIRECTORY_TRACK              = 40;   // Same as D82
			DIRECTORY_SECTOR             = 6;    // NOT the same as D82
			DIRECTORY_INTERLEAVE		 = 1;    // Same as D82

    		SECTORS_IN_TRACK = 
    		[
        		0,    
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80, // 1-16
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80, // -32
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80, // -48
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80, // -64
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80, // -80
        		80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80  // -96
			];
			
    		
    		TRACK_OFFSET =
    		[	
    			0, 
				0,20480,40960,61440,81920,102400,122880,143360,163840,184320,
				204800,225280,245760,266240,286720,307200,327680,348160,368640,389120,
				409600,430080,450560,471040,491520,512000,532480,552960,573440,593920,
				614400,634880,655360,675840,696320,716800,737280,757760,778240,798720,
				819200,839680,860160,880640,901120,921600,942080,962560,983040,1003520,
				1024000,1044480,1064960,1085440,1105920,1126400,1146880,1167360,1187840,
				1208320,1228800,1249280,1269760,1290240,1310720,1331200,1351680,1372160,
				1392640,1413120,1433600,1454080,1474560,1495040,1515520,1536000,1556480,
				1576960,1597440,1617920,1638400,1658880,1679360,1699840,1720320,1740800,
				1761280,1781760,1802240,1822720,1843200,1863680,1884160,1904640,1925120,1945600
			];

	   		SECTOR_OFFSET =
    		[
				0,
				0,80,160,240,320,400,480,560,640,720,800,880,960,1040,1120,1200,
				1280,1360,1440,1520,1600,1680,1760,1840,1920,2000,2080,2160,2240,2320,2400,2480,
				2560,2640,2720,2800,2880,2960,3040,3120,3200,3280,3360,3440,3520,3600,3680,3760,
				3840,3920,4000,4080,4160,4240,4320,4400,4480,4560,4640,4720,4800,4880,4960,5040,
				5120,5200,5280,5360,5440,5520,5600,5680,5760,5840,5920,6000,6080,6160,6240,6320,
				6400,6480,6560,6640,6720,6800,6880,6960,7040,7120,7200,7280,7360,7440,7520,7600
			];
			
			TRACK_WRITE_ORDER = // for now, linear.
			[
				 1, 2, 3, 4, 5, 6, 7, 8, 9,10,
				11,12,13,14,15,16,17,18,19,20,
				21,22,23,24,25,26,27,28,29,30,
				31,32,33,34,35,36,37,40,
				41,42,43,44,45,46,47,48,49,50,
				51,52,53,54,55,56,57,58,59,60,
				61,62,63,64,65,66,67,68,69,70,
				71,72,73,74,75,76,77,78,79,80,
				81,82,83,84,85,86,87,88,89,90,
				91,92,93,94,95,96	
			];
		}		

		override public function writeBamHeader( image:LByteArray ):void
		{
			var dosComplement:int  = 0xbb;
			var ioByte:int         = 0xc0;
			var offset:int         = 0;

			//    Bytes:$00-01: Track/sector of next bam sector
			//              02: DOS_VERSION
			//              03: Reserved ($00)
			//           04-05: DISK_ID
			for ( var i:int=0; i<this.BAM_SECTOR_TO_TRACK_MAPPING.length; i++ )
			{
				var sector:int = BAM_SECTOR_TO_TRACK_MAPPING[i][0];
				var track1:int = BAM_SECTOR_TO_TRACK_MAPPING[i][1];
				var trackn:int = BAM_SECTOR_TO_TRACK_MAPPING[i][2];
				
				offset = SECTOR_OFFSET[BAM_TRACK] * 256 + sector * 256;
				
				image[ offset + 0x00 ] = BAM_TRACK;
				image[ offset + 0x01 ] = sector+1;  // all except for the last one
				image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
				image[ offset + 0x03 ] = 0x00;
				image[ offset + 0x04 ] = DISK_ID.charCodeAt(0);
				image[ offset + 0x05 ] = DISK_ID.charCodeAt(1);	
			}
			
			// now overwrite last BAM entry's T,S link
			offset = SECTOR_OFFSET[BAM_TRACK] * 256 + 5 * 256; // last BAM sector
			image[ offset + 0x00 ] = 0;
			image[ offset + 0x01 ] = 0xff;
			
			// done
		}
	}
}
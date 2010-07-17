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
/*
	The CMD format reads in a disk image into a JSON structure, and writes
	a JSON structure out to a disk image.  It makes no attempt to preserve 
	the actual structure of the original disk -- i.e. it will consolidate
	the	directory and change the locations of the images' files.
	
	The generated structure looks like this:
	
	img:
	{
		info: 
		{
			imageName: 
			imageID  : 
			imageType:
			imageVersion:
		}
		dir:
		[
			{
				name: file name
				flags: file flags
				len: size in bytes
				load address:
				data:
				[
					{ 'bytes':ByteArray, 't':track, 's':sector }, 
					...
				]
			}
			,
			{
				// next entry
			}
		]
	}
	
	bam:
	{
		"t,s" indexes used sectors (for building a disk image)
	}
*/
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class CMD extends CommodoreImage
	{
		public var trackList:Array;
		public var bam:Object;
		
		/*
		 *  PHYSICAL DATA
		 *
		 *  This class serves as the parent class to typical CBM drives.  Any drive
		 *  that divides its data up into tracks and sectors can extend this class 
		 *  and override the physical data and behavior as needed.
		 *
		 */
		public var EXTENSION:String     = '';
		public var DOS_VERSION:String   = '';
		public var DOS_TYPE:String      = '';
		public var DISK_ID:String       = '';
		
		public var ZONES:Array          = []; // TODO - use this to generate SECTORS_IN_TRACK
		public var TRACKS:int           = 0;
    	public var SECTORS_IN_TRACK:Array = [];
    	public var TOTAL_SECTORS:int    = 0;
		public var HEADER_TRACK:int     = 0;
		public var HEADER_SECTOR:int    = 0; // The header *always* starts at sector 0.		
		public var FILE_INTERLEAVE:int  = 1; // TODO
		
		public var DIRECTORY_TRACK:int  = 0;
		public var DIRECTORY_SECTOR:int = 0;
		public var DIRECTORY_INTERLEAVE:int = 1;

		public var BAM_TRACK:int        = 0;
		public var BAM_SECTOR_TO_TRACK_MAPPING:Array = [];
		public var BAM_BYTE_OFFSET:int       = 0;
		public var BAM_BYTES_PER_TRACK:int = 0;
		public var BAM_SECTOR_BYTES_PER_TRACK:int = 0;
		public var BAM_POINTS_TO_DIRECTORY:Boolean = false;
		public var BAM_INTERLEAVE:int   = 1; // TODO
		public var BAM_PREPEND_INTERLEAVE:Boolean = false; // TODO
		public var BAM_HAS_SECTORS_FREE_COUNT:Boolean = true; // TODO
		
		public var TRACK_OFFSET:Array    = [];
    	public var SECTOR_OFFSET:Array   = [];
		
		public var TRACK_WRITE_ORDER:Array = [];
		
		public var PARTIAL_DISK_OK:Boolean = false;
		
		public var HEADER_DISK_NAME_BYTE_OFFSET:int = 0;
		
		public var DOUBLE_SIDED:Boolean = false;         // TODO
		public var ERROR_BYTES_PRESENT:Boolean = false;  // TODO
		public var BAM_HEADER_HAS_DOS_VERSION:Boolean = true;
		public var ERROR_BYTES:LByteArray = new LByteArray(); // TODO
		
		override public function getImageDetails():String
		{
			return "Extension: " + EXTENSION   + "\n"
			     + "DOS ver:   " + DOS_VERSION + "\n"
			     + "DOS type:  " + DOS_TYPE    + "\n"
			     + "Disk ID:   " + DISK_ID     + "\n"
			     + "Zone 1:    " + ZONES[0][0] + " tracks, " + ZONES[0][1] + " sectors per track\n"
			     + "Zone 2:    " + ZONES[1][0] + " tracks, " + ZONES[1][1] + " sectors per track\n"
			     + "Zone 3:    " + ZONES[2][0] + " tracks, " + ZONES[2][1] + " sectors per track\n"
			     + "Zone 4:    " + ZONES[3][0] + " tracks, " + ZONES[3][1] + " sectors per track\n"
			     + "2-sided:   " + (DOUBLE_SIDED? 'Yes':'No') + "\n"
			     + "Tracks:    " + TRACKS + "\n"
			     + "Sectors:   " + TOTAL_SECTORS + "\n"
			     + (ERROR_BYTES_PRESENT? "           Error bytes present\n":'')
			     + "Header:    " + HEADER_TRACK + "/" + HEADER_SECTOR + ", disk name offset " + HEADER_DISK_NAME_BYTE_OFFSET + "\n"
			     + "Directory: " + DIRECTORY_TRACK + "/" + DIRECTORY_SECTOR + ", interleave " + DIRECTORY_INTERLEAVE + "\n"
			     + "BAM:       " + BAM_TRACK + ", offset " + BAM_BYTE_OFFSET + ", interleave " + BAM_INTERLEAVE + "\n" 
			     + "           " + BAM_SECTOR_BYTES_PER_TRACK + " sector bytes per track, " + BAM_BYTES_PER_TRACK + " total\n"
			     + "File interleave: " + FILE_INTERLEAVE + "\n";
		}
    	/*
    	 *  END OF PHYSICAL DATA
    	 *
    	 */
    	 		
		public function CMD( fn:String=null )
		{
			super( fn );
			
			this.bam = new Object();
		}

		/***************************************************************************
		 * 
		 * Architectural methods
		 * 
		 * ************************************************************************/
		public function configure( zones:Array=null,
								   doubleSided:Boolean=false,
								   errorBytesPresent:Boolean=false,

								   hdrTrack:int=18,
								   dirSector:int=1,

								   hdrDiskNameOffset:int=0x04,
								   bamOffset:int=0x1C, // e.g. 0x06 for multi-BAM-sectors

								   bamInterleave:int=1,
								   prependBamInterleave:Boolean=false,

								   fileInterleave:int=1,
								   dirInterleave:int=1,

								   bamPointsToDir:Boolean=false,
								   bamHasSectorsFreeCount:Boolean=true,
								   bamHeaderHasDosVersion:Boolean=true,
								   
								   dirTrack:int=-1,
								   bamTrack:int=-1
								   ):void
		{
			if ( dirTrack < 0 ) dirTrack = hdrTrack;
			if ( bamTrack < 0 ) bamTrack = hdrTrack;
			
			this.HEADER_TRACK 					= hdrTrack;
			this.HEADER_DISK_NAME_BYTE_OFFSET 	= hdrDiskNameOffset;
			this.FILE_INTERLEAVE                = fileInterleave;
			this.ERROR_BYTES_PRESENT 			= errorBytesPresent;
			this.DOUBLE_SIDED					= doubleSided;
			this.DIRECTORY_INTERLEAVE           = dirInterleave;
			this.BAM_INTERLEAVE                 = bamInterleave;
			this.BAM_PREPEND_INTERLEAVE         = prependBamInterleave;
			this.DIRECTORY_TRACK                = dirTrack;
			this.DIRECTORY_SECTOR               = dirSector;
			this.BAM_TRACK                      = bamTrack;
			this.BAM_BYTE_OFFSET                = bamOffset;
			this.BAM_POINTS_TO_DIRECTORY        = bamPointsToDir;
			this.BAM_HAS_SECTORS_FREE_COUNT     = bamHasSectorsFreeCount;
			this.BAM_HEADER_HAS_DOS_VERSION     = bamHeaderHasDosVersion;

			if ( zones == null )
				zones = [[17,21],[7,19],[6,18],[5,17]]; // mimic the D64
							
			this.setZones( zones );
		}

		/**
		 *
		 * Zone data yields total number of tracks and sectors
		 * Zone data yields Sectors in track array
		 * Zone data yields track offset array
		 *  
		 * Total number of sectors yields sector offset array
		 * Total number of sectors yields BAM SECTOR BYTES PER TRACK
		 * Total number of sectors yileds BAM sector to track mapping
		 *
		 */
		public function setZones( zones:Array ):void
		{
			ZONES = zones;
			var totalSectors:int = 0;
			TRACKS = 0;
			totalSectors = buildZones( zones );
			
			if ( this.DOUBLE_SIDED )
			{
				var trackOffset:int = TRACKS;
				TRACKS *= 2;
				totalSectors = buildZones( zones, totalSectors, trackOffset );
			}
			
			TOTAL_SECTORS = totalSectors;
			
			// Total number of sectors yields sector offset array
		    // Total number of sectors yields BAM SECTOR BYTES PER TRACK
		    // Total number of sectors yileds BAM sector to track mapping

/* 			for( var i:int=0; i<TOTAL_SECTORS; i++ )
			{
				SECTOR_OFFSET[ i ] = i * 0x100;
			}
 */		    
		    var maxSectorsInTrack:int = zones[0][1];
		    BAM_SECTOR_BYTES_PER_TRACK = Math.ceil( maxSectorsInTrack/8 );
		    BAM_BYTES_PER_TRACK = BAM_SECTOR_BYTES_PER_TRACK;

		    if ( BAM_HAS_SECTORS_FREE_COUNT )
		       BAM_BYTES_PER_TRACK++;
		       
			var bamSectors:int = Math.ceil( (TRACKS * BAM_BYTES_PER_TRACK + BAM_BYTE_OFFSET)/256 );
			var tracksPerBamSector:int = Math.floor(TRACKS/bamSectors);
			
			for( var j:int=0; j<bamSectors; j++ )
			{
				var bamSector:int = j * BAM_INTERLEAVE;
				var firstTrack:int = j * tracksPerBamSector + 1;
				var lastTrackPlusOne:int = (j+1) * tracksPerBamSector + 1;
				BAM_SECTOR_TO_TRACK_MAPPING.push( [ bamSector, firstTrack, lastTrackPlusOne ] );
				
				//trace( "BAM T/S " + BAM_TRACK + '/' + bamSector + " serves tracks " + firstTrack + " to " + lastTrackPlusOne + "-1" );
			}		
			
			// guess at the track write order
			var tracksUsed:Object = new Object();
			
			// first let's mark our overhead tracks used
			tracksUsed[ "" + DIRECTORY_TRACK ] = 'x';
			tracksUsed[ "" + BAM_TRACK       ] = 'x';
			tracksUsed[ "" + HEADER_TRACK    ] = 'x';
			
			// now let's loop thru what's left, starting from the center and working out to the edges.
			for( var t:int=0; t<=TRACKS/2+1; t++ )
			{
				var innerTrack:int = TRACKS/2 - t;
				var outerTrack:int = TRACKS/2 + t;
				
				if ( innerTrack > 0 && innerTrack <= TRACKS 
				  && tracksUsed.hasOwnProperty( "" + innerTrack ) == false )
				{
					TRACK_WRITE_ORDER.push( innerTrack );
					tracksUsed[ "" + innerTrack ] = 'x';
				}
				if ( outerTrack > 0 && outerTrack <= TRACKS 
				  && tracksUsed.hasOwnProperty( "" + outerTrack ) == false )
				{
					TRACK_WRITE_ORDER.push( outerTrack );
					tracksUsed[ "" + outerTrack ] = 'x';
				}
			}
		}

		private function buildZones( zones:Array, totalSectors:int=0, startTrack:int=0 ):int
		{
			for( var i:int=0; i<zones.length; i++ )
			{
				var track:int = 1 + TRACKS + startTrack;
				var sectorCount:int = zones[i][1];
				var endTrack:int = 1 + TRACKS + zones[i][0];

				TRACKS += zones[i][0];
				
				for( var j:int=track; j<endTrack; j++ )
				{
					TRACK_OFFSET[ j ]     = totalSectors * 0x100;
					SECTOR_OFFSET[ j ]    = totalSectors;
					SECTORS_IN_TRACK[ j ] = sectorCount;
					//trace( 'track ' + j + ': offset=' + TRACK_OFFSET[ j ] + ', ' + sectorCount + ' sectors' );

					// now increment total ectors
					totalSectors += sectorCount; 
				}
			}
			return totalSectors;
		}
		
		/***************************************************************************
		 * 
		 * Data methods
		 * 
		 * ************************************************************************/
        public function readImage( bytes:ByteArray ):Boolean
        {
        	bytes.endian = Endian.LITTLE_ENDIAN;
        	bytes = initializeReading( bytes );
        	bytes.position = 0;
        	
        	newImage();
            trackList = buildTracks( bytes );
            
            image['info'] = readHeader( trackList );
            this.setDirectory( readDir( trackList ) );
            
            return true;
        }

		public function initializeReading( bytes:ByteArray ):ByteArray
		{
			// nothing to do
			return bytes;
		}
		
		public function writeImage():LByteArray
		{
			var image:LByteArray = initializeImage();
			writeHeader( image );
			writeImageEntries( image );
			writeImageDirectory( image );
			writeImageBAM( image );
			image = finalizeWriting( image );
			return image;
		}
		
		public function finalizeWriting( image:LByteArray ):LByteArray
		{
			// nothing to do
			return image;
		}
		
		public function initializeImage():LByteArray
		{
			var image:LByteArray = new LByteArray();
			image.length = TOTAL_SECTORS * 256;
			return image;
		}
		
		public function getTrack( t:int ):Array
		{
			return trackList[t];
		}
		
		public function getSector( t:int, s:int ):LByteArray
		{
			return trackList[t][s];
		}
		
		public function readBAM():Object
		{
			throw new Error( "readBAM() unsupported on parent class" );
		}
		
		public function getBAM():LByteArray
		{
			throw new Error( "getBAM() unsupported on parent class" );
		}
		
        //
        //  Takes a raw disk image and returns an array of
        //  tracks, each of which is an array of sectors in
        //  LByteArray format.
        //
        public function buildTracks( bytes:ByteArray ):Array
        {
   			var disk:Array = new Array(1); // zero-th track is bogus
   			for ( var trackNum:int=1; trackNum <= TRACKS; trackNum++ )
   			{
        		var trackData:Array = new Array();
        		var sectorCount:int = SECTORS_IN_TRACK[ trackNum ]
        		for ( var sectorNum:int=0; sectorNum<sectorCount; sectorNum++ )
        		{
            		var sectorData:LByteArray = new LByteArray();
            		
            		if ( bytes.bytesAvailable < 256 && PARTIAL_DISK_OK == false )
            		{
            			throw new Error( "Image data stops at Track " + trackNum + ", Sector " + sectorNum );
            		}
            		bytes.readBytes( sectorData, 0, 256 );
            		trackData.push( sectorData );
        		}
        		disk.push( trackData );
   			}
            return disk;
        }
        
		/*
		  Bytes:$00-01: Track/Sector location of the first directory sector (should
                be set to 18/1 but it doesn't matter, and don't trust  what
                is there, always go to 18/1 for first directory entry)
            02: Disk DOS version type (see note below)
                  $41 ('A')=1541
				  $43 ('C')=8050 or 8250
                  $44 ('D')=1581
 
 				1541: offset = 0x90
 				
      	   90-9F: Disk Name (padded with $A0)
       	   A0-A1: $A0
       	   A2-A3: Disk ID
       	      A4: $A0
       	   A5-A6: DOS Version"2A"
       	   A7-AA: $A0
         
         		1581: offset = 0x04
         
           04-13: Disk Name (padded with $A0)
           14-15: $A0
           16-17: Disk ID
           	  18: $A0
           19-1A: DOS Version "3D"
           1B-1C: $A0

				8250: offset = 0x06
		
        	06-16: Disk name (padded with $A0)
           	   17: $A0
        	18-19: Disk ID
          	   1A: $A0
        	1B-1C: DOS Version "2C"
        	1D-20: $A0
		*/
		public function readHeader( trackList:Array ):Object
		{			
			var info:Object    = new Object();			
			var hdr:ByteArray  = trackList[ HEADER_TRACK ][ HEADER_SECTOR ];
		
			/* 0x00 */ var dirTrack:uint  = hdr.readByte();
			/* 0x01 */ var dirSector:uint = hdr.readByte();
			/* 0x02 */ info[ 'imageVersion' ] = hdr.readByte();
			
			/* offset */ hdr.position = HEADER_DISK_NAME_BYTE_OFFSET;
			var diskName:LByteArray = new LByteArray();
			hdr.readBytes( diskName, 0, 16 );
			info[ 'imageName' ] = diskName.toString();
			
			hdr.readByte(); // pad
			hdr.readByte(); // pad

			/* offset + 0x12 */
			var diskId:LByteArray = new LByteArray();
			hdr.readBytes( diskId, 0, 2 );
			info[ 'imageID' ] = diskId;
			
			hdr.readByte(); // pad

			/* offset + 0x15 */
			var fmtChars:LByteArray = new LByteArray();
			hdr.readBytes( fmtChars, 0, 2 );
			info[ 'imageType' ] = fmtChars;
			
			return info;
		}
		
/*
        2b   Track/Sector location of the first directory sector.
        1b   Disk DOS version type ($41, $42, etc)
        1b   Unused ($00)
       16b   Disk name (16 bytes, $A0 padded)
        1b   $A0 
        2b   Disk ID (2 bytes)
        1b   $A0
        2b   DOS Type (2 bytes)           
*/
		public function writeHeader( image:LByteArray ):void
		{
			var offset:int = SECTOR_OFFSET[ HEADER_TRACK ] * 256
			               + HEADER_SECTOR * 256;
			
			image[ offset   ] = DIRECTORY_TRACK;
			image[ offset+1 ] = DIRECTORY_SECTOR;
			image[ offset+2 ] = DOS_VERSION.charCodeAt(0);
			image[ offset+3 ] = 0x00;
			
			// pad with 0xa0
			for( var p:int=HEADER_DISK_NAME_BYTE_OFFSET; p<HEADER_DISK_NAME_BYTE_OFFSET+0x19; p++ )
				image[ offset + p ] = 0xa0;
				
			var name:String = getImageName().toUpperCase();
			for( var i:int=0; i<name.length; i++ )
			{
				image[ offset + HEADER_DISK_NAME_BYTE_OFFSET + i ] = name.charCodeAt(i);	
			}

			if ( DISK_ID.length < 2 )
			{
				DISK_ID = '10'; 
			}
			
			image[ offset + HEADER_DISK_NAME_BYTE_OFFSET + 0x12 ] = DISK_ID.charCodeAt(0);
			image[ offset + HEADER_DISK_NAME_BYTE_OFFSET + 0x13 ] = DISK_ID.charCodeAt(1);

			image[ offset + HEADER_DISK_NAME_BYTE_OFFSET + 0x15 ] = DOS_TYPE.charCodeAt(0);
			image[ offset + HEADER_DISK_NAME_BYTE_OFFSET + 0x16 ] = DOS_TYPE.charCodeAt(1);	
			
			for( var q:int=HEADER_DISK_NAME_BYTE_OFFSET+0x1b; q<0xff; q++ ) // ZERO pad
				image[ offset + q ] = 0;	
		}

		protected function printDiskInfo():void
		{
			//trace( "filename : " + img[ 'name' ]   );
			//trace( "file sig : " + img[ 'filesig'] );
			trace( "img name : " + getImageName() );
			trace( "img ID   : " + getImageID() );
			trace( "img ver  : " + getImageVersion() );
			trace( "img type : " + getImageType() );			
		}
      
        //
        //  Takes the track array of a disk and chases down
        //  the sectors of each file in the directory.
        //
        //  It returns an array of entries, where each entry
        //  consists of an info block and data.  The
        //  info block contains metadata about the file, and
        //  the data is an array of LByteArray sectors.
        //
        public function readDir( trackList:Array ):Array
        {
            var dir:Array = new Array();
    		var sectorList:Array = readFile( DIRECTORY_TRACK, DIRECTORY_SECTOR, trackList );
            //var dirData:LByteArray = joinFile( sectorList );
            
            for each (var entry:Object in sectorList)
            {
            	var sec:LByteArray = entry[ 'bytes' ];
                // 32 bytes per entry
                for ( var offset:int = 0; offset < 256; offset += 32 )
                {
                    sec.position = offset;

                    var firstTrack:int = sec[offset+3];
                    if ( firstTrack == 0 ) break;

					var ft:int = sec[ offset + 2 ];                    
                    var fileType:int = sec[offset + 2] & 0xff;                    
                    if ( fileType == 0 ) continue;
                    
                    var fileNum:int = fileType & 0x07;

                    var flags:int = sec[offset + 2] >> 5;
                    
                    var firstSector:int = sec[offset+4];
                    
                    sec.position = offset + 5;
                    var dat:ByteArray = new ByteArray();
                    sec.readBytes( dat, 0, 16 );
                    var filename:String = dat.toString(); // PETSCII
                    
                    sec.position = offset;
                    var filesizeInSectors:int = sec[ offset+0x1e ] + sec[ offset+0x1f ] * 256;
                    var fileEntry:Array = [];
                    var prg:LByteArray = new LByteArray();
                    
                    if ( filesizeInSectors > 0 )
                    {
      			    	fileEntry = readFile( firstTrack, firstSector, trackList );
    	   				prg       = joinFile( fileEntry );
                    }
                    
                    var item:Object = 
                    {
                       	'name': filename,
                       	'sizeInSectors': filesizeInSectors,
                       	'sizeActual': prg.length,
                       	'type': fileType,
                       	'typeLabel': fileTypeLabel[ fileNum ],
                       	'flags': flags,
                       	'lsu': prg.length % 254,
                     	'data':fileEntry,
                     	'prg': prg
                    };
       
                    dir.push( item );
                }
            }
		    return dir;            
        }
        
        public function calcUsage( dir:Array ):Object
        {
        	var metrics:Object = new Object();
        	for each (var entry:Object in dir)
        	{
        		metrics[ 'sectors used' ] += entry['info'][ 'sizeInSectors' ];
        	}
        	return metrics;
        }
        
        //
        //  Takes a starting track and sector and returns 
        //  a chain of 256-byte data sectors.
        //
        public function readFile( track:int, 
								  sector:int, 
                                  trackList:Array ):Array
		{
    		var chain:Array = new Array();
			
    		// follow the chain
    		while( track > 0 )
    		{
                var dat:LByteArray = trackList[ track ][ sector ];
        		track  = dat[ 0 ];
        		sector = dat[ 1 ];
        		chain.push( { 'bytes':dat, 't':track, 's':sector } );
    		}
    
    		return chain;
		}
		
		public function writeImageEntries( newimage:LByteArray ):void
		{
			var SECTORS:Array = new Array();
			for each (var track:int in TRACK_WRITE_ORDER)
			{
				for (var sector:int=0; sector<SECTORS_IN_TRACK[ track ]; sector++)
				{
					SECTORS.push( { 's':sector, 't':track } );
				}
			}
			
			// assign sectors to directory entries
			var entries:Array = getDirectory();
			var entry:Object;
			var data:Array;
			var i:int;
			
			for each (entry in entries)
			{
				// Get the program
				data = entry[ 'data' ];
				if ( entry.hasOwnProperty( 'lsu' ) == false ) // then create it
					entry[ 'lsu' ] = entry[ 'sizeActual' ] % 254;
					
				// skip all the sector allocation nonsense if this is a zero-size file
				if ( entry[ 'sizeInSectors' ] == 0 )
					continue;
				
				// Get a free sector for the first block.
				var alloc:Object = SECTORS.shift();
				entry[ 'firstTrack' ] = alloc['t'];
				entry[ 'firstSector' ] = alloc['s'];
				
				// Assign free sectors to the blocks.  These are chain references.
				for (i=0; i<data.length-1; i++)
				{
					data[i][ 't' ] = alloc[ 't' ];
					data[i][ 's' ] = alloc[ 's' ];
					
					// get a free sector for the NEXT sector.
					alloc = SECTORS.shift();

					// chain it from the current block
					data[i][ 'bytes' ][0] = alloc[ 't' ];
					data[i][ 'bytes' ][1] = alloc[ 's' ];
				}
				// Now do the last block.
				var lastSector:Object = data[ data.length - 1 ];
				lastSector['bytes'][0] = 0;
				lastSector['bytes'][1] = entry[ 'lsu' ]; // contains # of bytes used
				lastSector['t'] = alloc[ 't' ];
				lastSector['s'] = alloc[ 's' ];
			}
			
			this.bam = new Object();
			
			for each (entry in entries)
			{				
				data = entry[ 'data' ];
				
				for( i=0; i<data.length; i++ ) // each block
				{
					// first do some housekeeping on the block size
					(data[i]['bytes'] as LByteArray).length = 256;
					
					// get the sector offset in bytes
					var t:int = data[i][ 't' ];
					var s:int = data[i][ 's' ];
					var offset:int  = SECTOR_OFFSET[ t ] * 256
				       		        + s * 256;
				
					// copy the sector into the byte buffer
					newimage.position = offset;
					newimage.writeBytes( data[i]['bytes'], 0, 256 );
					
					// mark BAM[ t + ',' + s ] = used
					this.bam[ t + ',' + s ] = 'x';
				}
			}
		}	
			
		public function writeImageDirectory( image:LByteArray ):void
		{
			var directoryBuffer:LByteArray = new LByteArray();
			var sector:int = DIRECTORY_SECTOR;
			var offset:int = 0;
			var dir:Array = this.getDirectory();
			
			for each (var entry:Object in dir)
			{
				if ( directoryBuffer.length == 256 )
				{
					sector = writeDirectorySector( directoryBuffer, image, sector );				
					directoryBuffer = new LByteArray();
					offset = 0;
				}
				
				// 00-01 T,S of next directory sector
				// 02    file type   82=PRG
				// 03-04 T,S of first sector of file
				// 05-14 filename, $A0 padded
				// 15-16 T,S of 1st side sector (REL)
				// 17    REL file record len
				// 18-1D GEOS
				// 1C-1D used during @SAVE or @OPEN -- holds the new t/s link
				// 1E-1F file or partition size in sectors
				
				directoryBuffer[offset+0x02] = entry[ 'type' ];
				var firstTrack:int  = HEADER_TRACK;
				var firstSector:int = HEADER_SECTOR;
				if ( entry[ 'data' ].length > 0 )
				{
					firstTrack  = entry['data'][0]['t'];
					firstSector = entry['data'][0]['s'];
				}
				directoryBuffer[offset+0x03] = firstTrack;
				directoryBuffer[offset+0x04] = firstSector;
				
				var name:String = entry[ 'name' ];
				for ( var i:int=0; i<16; i++ )
				{
					directoryBuffer[ offset+0x05 + i ] = name.charCodeAt(i);
				}
				
				directoryBuffer[offset+0x1e] = entry[ 'data' ].length % 256;
				directoryBuffer[offset+0x1f] = int(entry[ 'data' ].length / 256);
				offset += 32;
			}
			if ( directoryBuffer.length > 0 )
			{
				writeDirectorySector( directoryBuffer, image, sector );
			}
		}
		
		public function writeDirectorySector( directoryBuffer:LByteArray, image:LByteArray, sectorNum:int ):int
		{
			var position:int = SECTOR_OFFSET[DIRECTORY_TRACK] * 256
				       		 + sectorNum * 256;
			
			// next sector.
			// Interleave stored in DIRECTORY_INTERLEAVE.  For example the 1541's
			// directory tracks (interleave = 3) will progress like:
			// 1, 4, 7, 10, 13, 16, 19, 3, 6, 9, 12, 15, 18, 2, 5, 8, 11, 14, 17.
			sectorNum = (sectorNum + DIRECTORY_INTERLEAVE) % SECTORS_IN_TRACK[DIRECTORY_TRACK];
			
			if ( directoryBuffer.length == 256 )
			{	       		 
				directoryBuffer[0] = DIRECTORY_TRACK;
				directoryBuffer[1] = sectorNum;
			}
			else
			{
				directoryBuffer[0] = 0;
				directoryBuffer[1] = 255; // directoryBuffer.length;
			}
			
			image.position = position;
			image.writeBytes( directoryBuffer, 0, directoryBuffer.length );
			
//			trace( "Directory sector written:" );
//			trace( dump( directoryBuffer ) );
			
			return sectorNum;
		}
			
		/*
		     Rebuilds the BAM from scratch, given the physical directory structure.
		*/
		public function writeImageBAM( image:LByteArray ):void
		{
			var alloc:Object = getAllocationMap(); // new Object();
			var t:int;
			var s:int;

			//
			// TODO: if there's more than one BAM_SECTOR, then you've got some
			//       splainin' to do.  How do you figure out where the next
			//       BAM sector goes?  Blindly follow the interleave from here?
			//
			if ( HEADER_TRACK != BAM_TRACK )
			{
				writeBamHeader( image );
			}
			
			//for( var bx:int=0; bx<BAM_SECTORS.length; bx++ )
			for ( var bx:int=0; bx<this.BAM_SECTOR_TO_TRACK_MAPPING.length; bx++ )
			{			
				var bamSector:int      = BAM_SECTOR_TO_TRACK_MAPPING[bx][0];
				var bamFirstTrack:int  = BAM_SECTOR_TO_TRACK_MAPPING[bx][1];
				var bamLastTrack:int   = BAM_SECTOR_TO_TRACK_MAPPING[bx][2];
				
				if ( bamFirstTrack == 0x00 )
				{
					break;
				}	
							
 				image.position = SECTOR_OFFSET[BAM_TRACK] * 256
 			               	   //+ BAM_SECTORS[bx] * 256
 			               	   + bamSector * 256
 			               	   + BAM_BYTE_OFFSET;
 			 			               
				//for ( t=BAM_SECTOR_TRACK_LIST[bx][0]; t<=BAM_SECTOR_TRACK_LIST[bx][1]; t++ )
				for ( t=bamFirstTrack; t <= bamLastTrack; t++ )
				{
					var ba:LByteArray = new LByteArray();
					var va:int = 0;
					var count:int = 0;
				
					for( s=0; s<SECTORS_IN_TRACK[ t ]; s++ )
					{
						var pos:int = s % 8; // bit position within a byte
						
						if (pos == 0 && count > 0) // byte boundary
						{
							ba.writeByte( va & 0xff );
							va = 0;
						} 
						
						if ( alloc.hasOwnProperty( t + ',' + s ) == false ) // = free
						{
							va += Math.pow( 2, s % 8 );
							count++;
						}
					}
				
					// good for up to 255 sectors per track
					if ( BAM_SECTOR_BYTES_PER_TRACK < BAM_BYTES_PER_TRACK )
					{
						image.writeByte( count );
					}
					
					image.writeBytes(ba, 0, ba.length);
				}
			}
		}
		
		//
		//  The default behavior is to write a header in the style of the 8250.
		//
		//  BAM_SECTOR_TO_TRACK_MAPPING is in this format:
		//  [ [ sector_1, first track, last track ] ... ]
		//  [ [ 0, 1, 50 ], [ 3, 51, 100 ], [ 6, 101, 150 ], [ 9, 151, 154 ] ];
		//
		//  The BAM header writes out 6 bytes per BAM block:
		//  0  Next Track
		//  1  Next Sector
		//  2  DOS VERSION
		//  3  0x00 (reserved)
		//  4  First Track served
		//  5  Last Track + 1 served
		//
		public function writeBamHeader( image:LByteArray ):void
		{			
			for( var i:int=0; i<BAM_SECTOR_TO_TRACK_MAPPING.length; i++)
			{
				var map:Array = BAM_SECTOR_TO_TRACK_MAPPING[i];
				var sector:int = map[0];
				var offset:int = (SECTOR_OFFSET[BAM_TRACK] + sector) * 256;

				var nextTrack:int  = BAM_POINTS_TO_DIRECTORY? this.DIRECTORY_TRACK  : 0;
				var nextSector:int = BAM_POINTS_TO_DIRECTORY? this.DIRECTORY_SECTOR : 0xff;
				
				if ( i < BAM_SECTOR_TO_TRACK_MAPPING.length-1 ) // still some dir entries left
				{
					nextTrack  = BAM_SECTOR_TO_TRACK_MAPPING[i+1][1];
					nextSector = BAM_SECTOR_TO_TRACK_MAPPING[i+1][2];
				}
				
				image[ offset + 0x00 ] = nextTrack;
				image[ offset + 0x01 ] = nextSector;
				
				if ( BAM_HEADER_HAS_DOS_VERSION )
				{
					image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
					image[ offset + 0x03 ] = 0x00;
					image[ offset + 0x04 ] = map[1];
					image[ offset + 0x05 ] = map[2] + 1;
				}
				else 
				{
					image[ offset + 0x02 ] = map[1];
					image[ offset + 0x03 ] = map[2] + 1;					
				}
			}
			// done
		}
		
		//
		//  Mark every used sector.
		//
		public function getAllocationMap():Object
		{
			var alloc:Object = new Object();
			var t:int;
			var s:int;
			var dir:Array = this.getDirectory();
			
 			for each (var entry:Object in dir)
			{
				t = entry[ 'firstTrack' ];
				s = entry[ 'firstSector' ];
				alloc[ t + ',' + s ] = 1;
				
				var chain:Array = entry[ 'data' ] as Array;
				for each (var sec:Object in chain)
				{
					t = sec[ 't' ];
					s = sec[ 's' ];
					if ( t == 0 ) break;
					alloc[ t + ',' + s ] = 1;
				}
			}
			
			return alloc;			
		}
	}
}
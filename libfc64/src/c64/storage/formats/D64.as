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
 *** D64 (Electronic form of a physical 1541 disk)

 ** Document revision 1.1

   (Note: This document will try to explain the layout of the 1541  disks,  as
   well as the files they contain. However, I do not explain GEOS files  here.
   See the file GEOS.TXT for more information  on  that  file  type  and  disk
   layout.)

   First and foremost we have D64, which is  basically  a  sector-for-sector
   copy of a 1540/1541 disk. There are several versions of these which I  will
   cover shortly. The standard D64 is a 174848 byte file comprised of 256 byte
   sectors arranged in 35 tracks with a varying number of  sectors  per  track
   for a total of 683 sectors. Track counting starts at 1, not 0, and goes  up
   to 35. Sector counting starts at 0, not 1, for the first sector,  therefore
   a track with 21 sectors will go from 0 to 20.

   The original media (a 5.25" disk) has the tracks  laid  out  in  circles,
   with track 1 on the very outside of the disk  (closest  to  the  sides)  to
   track 35 being on the inside  of  the  disk  (closest  to  the  hub  ring).
   Commodore (in their infinite wisdom) varied the number of sectors per track
   (and data  densities  across  the  disk)  to  optimize  available  storage,
   resulting in the chart below. It shows the  sectors/track  for  a  standard
   D64. Since the outside diameter of a circle is the largest  (versus  closer
   to the center), the outside tracks have the largest amount of storage.

   Track        Sectors/track   # Sectors
   -----        -------------   ---------
   1-17             21            357
   18-24             19            133
   25-30             18            108
   31-35             17             85
   ---
   683

   Track #Sect #SectorsIn D64 Offset   Track #Sect #SectorsIn D64 Offset
   ----- ----- ---------- ----------   ----- ----- ---------- ----------
   1     21       0       $00000      21     19     414       $19E00
   2     21      21       $01500      22     19     433       $1B100
   3     21      42       $02A00      23     19     452       $1C400
   4     21      63       $03F00      24     19     471       $1D700
   5     21      84       $05400      25     18     490       $1EA00
   6     21     105       $06900      26     18     508       $1FC00
   7     21     126       $07E00      27     18     526       $20E00
   8     21     147       $09300      28     18     544       $22000
   9     21     168       $0A800      29     18     562       $23200
   10     21     189       $0BD00      30     18     580       $24400
   11     21     210       $0D200      31     17     598       $25600
   12     21     231       $0E700      32     17     615       $26700
   13     21     252       $0FC00      33     17     632       $27800
   14     21     273       $11100      34     17     649       $28900
   15     21     294       $12600      35     17     666       $29A00
   16     21     315       $13B00      36*    17     683       $2AB00
   17     21     336       $15000      37*    17     700       $2BC00
   18     19     357       $16500      38*    17     717       $2CD00
   19     19     376       $17800      39*    17     734       $2DE00
   20     19     395       $18B00      40*    17     751       $2EF00

 *Extra tracks on 40-track images only

   The directory track should be contained totally on track 18. Sectors 1-18
   contain the entries and sector 0 contains the BAM (Block Availability  Map)
   and disk name/ID. Since the directory is only 18 sectors large (19 less one
   for the BAM), and each sector can contain only  8  entries  (32  bytes  per
   entry), the maximum number of directory entries is 18 * 8 = 144. The  first
   directory sector is always 18/1, even though the t/s pointer at 18/0 (first
   two bytes) might point somewhere else.  It  then  follows  the  same  chain
   structure as a normal file.

   Each directory sector has the following layout (18/1 partial dump):

   00: 12 04 81 11 00 4E 41 4D 45 53 20 26 20 50 4F 53 <- notice the T/S link
   10: 49 54 A0 A0 A0 00 00 00 00 00 00 00 00 00 15 00 <- to 18/4 ($12/$04)
   20: 00 00 84 11 02 41 44 44 49 54 49 4F 4E 41 4C 20 <- and how its not here
   30: 49 4E 46 4F A0 11 0C FE 00 00 00 00 00 00 61 01 <- ($00/$00)

   The first two bytes of the sector ($12/$04) indicate the location of  the
   next track/sector of the directory (18/4). If the track is set to $00, then
   it is the last sector of the directory. It is possible,  however  unlikely,
   that the directory may *not* be competely on track 18 (some disks do  exist
   like this). Just follow the chain anyhow.

   When the directory is done, the track value will be $00. The sector  link
   should contain a value of $FF, meaning the whole sector is  allocated,  but
   the actual value doesn't matter. The drive will return  all  the  available
   entries anyways. This is a breakdown of a  standard  directory  sector  and
   entry:

   Bytes: $00-1F: First directory entry
   00-01: Track/Sector location of next directory sector ($00 $00 if
   not the first entry in the sector)
   02: File type.
   Typical values for this location are:
   $00 - Scratched (deleted file entry)
   80 - DEL
   81 - SEQ
   82 - PRG
   83 - USR
   84 - REL
   Bit 0-3: The actual filetype
   000 (0) - DEL
   001 (1) - SEQ
   010 (2) - PRG
   011 (3) - USR
   100 (4) - REL
   Values 5-15 are illegal, but if used will produce
   very strange results. The 1541 is inconsistent in
   how it treats these bits. Some routines use all 4
   bits, others ignore bit 3,  resulting  in  values
   from 0-7.
   Bit   4: Not used
   Bit   5: Used only during SAVE-@ replacement
   Bit   6: Locked flag (Set produces ">" locked files)
   Bit   7: Closed flag  (Not  set  produces  "*", or "splat"
   files)
   03-04: Track/sector location of first sector of file
   05-14: 16 character filename (in PETASCII, padded with $A0)
   15-16: Track/Sector location of first side-sector block (REL file
   only)
   17: REL file record length (REL file only)
   18-1D: Unused (except with GEOS disks)
   1E-1F: File size in sectors, low/high byte  order  ($1E+$1F*256).
   The approx. filesize in bytes is <= #sectors * 254
   20-3F: Second dir entry. From now on the first two bytes of  each
   entry in this sector  should  be  $00  $00,  as  they  are
   unused.
   40-5F: Third dir entry
   60-7F: Fourth dir entry
   80-9F: Fifth dir entry
   A0-BF: Sixth dir entry
   C0-DF: Seventh dir entry
   E0-FF: Eighth dir entry

   Note: No GEOS entries are listed in the above description. See the GEOS.TXT
   file for GEOS info.


   The layout of the BAM area (sector 18/0) is a bit more complicated...

   00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
   -----------------------------------------------
   00: 12 01 41 00 12 FF F9 17 15 FF FF 1F 15 FF FF 1F
   10: 15 FF FF 1F 12 FF F9 17 00 00 00 00 00 00 00 00
   20: 00 00 00 00 0E FF 74 03 15 FF FF 1F 15 FF FF 1F
   30: 0E 3F FC 11 07 E1 80 01 15 FF FF 1F 15 FF FF 1F
   40: 15 FF FF 1F 15 FF FF 1F 0D C0 FF 07 13 FF FF 07
   50: 13 FF FF 07 11 FF CF 07 13 FF FF 07 12 7F FF 07
   60: 13 FF FF 07 0A 75 55 01 00 00 00 00 00 00 00 00
   70: 00 00 00 00 00 00 00 00 01 08 00 00 03 02 48 00
   80: 11 FF FF 01 11 FF FF 01 11 FF FF 01 11 FF FF 01
   90: 53 48 41 52 45 57 41 52 45 20 31 20 20 A0 A0 A0
   A0: A0 A0 56 54 A0 32 41 A0 A0 A0 A0 00 00 00 00 00
   B0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   D0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   F0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

   Bytes:$00-01: Track/Sector location of the first directory sector (should
   be set to 18/1 but it doesn't matter, and don't trust  what
   is there, always go to 18/1 for first directory entry)
   02: Disk DOS version type (see note below)
   $41 ("A")
   03: Unused
   04-8F: BAM entries for each track, in groups  of  four  bytes  per
   track, starting on track 1 (see below for more details)
   90-9F: Disk Name (padded with $A0)
   A0-A1: Filled with $A0
   A2-A3: Disk ID
   A4: Usually $A0
   A5-A6: DOS type, usually "2A"
   A7-AA: Filled with $A0
   AB-FF: Normally unused ($00), except for 40 track extended format,
   see the following two entries:
   AC-BF: DOLPHIN DOS track 36-40 BAM entries (only for 40 track)
   C0-D3: SPEED DOS track 36-40 BAM entries (only for 40 track)

   Note: The BAM entries for SPEED and DOLPHIN dos  use  the  same  layout  as
   standard BAM entries.

   One of the interesting things from the BAM sector is the byte  at  offset
   $02, the DOS version byte. If it is set to anything other than $41 or  $00,
   then we have what is called "soft write protection". Any attempt  to  write
   to the disk will return the "DOS Version" error code 73  ,"CBM  DOS  V  2.6
   1541". The 1541 is simply telling  you  that  it  thinks  the  disk  format
   version is incorrect. This message will normally come  up  when  you  first
   turn on the 1541 and read the error channel. If you write a $00  or  a  $41
   into 1541 memory location $00FF (for device 0),  then  you  can  circumvent
   this type of write-protection, and change the DOS version back to  what  it
   should be.

   The BAM entries require a bit (no pun intended) more of a breakdown. Take
   the first entry at bytes $04-$07 ($12 $FF $F9 $17). The first byte ($12) is
   the number of free sectors on that track. Since we are looking at the track
   1 entry, this means it has 18 (decimal) free sectors. The next three  bytes
   represent the bitmap of which sectors are used/free. Since it is 3 bytes (8
   bits/byte) we have 24 bits of storage. Remember that at  most,  each  track
   only has 21 sectors, so there are a few unused bits.

   Bytes: 04-07: 12 FF F9 17   Track 1 BAM
   08-0B: 15 FF FF FF   Track 2 BAM
   0C-0F: 15 FF FF 1F   Track 3 BAM
   ...
   8C-8F: 11 FF FF 01   Track 35 BAM

   These entries must be viewed in binary to make any sense. We will use the
   first entry (track 1) at bytes 04-07:

   FF=11111111, F9=11111001, 17=00010111

   In order to make any sense from the binary notation, flip the bits around.

   111111 11112222
   01234567 89012345 67890123
   --------------------------
   11111111 10011111 11101000
   ^                     ^
   sector 0              sector 20

   Since we are on the first track, we have 21 sectors, and only use  up  to
   the bit 20 position. If a bit is on (1), the  sector  is  free.  Therefore,
   track 1 has sectors 9,10 and 19 used, all the rest are free.

   Each filetype has its own unique properties, but most follow  one  simple
   structure. The first file sector is pointed to by the directory and follows
   a t/s chain, until the track value reaches  $00.  When  this  happens,  the
   value in the sector link location indicates how much of the sector is used.
   For example, the following chain indicates a file 6 sectors long, and  ends
   when we encounter the $00/$34 chain. At this point the last sector occupies
   from bytes $02-$34.

   1       2       3       4       5       6
   ----    -----   -----   -----   -----   -----
   17/0    17/10   17/20   17/1    17/11    0/52
   (11/00) (11/0A) (11/14) (11/01) (11/0B)  (0/34)


   ---------------------------------------------------------------------------

 *** REL files


   The REL filetype, however, has a most unusual structure. It was  designed
   to make access to data *anywhere* on the disk very fast.  Take  a  look  at
   this directory entry...

   00: 00 00 84 11 02 41 44 44 49 54 49 4F 4E 41 4C 20  ��..ADDITIONAL�
   10: 49 4E 46 4F A0 11 0C FE 00 00 00 00 00 00 61 01  INFO ..�������a.

   The third byte ($84) indicates this entry is a  REL  file  and  that  the
   three normally empty entries at offset $15, $16 and $17  are  now  used  as
   they are explained above. It's the sector chain that this entry  points  to
   (called the SIDE SECTORS) which are of interest here (in this case, 17/12).
   Here is a dump of the beginning of that sector...

   00: 0C 13 00 FE 11 0C 0C 13 06 09 00 00 00 00 00 00
   10: 11 02 11 0D 11 03 11 0E 11 04 11 0F 11 05 11 10

   Bytes:   $00: Track location of next side-sector ($00 if last sector)
   01: Sector location of next side-sector
   02: Side-sector block number (first sector is $00, the next  is
   $01, then $02, etc)
   03: REL file RECORD size (from directory entry)
   04-0F: Track/sector locations of the six other side-sectors.  Note
   the first entry is this very sector we  have  listed  here.
   The next is the next t/s listed at  the  beginning  of  the
   sector. All of this information must be correct. If one  of
   these chains is $00/$00, then we have no more side sectors.
   Also, all of these (up to six) side sectors must  have  the
   same values in this range.
   10-FF: T/S chains of *each* sector of the data  portion.  When  we
   get a $00/$00, we are at the end of the file.

   If the speed advantage regarding this type file file isn't  obvious  yet,
   consider the following scenario... If we  need  record  4000,  its  only  a
   couple of calculations to see how many bytes into the file it is (record# *
   record length). Once we know this, we can calculate how many  sectors  into
   the file it is (result/254). Now that we know the number of sectors, we can
   look it up in our side-sector tables to see where the record is. The  speed
   of this system is truly amazing, given the era of the  C64,  and  a  floppy
   drive.


   ---------------------------------------------------------------------------

 *** Variations on the D64 layout


   These are some variations of the D64 layout:

   1. Standard 35 track layout but with 683 error bytes added on to the  end
   of the file. Each byte of the  error  info  corresponds  to  a  single
   sector stored in the D64, indicating if the  sector  on  the  original
   disk contained an error. The first byte is for track 1/0, and the last
   byte is for track 35/16.

   2. A 40 track layout, following the same layout as a 35 track  disk,  but
   with 5 extra tracks. These contain 17 sectors each, like tracks 31-35.
   Some of the PC utilities do allow you to create and  work  with  these
   files.

   The location of the extra BAM  information  in  sector  18/0  will  be
   different depending on what standard the  disks  have  been  formatted
   with. SPEED DOS stores them from $C0 to $D3, and  DOLPHIN  DOS  stores
   them from $AC to $BF. 64COPY and Star Commander let  you  select  from
   several  different  types  of  extended  disk  formats  you  want   to
   create/work with.

   Disk type                  Size
   ---------                  ------
   35 track, no errors        174848
   35 track, 683 error bytes  175531
   40 track, no errors        196608
   40 track, 768 error bytes  197376


   Here is the meaning of the error bytes added onto the end of any extended
   D64. The CODE is the same as that generated by the 1541 drive controller...
   it reports these numbers, not the error code we usually see when  an  error
   occurs.

   Some of what comes  below  is  taken  from  Immers/Neufeld  book  "Inside
   Commodore DOS". Note the descriptions are not  completely  accurate  as  to
   what the drive DOS is actually doing to seek/read/decode/write sectors, but
   serve as simple examples only. The "type" field is where the error  usually
   occurs, but it can occur elsewhere.

   Code  Error  Type   1541 error description
   ----  -----  ----   ------------------------------
   01    00    N/A    No error.

   Self explanatory. No errors were  detected  in  the
   reading and decoding of the sector.


   02    20    Read   Header descriptor byte not found ($08)

   Each sector is preceeded by an 8-byte header block,
   which starts with the value $08. If this  value  is
   not $08, this error is generated.


   03    21    R/W    No sync sequence found.

   Each  sector  data  block  and  header  block   are
   preceeded by SYNC marks. If *no* sync  sequence  is
   found, then the  whole  track  is  unreadable,  and
   likely unformatted.


   04    22    Read   Data descriptor byte not found ($07)

   Each sector data block is preceeded  by  the  value
   $07, the "data block" descriptor. If this value  is
   not there, this error is  generated.  Each  encoded
   sector  has  actually  260  bytes.  First  is   the
   descriptor byte, then  follows  the  256  bytes  of
   data, a checksum, and two "off" bytes.


   05    23    Read   Checksum error in data block

   The checksum of  the  data  read  of  the  disk  is
   calculated, and compared against the one stored  at
   the end of the sector. If  there's  a  discrepancy,
   this error is generated.


   06    24    Write  Write verify (on format)


   07    25    Write  Write verify error

   Once the GCR-encoded sector  is  written  out,  the
   drive waits for the sector to come around again and
   verifies the whole 325-byte GCR block.  Any  errors
   encountered will generate this error.


   08    26    Write  Write protect on

   Self explanatory. Remove the write-protect tab, and
   try again.


   09    27    Seek   Checksum error in header block

   The 8-byte header block contains a checksum  value,
   calculated by XOR'ing the TRACK,  SECTOR,  ID1  and
   ID2 values. If this checksum is wrong,  this  error
   is generated.


   0A    28    Write  Write error

   In actual fact, this error never occurs, but it  is
   included for completeness.


   0B    29    Seek   Disk sector ID mismatch

   The ID's from the header  block  of  the  currently
   read sector are compared against the ones from  the
   header of 18/0. If there is a mismatch, this  error
   is generated.


   0F    74    Read   Drive Not Ready (no disk in drive or no device 1)


   The advantage with using the 35 track D64  format,  regardless  of  error
   bytes, is that it can be converted directly back to a 1541 disk  by  either
   using the proper cable and software on the PC, or send it down to  the  C64
   and writing it back to a 1541. It is the best documented format since it is
   also native to the C64, with many books explaining the disk layout and  the
   internals of the 1541.


   ---------------------------------------------------------------------------

   What it takes to support D64:


   The D64 layout is probably the most robust of all the  ones  that  exist,
   being that it is an electronic representation of a physical 1541  disk.  It
   shares *most* of the 1541 attributes and  it  supports  all  file  formats,
   since all C64 files came from here. The only file I have found  that  can't
   be copied to a D64 is a T64 FRZ (FRoZen image), since  you  lose  the  file
   type attribute.

   Since the D64 layout seems to be an exact byte copy of a 1541 floppy,  it
   would appear to be the perfect format for *any* emulator. However, it  does
   not contain certain vital bits of information that, as a user, you normally
   don't have access to.

   Preceeding each sector on a real 1541 disk, there is a header block which
   contains the sector ID bytes and checksum. From the  information  contained
   in the header, the drive determines if there's  an  error  on  that  header
   (27-checksum error, 29-disk ID mismatch). The sector itself  also  contains
   info (data block signature, checksum) that result in  error  detection  (23
   checksum, 22 data block not present, etc). The error bytes had to be  added
   on to the D64 image, "extending"  the  format  to  take  into  account  the
   missing info.

   The disk ID is important in the copy protection of  some  programs.  Some
   programs fail to work properly since the D64 doesn't  contain  these  ID's.
   These bytes would be an addition to the format which has  never  been  done
   and would be difficult to do. (As an aside, the  4-pack  ZipCode  files  do
   contain the original master disk ID, but these are lost in  the  conversion
   of a ZipCode to a D64. Only storing *one* of the ID's is  not  enough,  all
   the sector ID's should be kept.)

   The extended track 1541 disks also presented  a  problem,  as  there  are
   several different formats (and how/where to store the extra BAM entries  in
   a sector that was not designed for  them,  yet  still  remain  compatible).
   Because of the additions to the format (error bytes and  40  tracks)  there
   exists 4 different types of D64's, all recognizeable by their size.

   It is also the only format that uses the sector count for the  file  size
   rather than  actual  bytes  used.  This  can  present  some  problems  when
   converting/copying the to another format because you may have to  know  the
   size before you begin (see LBR format).

   It also contains no consistent signature, useful  for  recognizing  if  a
   file is really what it claims to be. In order to determine if a file  is  a
   D64, you must check the file size.

   ---------------------------------------------------------------------------

   Overall Good/Bad of D64 Files:

   Good
   ----
 * D64 files are the most widely supported and well-defined format, as  it
   is simply an electronic version of a 1541 disk

 * Supports *all* filenames, even those with $00's in them

 * Filenames are padded with the standard $A0 character

 * Supports GEOS and REL files

 * Allows complete directory customization

 * Because it is a random-access  device,  it  supports  fast-loaders  and
   random sector access

 * Cluster slack-space loss is minimized since the file is a larger  fixed
   size

 * Has a label (description) field

 * Format extentible to allow for 40-track disks

 * With  the  inclusion  of  error  bytes,  you  have  support  for  basic
   copy-protection

 * Files on a disk can easily be re-written, as  long  as  there  is  free
   blocks



   Bad
   ---
 * The format doesn't contain *all* the info from the 1541 disk (no sector
   header info like  ID  bytes,  checksums).  This  renders  some  of  the
   original special-loaders and copy-protection useless.

 * You don't *really* know the file size of the  contained  C64  files  in
   bytes, only blocks

 * It can't store C64s FRZ files due to FRZ files needing a  special  flag
   that a D64 can't store

 * It is not an expandable filesize, like LNX or T64

 * Unless most of the space on a D64 disk is used,  you  do  end  up  with
   wasted space

 * Directory limited to 144 files maximum

 * Cannot have loadable files with the same names

 * Has no recognizeable file signature (unlike most  other  formats).  The
   only reliable way to know if a file is a D64 is by its size

 * It is too easy for people to muck up the standard layout

 * It is much more difficult to support  fully,  as  you  really  need  to
   emulate the 1541 DOS (sector interleave, REL support, GEOS interleave)
 */
{
	import c64.storage.CMD;
	import c64.storage.LByteArray;
	
	public class D64 extends CMD implements Storable
	{	
		public function D64( fn:String=null )
		{
			super();
			
			filename = fn;
			
			EXTENSION 					 = 'D64';
			DOS_VERSION                  = 'A';
			DOS_TYPE                     = '2A';
			
			TRACKS           			 = 35;
			TOTAL_SECTORS    			 = 683;
			
			HEADER_TRACK     			 = 18;
			HEADER_SECTOR    			 = 0;
			HEADER_DISK_NAME_BYTE_OFFSET = 0x90;
			
			BAM_TRACK        			= 18;
			BAM_SECTOR_TO_TRACK_MAPPING = [ [0, 1, 35] ];		    
			BAM_BYTE_OFFSET    		    = 0x04;
			BAM_BYTES_PER_TRACK 		= 4;
			BAM_SECTOR_BYTES_PER_TRACK  = 3;
			
			DIRECTORY_TRACK  			= 18;
			DIRECTORY_SECTOR 			= 1;
			DIRECTORY_INTERLEAVE 		= 3;
			
			SECTORS_IN_TRACK =
				[
				0,                                                                   // "0"
				21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,  // 1-17
				19, 19, 19, 19, 19, 19, 19,                                          // 18-24
				18, 18, 18, 18, 18, 18,                                              // 25-30
				17, 17, 17, 17, 17                                                   // 31-35
//        	17, 17, 17, 17, 17                                                   // 36-40
				];
			
			TRACK_OFFSET = 
				[
				0x0,                                                                                       // "track 0"
				0x0,     0x01500,    0x02a00,    0x03f00,    0x05400,    0x06900,    0x07e00,    0x09300,  // 1-8
				0x0a800, 0x0bd00,    0x0d200,    0x0e700,    0x0fc00,    0x11100,    0x12600,    0x13b00,  // 9-16
				0x15000, 0x16500,    0x17800,    0x18b00,    0x19e00,    0x1b100,    0x1c400,    0x1d700,  // 17-24
				0x1ea00, 0x1fc00,    0x20e00,    0x22000,    0x23200,    0x24400,    0x25600,    0x26700,  // 25-32
				0x27800, 0x28900,    0x29a00                                                               // 33-35
				];
			
			SECTOR_OFFSET =
				[
				0,
				0,21,42,63,84,105,126,147,168,189,210,231,252,273,294,315,336,
				357,376,395,414,433,452,471,
				490,508,526,544,562,580,
				598,615,632,649,666
//			683,700,717,734,751	// Tracks 36..40
				];
			
			TRACK_WRITE_ORDER =
				[
				17,16,15,19,20,21,14,13,12,22,23,24,11,10,9,25,26,27,8,7,6,28,29,30,5,4,3,31,32,33,2,1,34,35
				];
		
		}
		
		override public function getBAM():LByteArray
		{
			var sec:LByteArray = trackList[BAM_TRACK][0];
			var bam:LByteArray = new LByteArray();
			
			bam.readBytes( sec, BAM_BYTE_OFFSET, TRACKS * BAM_BYTES_PER_TRACK );
			return bam; 
		}
		
		override public function writeBamHeader( image:LByteArray ):void
		{
			// nothing to do here.  the disk header does all the work: the D64 essentially combines the two.
		}
	}
}


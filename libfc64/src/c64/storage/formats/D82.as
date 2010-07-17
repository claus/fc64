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
The CBM 8250 supports 77 tracks per side with 23 to 29 sectors per track, f
or a total of 4,166 sectors; BAM in four sectors on track 38 (0, 3, 6 and 9), 
and directory entries on track 39; A total of 224 free file slots (29 sectors). 
4,133 blocks are free on a freshly formatted disk.

This format was also used by the prototype SFD 1001 ("Super Floppy Drive").

Nicolas Welte has provided an analysis of the 8050/8250 disk format.

CBM8050/8250 Format

29 sectors/track for track 1-39 /78-116
27 sectors/track for track 40-53/117-130
25 sectors/track for track 54-64/131-141
23 sectors/track for track 65-77/142-154

BAM on track 38 (8050 2 blocks, 8250 4 blocks, rest is free for files)
DIR on track 39 (1 block for header, 28 blocks for dir entries)


*** D80 (Disk image of an 8050 diskette, single-sided)
*** D82 (Disk image of an 8250 diskette, double-sided)
*** Document revision: 1.3
*** Last updated: Nov 7, 2008
*** Compiler/Editor: Peter Schepers
*** Contributors/sources: "Complete Commodore Innerspace Anthology"

  This is a sector-for-sector copy of an 8x50 floppy disk.  The  file  size
for an 8050 image is 533248 bytes, and the 8250 image is 1066496 bytes.  It
is comprised of 256-byte sectors arranged across 77 tracks (or 154  for  an
8250), with a varying number of sectors per  track  for  a  total  of  2083
sectors (or 4166 for an 8250). Track counting  starts  at  1  (not  0)  and
sector counting starts at 0 (not 1), therefore a track with 29 sectors will
go from 0 to 28.

  The only sample files I had to work with were those created by  the  VICE
emulator. I can only assume that the way VICE  worked  with  the  image  is
correct and all of the image specifics contained herein are based on  those
samples. Any deviation from the way that the 8x50 drive actually  works  is
unfortunate but unavoidable.

  The original media (a 5.25" disk) has the tracks  laid  out  in  circles,
with track 1 on the very outside of the disk  (closest  to  the  sides)  to
track 77 being on the inside of the disk (closest to the inner  hub  ring).
Commodore, in their infinite wisdom, varied the number of sectors per track
and data densities across the disk to optimize available storage, resulting
in the chart below. It shows the sectors/track for a D80 and D82. Since the
outside diameter of a circle is the largest (versus closer to the  center),
the outside tracks have the largest amount of storage.


        Track Range    Sectors/track   # Sectors
      --------------   -------------   ---------
       1-39,  78-116        29           1131
      40-53, 117-130        27            378
      54-64, 131-141        25            275
      65-77, 142-154        23            299
                                         ----
                                  Total  2083 (double this for an 8250)


  Track #Sect #SectorsIn D8x Offset | Track #Sect #SectorsIn D8x Offset
  ----- ----- ---------- ---------- | ----- ----- ---------- ----------
   1     29      0        $000000   |  78    29      2083      $82300
   2     29      29          1D00   |  79    29      2112       84000
   3     29      58          3A00   |  80    29      2141       85D00
   4     29      87          5700   |  81    29      2170       87A00
   5     29      116         7400   |  82    29      2199       89700
   6     29      145         9100   |  83    29      2228       8B400
   7     29      174         AE00   |  84    29      2257       8D100
   8     29      203         CB00   |  85    29      2286       8EE00
   9     29      232         E800   |  86    29      2315       90600
   10    29      261        10500   |  87    29      2344       92800
   11    29      290        12200   |  88    29      2373       94500
   12    29      319        13F00   |  89    29      2402       96200
   13    29      348        15C00   |  90    29      2431       97F00
   14    29      377        17900   |  91    29      2460       99C00
   15    29      406        19600   |  92    29      2489       9B900
   16    29      435        1B300   |  93    29      2518       9D600
   17    29      464        1D000   |  94    29      2547       9F300
   18    29      493        1ED00   |  95    29      2576       A1000
   19    29      522        20A00   |  96    29      2605       A2D00
   20    29      551        22700   |  97    29      2634       A4A00
   21    29      580        24400   |  98    29      2663       A6700
   22    29      609        26100   |  99    29      2692       A8400
   23    29      638        27E00   |  100   29      2721       AA100
   24    29      667        29B00   |  101   29      2750       A6E00
   25    29      696        2B800   |  102   29      2779       ADB00
   26    29      725        2D500   |  103   29      2808       AF800
   27    29      754        2F200   |  104   29      2837       B1500
   28    29      783        30F00   |  105   29      2866       B3200
   29    29      812        32C00   |  106   29      2895       B4F00
   30    29      841        34900   |  107   29      2924       B6C00
   31    29      870        36600   |  108   29      2953       B8900
   32    29      899        38300   |  109   29      2982       BA600
   33    29      928        3A000   |  110   29      3011       BC300
   34    29      957        3BD00   |  111   29      3040       BE000
   35    29      986        3DA00   |  112   29      3069       BFD00
   36    29      1015       3F700   |  113   29      3098       C1A00
   37    29      1044       41400   |  114   29      2137       C3700
   38    29      1073       43100   |  115   29      3156       C5400
   39    29      1102       44E00   |  116   29      3185       C7100
   40    27      1131       46B00   |  117   27      3214       C8E00
   41    27      1158       48600   |  118   27      3241       CA900
   42    27      1185       4A100   |  119   27      3268       CC400
   43    27      1212       4BC00   |  120   27      3295       CDF00
   44    27      1239       4D700   |  121   27      3322       CFA00
   45    27      1266       4F200   |  122   27      3349       D1500
   46    27      1293       50D00   |  123   27      3376       D3000
   47    27      1320       52800   |  124   27      3403       D4B00
   48    27      1347       54300   |  125   27      3430       D6600
   49    27      1374       55E00   |  126   27      3457       D8100
   50    27      1401       57900   |  127   27      3484       D9C00
   51    27      1428       59400   |  128   27      3511       DB700
   52    27      1455       5AF00   |  129   27      3538       DD200
   53    27      1482       5CA00   |  130   27      3565       DED00
   54    25      1509       5E500   |  131   25      3592       E0800
   55    25      1534       5FE00   |  132   25      3617       E2100
   56    25      1559       61700   |  133   25      3642       E3A00
   57    25      1584       63000   |  134   25      3667       E5300
   58    25      1609       64900   |  135   25      3692       E6C00
   59    25      1634       66200   |  136   25      3717       E8500
   60    25      1659       67B00   |  137   25      3742       E9E00
   61    25      1684       69400   |  138   25      3767       E6700
   62    25      1709       6AD00   |  139   25      3792       ED000
   63    25      1734       6C600   |  140   25      3817       EE900
   64    25      1759       6DF00   |  141   25      3842       F0200
   65    23      1784       6F800   |  142   23      3867       F1B00
   66    23      1807       70F00   |  143   23      3890       F3200
   67    23      1830       72600   |  144   23      3913       F4900
   68    23      1853       73D00   |  145   23      3936       F6000
   69    23      1876       75400   |  146   23      3959       F7700
   70    23      1899       76B00   |  147   23      3982       F8E00
   71    23      1922       78200   |  148   23      4005       FA500
   72    23      1945       79900   |  149   23      4028       FBC00
   73    23      1968       7B000   |  150   23      4051       FD300
   74    23      1991       7C700   |  151   23      4074       FEA00
   75    23      2014       7DE00   |  152   23      4097      100100
   76    23      2037       7F500   |  153   23      4120      101800
   77    23      2060       80C00   |  154   23      4143      102F00

  The BAM (Block Availability Map) is on track  38.  The  D80  is  only  77
tracks and so the BAM is contained on 38/0 and 38/3. The D82  contains  154
tracks and so the BAM is larger and is contained on 38/0,  38/3,  38/6  and
38/9. The BAM interleave is 3.

  The directory is on track 39, with 39/0 contains the  header  (DOS  type,
disk name, disk ID's) and sectors 1-28 contain the directory entries.  Both
files and the directory use an interleave of 1. Since the directory is only
28 sectors large (29 less one for the header), and each sector can  contain
only 8 entries (32 bytes  per  entry),  the  maximum  number  of  directory
entries is 28 * 8 = 224. The first directory sector is always 39/1. It then
follows a chain structure using a sector interleave of 1 making  the  links
go 39/1, 39/2, 39/3 etc.

  When reading a disk, you start with 39/0 (disk label/ID) which points  to
38/0 (BAM0), 38/3 (BAM1), 38/6 (BAM2, D82 only), 38/9 (BAM3, D82 only), and
finally to 39/1 (first dir entry sector). When writing a file  to  a  blank
disk, it will start at 38/1 because 38/0 is already allocated.


Below is a dump of the header sector 39/0:

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 26 00 43 00 00 00 73 61 6D 70 6C 65 20 64 38 30  &úCúúúsampleúd80
10: A0 A0 A0 A0 A0 A0 A0 A0 65 72 A0 32 43 A0 A0 A0          er 2C   
20: A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   úúúúúúúúúúúúúúú
...
F0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to first BAM sector (38/0)
           02: $43 'C' is for DOS format version
           03: Reserved
        04-05: Unused
        06-16: Disk name, padded with 0xA0 ("sample d80")
           17: 0xA0
        18-19: Disk ID bytes "er"
           1A: 0xA0
        1B-1C: DOS version bytes "2C".
        1D-20: 0xA0
        21-FF: Unused


Below is a dump of the first directory sector, 39/1

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 27 02 82 26 01 54 45 53 54 A0 A0 A0 A0 A0 A0 A0  'ú‚&úTEST       
10: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 01 00       úúúúúúúúúúú
20: 00 00 82 26 02 54 45 53 54 32 A0 A0 A0 A0 A0 A0  úú‚&úTEST2      
30: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 01 00       úúúúúúúúúúú
40: 00 00 82 26 04 54 45 53 54 33 A0 A0 A0 A0 A0 A0  úú‚&úTEST3      
50: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 05 00       úúúúúúúúúúú
60: 00 00 82 26 0B 54 45 53 54 34 A0 A0 A0 A0 A0 A0  úú‚&úTEST4      
70: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 09 00       úúúúúúúúúúú
80: 00 00 82 26 14 54 45 53 54 35 A0 A0 A0 A0 A0 A0  úú‚&úTEST5      
90: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 0C 00       úúúúúúúúúúú
A0: 00 00 82 28 00 54 45 53 54 36 A0 A0 A0 A0 A0 A0  úú‚(úTEST6      
B0: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 01 00       úúúúúúúúúúú
C0: 00 00 82 28 01 54 45 53 54 37 A0 A0 A0 A0 A0 A0  úú‚(úTEST7      
D0: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 01 00       úúúúúúúúúúú
E0: 00 00 82 28 02 54 45 53 54 38 A0 A0 A0 A0 A0 A0  úú‚(úTEST8      
F0: A0 A0 A0 A0 A0 00 00 00 00 00 00 00 00 00 01 00       úúúúúúúúúúú

  The first two bytes  of  the  directory  sector  ($27/$02)  indicate  the
location of the next track/sector of the directory (39/2). If the track  is
set to $00, then it is the last sector of the directory.

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
                          very strange results.
                 Bit   4: Not used
                 Bit   5: Used only during SAVE-@ replacement
                 Bit   6: Locked flag (Set produces ">" locked files)
                 Bit   7: Closed flag  (Not  set  produces  "*", or "splat"
                          files)
          03-04: Track/sector location of first sector of file
          05-14: 16 character filename (in PETASCII, padded with $A0)
          15-16: Track/Sector location of first side-sector block (REL file
                 only)
             17: REL file record length (REL file only, max. value 254)
          18-1D: Unused
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


*** Non-Standard & Long Directories

  Most Commdore floppy disk drives use a single dedicated  directory  track
where all filenames are stored. This limits the number of files stored on a
disk based on the number of sectors on the directory track. There are  some
disk images that contain more files than would normally  be  allowed.  This
requires extending  the  directory  off  the  default  directory  track  by
changing the last directory sector pointer to a new track,  allocating  the
new sectors in the BAM, and manually  placing  (or  moving  existing)  file
entries there. The directory of an extended disk can be read and the  files
that reside there can be loaded without problems on a real drive.  However,
this is still a very dangerous practice as writing to the extended  portion
of the directory will cause directory corruption in the non-extended  part.
Many of the floppy drives core ROM routines ignore the track value that the
directory is on and assume the default directory track for operations.

  To explain: assume that the directory has been extended from track 18  to
track 19/6 and that the directory is full except for a few slots  on  19/6.
When saving a new file, the drive DOS will find an empty file slot at  19/6
offset $40 and correctly write the filename and a  few  other  things  into
this slot. When the file is done being saved  the  final  file  information
will be written to 18/6 offset $40 instead of 19/6 causing  some  directory
corruption to the entry at 18/6. Also, the  BAM  entries  for  the  sectors
occupied by the new file will not be saved and the new file will be left as
a SPLAT (*) file.

  Attempts to validate the disk will result in those files residing off the
directory track to not be allocated in the BAM, and  could  also  send  the
drive into an endless loop. The default directory track is assumed for  all
sector reads when validating so if the directory goes  to  19/6,  then  the
validate code will read 18/6  instead.  If  18/6  is  part  of  the  normal
directory chain then the validate routine will loop endlessly. 


*** BAM layout

  The BAM only occupies up to four sectors on track 38, so the rest of  the
track is empty and is available for file storage. Below is a  dump  of  the
first BAM block, 38/0. A D80 will only contain two BAM  sectors,  38/0  and
38/3. A D82 needs two extra BAM sectors for the extra  tracks.  Each  entry
takes 5 bytes, 1 for the free count on that track, and 4 for the BAM bits.

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 26 03 43 00 01 33 1D FF FF FF 1F 1D FF FF FF 1F  &úCúú3úúúúúúúúúú
10: 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D  úúúúúúúúúúúúúúúú
20: FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF  úúúúúúúúúúúúúúúú
30: FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF  úúúúúúúúúúúúúúúú
40: FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF  úúúúúúúúúúúúúúúú
50: 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F  úúúúúúúúúúúúúúúú
60: 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D  úúúúúúúúúúúúúúúú
70: FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF  úúúúúúúúúúúúúúúú
80: FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF  úúúúúúúúúúúúúúúú
90: FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF  úúúúúúúúúúúúúúúú
A0: 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F  úúúúúúúúúúúúúúúú
B0: 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1B  úúúúúúúúúúúúúúúú
C0: F6 FF FF 1F 1B FC FF FF 1F 1B FF FF FF 07 1B FF  öúúúúüúúúúúúúúúú
D0: FF FF 07 1B FF FF FF 07 1B FF FF FF 07 1B FF FF  úúúúúúúúúúúúúúúú
E0: FF 07 1B FF FF FF 07 1B FF FF FF 07 1B FF FF FF  úúúúúúúúúúúúúúúú
F0: 07 1B FF FF FF 07 1B FF FF FF 07 1B FF FF FF 07  úúúúúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to second BAM sector (38/3)
           02: DOS version byte (0x43='C')
           03: Reserved
           04: Lowest track covered by this BAM (0x01=1)
           05: Highest+1 track covered by this BAM (0x33=51)
        06-0A: BAM for track 1. The first byte shows the "blocks free"  for
               this track, the remaining 4 show the BAM for the track.
        0B-0F: BAM for track 2
        ...
        FB-FF: BAM for track 50


  Being bit-based, the BAM entries need some explanation. The  first  track
entry in the above BAM sector is at offset 06, "1D FF FF FF 1F". The  first
number is how many blocks are free on this track ($1D=29) and the remainder
is the bit representation of the usage map for  the  track.  These  entries
must be viewed in binary to make any sense. First  convert  the  values  to
binary:

     FF=11111111, FF=11111111, FF=11111111, 1F=00011111

In order to make any sense from the binary notation, flip the bits around.

                   111111 11112222 222222
        01234567 89012345 67890123 456789...
        -------------------------- ---------
        11111111 11111111 11111111 11111000
        ^                              ^
    sector 0                       sector 28

  Since we are on the first track, we have 29 sectors, and only use  up  to
the bit 28 position. If a bit is on (1), the  sector  is  free.  Therefore,
track 1 is clean, all sectors are free. Any leftover  bits  that  refer  to
sectors that don't exist, like bits 29-31 in the above example, are set  to
allocated.



Second BAM block 38/3, D80 only.

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 27 01 43 00 33 4E 1B FF FF FF 07 1B FF FF FF 07  'úCú3Núúúúúúúúúú
10: 1B FF FF FF 07 19 FF FF FF 01 19 FF FF FF 01 19  úúúúúúúúúúúúúúúú
20: FF FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19 FF  úúúúúúúúúúúúúúúú
30: FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19 FF FF  úúúúúúúúúúúúúúúú
40: FF 01 19 FF FF FF 01 19 FF FF FF 01 17 FF FF 7F  úúúúúúúúúúúúúúú
50: 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00  úúúúúúúúúúúúú
60: 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 17  úúúúúúúúúúúúú
70: FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF  úúúúúúúúúúúúú
80: FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 00 00 00  úúúúúúúúúúúúú
90: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
A0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
B0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
D0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
F0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to first directory sector (39/1)
           02: DOS version byte (0x43 'C')
           03: Reserved
           04: Lowest track covered by this BAM (0x33=51)
           05: Highest+1 track covered by this BAM (0x43=78)
        06-0A: BAM for track 51. The first byte shows the "blocks free" for
               this track, the remaining 4 show the BAM for the track.
        0B-0F: BAM for track 52
        ...
        88-8C: BAM for track 77
        8D-FF: Not used for an D80 (8050)


Second BAM block 38/3, D82 only

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 26 06 43 00 33 65 1B FF FF FF 07 1B FF FF FF 07  &úCú3eúúúúúúúúúú
10: 1B FF FF FF 07 19 FF FF FF 01 19 FF FF FF 01 19  úúúúúúúúúúúúúúúú
20: FF FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19 FF  úúúúúúúúúúúúúúúú
30: FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19 FF FF  úúúúúúúúúúúúúúúú
40: FF 01 19 FF FF FF 01 19 FF FF FF 01 17 FF FF 7F  úúúúúúúúúúúúúúú
50: 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00  úúúúúúúúúúúúú
60: 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 17  úúúúúúúúúúúúú
70: FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF  úúúúúúúúúúúúú
80: FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 1D FF FF  úúúúúúúúúúúúú
90: FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF  úúúúúúúúúúúúúúúú
A0: 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F  úúúúúúúúúúúúúúúú
B0: 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D  úúúúúúúúúúúúúúúú
C0: FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF  úúúúúúúúúúúúúúúú
D0: FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF  úúúúúúúúúúúúúúúú
E0: FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF  úúúúúúúúúúúúúúúú
F0: 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F  úúúúúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to second BAM sector (38/6)
           02: DOS version byte (0x43='C')
           03: Reserved
           04: Lowest track covered by this BAM (0x33=51)
           05: Highest+1 track covered by this BAM (0x65=101)
        06-0A: BAM for track 51. The first byte shows the "blocks free" for
               this track, the remaining 4 show the BAM for the track.
        0B-0F: BAM for track 52
        ...
        FB-FF: BAM for track 100


Third BAM block 38/6, D82 only

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 26 09 43 00 65 97 1D FF FF FF 1F 1D FF FF FF 1F  &úCúe—úúúúúúúúúú
10: 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D  úúúúúúúúúúúúúúúú
20: FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF  úúúúúúúúúúúúúúúú
30: FF FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF  úúúúúúúúúúúúúúúú
40: FF 1F 1D FF FF FF 1F 1D FF FF FF 1F 1D FF FF FF  úúúúúúúúúúúúúúúú
50: 1F 1D FF FF FF 1F 1B FF FF FF 07 1B FF FF FF 07  úúúúúúúúúúúúúúúú
60: 1B FF FF FF 07 1B FF FF FF 07 1B FF FF FF 07 1B  úúúúúúúúúúúúúúúú
70: FF FF FF 07 1B FF FF FF 07 1B FF FF FF 07 1B FF  úúúúúúúúúúúúúúúú
80: FF FF 07 1B FF FF FF 07 1B FF FF FF 07 1B FF FF  úúúúúúúúúúúúúúúú
90: FF 07 1B FF FF FF 07 1B FF FF FF 07 19 FF FF FF  úúúúúúúúúúúúúúúú
A0: 01 19 FF FF FF 01 19 FF FF FF 01 19 FF FF FF 01  úúúúúúúúúúúúúúúú
B0: 19 FF FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19  úúúúúúúúúúúúúúúú
C0: FF FF FF 01 19 FF FF FF 01 19 FF FF FF 01 19 FF  úúúúúúúúúúúúúúúú
D0: FF FF 01 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF  úúúúúúúúúúúúúú
E0: 7F 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F  úúúúúúúúúúúú
F0: 00 17 FF FF 7F 00 17 FF FF 7F 00 17 FF FF 7F 00  úúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to fourth BAM sector (38/9)
           02: DOS version byte (0x43='C')
           03: Reserved
           04: Lowest track covered by this BAM (0x65=101)
           05: Highest+1 track covered by this BAM (0x97=151)
        06-0A: BAM for track 101. The first byte shows  the  "blocks  free"
               for this track, the remaining 4 show the BAM for the track.
        0B-0F: BAM for track 102
        ...
        FB-FF: BAM for track 150


Fourth BAM block 38/9, D82 only

    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F       ASCII
    -----------------------------------------------  ----------------
00: 27 01 43 00 97 9B 17 FF FF 7F 00 17 FF FF 7F 00  'úCú—›úúúúúúúú
10: 17 FF FF 7F 00 17 FF FF 7F 00 00 00 00 00 00 00  úúúúúúúúúúúúúú
20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
30: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú
40: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  úúúúúúúúúúúúúúúú

  Byte:$00-01: T/S pointer to first directory sector (39/1)
           02: DOS version byte (0x43 'C')
           03: Reserved
           04: Lowest track covered by this BAM (0x97=151)
           05: Highest+1 track covered by this BAM (0x9B=155)
        06-0A: BAM for track 151. The first byte shows the "blocks free" for
               this track, the remaining 4 show the BAM for the track.
        0B-0F: BAM for track 152
        ...
        15-19: BAM for track 154
        1A-FF: Not used
*/
{
	import storage.CMD;
	import storage.LByteArray;

	public class D82 extends CMD implements Storable
	{
		public function D82( fn:String=null )
		{
			super();

			filename = fn;

			EXTENSION 					 = 'D82';
			DOS_VERSION                  = 'C';
			DOS_TYPE                     = '2C';

			TRACKS 					     = 154;
			TOTAL_SECTORS                = 4166;
			
			HEADER_TRACK                 = 39;
			HEADER_SECTOR                = 0;
		    HEADER_DISK_NAME_BYTE_OFFSET = 0x06;

			BAM_TRACK                    = 38;
			BAM_SECTOR_TO_TRACK_MAPPING  = [ [ 0, 1, 50 ], [ 3, 51, 100 ], [ 6, 101, 150 ], [ 9, 151, 154 ] ];
		    BAM_BYTE_OFFSET    		     = 0x06;
			BAM_BYTES_PER_TRACK          = 5;
			BAM_SECTOR_BYTES_PER_TRACK   = 4;

			DIRECTORY_TRACK              = 39;
			DIRECTORY_SECTOR             = 1;
			DIRECTORY_INTERLEAVE		 = 1;

    		SECTORS_IN_TRACK = 
    		[
        		0,    
        		29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,  // tracks 1-39
        		29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,
        		27,27,27,27,27,27,27,27,27,27,27,27,27,27,                    // tracks 40-53
        		25,25,25,25,25,25,25,25,25,25,25,                             // tracks 54-64
        		23,23,23,23,23,23,23,23,23,23,23,23,23,                       // tracks 65-77

        		29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,  // tracks 77+ 1-39
        		29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,
        		27,27,27,27,27,27,27,27,27,27,27,27,27,27,                    // tracks 77 + 40-53
        		25,25,25,25,25,25,25,25,25,25,25,                             // tracks 77 + 54-64
        		23,23,23,23,23,23,23,23,23,23,23,23,23                        // tracks 77 + 65-77
    		];	
    		
    		TRACK_OFFSET =
    		[	
    			0, 
    			0,
    			0x0000,0x1D00,0x3A00,0x5700,0x7400,0x9100,0xAE00,0xCB00,0xE800,0x10500,
    			0x12200,0x13F00,0x15C00,0x17900,0x19600,0x1B300,0x1D000,0x1ED00,0x20A00,
    			0x22700,0x24400,0x26100,0x27E00,0x29B00,0x2B800,0x2D500,0x2F200,0x30F00,
    			0x32C00,0x34900,0x36600,0x38300,0x3A000,0x3BD00,0x3DA00,0x3F700,0x41400,
    			0x43100,0x44E00,0x46B00,0x48600,0x4A100,0x4BC00,0x4D700,0x4F200,0x50D00,
    			0x52800,0x54300,0x55E00,0x57900,0x59400,0x5AF00,0x5CA00,0x5E500,0x5FE00,
    			0x61700,0x63000,0x64900,0x66200,0x67B00,0x69400,0x6AD00,0x6C600,0x6DF00,
    			0x6F800,0x70F00,0x72600,0x73D00,0x75400,0x76B00,0x78200,0x79900,0x7B000,
    			0x7C700,0x7DE00,0x7F500,0x80C00,0x82300,0x84000,0x85D00,0x87A00,0x89700,
    			0x8B400,0x8D100,0x8EE00,0x90600,0x92800,0x94500,0x96200,0x97F00,0x99C00,
    			0x9B900,0x9D600,0x9F300,0xA1000,0xA2D00,0xA4A00,0xA6700,0xA8400,0xAA100,
    			0xA6E00,0xADB00,0xAF800,0xB1500,0xB3200,0xB4F00,0xB6C00,0xB8900,0xBA600,
    			0xBC300,0xBE000,0xBFD00,0xC1A00,0xC3700,0xC5400,0xC7100,0xC8E00,0xCA900,
    			0xCC400,0xCDF00,0xCFA00,0xD1500,0xD3000,0xD4B00,0xD6600,0xD8100,0xD9C00,
    			0xDB700,0xDD200,0xDED00,0xE0800,0xE2100,0xE3A00,0xE5300,0xE6C00,0xE8500,
    			0xE9E00,0xE6700,0xED000,0xEE900,0xF0200,0xF1B00,0xF3200,0xF4900,0xF6000,
    			0xF7700,0xF8E00,0xFA500,0xFBC00,0xFD300,0xFEA00,0x100100,0x101800,0x102F00
			];
			
	   		SECTOR_OFFSET =
    		[
				0,
				0,29,58,87,116,145,174,203,232,261,290,319,348,377,406,435,464,493,522,551,580,
				609,638,667,696,725,754,783,812,841,870,899,928,957,986,1015,1044,1073,1102,1131,
				1158,1185,1212,1239,1266,1293,1320,1347,1374,1401,1428,1455,1482,1509,1534,1559,
				1584,1609,1634,1659,1684,1709,1734,1759,1784,1807,1830,1853,1876,1899,1922,1945,
				1968,1991,2014,2037,2060,2083,2112,2141,2170,2199,2228,2257,2286,2315,2344,2373,
				2402,2431,2460,2489,2518,2547,2576,2605,2634,2663,2692,2721,2750,2779,2808,2837,
				2866,2895,2924,2953,2982,3011,3040,3069,3098,2137,3156,3185,3214,3241,3268,3295,
				3322,3349,3376,3403,3430,3457,3484,3511,3538,3565,3592,3617,3642,3667,3692,3717,
				3742,3767,3792,3817,3842,3867,3890,3913,3936,3959,3982,4005,4028,4051,4074,4097,
				4120,4143
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
				91,92,93,94,95,96,97,98,99,100,
				101,102,103,104,105,106,107,108,109,110,
				111,112,113,114,115,116,117,118,119,120,
				121,122,123,124,125,126,127,128,129,130,
				131,132,133,134,135,136,137,138,139,140,
				141,142,143,144,145,146,147,148,149,150,
				151,152,153,154
			]
		}
		
		/*
		  Byte:$00-01: T/S pointer to second BAM sector (38/3)
           02: DOS version byte (0x43='C')
           03: Reserved
           04: Lowest track covered by this BAM (0x01=1)
           05: Highest+1 track covered by this BAM (0x33=51)
		 */
		 
		 
		// perhaps superseded by CMD's default method... 
/* 		override public function writeBamHeader( image:LByteArray ):void
		{
			// position image to beginning of BAM block
			var offset:int = SECTOR_OFFSET[BAM_TRACK] * 256;
			
			// sector 0
			// write next Track=38
			// write next Sector=3
			// write DOS version = 0x43 'C' == DOS_VERSION.charCodeAt(0)
			image[ offset + 0x00 ] = 38;
			image[ offset + 0x01 ] = 3;
			image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
			image[ offset + 0x03 ] = 0;
			image[ offset + 0x04 ] = 1;
			image[ offset + 0x05 ] = 51;

			// sector 3
			// write next Track=38
			// write next Sector=6
			// write DOS version = 0x43 'C'
			offset += 256 * 3;
			image[ offset + 0x00 ] = 38;
			image[ offset + 0x01 ] = 6;
			image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
			image[ offset + 0x03 ] = 0;
			image[ offset + 0x04 ] = 51;
			image[ offset + 0x05 ] = 101;

			// sector 6
			// write next Track=38
			// write next Sector=9
			// write DOS version = 0x43 'C'
			offset += 256 * 6;
			image[ offset + 0x00 ] = 38;
			image[ offset + 0x01 ] = 9;
			image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
			image[ offset + 0x03 ] = 0;
			image[ offset + 0x04 ] = 101;
			image[ offset + 0x05 ] = 151;

			// sector 9
			// write next Track=39
			// write next Sector=1
			// write DOS version = 0x43 'C'
			offset += 256 * 9;
			image[ offset + 0x00 ] = DIRECTORY_TRACK;
			image[ offset + 0x01 ] = DIRECTORY_SECTOR;
			image[ offset + 0x02 ] = DOS_VERSION.charCodeAt(0);
			image[ offset + 0x03 ] = 0;
			image[ offset + 0x04 ] = 151;
			image[ offset + 0x05 ] = 155;
			
			// done
		} */
	}
}
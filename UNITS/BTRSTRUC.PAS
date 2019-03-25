UNIT BtrStruc;
{ file sizes for btreive files used by afs:Trade }

interface

TYPE
  BTRFile = RECORD
     name : STRING;
     RecSize : INTEGER;
  END;

CONST
  FCusip    : BTRFile = (name : 'h:\apps\afstrade\cusip290.btr'; RecSize :290);
  FCurrLots : BTRFile = (name : 'h:\apps\afstrade\currlots.btr'; RecSize : 80);
  FBlocks   : BTRFile = (name : 'h:\apps\fstrade\blockfil.btr'; RecSize :  6);
  FTransact : BTRFile = (name : 'h:\apps\afstrade\transfil.btr'; RecSize : 185);

implementation
END.

{
 File Stats for CURRLOTS.BTR
     Record Length = 80            Compressed Records = No
  Variable Records = Yes         Free Space Threshold = 5%
    Number of Keys = 2
         Page Size = 512                 Unused Pages = 0
     Total Records = 1590

   Key  Position  Length  Duplicates  Modifiable   Type    Null      Total

     0     13        9        No          Yes     String    --         1590
     0      1       12        No          Yes     String    --         1590
     1      1       21        No          Yes     String    --         1590


 File Stats for BLOCKFIL.BTR
     Record Length = 6             Compressed Records = No
  Variable Records = No
    Number of Keys = 2
         Page Size = 512                 Unused Pages = 0
     Total Records = 8230

   Key  Position  Length  Duplicates  Modifiable   Type    Null      Total

     0      3        4        No          Yes     Unsigned  --         8230
     1      1        2        No          Yes     Unsigned  --         8230
     1      3        4        No          Yes     Unsigned  --         8230


Btrieve Utilities Version 5.00
Copyright 1982, 1988, Novell, Inc.  All Rights Reserved.

 File Stats for TRANSFIL.BTR
     Record Length = 185           Compressed Records = No
  Variable Records = No
    Number of Keys = 5
         Page Size = 2048                Unused Pages = 0
     Total Records = 8232

   Key  Position  Length  Duplicates  Modifiable   Type    Null      Total

     0     10        4        No          Yes     Unsigned  --         8232
     1     15        2        No          Yes     Unsigned  --         8232
     1     10        4        No          Yes     Unsigned  --         8232
     2      1        9        No          Yes     String    --         8232
     2     15        2        No          Yes     Unsigned  --         8232
     2     10        4        No          Yes     Unsigned  --         8232
     3     21       12        No          Yes     String    --         8232
     3     15        2        No          Yes     Unsigned  --         8232
     3     10        4        No          Yes     Unsigned  --         8232
     4     19        2        No          Yes     Unsigned  --         8232
     4     10        4        No          Yes     Unsigned  --         8232
}
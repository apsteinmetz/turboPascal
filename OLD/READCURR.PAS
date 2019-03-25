PROGRAM ReadCurr;
(* Read CURRFILE.BTR *)
{$N+,E+}

uses BTRIEVE, DOS;
CONST
  FileName = 'F:\trade\currfile.btr';
  ReadOnly = -2;
  KeyLength = 255;
  KeyNum = 1;
  FirstKey = 'BOND';

TYPE
   PosBlock = ARRAY[1..128] OF BYTE;

   CurrFileRec = RECORD
   CASE INTEGER OF
   1 : (
       Fund    :   ARRAY[1..12] OF CHAR;  {3..12}
       Cusip   :   ARRAY[1..9] OF CHAR;   {13..21}
       ParAmt  :   DOUBLE;                {22..29}
       TDAmt   :   DOUBLE;   {Trade Date} {30..37}
       Lot     :   INTEGER;               {38..39}
       AvgCost :   DOUBLE; {40..47}
       MktPx   :   DOUBLE; {48..55}
       AvgYld  :   SINGLE;  { / 1000 }   {56..57}
       Unused  :   ARRAY[1..15] OF CHAR;
        );
    2 : (Entire : ARRAY[1..72] OF CHAR);
   END;

VAR
  OldExitProc : POINTER;
  n,
  BufLen   : INTEGER;
  DataBuf  : CurrFileRec;
  KeyBuf   : ARRAY[1..KeyLength] OF CHAR;
  KeyStr   : String;
  Status   : INTEGER;
  Handle1  : PosBlock;

(* ---------------------------------------------- *)
PROCEDURE TestForNum(Source : CurrFileRec; Start, Stop : INTEGER);


VAR
  TestInt      : ARRAY[0..1] OF CHAR;
  TestLongInt  : ARRAY[0..3] OF CHAR;
  TestSingle   : ARRAY[0..3] OF CHAR;
  TestDouble   : ARRAY[0..7] OF CHAR;

    PROCEDURE MapNum(VAR TestNum; Size : INTEGER);
    TYPE
       TestArray = ARRAY[0..255] OF CHAR;
    BEGIN
      FOR n := 0 TO Size-1 DO
         TestArray(TestNum) [n] := Source.Entire [Start + n];
    END;


BEGIN
  REPEAT
    MapNum(TestInt, SIZEOF(Integer));
    Writeln(Start:4, INTEGER(TestInt):10);

    MapNum(TestLongInt, SIZEOF(LONGINT));
    Writeln(LONGINT(TestLongInt):10);

    MapNum(TestSingle, SIZEOF(SINGLE));
    Writeln(SINGLE(TestSingle):10:5);

    MapNum(TestDouble, SIZEOF(Double));
    Writeln(DOUBLE(TestDouble):10:5);

    Readln;
    INC(Start)
  UNTIL Start + SIZEOF(DOUBLE) = Stop
END;

(* ---------------------------------------------- *)
PROCEDURE AssignStr(var Dest; Source : string);
CONST
  PadChar = #0;

TYPE
  CharArray = ARRAY[1..KeyLength] OF CHAR;

VAR
  m, n, stop : INTEGER;

BEGIN
   n := 1;
   stop := ord(Source[0])+1;  { length of Source + 1 }
   WHILE n <  stop DO
   BEGIN
     CharArray(Dest) [n] := Source[n];
     inc(n);
   END;

   FOR m := n TO KeyLength DO
      CharArray(Dest) [m] := PadChar;   { null terminate}

END (* AssignString *);
(* ---------------------------------------------- *)
PROCEDURE DisplayRec(Holding : CurrFileRec);

BEGIN
  WITH Holding DO
  BEGIN
    Write(Fund:14);
    Write(Cusip:10);
    Writeln;
    Write(ParAmt:12:5);
    Write(TDAmt:12:5);
    Write(MktPx:12:6);
    Write(AvgCost:12:6);
    Write(AvgYld /1000:8:3);
    WriteLn;
  END;
END;
(* ---------------------------------------------- *)
{F+}
PROCEDURE MyExitProc;
VAR
  f: text;

BEGIN
   ExitProc := OldExitProc;
   Writeln('ExitProc');
END;
{F-}
(* ---------------------------------------------- *)
BEGIN
{
   OldExitProc := ExitProc;
   ExitProc := @MyExitProc;
}
   (* open *)
   AssignStr(KeyBuf,'F:\trade\currfile.btr');
   BufLen := SizeOf(DataBuf);
   Status := BTRV(BtrOpen,Handle1,DataBuf,BufLen,KeyBuf,ReadOnly);
   WriteLn('Open Status: ',Status:2);
   IF Status <> 0 THEN HALT;
(*
   { get rec }
   Status := BTRV(GetFirst,Handle1,DataBuf,BufLen,KeyBuf,1);
   WriteLn('Status: ',Status:2);
   IF Status = 0 THEN
   BEGIN
     DisplayRec(DataBuf);
{     TestForNum(DataBuf,1,72); }
   END;
*)
   AssignStr(KeyBuf,FirstKey);

   REPEAT
     Status := BTRV(GetKey + GetGreater,Handle1,DataBuf,BufLen,KeyBuf,KeyNum);
     KeyStr := KeyBuf;
     KeyStr[0] := chr(4);

     IF (Status = 0) AND (KeyStr = FirstKey) THEN
     BEGIN
       Status := BTRV(GetEqual,Handle1,DataBuf,BufLen,KeyBuf,KeyNum);
       DisplayRec(DataBuf)
     END
     ELSE
       Writeln('GetNext failed. Status: ',Status:2);
   UNTIL (Status <> 0) OR (KeyStr <> FirstKey);

   { close }
   Status := BTRV(BtrClose,Handle1,DataBuf,BufLen,KeyBuf,ReadOnly);
   IF Status = 0 THEN
       Writeln('Closed')
   ELSE
     WriteLn('Not Closed. Status: ',Status:2);
   WriteLn;
end.
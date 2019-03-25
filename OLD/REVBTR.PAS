PROGRAM REVBTR;
{$S+,R+}
(* Reverse engineer BTRIEVE file structure *)


{$N+,E+}

uses BTRIEVE, BTRError, DOS, HPDATE, afsDate, BtrStruc;

CONST
  KeyNum = 2; { normally the key with CUSIP }
  SearchKey = '733580TQ7';
  CusipRecSize = 290;
  TransRecSize = 185;

VAR
  OldExitProc : POINTER;
  KeyBuf   : BTrieve.KeyBufType;
  KeyStr   : String;
  lookupcount,
  Status   : INTEGER;
  Handle1  : BTrieve.PosBlock;
  outfile  : text;

(* ---------------------------------------------- *)
PROCEDURE TestForNum(BufPtr : POINTER; Start, Stop : INTEGER);
TYPE
  SourceType = ARRAY[1..CusipRecSize] OF CHAR;

VAR
  TestInt      : ARRAY[0..1] OF CHAR;
  TestLongInt  : ARRAY[0..3] OF CHAR;
  TestSingle   : ARRAY[0..3] OF CHAR;
  TestDouble   : ARRAY[0..7] OF CHAR;
  tempstr      : String;
  len          : word;
  Source       : ^SourceType;

    PROCEDURE MapNum(VAR TestNum; Size : BYTE);
    TYPE
       TestArray = ARRAY[0..CusipRecSize-1] OF CHAR;
    VAR
       n : INTEGER;

    BEGIN
      FOR n := 0 TO Size - 1 DO
         TestArray(TestNum) [n] := Source^ [Start + n];
    END;


BEGIN
  Source := BufPtr;
  len := Stop-Start+1;
  IF len > 255 THEN len := 255;
  Move(Source,tempstr[1],len-2);
  tempstr[0] := chr(len);
{
  IF ORD(tempstr[1]) = CusipRecSize-1 THEN
  BEGIN
    Write(outfile,'look',lookupcount:3);
    INC(lookupcount);
  END;
}
  Writeln(outfile,tempstr);
  REPEAT
    Write(outfile,Start:4, ORD(Source^[Start]):4);

    Write(outfile,chr(ord(Source^[Start])):4);

    MapNum(TestInt, SIZEOF(Integer));
    Write(outfile, INTEGER(TestInt):10);

    MapNum(TestLongInt, SIZEOF(LONGINT));
    str(LONGINT(TestLongInt):10, tempstr);
    Write(outfile,LONGINT(testlongint):11);

    MapNum(TestSingle, SIZEOF(SINGLE));
    str(SINGLE(TestSingle):10:5, tempstr);
    Write(outfile,single(testsingle):10:5);

    MapNum(TestDouble, SIZEOF(Double));
    str(DOUBLE(TestDouble):10:5, tempstr);
    Write(outfile,double(testdouble):10:5);
(*
    { Do a date test }
    IF INTEGER(TestInt) > 0 THEN
      Write(outfile,IntToDate(INTEGER(TestInt)):10);
*)
    Writeln(outfile);
    INC(Start)
  UNTIL Start + SIZEOF(DOUBLE) = Stop +1;
END;

(* ---------------------------------------------- *)
PROCEDURE AssignKey(var Dest; Source : string);
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
      CharArray(Dest) [m] := PadChar;   { null terminate }

END (* AssignKeying *);
(* ---------------------------------------------- *)

PROCEDURE GetOne(afs : BTRFile);
VAR
  DataBuf  : POINTER;

BEGIN
   GetMem(DataBuf,afs.RecSize);

   Assign(outfile,'GETONE.prn');
   rewrite(outfile);

   (* open *)
   AssignKey(KeyBuf,afs.Name);
   Status := BTRV(BtrOpen,Handle1,DataBuf^,afs.RecSize,KeyBuf,ReadOnly);
   WriteLn('Open Status: ',Status:2);
   IF Status <> 0 THEN
   BEGIN
      writeln(BTRSTatus(Status));
      HALT;
   END;
   { get rec }
   AssignKey(KeyBuf,SearchKey);
   Writeln(KeyBuf);
   Status := BTRV(GetGreaterOrEqual,Handle1,DataBuf^,afs.RecSize,KeyBuf,KeyNum);
   WriteLn('GetEqual Status: ',Status:2);
   IF Status = 0 THEN
   BEGIN
     Writeln(STRING(DataBuf^));
     TestForNum(DataBuf,1,afs.RecSize);
   END;
   { close }
   Status := BTRV(BtrClose,Handle1,DataBuf^,afs.RecSize,KeyBuf,ReadOnly);
   IF Status = 0 THEN
       Writeln('Closed')
   ELSE
     WriteLn('Not Closed. Status: ',Status:2);
   WriteLn;
   close(outfile);
   FreeMem(DataBuf,afs.RecSize);

END {GetOne};
{----------------------------------------------------------------}
PROCEDURE ShowAll(afs : BTRFile);

VAR
  DataBuf  : POINTER;

BEGIN

   GetMem(DataBuf,afs.RecSize);

   lookupcount := 0;
   Assign(outfile,'lookups.prn');
   rewrite(outfile);

   (* open *)
   AssignKey(KeyBuf,afs.Name);
   Status := BTRV(BtrOpen,Handle1,DataBuf^,afs.RecSize,KeyBuf,ReadOnly);
   WriteLn('Open Status: ',Status:2);
   IF Status <> 0 THEN HALT;

   { get rec }
   AssignKey(KeyBuf,SearchKey);
   Writeln(KeyBuf);
   Status := BTRV(GetGreater,Handle1,DataBuf^,afs.RecSize,KeyBuf,KeyNum);
   WriteLn('StepFirst Status: ',Status:2);
   IF Status = 0 THEN
   REPEAT
     Writeln(KeyBuf);
     Status := BTRV(GetNext,Handle1,DataBuf^,afs.RecSize,KeyBuf,KeyNum);
     IF NOT (copy(Keybuf,1,8) = copy(searchkey,1,8)) then
        status := 0
     ELSE
        TestForNum(DataBuf,1,afs.RecSize);
   UNTIL Status > 0;
   { close }
   Status := BTRV(BtrClose,Handle1,DataBuf^,afs.RecSize,KeyBuf,ReadOnly);
   IF Status = 0 THEN
       Writeln('Closed')
   ELSE
     WriteLn('Not Closed. Status: ',Status:2);
   WriteLn;
   close(outfile);
   FreeMem(DataBuf,afs.RecSize);

END {ShowAll};
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
{----------------------------------------------------------------}
begin
{
  OldExitProc := ExitProc;
  ExitProc    := @MyExitProc;
}
  ShowAll(FCusip);
end.
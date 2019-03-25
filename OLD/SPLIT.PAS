program SPLIT;
(* split a long text file into two pieces *)

uses DOS, fileops;

CONST
  RecSize = 1;
  InitBufSize : LONGINT = 16384;

VAR
  ExitPtr : POINTER;
  buf     : POINTER;


PROCEDURE SplitFile;
VAR
  infile, outfile      : FILE;
  Name, Name1, Name2   : String;
  NumRead, NumWritten  : Word;
  BufSize,
  SplitSize, RecCount   : LONGINT;
  err                  : INTEGER;
  ByteCount,
  CumCount            : LONGINT;

{ ===================================================== }
FUNCTION MakeName(name : NameStr; count : INTEGER) : String;
VAR
 ext : ExtStr;

BEGIN
    str(count:1,ext);
    IF count > 999 THEN
    BEGIN
      writeln('Max files is 999');
      HALT;
    END;
    IF count < 100 THEN ext := '0' + ext;
    IF count <  10 THEN ext := '0' + ext;
    MakeName := name + '.' + ext;
END;

(* =================================================== *)
PROCEDURE ParseName(VAR FromName, ToName : String);
VAR
  path : PathStr;
  dir  : DirStr;
  name : NameStr;
  ext  : ExtStr;
  count : INTEGER;

BEGIN
  IF (ParamCount < 1) or (ParamStr(1) = '?') or
       NOT exist(ParamStr(1)) THEN
  BEGIN
    WriteLn('usage: SPLIT FileName');
    HALT;
  END;
  path := ParamStr(1);
  FSplit(path,dir,name,ext);
  FromName := path;
  count := 0;
  REPEAT
    INC(count);
    ToName := MakeName(name,count);
  UNTIL NOT exist(ToName);
END (* ParseName *);

(* =================================================== *)
BEGIN
  GetMem(buf,InitBufSize);
  ParseName(Name, Name1);
  Assign(infile, Name);
  Reset(infile,RecSize);
  SplitSize := FileSize(infile) DIV 2;
  CumCount := 0;
  IF (paramcount > 1) THEN
     val(paramstr(2),SplitSize,err);
  WriteLn('Copying ', SplitSize, ' of ', FileSize(infile),' bytes from ',name);
  WHILE NOT eof(infile) DO
  BEGIN
     ParseName(Name, Name1);
     Assign(outfile, Name1);
     Rewrite(outfile,RecSize);
     BufSize   := InitBufSize;
     ByteCount := 0;
     Write('Writing ', Name1, ' using',BufSize:8,' Buffer');
     REPEAT
        { shrink buffer as we approach split point }
        IF (ByteCount + BufSize > SplitSize) THEN
           BufSize := BufSize DIV 2;
        BlockRead(infile,buf^, BufSize,NumRead);
        BlockWrite(outfile,buf^,NumRead,NumWritten);
        Write('.');
        ByteCount := FilePos(outfile);
     UNTIL (ByteCount > SplitSize) OR (NumRead = 0) or
          (NumWritten <> NumRead);
     Writeln;
     Writeln('Wrote ',ByteCount,' Bytes');
     CumCount := CumCount + ByteCount;
     Close(outfile);
  END {while};
  close(infile);
  Writeln(CumCount,' Total Bytes Written');

END (* SplitFile *);

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{$F+} PROCEDURE CleanUp; {$F-}
{ restore original directory }
BEGIN
   IF buf <> NIL THEN FreeMem(buf,InitBufSize);
   buf := NIL;
   ExitProc := ExitPtr;
END;

(* =================================================== *)
BEGIN
   { Install Termination Code }
   ExitPtr := ExitProc;
   ExitProc := @CleanUp;
  SplitFile;
END (*SPLIT*).
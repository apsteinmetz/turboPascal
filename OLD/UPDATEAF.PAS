PROGRAM UPDATEAF;

{$N+,E+}

uses BTRIEVE, AFSTRADE, Crt, StrUtil, AfsSect;


CONST
  { TOGGLE THIS TO PREVENT WRITE OPERATIONS }
  OpenMode = ReadOnly; {ReadOnly or Normal}

  CashCusips = '999999CSH 999999ACR 999999DEP 999999WDR';
  TestSec = '';
  cusipfilename = '\afstrade\cusip290.btr';
  currfilename = '\afstrade\currfile.btr';
  StdOutput = 'afschange.log';
  readfile = '\art\temp.prn';


TYPE
   SecStr = STRING[2];
   { CusipFil sector codes }
   SecArray = ARRAY[1..4] OF SecStr;

VAR
  Cusip   : CusipFile;
  KeyNum  : INTEGER;
  Fund,
  PosKey,
  KeyData     : String;
  SecurityPtr : CusipObjectPtr;
  err    : INTEGER;
  Done   : BOOLEAN;
  outfile : text;


(* ---------------------------------------------- *)
PROCEDURE ChangeSec(WhichSector : BYTE; newsec : BYTE);

VAR
  n, num, err : INTEGER;
  temp : string;

BEGIN
  CASE WhichSector OF
     1 : Cusip.afsSecurity.Sector1 := newsec;
     2 : Cusip.afsSecurity.Sector2 := newsec;
     3 : Cusip.afsSecurity.Sector3 := newsec;
   ELSE
     BEGIN END; { else nothing 3 & 4 NOT IMPLEMENTED}
  END;

END;
(* ---------------------------------------------- *)
PROCEDURE ChangeRating(rating : BYTE);

VAR
  n, num, err : INTEGER;
  temp : string;

BEGIN
     Cusip.afsSecurity.RateSP := rating;
     Cusip.afsSecurity.RateMdy := rating;
END;

{----------------------------------------------------------------- }

PROCEDURE FixField;

CONST
  Sector : SecArray = ('MB','GN','  ','  ');
  Agy    : BYTE = 2;

VAR
  cusipnum,
  Sec1, Sec2, Desc : STRING;
  FixRec : BOOLEAN;

BEGIN
  FixRec := FALSE;
  cusipnum := Cusip.afsSecurity.CUSIP;
  Sec1 := Cusip.OrdinalField(17);
  Sec2 := Cusip.OrdinalField(18);

  IF (pos('MB',Sec1) > 0)  AND
  ((Cusip.afsSecurity.RateSP <> 2) OR (Cusip.afsSecurity.RateMdy <> 2))
       THEN FixRec := TRUE;

  IF FixRec THEN
  BEGIN
      Write(cusipnum, Sec1);
      Desc := StripTrail(Cusip.OrdinalField(4),' ');
      Writeln;
      write(outfile,Cusip.afsSecurity.CUSIP);
      writeln(outfile,Desc);
      write(outfile,Cusip.afsSecurity.RateSP);
      write(outfile,Cusip.afsSecurity.RateMdy);

      write(outfile,' Changing to ');

      { HERE'S WHERE THE CHANGES ARE MADE }
      ChangeRating(Agy);
      ChangeRating(Agy);

      write(outfile,Cusip.afsSecurity.RateSP);
      writeln(outfile,Cusip.afsSecurity.RateMdy);

      IF OpenMode = Normal THEN
      BEGIN
      { *** Update Record. THIS IS THE WRITE OPERATION! *** }
         SecurityPtr := Cusip.RecordOp(KeyData,UpDate,CusipKey,err);
            IF err > 0 THEN writeln(outfile,'Btrieve error #',err);
      END
      ELSE
       BEGIN
       writeln(outfile,'Write Operation not done in "TestSec"');
       writeln;
       END;
  END
  ELSE
    write('.');

END;
{ -------------------------------------------------------------------- }
PROCEDURE ModifySectors;
VAR
  Sec1, Sec2, Sec3 : BYTE;
  Desc : STRING;
  FixRec : BOOLEAN;

BEGIN
  FixRec := TRUE;
  Sec1 := Cusip.afsSecurity.Sector1;
  Sec2 := Cusip.afsSecurity.Sector2;
  Sec3 := Cusip.afsSecurity.Sector3;
  Write(Sec1:4,Sec2:4,Sec3:4);
  IF FixRec THEN
  BEGIN
      Desc := StripTrail(Cusip.OrdinalField(4),' ');
      write(outfile,Cusip.afsSecurity.CUSIP,' ');
      write(outfile,Desc);
      write(outfile,Cusip.afsSecurity.Sector1:4);
      write(outfile,Cusip.afsSecurity.Sector2:4);
      write(outfile,Cusip.afsSecurity.Sector3:4);
      { MAKE CHANGES HERE }
      RemapSect(sec1,sec2,sec3);
      ChangeSec(1,sec1);
      ChangeSec(2,sec2);
      ChangeSec(3,sec3);
      write(outfile,' --> ');
      write(outfile,Cusip.afsSecurity.Sector1:4);
      write(outfile,Cusip.afsSecurity.Sector2:4);
      write(outfile,Cusip.afsSecurity.Sector3:4);

      {screen display of results }

      Sec1 := Cusip.afsSecurity.Sector1;
      Sec2 := Cusip.afsSecurity.Sector2;
      Sec3 := Cusip.afsSecurity.Sector3;
      Writeln(Sec1:4,Sec2:4,Sec3:4);

      IF OpenMode = Normal THEN
      BEGIN
      { *** Update Record. THIS IS THE WRITE OPERATION! *** }
      SecurityPtr := Cusip.RecordOp(KeyData,UpDate,CusipKey,err);
         IF err > 0 THEN writeln(outfile,'Btrieve error #',err);
      END
      ELSE
        write(outfile,'ReadOnly');
      writeln(outfile);
  END;
END {ModifySectors};

(* ---------------------------------------------- *)
PROCEDURE TestSymbol;
VAR
  Symbol, Sec1, Sec2, Desc, Coup, Mat : STRING;
  FixRec : BOOLEAN;

BEGIN
  FixRec := FALSE;
  Symbol := Cusip.OrdinalField(2);
  Sec1   := Cusip.OrdinalField(17);
  Sec2   := Cusip.OrdinalField(18);
  write('.');
  { Is it a proper mortage? }
  IF pos('MB',Sec1) > 0 THEN
      IF pos(Sec2,'GNFHFN') > 0 THEN
        { Has it already been fixed? }
        IF pos(Sec2,Symbol) = 0 THEN
            FixRec := TRUE;

  IF FixRec THEN
  BEGIN
      Desc := StripTrail(Cusip.OrdinalField(4),' ');
      Coup := Cusip.OrdinalField(6);
      Mat :=  Cusip.OrdinalField(7);
  writeln(Symbol);

      Writeln;
      write(outfile,Cusip.afsSecurity.CUSIP,' ');
      write(outfile,Desc,' ');
      write(outfile,Coup,' ');
      write(outfile,Mat,' ');
      write(outfile,Sec2,' ');
      write(outfile,Symbol,' ');

      IF Symbol[1] = 'P' THEN
      BEGIN
        IF Symbol[2] = ' ' THEN { some of those buggers have spaces }
           delete(Symbol,1,2)
        ELSE
           delete(Symbol,1,1);

        Symbol := concat(Sec2,Symbol);
        BTRString( Cusip.afsSecurity.Symbol,
                   SIZEOF(Cusip.afsSecurity.Symbol),Symbol);

       IF OpenMode = Normal THEN
       BEGIN
       { *** Update Record. THIS IS THE WRITE OPERATION! *** }
        SecurityPtr := Cusip.RecordOp(KeyData,UpDate,CusipKey,err);
          IF err > 0 THEN
             write(outfile,'Btrieve error #',err)
          ELSE
             write(outfile,'Changing ',Cusip.afsSecurity.Symbol);
       END
       ELSE
         write(outfile,'No Write of ',Cusip.afsSecurity.Symbol);

      END
      ELSE
        write(outfile,'BOGUS SYMBOL');

      writeln(outfile);

  END;
END;
(* ---------------------------------------------- *)

PROCEDURE ScanAllCusips(subrange : string);

BEGIN
   Done := FALSE;
   KeyData := TestSec;  { we don't care }
   Assign(outfile,StdOutput);
   rewrite(outfile);
   ClrScr;

   (* open *)

   Cusip.Init(OpenMode,err);
   IF err = 0 THEN
   REPEAT
     SecurityPtr := Cusip.RecordOp(KeyData,GetGreater,CusipKey,err);
     IF (length(subrange) > 0) AND
         (pos(subrange,KeyData) = 0) THEN
           err := EndOfFile;
     IF err = 0 THEN
     BEGIN
       ModifySectors;
     END
     ELSE
     BEGIN
       IF err = EndOfFile THEN
           Writeln('End of File Reached')
       ELSE
           Writeln('Btrieve error #',err);
       Done := TRUE;
     END;
   UNTIL Done = TRUE;
   Writeln;
   Close(outfile);
   Cusip.Close;
END {ScanAllCusips};

{ ------------------------------------------------------------------ }

PROCEDURE ScanSelectCusips;
VAR
  n : INTEGER;
  infile : TEXT;
  instr    : String;
  Sector : SecArray;

BEGIN
   Done := FALSE;
   Assign(outfile,StdOutput);
   rewrite(outfile);

   {initialize all sectors to ' ' }
   FOR n := 1 to 4 DO
    Sector[n] := '  ';

   ClrScr;

   (* open *)

   Cusip.Init(OpenMode,err);
   IF err > 0 THEN HALT;
   assign(infile,readfile);
   reset(infile);
   REPEAT
     readln(infile,instr);
     KeyData :=  copy(instr,2,9);  { put CUSIP in KeyData }
     Sector[2] := copy(instr,19,2);  { put sector in sec2 }
     SecurityPtr := Cusip.RecordOp(KeyData,GetGreaterOrEqual,CusipKey,err);
     IF (err = 0) AND (pos('CUSIP',instr) = 0) THEN
     BEGIN
       ModifySectors;
     END
     ELSE
     BEGIN
       IF err = EndOfFile THEN
           Writeln('End of BTREIVE File Reached')
       ELSE
           Writeln('Btrieve error #',err);
       Done := TRUE;
     END;
   UNTIL eof(infile);
   Writeln;
   Close(outfile);
   Close(infile);
   Cusip.Close;
END; {ScanSelectCUSIPS}

{ -----------------------------------------------------------}
BEGIN { main}
ScanAllCusips(TestSec);
end.

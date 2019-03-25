PROGRAM AFSPRICE;

{ Prices bonds currently in afs:TRADE system portfolios }
{ Gets prices from denver mainframe file, FIXED.DEN     }
{ Scans afs file, CURRLOTS.BTR, for each occurance      }
{ of current CUSIP and updates price.                   }

{$N+,E+}

uses BTRIEVE, BTRError, AFSTRADE, Crt, StrUtil, FileOps;

CONST
  { TOGGLE THIS TO PREVENT WRITE OPERATIONS }
  OpenMode = ReadOnly; {ReadOnly or Normal}

  { toggle this to ignore equity cusips }
  IgnoreEquity = TRUE;

  blank = '                     ';
  alphas : SET OF CHAR  = ['A'..'Z'];

(*
  { These parameters are read in from the command line }
  readfile     = 'h:fixed.den';
  { position of price in file from mainframe }
  CusipStart = 8;
  CusipLength = 9;
  PriceStart = 171;
  PriceLength = 13;
  FactorStart = 79;
  FactorLength =13;
*)
  DescStart = 20;
  DescLength = 25;
  MatStart = 104;
  MatLen = 10;

  errlogfile   = 'priceerr.log';

TYPE
  CusipString = String[9];

  CusipNodePtr = ^CusipNode;
  CusipNode = RECORD
    CusipNum : CusipString;
    Next     : CusipNodePtr;
  END;
  SecArray = ARRAY[0..99] OF CusipNodePtr;

VAR
  Holdings   : HoldingFile;
  Cusips     : CusipFile;
  Cusip      : CusipString;
  Instr      : String;
  CusipList  : SecArray;
  ExitSave,
  heap      : POINTER;
  errlog    : text;

  { input parameters }
  PriceStart,
  PriceLength,
  FactorStart,
  FactorLength,
  CusipStart,
  CusipLength  : WORD;
  ReadFile     : String;


(* ---------------------------------------------- *)
PROCEDURE Help;
BEGIN
  Writeln('usage: AFSPRICE FileName CusipStart CusipLen PriceStart PriceLen FactStart FactLen');
  Writeln('Error report will be in PRICEERR.LOG');
  HALT;
END;

(* ---------------------------------------------- *)
PROCEDURE Setup;
VAR
  err : INTEGER;

BEGIN
  ReadFile := Paramstr(1);
  val(paramstr(2),CusipStart,err);
  IF err > 0 THEN Help;
  val(paramstr(3),CusipLength,err);
  IF err > 0 THEN Help;
  val(paramstr(4),PriceStart,err);
  IF err > 0 THEN Help;
  val(paramstr(5),PriceLength,err);
  IF err > 0 THEN Help;
  val(paramstr(6),FactorStart,err);
  IF err > 0 THEN Help;
  val(paramstr(7),FactorLength,err);
  IF err > 0 THEN Help;

   ClrScr;
   { prepare error log}
   assign(errlog,errlogfile);
   rewrite(errlog);
   writeln(errlog,'AFSPRICE Error Log');
   writeln(errlog);

END;

(* ---------------------------------------------- *)
PROCEDURE InitNodes;
VAR
  n : BYTE;
BEGIN
  Mark(heap);
  FOR n := 0 TO 99 DO
    CusipList[n] := NIL;
END;

(* ---------------------------------------------- *)
FUNCTION CusipWasDone(CusipStr : CusipString) : BOOLEAN;
{ build a linked list of CUSIPs found }
{ scan linked list to see if cusip is present,
{ add if not, return FALSE. Return TRUE if it is }

{ also return TRUE on Error - assume error has }
{ already been done so no action will be taken }

VAR

err,
nodecount,
index : INTEGER;
CusipNode,
Node     : CusipNodePtr;
Done,
FoundCusip : BOOLEAN;

BEGIN
  FoundCusip := FALSE;
  Done := FALSE;
  nodecount := 0;
  val(copy(CusipStr,1,2),index,err);
  IF err > 0 THEN
    CusipWasDone := TRUE
  ELSE
  BEGIN
    Node := CusipList[index];
    IF NOT (Node = NIL) THEN
    { array index points to something }
    REPEAT
      inc(NodeCount);
      IF (Node^.CusipNum = CusipStr) THEN
      BEGIN
         FoundCusip := TRUE;
         Done       := TRUE;
      END
      ELSE
         IF Node^.Next = NIL THEN
            Done := TRUE
         ELSE
            Node := Node^.Next;
    UNTIL Done;
    IF NOT FoundCusip THEN
    BEGIN
       New(CusipNode);
       CusipNode^.CusipNum := CusipStr;
       CusipNode^.Next := NIL;
       IF (Node = NIL) THEN  {first item in list}
           CusipList[index] := CusipNode
        ELSE                 { somewhere down the list }
           Node^.Next := CusipNode;
    END;
    CusipWasDone := FoundCusip;
  END {if err <> 0};
END;

(* ---------------------------------------------- *)
PROCEDURE ChangePrice(newprice : DOUBLE);
{ Stick newprice in holding record }

BEGIN
{$IFDEF DEBUG}
   DisplayPos(@Holdings.Holding);
   Writeln;
{$ENDIF}
   Holdings.afsHolding.MktPx := newprice;
END;
{ ------------------------------------------------- }
PROCEDURE ErrorReport(err,Desc : String);
BEGIN
  Writeln(errlog,err,' ',Desc);
  Write('ERROR');
END;

{ ------------------------------------------------- }
FUNCTION FXRate(FXNum : BYTE) : DOUBLE;

VAR
  KeyData : String;
  code : string[2];
  err  : INTEGER;
  CusipPtr  : ^CusipObject;
  rate : double;
  TestCusip,
  Cusip : CusipString;

BEGIN
  CASE FXNum OF
     0 : code := 'US';
     1 : code := 'AD';
     2 : code := 'AS';
     3 : code := 'BD';
     4 : code := 'BF';
     5 : code := 'BK';
     6 : code := 'CD';
     7 : code := 'DK';
     8 : code := 'DM';
     9 : code := 'EC';
    10 : code := 'FF';
    11 : code := 'FM';
    12 : code := 'GD';
    13 : code := 'HK';
    14 : code := 'IL';
    15 : code := 'IP';
    16 : code := 'IR';
    17 : code := 'JY';
    18 : code := 'KD';
    19 : code := 'MR';
    20 : code := 'NG';
    21 : code := 'NK';
    22 : code := 'NZ';
    23 : code := 'PE';
    24 : code := 'PK';
    25 : code := 'SA';
    26 : code := 'SD';
    27 : code := 'SF';
    28 : code := 'SK';
    29 : code := 'SL';
    30 : code := 'SO';
    31 : code := 'SP';
    32 : code := 'TB';
    33 : code := 'UD';
    34 : code := 'UG';
    35 : code := 'UK';
  ELSE
    BEGIN
      code := 'US';
      ErrorReport('No Currency Found for ',copy(instr,1,30));
    END;
  END;

  { quotation in $/FX }
  KeyData := '9999' + 'US' + code;
  TestCusip := KeyData;
  CusipPtr := Cusips.GetRecord(KeyData,GetGreaterOrEqual,CusipKey,err);
  Cusip := CusipPtr^.Cusip.StrForm;
  IF (copy(Cusip,1,8) <> TestCusip) OR (err > 0) THEN
  BEGIN
     { quotation in FX/$ }
     { return reciprocal }
     KeyData := '9999' + code + 'US';
     TestCusip := KeyData;
     CusipPtr := Cusips.GetRecord(KeyData,GetGreaterOrEqual,CusipKey,err);
     Cusip := CusipPtr^.Cusip.StrForm;
     IF (copy(Cusip,1,8) <> TestCusip) OR (err > 0) THEN
       Rate := 1
     ELSE
       Rate := 1 / (CusipPtr^.MktPrice.Num);
  END
  ELSE
      Rate := CusipPtr^.MktPrice.Num;
  write(code:3, Rate:10:4);
  FXRate := Rate;
END;

{ ------------------------------------------------- }
FUNCTION FXAdj(Cusip : String) : DOUBLE;
VAR
  err : INTEGER;
  CusipPtr  : ^CusipObject;

BEGIN
  { lookup cusip to see if non-US denominated }
  CusipPtr := Cusips.GetRecord(Cusip,GetGreaterOrEqual,CusipKey,err);
  IF err = 0 THEN
    IF CusipPtr^.Currency.Num > 0 THEN
      FXAdj := FXRate(CusipPtr^.Currency.Num)
    ELSE
      FXAdj := 1
  ELSE
    FXAdj := 1;
END;

{ ------------------------------------------------- }
FUNCTION TestDebt(Cusip : String) : BOOLEAN ;
{ scan issue code section of cusip for alpha chars }
{ if found issue is fixed income }

BEGIN
  IF NOT IgnoreEquity THEN
    TestDebt := TRUE
  ELSE
    IF (Cusip[7] IN alphas) OR
         (Cusip[8] IN alphas) THEN
           TestDebt := TRUE
    ELSE
        TestDebt := FALSE;
END {TestDebt};

{ ------------------------------------------------- }
PROCEDURE ModifyFactor(Cusip : String; Factor : DOUBLE);
VAR
  err : INTEGER;
  CusipPtr  : ^CusipObject;

BEGIN
  CusipPtr := Cusips.GetRecord(Cusip,GetGreaterOrEqual,CusipKey,err);
  IF Cusips.afsSecurity.CallPxOrFactor <> Factor THEN
  BEGIN

    {$IFDEF DEBUG}
      writeln('Old Factor: ',Cusips.afsSecurity.CallPxOrFactor:11:9);
      writeln('change to ' ,factor:11:9);
   {$ENDIF}
     { write operation  }
     Cusips.afsSecurity.CallPxOrFactor := Factor;
    {$IFDEF DEBUG}
     writeln('New Factor: ',Cusips.afsSecurity.CallPxOrFactor:11:9);
    {$ENDIF}
     write(' MBS');
  IF OpenMode = Normal THEN
  REPEAT
  BEGIN
       CusipPtr := Cusips.GetRecord(Cusip,Update,CusipKey,err);
       IF err > 0 THEN
       { IF another file updated record since then re-read }
          IF (err = Conflict) THEN
            CusipPtr := Cusips.GetRecord(Cusip,GetEqual,CusipKey,err)
          ELSE
          BEGIN
             ErrorReport(BtrErrReport(GetEqual,err)+' FATAL',copy(instr,DescStart,DescLength));
             Cusips.Close;
             Holdings.Close;
             HALT;
          END;
  END;
  UNTIL err = 0;
  END;
END;

{ ------------------------------------------------- }
PROCEDURE ModifyHoldings(Cusip : String; price : DOUBLE);
VAR
  HoldingPtr  : ^CurrFileObj;
  KeyNum      : INTEGER;
  Fund,
  KeyData
        : String;
  err    : INTEGER;
  outfile : text;
  FX : DOUBLE;

BEGIN
  { get first cusip match }
  KeyData := Cusip;
  HoldingPtr := Holdings.GetRecord(KeyData,GetGreaterOrEqual,CusipKey,err);
  IF (err > 0) OR (HoldingPtr^.Cusip.StrForm <> cusip) THEN
     { if mat field is blank suspect an equity and don't report error }
     IF NOT(copy(instr,MatStart,MatLen) = copy(blank,1,MatLen)) THEN
        ErrorReport('No CUSIP Match ',copy(instr,1,44))
     ELSE
        Writeln('Suspected Equity',copy(instr,1,40));

  { Adjust foreign price (if non-US) back to native price }
  FX := FxAdj(cusip);
  Price := Price / FX;

  WHILE (err = 0) DO
  BEGIN
     IF (err = 0) THEN
        IF HoldingPtr^.Cusip.StrForm = cusip THEN
        BEGIN
          { stuff new price in record }
          ChangePrice(price);

          { write operation  }
          IF OpenMode = Normal THEN
             HoldingPtr := Holdings.GetRecord(KeyData,Update,CusipKey,err);

          IF err > 0 THEN
            { IF another file updated record since then re-read }
            IF (err = Conflict) THEN
              HoldingPtr := Holdings.GetRecord(KeyData,GetEqual,CusipKey,err)
            ELSE
            BEGIN
               ErrorReport(BtrErrReport(GetEqual,err)+' FATAL',copy(instr,DescStart,DescLength));
               Holdings.Close;
               HALT;
            END
          ELSE { update worked }
            { now get the next fund with that cusip in it }
            HoldingPtr := Holdings.GetRecord(KeyData,GetNext,CusipKey,err);
         END
        ELSE
           { cusip is diff. so look no further }
           err := EndOfFile;
  END;
  IF err = EndOfFile THEN
  {$IFDEF DEBUG}
        Writeln('No more matches.')
  {$ENDIF}
   ELSE
       ErrorReport(BtrErrReport(GetNext,err),copy(instr,DescStart,DescLength));
END;

{ ------------------------------------------------- }
PROCEDURE ScanPriceFile;
VAR
  n : INTEGER;
  infile : TEXT;
  Factor,
  price    : DOUBLE;
  pricestr,
  FactStr,
  Desc     : string;
  err      : INTEGER;

BEGIN


   (* open *)
   Holdings.Init(OpenMode,err);
   IF err > 0 THEN
   BEGIN
     writeln(currfilename,' Open failed. Error ',BtrStatus(err));
     HALT;
   END;

   (* open *)
   { we open the cusip database just to check for non-$ denominated }
   { securities.  PMS uses dollar adjusted prices so we have to reset }
   { them to native valuations }
   Cusips.Init(OpenMode,err);
   IF err > 0 THEN
   BEGIN
     writeln(cusipfilename,' Open failed. Error ',BtrStatus(err));
     HALT;
   END;
   IF NOT exist(ReadFile) THEN
   BEGIN
     writeln('Cannot find pricing file: ',ReadFile);
     Help;
   END;

   assign(infile,readfile);
   reset(infile);
   REPEAT
     readln(infile,instr);
     IF NOT eof(infile) THEN
     BEGIN
        Cusip := copy(instr,CusipStart,CusipLength);
        Desc  := copy(instr,DescStart,DescLength);

        { check for valid cusip }
        IF copy(Cusip,1,1) = ' ' THEN
          ErrorReport('No Cusip. Not Priced',copy(instr,1,44));

        IF NOT CusipWasDone(Cusip) AND TestDebt(Cusip) THEN
        BEGIN
           { do price }
           priceStr := copy(instr,PriceStart,PriceLength);
           val(pricestr,price,err);
           IF ((err > 0) OR (price = 0.0)) THEN
             ErrorReport('Bogus price string: ',pricestr + ' '+copy(instr,1,44))
           ELSE
           BEGIN
              write(cusip:10,pricestr:14);
              ModifyHoldings(Cusip,Price);
           END;
           { do factor }
           FactStr := copy(instr,FactorStart,FactorLength);
           val(Factstr,factor,err);
           IF ((err = 0) AND (factor <> 1.0)) AND (factor > 0) THEN
              ModifyFactor(Cusip,Factor);
           Writeln;
        END
        ELSE
        {$IFDEF DEBUG}
           writeln(cusip:10,' found');
        {$ENDIF}
     END;
   UNTIL eof(infile);
   Writeln;
   Close(infile);
   Close(errlog);
   Holdings.Close;
END; {ScanPriceFile}

{ -----------------------------------------------------------}
{$F+} PROCEDURE CleanUp; {$F-}
BEGIN
   IF heap <> NIL THEN
     release(heap);
   ExitProc := ExitSave;

END; { CleanUp }
{ ---------------------------------------------------------------}
BEGIN
  { Exit Procedures }
  IF (paramstr(1) = '?') OR (Paramcount < 5) THEN Help;
  { Exit Procedures }
  ExitSave := ExitProc;
  ExitProc := @CleanUp;
  SetUp;
  InitNodes;
  ScanPriceFile;
end.

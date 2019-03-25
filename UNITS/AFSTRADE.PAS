UNIT AFSTRADE;
(* Decoding routines for AFS BTRIEVE files *)
(* Cusip records and fund holdings *)

{No math routines but this uses IEEE number formats}
{$N+,E+}


interface

uses BTRIEVE, BTRError, StrUtil;

CONST
  {key codes apply to cusip file and holding file only }
  CusipKey = 0;
  FundKey = 1;

  { these key codes apply to transaction file only }
  TradeDateKey = 1;
  TransCusipKey = 2;
  TransFundKey = 3;
  TickNoKey = 0;
  SettleDateKey = 4;

  CurrFileName  = 'h:\apps\afstrade\currlots.btr';
  CusipFileName = 'h:\apps\afstrade\cusip290.btr';
  TransFileName = 'h:\apps\afstrade\transfil.btr';
  AlphaNumSet : SET OF CHAR = ['0'..'9','A'..'Z','a'..'z'];

TYPE

   afsField = object
     afsStr : String;
     Constructor Init(NewStr : String);
     function StrForm : STRING; virtual;
     function DelimAscForm : STRING; virtual;
     procedure Display;
     procedure Out(VAR f : text);
   END;

   afsDateNum = object(afsField)
      Num     : INTEGER;
      Lotus   : LONGINT;
      Constructor Init(NewNum : INTEGER);
      function StrForm : STRING; virtual;
      function LotusStrForm : STRING; virtual; (* lotus date number *)
   END;

   afsShortInt = object(afsField)
      Num     : BYTE;
      Constructor Init(NewNum : BYTE);
      function StrForm : STRING; virtual;
      function DelimAscForm : STRING; virtual;
   END;

   afsRealInt = object(afsField)
      Num     : DOUBLE;
      width   : BYTE;
      dec     : BYTE;
      Constructor Init(NewNum : INTEGER; Divisor : WORD);
      function StrForm : STRING; virtual;
      function DelimAscForm : STRING; virtual;
      procedure SetFormat(wid,deci : BYTE);
   END;

   afsReal   = object(afsField)
      Num     : DOUBLE;
      width   : BYTE;
      dec     : BYTE;
      Constructor Init(NewNum : DOUBLE; Divisor : WORD);
      function StrForm : STRING; virtual;
      function DelimAscForm : STRING; virtual;
      procedure SetFormat(wid,deci : BYTE);
   END;

{-----------------------------------------------------------------}
(* TRANSACTION FILE TRANSFIL.BTR

     Key  Pos  Len

      2    1    9   Cusip    String
      0   10    4   TickNo
      1   15    2   Date (?)
      4   19    2   Settle Date (?)
      3   21   12   Account
          33   12   Broker
          45    3   Trader
          48   52   Unknown
         100   50   Comment

*)
   TransFileRec = RECORD
   CASE INTEGER OF
   1 : (
       Cusip   :   ARRAY[1..9] OF CHAR;  {1..9}
       TickNo  :   integer;              {10.13}
       TradeD  :   INTEGER;              {15..16}
       SettleD :   INTEGER;              {19..20}
       Fund    :   ARRAY[1..12] OF CHAR; {21..32}
       Broker  :   ARRAY[1..12] OF CHAR; {33..44}
       Trader  :   ARRAY[1..3] OF CHAR;  {45..47}
       Unkn1   :   ARRAY[1..52] OF CHAR;  {48..99}
       Comment :   ARRAY[1..50] OF CHAR; {100..150}
       Unkn2   :   ARRAY[1..35] OF CHAR; {151..185}
        );
    2 : (Entire : ARRAY[1..185] OF CHAR);
   END;

   TransFileObjPtr = ^TransFileObj;

   TransFileObj = RECORD
       Cusip   :   AfsField;
       TickNo  :   afsRealInt;
       TradeD  :   afsDateNum;
       SettleD :   afsDateNum;
       Fund    :   afsField;
       Broker  :   afsField;
       Trader  :   afsField;
       Comment :   afsField;
   END;
{-----------------------------------------------------------------}
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
       Unused  :   ARRAY[1..23] OF CHAR; {58..80}
        );
    2 : (Entire : ARRAY[1..80] OF CHAR);
   END;

   CurrFileObjPtr = ^CurrFileObj;

   CurrFileObj = RECORD
       Fund    :   AfsField;
       Cusip   :   AfsField;
       ParAmt  :   afsReal;
       TDAmt   :   afsReal;
       Lot     :   INTEGER;
       AvgCost :   afsReal;
       MktPx   :   afsReal;
       AvgYld  :   afsReal;
   END;
{--------------------------------------------------------------------}

   CusipFileRec = RECORD
   CASE INTEGER OF
   1 : (
       Cusip       : ARRAY[1..9] OF CHAR;   {1..9}
       Symbol      : ARRAY[1..8] OF CHAR;  {10..17}
       UserID      : ARRAY[1..10] OF CHAR; {18..27}
       Descrip     : ARRAY[1..30] OF CHAR;  {28..57}
       Descrip2    : ARRAY[1..30] OF CHAR;  {58..87}
       Coupon      : INTEGER;  { 88..89}
       MatDtNm     : INTEGER;  { 90..91}
       IssDtNm     : INTEGER;  { 92..93}
       FirstCpDtNm : INTEGER;  { 94..95}
       CallPxOrFactor : DOUBLE;  {96..103}
       CallDtNm    : INTEGER;    {104..105}
       PutPxOrSpeed  : SINGLE;  {106..109}
       ParCallDtNm : INTEGER; {110..111}
       Unkn1       : SINGLE;  {112..115}
       PutDtNm     : INTEGER; {116..117}
       Unkn2       : ARRAY[1..5] OF CHAR; { 118..122 }
       RateSP      : BYTE;  { 123 }
       RateMdy     : BYTE;  { 124 }
       Unkn3       : BYTE; {125}
       Sector1     : BYTE; {126}
       Sector2     : BYTE; {127}
       Sector3     : BYTE; {128}
       Sector4     : BYTE; {129}
       IssSize     : SINGLE;  {130..133}
       CalcCode    : BYTE;    { 134 }
       PmtFreq     : BYTE; {135}
       Unkn4       : ARRAY[1..8] OF CHAR; {136..143}
       Country     : ARRAY[1..2] OF CHAR; {144..145}
       Unkn5       : ARRAY[1..22] OF CHAR; {146..167}
       Currency    : BYTE; {168}
       Unkn6       : ARRAY[1..49] OF CHAR; {169..217}
       MktPrice    : DOUBLE;  {218..225}
       Unkn8       : ARRAY[1..64] OF CHAR; {226..290}
        );
    2 : (Entire : ARRAY[1..290] OF CHAR);
   END;

   CusipObjectPtr = ^CusipObject;

   CusipObject = RECORD        { This is the processed CUSIP record }
       Cusip       : AfsField;
       Symbol      : AfsField;
       UserID      : AfsField;
       Descrip     : AfsField;
       Descrip2    : AfsField;
       Coupon      : afsRealInt;
       MatDt       : afsDateNum;
       IssDt       : afsDateNum;
       FirstCpDt   : afsDateNum;
       CallPxOrFactor : afsReal;
       CallDt      : afsDateNum;
       PutPxOrSpeed  : afsReal;
       ParCallDt   : afsDateNum;
       PutDt       : afsDateNum;
       RateSP      : afsShortInt;
       RateMdy     : afsShortInt;
       Sector1     : afsShortInt;
       Sector2     : afsShortInt;
       Sector3     : afsShortInt;
       Sector4     : afsShortInt;
       IssSize     : afsReal;
       CalcCode    : afsShortInt;
       PmtFreq     : afsShortInt;
       Currency    : afsShortInt;
       Country     : AfsField;
       MktPrice    : AfsReal;
   END;

(* ========================================================= *)
{BTRIEVE OBJECTS}
   BtrFile = object
      Handle   : PosBlock;
      Name : String;
      BtrRecPtr  : POINTER;
      RecLen   : INTEGER;

      CONSTRUCTOR Init( FileName : String;
                        FileMode : SHORTINT;
                        RecPtr   : POINTER;
                        RecSize  : INTEGER;
                        VAR error : INTEGER);


      PROCEDURE AssignRec(VAR Rec : POINTER); virtual;
      { Takes pointer to CurrFileRec or CusipFileRec }

      PROCEDURE AccessRecord(VAR KeyData : STRING;
                             ActionCode : WORD;
                             KeyNum : INTEGER;
                             VAR error : INTEGER); virtual;

      FUNCTION RecordOp( VAR KeyData : String;
                           ActionCode : WORD;
                           KeyNum : INTEGER;
                           VAR error : INTEGER) : POINTER; virtual;
      { Returns pointer to CurrFileRec or CusipFileRec }

      DESTRUCTOR Close; virtual;
   END;

(* ----------------------------------------------------------- *)
   CusipFile = object(BtrFile)
      afsSecurity : CusipFileRec;
      Security    : CusipObject;

      CONSTRUCTOR Init( FileMode : SHORTINT;
                        VAR error : INTEGER);

      PROCEDURE AssignRec(VAR Rec : POINTER); virtual;

      FUNCTION OrdinalField(Num : INTEGER) : String; virtual;

      FUNCTION OrdinalDelimField(Num : INTEGER;
                                      Lotus : BOOLEAN) : String; virtual;
      (* numbers and strings in quotes for delimted ASCII export *)
      (* set Lotus=TRUE for dates in lotus numeric format *)

      PROCEDURE ShowOrdinalFields;
   END;

(* ----------------------------------------------------------- *)

   HoldingFile = object(BtrFile)
      afsHolding : CurrFileRec;
      Holding    : CurrFileObj;

      CONSTRUCTOR Init( FileMode : SHORTINT;
                        VAR error : INTEGER);

      PROCEDURE AssignRec(VAR Rec : POINTER); virtual;

      FUNCTION OrdinalField(Num : INTEGER) : String; virtual;

      FUNCTION OrdinalDelimField(Num : INTEGER;
                                      Lotus : BOOLEAN) : String; virtual;

      PROCEDURE ShowOrdinalFields;
   END;

(* ----------------------------------------------------------- *)

   TransFile = object(BtrFile)
      afsTrans : TransFileRec;
      Trans    : TransFileObj;

      CONSTRUCTOR Init( FileMode : SHORTINT;
                        VAR error : INTEGER);

      PROCEDURE AssignRec(VAR Rec : POINTER); virtual;

      FUNCTION OrdinalField(Num : INTEGER) : String; virtual;

      FUNCTION OrdinalDelimField(Num : INTEGER;
                                      Lotus : BOOLEAN) : String; virtual;

      PROCEDURE ShowOrdinalFields;
   END;

(* ------------------------------------------------- *)

PROCEDURE DisplaySec(Security : CusipObjectPtr);

PROCEDURE DisplayPos(Pos : CurrFileObjPtr);

(* ========================================================= *)
implementation

uses DOS, { HPDATE,} afsDate, Calendar;

VAR
  CenturyCrossover : LONGINT;

(* =============== OBJECT METHODS =========================== *)
Constructor afsField.Init(NewStr : String);
BEGIN
    afsStr := NewStr;
END;
(* ---------------------------------------------- *)

function afsField.StrForm : STRING;
     BEGIN
       StrForm := afsStr;
     END;

(* ---------------------------------------------- *)

procedure afsField.Display;
BEGIN
  Write(StrForm);
END;

(* ---------------------------------------------- *)
function afsField.DelimAscForm : STRING;

BEGIN
    DelimAscForm  := '"' + striptrail(striptrail(StrForm,#0),' ') + '"';
END;
(* ---------------------------------------------- *)
procedure afsField.Out(VAR f : text);
BEGIN
  Write(f,StrForm);
END;

Constructor afsShortInt.Init(NewNum : BYTE);
BEGIN
    num := Newnum;
END;
(* ---------------------------------------------- *)

function afsShortInt.StrForm : STRING;
VAR
  tempstr : STRING;

BEGIN
    str(num,tempstr);
    StrForm := tempstr;
END;

(* ---------------------------------------------- *)
function afsShortInt.DelimAscForm : STRING;

BEGIN
    DelimAscForm  := StrForm;
END;
(* ---------------------------------------------- *)
Constructor afsDateNum.Init(NewNum : INTEGER);
BEGIN
    Num := NewNum;
    Lotus := IntToSerial(Num) - date(12,31,1899) + 1 ;
END;

(* ---------------------------------------------- *)
function afsDateNum.LotusStrForm : STRING;
VAR
  tempstr : string;
     BEGIN
       str(Lotus:7,tempstr);
       LotusStrForm := tempstr;
     END;

(* ---------------------------------------------- *)
function afsDateNum.StrForm : STRING;
VAR
  datenum : LONGINT;

     BEGIN
       datenum := IntToSerial(Num);
       IF datenum < CenturyCrossover THEN
         datenum := date(month(datenum),day(datenum),year(datenum)+100);
       StrForm := DateString(IntToSerial(Num),1);
     END;
(* ---------------------------------------------- *)
Constructor afsReal.Init(NewNum : DOUBLE; Divisor : WORD);

BEGIN
    width := 10;
    dec := 3;
    Num := NewNum / Divisor
END;

(* ---------------------------------------------- *)
procedure afsReal.SetFormat(wid,deci : BYTE);
BEGIN
  width := wid;
  dec   := deci;
END;

(* ---------------------------------------------- *)
function afsReal.StrForm : STRING;
VAR
  tempstr : STRING;

BEGIN
    str(Num:width:dec,tempstr);
    StrForm := tempstr;
END;

(* ---------------------------------------------- *)
function afsReal.DelimAscForm : STRING;

BEGIN
    DelimAscForm  := StrForm;
END;
(* ---------------------------------------------- *)
Constructor afsRealInt.Init(NewNum : INTEGER; Divisor : WORD);

BEGIN
    width := 6;
    dec   := 3;
    Num := NewNum / Divisor;
END;

(* ---------------------------------------------- *)
procedure afsRealInt.SetFormat(wid,deci : BYTE);
BEGIN
  width := wid;
  dec   := deci;
END;

(* ---------------------------------------------- *)
function afsRealInt.StrForm : STRING;
VAR
  tempstr : STRING;

BEGIN
    str(Num:width:dec,tempstr);
    StrForm := tempstr;
END;

(* ---------------------------------------------- *)
function afsRealInt.DelimAscForm : STRING;

BEGIN
    DelimAscForm  := StrForm;
END;

(* ---------------------------------------------- *)
CONSTRUCTOR BtrFile.Init( FileName : String;
                          FileMode : SHORTINT;
                          RecPtr   : POINTER;
                          RecSize  : INTEGER;
                          VAR error : INTEGER);

VAR
  KeyBuf : KeyBufType;

BEGIN
   Name := FileName;
   AssignKey(KeyBuf,Name);
   RecLen := RecSize;
   BtrRecPtr := RecPtr;
   error := BTRV(BtrOpen,Handle,BtrRecPtr^,RecLen,KeyBuf,FileMode);
END {BtrFile.Init};

(* ---------------------------------------------- *)
PROCEDURE BtrFile.AssignRec(VAR Rec : POINTER);
BEGIN
END;

(* ---------------------------------------------- *)


PROCEDURE BtrFile.AccessRecord( VAR KeyData : String;
                                ActionCode : WORD;
                                KeyNum : INTEGER;
                                VAR error : INTEGER);
VAR
  KeyBuf : KeyBufType;

BEGIN
   AssignKey(KeyBuf,KeyData);
   error := BTRV( GetKey+ActionCode,Handle,
                  BtrRecPtr^,RecLen,KeyBuf,KeyNum);
   KeyData := KeyBuf;
END {BtrFile.AccessRecord};

(* ---------------------------------------------- *)
FUNCTION BtrFile.RecordOp( VAR KeyData : String;
                           ActionCode : WORD;
                           KeyNum : INTEGER;
                           VAR error : INTEGER) : POINTER;
VAR
  KeyBuf : KeyBufType;
  Rec    : POINTER;
  test2   : CusipFileRec;
  test1   : CurrFileRec;

BEGIN
   AssignKey(KeyBuf,KeyData);
   error := BTRV( ActionCode,Handle,
                  BtrRecPtr^,RecLen,KeyBuf,KeyNum);
{   IF error = 0 THEN }
   BEGIN
       CASE RecLen OF
         SIZEOF(CusipFileRec)  : test2 := CusipFileRec(BtrRecPtr^);
         SIZEOF(CurrFileRec)   : test1 := CurrFileRec(BtrRecPtr^);
       END;
       AssignRec(Rec);
       RecordOp := Rec;
   END;
   KeyData := KeyBuf;
END {BtrFile.RecordOp};

(* ---------------------------------------------- *)
DESTRUCTOR BtrFile.Close;
VAR
  KeyBuf : KeyBufType;
  error : INTEGER;

BEGIN
   error := BTRV(BtrClose,Handle,BtrRecPtr^,RecLen,KeyBuf,0);
END {BtrFile.Close};

(* ---------------------------------------------- *)
CONSTRUCTOR CusipFile.Init( FileMode : SHORTINT;
                          VAR error : INTEGER);

VAR
  KeyBuf : KeyBufType;

BEGIN
   Name   := CusipFileName;
   RecLen := SIZEOF(afsSecurity);
   BtrFile.Init(Name,FileMode,@afsSecurity,RecLen,error);
END {CusipFile.Init};

(* ---------------------------------------------- *)
PROCEDURE CusipFile.AssignRec(VAR Rec : POINTER);
BEGIN
  WITH Security DO
  BEGIN
       Cusip    .Init( afsSecurity.Cusip);
       Symbol   .Init( afsSecurity.Symbol);
       UserID   .Init( afsSecurity.UserID);
       Descrip  .Init( afsSecurity.Descrip);
       Descrip2 .Init( afsSecurity.Descrip2);
       Sector1  .Init( afsSecurity.Sector1);
       Sector2  .Init( afsSecurity.Sector2);
       Sector3  .Init( afsSecurity.Sector3);
       Sector4  .Init( afsSecurity.Sector4);
       CalcCode .Init(afsSecurity.CalcCode);
       PmtFreq  .Init(afsSecurity.PmtFreq);
       Coupon.Init(         afsSecurity.Coupon,1000);
       MatDt.Init(          afsSecurity.MatDtNm);
       IssDt.Init(          afsSecurity.IssDtNm);
       FirstCpDt.Init(      afsSecurity.FirstCpDtNm);
       CallPxOrFactor.Init( afsSecurity.CallPxOrFactor,1);
       CallPxOrFactor.SetFormat(11,9);
       CallDt.Init(         afsSecurity.CallDtNm);
       PutPxOrSpeed.Init(   afsSecurity.PutPxOrSpeed,1);
       ParCallDt.Init(      afsSecurity.ParCallDtNm);
       PutDt.Init(          afsSecurity.PutDtNm);
       RateSP.Init(         afsSecurity.RateSP);
       RateMdy.Init(        afsSecurity.RateMdy);
       IssSize.Init(        afsSecurity.IssSize,1);
       Currency.Init(        afsSecurity.Currency);
       Country.Init(        afsSecurity.Country);
       MktPrice.Init(       afsSecurity.MktPrice,1);
   END;
   Rec := @Security;
END;

(* --------------------------------------------------- *)
FUNCTION CusipFile.OrdinalField(Num : INTEGER) : String;
VAR
  Fld : String;

BEGIN
   WITH Security DO
   CASE Num OF
     1 :  Fld :=   Cusip.StrForm;
     2 :  Fld :=   Symbol.StrForm;
     3 :  Fld :=   UserID.StrForm;
     4 :  Fld :=   Descrip.StrForm;
     5 :  Fld :=   Descrip2.StrForm;
     6 :  Fld :=   Coupon.StrForm;
     7 :  Fld :=   MatDt.StrForm;
     8 :  Fld :=   IssDt.StrForm;
     9 :  Fld :=   FirstCpDt.StrForm;
    10 :  Fld :=   CallPxOrFactor.StrForm;
    11 :  Fld :=   CallDt.StrForm;
    12 :  Fld :=   PutPxOrSpeed.StrForm;
    13 :  Fld :=   ParCallDt.StrForm;
    14 :  Fld :=   PutDt.StrForm;
    15 :  Fld :=   RateSP.StrForm;
    16 :  Fld :=   RateMdy.StrForm;
    17 :  Fld :=   Sector1.StrForm;
    18 :  Fld :=   Sector2.StrForm;
    19 :  Fld :=   IssSize.StrForm;
    20 :  Fld :=   CalcCode.StrForm;
    21 :  Fld :=   PmtFreq.StrForm;
    22 :  Fld :=   Currency.StrForm;
    23:   Fld :=   Country.StrForm;
    24:   Fld :=   MktPrice.StrForm;
    25:   Fld :=   Sector3.StrForm;
    26:   Fld :=   Sector4.StrForm;
   ELSE
     Fld := 'NA';
   END;
   OrdinalField := Fld;
END;
(* --------------------------------------------------- *)
FUNCTION CusipFile.OrdinalDelimField( Num : INTEGER;
                                      Lotus : BOOLEAN) : STRING;

VAR
  Fld : String;

BEGIN
   WITH Security DO
   CASE Num OF
     1 :  Fld :=   Cusip.DelimAscForm;
     2 :  Fld :=   Symbol.DelimAscForm;
     3 :  Fld :=   UserID.DelimAscForm;
     4 :  Fld :=   Descrip.DelimAscForm;
     5 :  Fld :=   Descrip2.DelimAscForm;
     6 :  Fld :=   Coupon.DelimAscForm;
     7 :  IF Lotus THEN
            Fld :=   MatDt.LotusStrForm
          ELSE
            Fld :=   MatDt.DelimAscForm;
     8 :  IF Lotus THEN
            Fld :=   IssDt.LotusStrForm
          ELSE
            Fld :=   IssDt.DelimAscForm;
     9 :  IF Lotus THEN
            Fld :=   FirstCpDt.LotusStrForm
          ELSE
            Fld :=   FirstCpDt.DelimAscForm;
    10 :  Fld :=   CallPxOrFactor.DelimAscForm;
    11 :  IF Lotus THEN
            Fld :=   CallDt.LotusStrForm
          ELSE
            Fld :=   CallDt.DelimAscForm;
    12 :  Fld :=   PutPxOrSpeed.DelimAscForm;
    13 :  IF Lotus THEN
            Fld :=   ParCallDt.LotusStrForm
          ELSE
            Fld :=   ParCallDt.DelimAscForm;
    14 :  IF Lotus THEN
            Fld :=   PutDt.LotusStrForm
          ELSE
            Fld :=   PutDt.DelimAscForm;
    15 :  Fld :=   RateSP.DelimAscForm;
    16 :  Fld :=   RateMdy.DelimAscForm;
    17 :  Fld :=   Sector1.DelimAscForm;
    18 :  Fld :=   Sector2.DelimAscForm;
    19 :  Fld :=   IssSize.DelimAscForm;
    20 :  Fld :=   CalcCode.DelimAscForm;
    21 :  Fld :=   PmtFreq.DelimAscForm;
    22 :  Fld :=   Currency.DelimAscForm;
    23 :  Fld :=   Country.DelimAscForm;
    24 :  Fld :=   MktPrice.DelimAscForm;
    25 :  Fld :=   Sector3.DelimAscForm;
    26 :  Fld :=   Sector4.DelimAscForm;
   ELSE
     Fld := '"NA"';
   END;
   OrdinalDelimField := Fld;
END;
(* --------------------------------------------------- *)
PROCEDURE CusipFile.ShowOrdinalFields;

BEGIN
    write(' 1 :  Cusip':21);
    writeln(' 2 :  Symbol':21);
    write(' 3 :  UserID':21);
    writeln(' 4 :  Descrip':21);
    write(' 5 :  Descrip2':21);
    writeln(' 6 :  Coupon':21);
    write(' 7 :  MatDt':21);
    writeln(' 8 :  IssDt':21);
    write(' 9 :  FirstCpDt':21);
    writeln('10 :  CallPxOrFactor':21);
    write('11 :  CallDt':21);
    writeln('12 :  PutPxOrSpeed':21);
    write('13 :  ParCallDt':21);
    writeln('14 :  PutDt':21);
    write('15 :  RateSP':21);
    writeln('16 :  RateMdy':21);
    write('17 :  Sector1':21);
    writeln('18 :  Sector2':21);
    write('19 :  IssSize':21);
    writeln('20 :  CalcCode':21);
    writeln('21 :  PmtFreq':21);
    writeln('22 :  Currency':21);
    writeln('23 :  Country':21);
    writeln('24 :  MktPrice':21);
    write('25 :  Sector3':21);
    write('26 :  Sector4':21);
END;
(* ---------------------------------------------- *)

CONSTRUCTOR HoldingFile.Init( FileMode : SHORTINT;
                              VAR error : INTEGER);

VAR
  KeyBuf : KeyBufType;

BEGIN
   Name := CurrFileName;
   RecLen := SIZEOF(afsHolding);
   BtrFile.Init(Name,FileMode,@afsHolding,RecLen,error);
END {CusipFile.Init};

(* ---------------------------------------------- *)
PROCEDURE HoldingFile.AssignRec(VAR Rec : POINTER);

BEGIN
  WITH Holding DO
  BEGIN
       Fund .Init( AfsHolding.Fund);
       Cusip.Init( AfsHolding.Cusip);
       Lot := AfsHolding.Lot;

       { kludge to handle null records}
       IF NOT (AfsHolding.Cusip[1] IN AlphaNumSet) THEN
       BEGIN
          ParAmt.Init(0.0,1);
          TDAmt.Init(0.0,1);
          AvgCost.Init(0.0,1);
          MktPx.Init(0.0,1);
          AvgYld.Init(0.0,1);
       END
       ELSE
       BEGIN
          ParAmt.Init(  AfsHolding.ParAmt,1);
          TDAmt.Init(   AfsHolding.TDAmt,1);
          AvgCost.Init( AfsHolding.AvgCost,1);
          MktPx.Init(   AfsHolding.MktPx,1);
          AvgYld.Init(  AfsHolding.AvgYld,1000);
       END;
   END;
   Rec := @Holding;
END;
(* ---------------------------------------------- *)
FUNCTION HoldingFile.OrdinalField(Num : INTEGER) : String;

VAR
  Fld : String;
BEGIN
  WITH Holding DO
  CASE Num OF
    52 :  Fld := Fund.StrForm;
    53 :  Fld := Cusip.StrForm;
    54 :  str(Lot,Fld);
    55 :  Fld := ParAmt.StrForm;
    56 :  Fld := TDAmt.StrForm;
    57 :  Fld := AvgCost.StrForm;
    58 :  Fld := MktPx.StrForm;
    59 :  Fld := AvgYld.StrForm;
   ELSE
     Fld := 'NA';
   END;
   OrdinalField := Fld;
END;

(* ---------------------------------------------- *)
FUNCTION HoldingFile.OrdinalDelimField(Num : INTEGER;
                                      Lotus : BOOLEAN) : String;

VAR
  Fld : String;
BEGIN
  WITH Holding DO
  CASE Num OF
    52 :  Fld := Fund.DelimAscForm;
    53 :  Fld := Cusip.DelimAscForm;
    54 :  BEGIN str(Lot,Fld); Fld := '"'+Fld+ '"'; END;
    55 :  Fld := ParAmt.DelimAscForm;
    56 :  Fld := TDAmt.DelimAscForm;
    57 :  Fld := AvgCost.DelimAscForm;
    58 :  Fld := MktPx.DelimAscForm;
    59 :  Fld := AvgYld.DelimAscForm;
   ELSE
     Fld := '"NA"';
   END;
   OrdinalDelimField := Fld;
END;

(* ---------------------------------------------- *)
PROCEDURE HoldingFile.ShowOrdinalFields;

BEGIN
    write  (' 52 :  Fund':21);
    writeln(' 53 :  Cusip':21);
    write  (' 54 :  Lot':21);
    writeln(' 55 :  ParAmt':21);
    write  (' 56 :  TDAmt':21);
    writeln(' 57 :  AvgCost':21);
    write  (' 58 :  MktPx':21);
    writeln(' 59 :  AvgYld':21);
END;
(* =================================================== *)
(* ---------------------------------------------- *)

CONSTRUCTOR TransFile.Init( FileMode : SHORTINT;
                              VAR error : INTEGER);

VAR
  KeyBuf : KeyBufType;

BEGIN
   Name := TransFileName;
   RecLen := SIZEOF(afsTrans);
   BtrFile.Init(Name,FileMode,@afsTrans,RecLen,error);
END {TransFile.Init};

(* ---------------------------------------------- *)
PROCEDURE TransFile.AssignRec(VAR Rec : POINTER);

BEGIN
  WITH Trans DO
  BEGIN
       TickNo.Init(AfsTrans.TickNo,1);
       Fund .Init( AfsTrans.Fund);
       Cusip.Init( AfsTrans.Cusip);
       TradeD.Init(afsTrans.TradeD);
       SettleD.Init(afsTrans.SettleD);
       Broker.Init(afsTrans.Broker);
       Trader.Init(afsTrans.Trader);
       comment.Init(afsTrans.Comment);
   END;
   Rec := @Trans;
END;
(* ---------------------------------------------- *)
FUNCTION TransFile.OrdinalField(Num : INTEGER) : String;

VAR
  Fld : String;
BEGIN
  WITH Trans DO
  CASE Num OF
    60 :  Fld := Cusip.StrForm;
    61 :  Fld := TickNo.StrForm;
    62 :  Fld := TradeD.StrForm;
    63 :  Fld := SettleD.StrForm;
    64 :  Fld := Fund.StrForm;
    65 :  Fld := Broker.StrForm;
    66 :  Fld := Trader.StrForm;
    67 :  Fld := Comment.StrForm;
   ELSE
     Fld := 'NA';
   END;
   OrdinalField := Fld;
END;

(* ---------------------------------------------- *)
FUNCTION TransFile.OrdinalDelimField(Num : INTEGER;
                                      Lotus : BOOLEAN) : String;

VAR
  Fld : String;
BEGIN
  WITH Trans DO
  CASE Num OF
    60 :  Fld := Cusip.DelimAscForm;
    61 :  Fld := TickNo.DelimAscForm;
    62 :  Fld := TradeD.DelimAscForm;
    63 :  Fld := SettleD.DelimAscForm;
    64 :  Fld := Fund.DelimAscForm;
    65 :  Fld := Broker.DelimAscForm;
    66 :  Fld := Trader.DelimAscForm;
    67 :  Fld := Comment.DelimAscForm;
   ELSE
     Fld := '"NA"';
   END;
   OrdinalDelimField := Fld;
END;

(* ---------------------------------------------- *)
PROCEDURE TransFile.ShowOrdinalFields;

BEGIN
    write  (' 60 :  Cusip':21);
    writeln(' 61 :  TickNo':21);
    write  (' 62 :  TradeD':21);
    writeln(' 63 :  SettleD':21);
    write  (' 64 :  Fund':21);
    writeln(' 65 :  Broker':21);
    write  (' 66 :  Trader':21);
    writeln(' 67 :  Comment':21);
END;

(* ============================================================= *)

(* ---------------------------------------------- *)
PROCEDURE DisplaySec(Security : CusipObjectPtr);


BEGIN
  WITH Security^ DO
  BEGIN
    Cusip.Display;
    Descrip.Display;
    UserID.Display;
    Descrip2.Display;
    Coupon.Display;
    MatDt.Display;
    IssDt.Display;
    FirstCpDt.Display;
    Writeln;
    CallPxOrFactor.Display;
    CallDt.Display;
    PutPxOrSpeed.Display;
    ParCallDt.Display;
    PutDt.Display;
    Writeln;
    RateSP.Display;
    RateMdy.Display;
    Sector1.Display;
    Sector2.Display;
    Sector3.Display;
    Sector4.Display;
    IssSize.Display;
    CalcCode.Display;
    PmtFreq.Display;
    Currency.Display;
    Country.Display;
  END;
END;

(* ---------------------------------------------- *)
PROCEDURE DisplayPos(Pos : CurrFileObjPtr);

BEGIN
  WITH Pos^ DO
  BEGIN
    Cusip.Display;
    Fund.Display;
    ParAmt.Display;
    TDAmt.Display;
    AvgCost.Display;
    AvgYld.Display;
    MktPx.Display;
  END;
END;

(* ---------------------------------------------- *)
BEGIN
(*  { not used }
  CenturyCrossover := date(1,1,1940);
*)
END.

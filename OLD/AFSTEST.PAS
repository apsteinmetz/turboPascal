PROGRAM AFSTEST;
(* Decoding routines for AFS BTRIEVE files *)

{No math routines but this uses IEEE number formats}
{$N+,E+}

uses BTRIEVE, AFSTRADE;


CONST
  CashCusips = '999999CSH 999999ACR 999999DEP 999999WDR';

VAR
  Cusip   : CusipFile;
  Holding : HoldingFile;
  KeyNum  : INTEGER;
  Fund,
  PosKey,
  SecKey     : String;
  SecurityPtr : CusipObjectPtr;
  PositionPtr : CurrFileObjPtr;
  n, err    : INTEGER;
  Done   : BOOLEAN;
  outfile : text;
  KeyBuf : KeyBufType;


(* ---------------------------------------------- *)
BEGIN

   Done := FALSE;

   (* open *)

   Fund := Paramstr(1);
   AssignKey(KeyBuf,Fund);
   Fund := 'blorp';
   AssignKey(KeyBuf,Fund);
end.
PROGRAM PORTSUM7;

{No math routines but this uses IEEE number formats}
{$N+,E+}

uses BTRIEVE, AFSTRADE, Crt, StrUtil;


CONST
  AvoidAcct = '-CURRENC';
  CashCusips = '999999CSH 999999ACR 999999DEP 999999WDR';
  CurrFileName = 'f:\trade7\currfile.btr';
  CusipFileName ='f:\trade7\cusipfil.btr';

VAR
  Cusip   : CusipFile;
  Holding : HoldingFile;
  KeyNum  : INTEGER;
  Fund,
  PosKey,
  SecKey     : String;
  SecurityPtr : CusipObjectPtr;
  PositionPtr : CurrFileObjPtr;
  err    : INTEGER;
  Done   : BOOLEAN;
  outfile : text;


(* ---------------------------------------------- *)
PROCEDURE OutPos(VAR f : TEXT);
VAR
  n, num, err : INTEGER;
  temp : string;

BEGIN
  FOR n := 2 TO ParamCount DO
  BEGIN
     val(paramstr(n),num,err);
     IF err = 0 THEN
        IF num < 22 THEN
        BEGIN
          temp := Cusip.OrdinalLotusField(num);
          write(f,temp:length(temp)+1)
        END
        ELSE BEGIN
          temp := Holding.OrdinalLotusField(num);
          write(f,temp:length(temp)+1)
        END;
  END;
  writeln(f);
END;




(* ---------------------------------------------- *)
BEGIN
   IF paramcount < 1 THEN
   BEGIN
      Cusip.ShowOrdinalFields;
      Holding.ShowOrdinalFields;
      Writeln('PORTSUM <Fund> <Field [Field] ....>');
      HALT;
   END;

   Assign(outfile,paramstr(1) + '.prn');
   Rewrite(outfile);

   Done := FALSE;
   ClrScr;

   (* open *)

   Fund := Capitalize(ParamStr(1));
   PosKey := Fund;
   Holding.Init(CurrFileName,ReadOnly,err);
   IF err =  0 THEN
      Cusip.Init(CusipfileName,ReadOnly,err)
   ELSE
     Halt;
   IF err = 0 THEN
   REPEAT
     PositionPtr := Holding.GetRecord(PosKey,GetGreater,FundKey,err);
     IF (err = 0) AND
        (copy(PosKey,1,4) = copy(Fund,1,4)) AND
        (pos(AvoidAcct,PosKey)=0) THEN
     BEGIN
         GotoXY(1,3);
         Write(copy(PosKey,1,22));
         SecKey := copy(PosKey,13,9);
         GotoXY(1,1);
         {skip if cash }
         IF pos(SecKey,CashCusips) = 0 THEN
        BEGIN
           SecurityPtr := Cusip.GetRecord(SecKey,GetEqual,CusipKey,err);
           IF err = 0 THEN
              OutPos(outfile);
        END;
     END
     ELSE
     BEGIN
         IF err > 0 THEN Writeln('Btrieve error #',err);
         Done := TRUE;
     END;
   UNTIL Done = TRUE;
   Writeln(outfile);
   Close(outfile);
   Writeln;
   Cusip.Close;
   Holding.Close;
end.

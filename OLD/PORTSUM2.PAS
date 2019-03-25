PROGRAM PORTSUM2;

{No math routines but this uses IEEE number formats}
{$N+,E+}

{$DEFINE Paradox}

uses BTRIEVE, AFSTRADE, Crt, StrUtil;


CONST
  AvoidAcct = '_CURR';
  CashCusips = '999999CSH 999999ACR 999999DEP 999999WDR';

  CurrFileName = 'f:\afstrade\currlots.btr';
  CusipFileName ='f:\afstrade\cusip290.btr';

VAR
  Cusip   : CusipFile;
  Holding : HoldingFile;
  BtrOp,
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
  Lotus : BOOLEAN;

BEGIN
{$IFDEF PARADOX}
  Lotus := FALSE;
{$ELSE}
  Lotus := TRUE;
{$ENDIF}

  FOR n := 2 TO ParamCount DO
  BEGIN
     val(paramstr(n),num,err);
     IF err = 0 THEN
     BEGIN
        { comma delimit fields after first one }
        IF n > 2 THEN
          write(f,',');
        IF num < 50 THEN
        BEGIN
          temp := Cusip.OrdinalDelimField(num,Lotus);
          write(f,temp:length(temp)+1)
        END
        ELSE BEGIN
          temp := Holding.OrdinalDelimField(num,Lotus);
          write(f,temp:length(temp)+1)
        END;
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

   { Open Files }
   Holding.Init(ReadOnly,err);
   IF err =  0 THEN
   BEGIN
      Cusip.Init(ReadOnly,err);
      IF err > 0 THEN
      BEGIN
        Holding.Close;
        HALT;
      END;
   END
   ELSE
     Halt;

   { Determine if All holdings should be scanned or just one fund }
   IF (pos('ALL',Fund) > 0) THEN
   BEGIN
     PositionPtr := Holding.RecordOp(PosKey,StepFirst,FundKey,err);
     BtrOp := StepNext;
   END
   ELSE
     BtrOp := GetGreater;


   IF err = 0 THEN
   REPEAT
     PositionPtr := Holding.RecordOp(PosKey,BtrOp,FundKey,err);


     { cash holdings have screwy record sizes that generate }
     { BTRIEVE error #22.  It's not fatal so override it    }
     IF err = 22 then err := 0;

     IF NOT (
          (err > 0)
        OR
          { if doing one fund confirm correct fund }
          ((BtrOp=GetGreater) AND (copy(PosKey,1,4) <> copy(Fund,1,4)))
        OR
          (pos(AvoidAcct,PosKey)>0)
           ) THEN
     BEGIN
         GotoXY(1,3);
         Write(Holding.Holding.Fund.StrForm);
         Write(Holding.Holding.Cusip.StrForm);
         SecKey := Holding.Holding.Cusip.StrForm;
(*
         Write(copy(PosKey,1,22));
         SecKey := copy(PosKey,13,9);
*)
         GotoXY(1,1);
         {skip if cash }
         IF (pos(SecKey,CashCusips) = 0) AND
            NOT (Holding.Holding.Fund.StrForm = '') THEN
         BEGIN
           SecurityPtr := Cusip.RecordOp(SecKey,GetEqual,CusipKey,err);
           IF err = 0 THEN
              { write the record out to file }
              OutPos(outfile);
         END;
     END
     ELSE
     BEGIN
         IF err > 0 THEN Writeln('Btrieve error #',err);
         Done := TRUE;
     END;
   UNTIL Done = TRUE;
{   Writeln(outfile); }
   Close(outfile);
   Writeln;
   Cusip.Close;
   Holding.Close;
end.

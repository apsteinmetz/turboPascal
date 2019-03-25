PROGRAM afsdate;
var
  instr : STRING;
  num   : WORD;

(* ---------------------------------------------- *)
FUNCTION IntToDate(DateNum : WORD) : STRING;

VAR
  Month, Day, Year : STRING[3];

{ INTEGER to date string
DEF FNDT$(A1)=RIGHT$(STR$(100+(A1 AND 480)/32),2)+"/" +
            RIGHT$(STR$(100+(A1 AND 31)),2)+"/"+
                 RIGHT$(STR$(80+(A1 AND -512)/512),2)
 }
BEGIN

  str( 80 + (DateNum shr 9) - ORD(DateNum shr 9 > 19)*100:2,Year);
  str(DateNum AND 511 div 32:2,Month);
  str((DateNum AND 31):2,Day);
  IntToDate := Month + '/' + Day + '/' + Year;

END;

(* ---------------------------------------------- *)
FUNCTION DateStrToNum(DateStr : String) : WORD;

VAR
  code : INTEGER;
  Month, Day, Year : WORD;
{
DEF FNBDT(DT$)=((VAL(RIGHT$(DT$,2))- (100*(VAL(RIGHT$(DT$,2))<40)) )-80)*512 +
                    VAL(DT$)*32 +
                    VAL(MID$(DT$,4))
}
BEGIN
   val(copy(DateStr,7,2),Year,code);
   val(copy(DateStr,1,2),Month,code);
   val(copy(DateStr,4,2),Day,code);

   DateStrToNum := ((Year + (100 * ORD(Year<40)))-80) * 512 +
                         Month * 32 + Day

END;

BEGIN
  Readln(instr);
  num := DateStrToNum(instr);
  Writeln(num:5);
  Writeln(IntToDate(num));
END.
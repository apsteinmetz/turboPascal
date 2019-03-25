{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program Muni;
{ $G1024}
!{!^ 1. Directives A,B,C,D,F,G,P,U,W,X are obsolete or changed in meaning}
{ $P1024}
!{!^ 2. Directives A,B,C,D,F,G,P,U,W,X are obsolete or changed in meaning}
{ $U+}
!{!^ 3. Directives A,B,C,D,F,G,P,U,W,X are obsolete or changed in meaning}


Uses
  Crt;

CONST
       space   = ' ';
       SemiYr  = 182.625;
       digits  = '0123456789';
       NYfil   = 'F:\ART\NYDATA.PRN';
       TFfil   = 'F:\ART\TFDATA.PRN';
       NumFutFile = 'F:\ART\NUMFUT.PRN';

       (* FIELD DATA FOR PARSER *)
       StartDataCol = 5;
       pNamS  = 41; pNamL  = 20;
       pMktS =  33; pMktL  = 7;
       pCoupS = 72; pCoupL = 6;
       pPxS   = 15; pPxL =   7;
       pYldS  = 90; pYldL =  6;
       pPreS  = 100; pPreL =  5;
       pPPxS  = 109; pPPxL =  5;
       pMatS  = 82; pMatL =  5;


type
     str80       = string[80];
     str132      = string[132];
     Destination = (Printer, Console, TextFile);
     DateNo      = REAL;
     BondRec     = RECORD
                   Issue    : str80;
                   NumFlows : integer;
                   Mkt,
                   Coupon,
                   Pmt,
                   PreRePx,
                   Accrued,
                   EstMat,
                   Mat, Settle,
                   NextPmt,
                   PrevPmt    : real;
                 end;

{Variables marked ** are input via the RECSCRN procedure}

var Bond       : BondRec;
    dest       : Destination;
    Index01,
    IndexVol,
    Price,
    Yield      : REAL;
    err        : INTEGER;
    FundsToDo  : SET OF (NY,TF);
    Answer     : Str80;
    infile,
    outnum,
    out        : Text;


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
(*
{$I CALENDAR.SUB}
{$I PRNDRV.INC}
*)
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DisplayMsg;
BEGIN
writeln('FOR FUTURE REFERENCE:');
writeln('All the information this program needs can be entered from');
writeln('the command line in the form MUNIHED Val01 Fund(s) Dest DestFile');
writeln('where: Val01 is the Muni Index Value of 01 from Telerate Page 14837');
writeln('       Fund(s) is N or T or both -  for NYTE or TaxFree or both');
writeln('       Dest is P(rinter) OR (S)creen OR (F)ile');
writeln('       DestFile as a filename to use if Dest = F');
writeln('FOR EXAMPLE: MUNIHED 0.089 N S or MUNIHED 0.089 NT F BOTHFUND.DAT');
writeln;
END;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION Exist(NameofFile: str80):Boolean;
  var
    Fil: file;
  begin
    Assign(Fil,NameOfFile);
    {$I-}
    Reset(Fil);
    {$I+}
    if IOresult <> 0 then
!{! 4. ^IOResult now returns different values corresponding to DOS error codes.}
     Exist := False
    else Exist := True;
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE OpenFile(VAR handle : text; Name : str80);
CONST DEBUG = TRUE;

BEGIN
   if debug then writeln(name);
   if not Exist(Name) then
   begin
     writeln(Name,' NOT FOUND');
     HALT;
   end;
   Assign(handle,Name);
   Reset(handle);
END; {OpenFile}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION DirectOutput(chr :CHAR; GoodFile : BOOLEAN) : Destination;
CONST ValidChars : SET OF CHAR = ['S','P','F'];

begin
  IF NOT (chr in ValidChars) THEN
  BEGIN
     write('Direct Output to (S)creen, (P)rinter or (F)ile? ');
     readln(answer);
     chr := upcase(answer[1]);
  END;
  case chr of
     'S' : begin
             assign(out,'CON:');
!{! 5. Special filenames^ CON:, TRM:, AUX:, USR: are not supported in Turbo 4.0.}
             DirectOutput := Console;
           end;
     'P' : begin
             assign(out,'LST:');
!{! 6. Special filename ^LST: is not supported now. USE PRINTER Lst file.}
             DirectOutput := Printer;
           end;
     'F' : BEGIN
           DirectOutput := TextFile;
           IF NOT GoodFile THEN
           BEGIN
             write('Enter name of file to put messages: ');
             readln(answer);
             assign(out,answer);
             if exist(answer) then
             begin
               write('FILE EXISTS!  Overwrite it? ');
               readln(answer);
               if upcase(copy(answer,1,1)) <> 'Y' then
                   DirectOutput := DirectOutput(chr,FALSE);
             end;
           END
           ELSE assign(out,paramstr(3))
           END;
  end; {case}
  rewrite(out);
end; {directoutput}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION trim(str : str80) : str80;
BEGIN
   while str[1] = space do delete(str,1,1);
   while str[length(str)] = space do delete(str,length(str),1);
   trim := str;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Parse(var Bond : BondRec;
                var Px, Yld : REAL;
                data :str132);
CONST debug = FALSE;
VAR err : INTEGER;

BEGIN
  with Bond DO
  BEGIN
    Issue := copy(data,pNamS,pNamL);
    val(trim(copy(data,pCoupS,pCoupL)),Coupon,err);
      if err > 0 then BEGIN writeln('C ERR'); HALT; END;
    val(trim(copy(data,pPreS,pPreL)),Mat,err);
      if err > 0 then BEGIN writeln('M ERR'); HALT; END;
      Mat := Mat + date(12,31,1899);
      if debug then writeln(datestring(mat,1));
    val(trim(copy(data,pPPxS,pPPxL)),PreRePx,err);
      if err > 0 then BEGIN writeln('p2 ERR'); HALT; END;
    val(trim(copy(data,pMktS,pMktL)),Mkt,err);
      if err > 0 then BEGIN writeln('Mkt ERR'); HALT; END;
  END;
  val(trim(copy(data,pPxS,pPxL)),Px,err);
     if err > 0 then BEGIN writeln('P ERR'); HALT; END;
  val(trim(copy(data,pYldS,pYldL)),Yld,err);
     if err > 0 then BEGIN writeln('Y ERR'); HALT; END;
END; {Parse}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FlowCount(First, Mat :real) : integer;
{compute the number of cash flows}

begin
   FlowCount := 1 + round((Mat - First)/SemiYr);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FirstPay(Setl, Maty : real) : real;
{date of first cashflow}

var m,d,y,
    Ms, Mm : integer;

begin
   d := day(Maty);          {first day..}
   Ms := month(Setl);
   Mm := month(Maty);
   if abs(Ms - Mm) > 6 then m := Mm
       else m := Mm + 6;
   if Mm = Ms then
       if Day(Maty) < Day(Setl) then m := Mm + 6;
   if m > 12 then   {adjust for year rollover mm # 13}
   begin
      m := m - 12;
      y := year(Setl) + 1;
    end
    else y := year(Setl);
    FirstPay := date(m,d,y);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Procedure Accrue(VAR B : BondRec);

var NextCoup, LastCoup : real;

begin
  WITH B DO
  BEGIN
    NextPmt := FirstPay(Settle,Mat);
    PrevPmt :=
      date(month(NextPmt-182.625),day(Mat),year(NextPmt-182.625));
    Accrued := (Coupon/2.0) * (Settle-PrevPmt)/(NextPmt-PrevPmt);
  END; {WITH}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Power(base,raise : real) : real;

begin
   Power  := exp(ln(base) * raise)
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Makebond(VAR B : BondRec);

begin
  Accrue(B);
  WITH B DO
  BEGIN
     Pmt := Coupon/200;
     numflows  := flowcount(NextPmt,mat);
  END;
end; {MakeBond}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function priceBond(B : BondRec; yield :real) : real;
{discount all cash flows to compute present value}
{ express yield as N.NN, not 0.0NNN }
var
     Basis,
     DiscSum  :  real;
     i        :  integer;

  begin
  with B do
  begin
    Basis := (NextPmt - settle)/(NextPmt-PrevPmt);
    yield   := ln(1 + yield/200); {intermediate result, saves time}
    DiscSum := 0;
    for i   := 1 to numFlows do
        begin
          DiscSum := DiscSum + pmt / exp(yield*(i-1));
        end;
    DiscSum := DiscSum + (PreRePx/100) / exp(yield*(numflows-1));
    DiscSum  := DiscSum / exp(yield*Basis);
    PriceBond := DiscSum;   {this includes accrued interest}
  end; {with}
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Duration(B : BondRec; yield : real; VAR AL : real): real;
{discount all cash flows to compute a
 modified MacCauly Duration value}

var  DiscSum,
     Basis,
     SumFlows,
     pp, Dur, PV  :  real;
     i            :  integer;

begin
  SumFlows := 0;
  AL       := 0;
  with B do
  begin
    Basis    := (NextPmt - settle)/(NextPmt-PrevPmt);
    yield    := ln(1 + yield/200); {intermediate result, saves time}
    DiscSum  := 0;
    Dur      := 0;
    for i    := 1 to numFlows do
        begin
          PV      := pmt / exp(yield*(i-1+basis));
          DiscSum := DiscSum + PV; { accumulate the denominator }
          Dur     := Dur + (PV * (i-1)); {accumulate the numerator }

          AL       := AL + (i * Pmt);
          SumFlows := SumFlows + Pmt;

        end;
    PP := (PreRePx/100);
    PV := PP / exp(yield*(numflows-1+basis));
    Dur := Dur + (PV * (numflows-1)); { numerator }
    DiscSum := DiscSum + PV;
    AL  := (Basis + (AL + pp * numflows)/(SumFlows+pp)) / 2;
    Duration := Dur/(DiscSum * 2 * exp(yield));
  end;
end; {Duration}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Procedure MatBond(VAR Bond : BondRec; Yld, Px : real);

const maxiter   = 40;
      tolerance = 0.0003;
      DEBUG     = FALSE;

var   low,high,incr,
      upper,lower,
      GrossPx,
      pricecalc  :  real;
      n          :  integer;
      done       :  boolean;

begin
  n         := 0;
  GrossPX   := (Px + Bond.Accrued)/100; {*}
  high      := date(1,1,2060); { max maturity 1/1/2060 } {*}
  low       := Today; {*}
  incr      := (high - low)/2;
  upper     := GrossPx + tolerance;
  lower     := GrossPx - tolerance;
  done      := false;
    repeat   {goal seeking}
       n := n + 1;
       Bond.EstMat  := low + incr;
       Bond.numflows := FlowCount(Bond.NextPmt,Bond.EstMat);
       pricecalc := priceBond(Bond,Yld);

       if debug then writeln(n:3,incr:5:0,' ',
                             datestring(low,1),' ',
                             datestring(Bond.EstMat,1),
                             pricecalc*100-Bond.Accrued:9:3);

       if Yield < Bond.Coupon then
          if pricecalc < lower then low := low + incr
            else if pricecalc > upper then incr := incr/2
               else done := true;
       if Yield > Bond.Coupon then
          if pricecalc > upper then low := low + incr
            else if pricecalc < lower then incr := incr/2
               else done := true;

       if n = maxiter then done := true;
    until done;  {goal seeking}
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function YieldBond(Bond: BondRec; Px : real) :real;
  {iteration routine to find yield - quite slow}

const maxiter   = 25;
      tolerance = 0.0003;
      DEBUG = FALSE;

var   low,high,incr,
      upper,lower,
      Ayield,
      GrossPx,
      pricecalc  :  real;
      n          :  integer;
      done       :  boolean;

begin
  n         := 0;
  GrossPX   := (Px + Bond.Accrued)/100;
  high      := Bond.Coupon/GrossPx +1;
  low       := 1.00;
  incr      := (high - low)/2;
  upper     := GrossPx + tolerance;
  lower     := GrossPx - tolerance;
  done      := false;
  if debug then writeln(bond.accrued:5:2);
  if debug then writeln(datestring(bond.prevpmt,1));
  if debug then writeln(datestring(bond.settle,1));
  if debug then writeln(datestring(bond.nextpmt,1));
  if debug then writeln(bond.numflows:5);
    repeat   {goal seeking}
       n := n + 1;
       Ayield    := low + incr;
       pricecalc := priceBond(Bond,Ayield);
       if pricecalc < lower then incr := incr/2
         else if pricecalc > upper then low := low + incr
             else done := true;
       if n = maxiter then done := true;
    until done;  {goal seeking}
yieldBond := Ayield;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION comma(v : real; w: integer) : str80;
VAR
   s        : str80;
   n, start : integer;
BEGIN
   s := '';
   str(v:w:0,s);
   start := w div 3;
   for n := 1 to start do
       if pos(s[w-n*3],digits)>0 then insert(',',s,w-n*3+1);
   comma := s;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE GetIndexInfo;

BEGIN
     writeln('Telerate Page 14837 has the "VALUE OF .01: "');
     writeln(' of the Bond Buyer Index');
     REPEAT
        write('Type in that value: ');
        readln(answer);
        val(trim(answer),Index01,err);
        if (Index01 > 1.0) or (err > 0) then
         begin
          writeln('BAD NUMBER!  The number must be less than one');
          writeln('and it cannot have any letters in it. Try again.');
        end;
     UNTIL (Index01 < 1.0) AND (err = 0);
END;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE PrintSummary(VAR output : text;
                        SumVol, SumMkt,
                        SumDur, SumAL  : REAL);
BEGIN
   writeln(output);
   write(output,'Portfolio "01" val: ',SumVol/SumMkt:5:3);
   write(output,'  Dur:',SumDur:5:3,' yrs');
   write(output,'  AvgLife:',SumAL:5:3,' yrs');
   writeln(output);
   writeln(output,'Portfolio Price Risk per 100 BP: $',comma(SumVol,10));
   writeln(output);
   writeln(output,'Value of an "01" to Bond Buyer Index:',Index01:5:3);
   writeln(output,'Muni Futures Change per 100 BP:  $',comma(IndexVol,7));
   writeln(output,'Futures needed to hedge: ',comma(SumVol/IndexVol,7));
   writeln(output); writeln(output);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE CheckCommandLine;
VAR chr      : CHAR;
    GoodFile : BOOLEAN;

  PROCEDURE CheckFund(n : str80);
  BEGIN
     if length(n) > 0 then
     BEGIN
        IF pos('N',n) > 0 THEN FundsToDo := FundsToDo + [NY];
        IF pos('T',n) > 0 THEN FundsToDo := FundsToDo + [TF];
     END;
  END;

BEGIN
  err := 1;
  if length(paramstr(1)) > 1 then val(paramstr(1),Index01,err)
    ELSE DisplayMsg;
  if err > 0 then GetIndexInfo;

  IF length(paramstr(4)) > 0 THEN GoodFile := TRUE;
  chr :=#0;
  if length(paramstr(3)) > 0 then
       chr := upcase(copy(paramstr(3),1,1));
  IF NOT (chr = 'F') THEN dest := DirectOutput(chr,FALSE)
     ELSE dest := DirectOutput(chr,GoodFile);
  FundsToDo := [];
  CheckFund(paramstr(2));
  If FundsToDo = [] THEN
  BEGIN
     write('Evaluate NYTE or TaxFree (<Return> for both)? ');
     readln(answer);
     CheckFund(answer);
  END;

END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Process(thefile : str80; Yloc : integer);
CONST debug = TRUE;
VAR
    SumVol,
    SumMkt,
    SumDur,
    SumAL,
    Vol,
    AL,
    dur   : real;
    data  : Str132;

BEGIN
   SumVol := 0;
   SumMkt := 0;
   SumDur := 0;
   SumAL  := 0;
   IndexVol := Index01 * 100000.0 (* $ per contract *);
   OpenFile(infile,thefile);
   writeln(out,' ISSUE    ':20,'COUP ':7,'PR MAT':9,' DUR  ':10,
              'Px Vol':14,'Hedge  ':10);
   while not EOF(infile) do
   BEGIN
      readln(infile,data);
      if pos(data[StartDataCol],digits) > 0 then
      BEGIN
         Parse(Bond,Price,Yield,data);
         Bond.Settle := Today;
         MakeBond(Bond);
         with Bond DO
         BEGIN
            write(out,Issue,Coupon:7:3,'  ',datestring(Mat,1));
            if dest <> Console then
                 BEGIN
                    gotoXY(1,yLoc);
                    write(Issue);
                 END;
            numflows := FlowCount(NextPmt,Mat);
            dur := duration(Bond,Yield, AL);
            write(out,dur:7:2,' yrs  ');
    IF DEBUG THEN write('  AL: ',AL:5:2,' yrs  ');
            Vol := Mkt*dur/100;
            SumVol := SumVol + Vol;
            SumMkt := SumMkt + Mkt;
            SumDur := SumDur + (Mkt*Dur);
            SumAL  := SumAL  + (Mkt*AL);
            write(out,comma(Vol,6));
            write(out,Vol/Indexvol:5:1,' futs');
            writeln(out);
         END;
      END;
   END;  {while not EOF}
   GotoXY(1,Yloc); writeln('                                   ');
   SumDur := SumDur/SumMkt;
   SumAL  := SumAL /SumMkt;
   PrintSummary(out,Sumvol,SumMkt,SumDur, SumAL);
   if dest <> Console then PrintSummary(CON,SumVol,SumMkt,SumDur,SumAL);
!{! 7. Special devices Con, Trm, Aux, Us^r are not supported in Turbo 4.0.}
   writeln(outnum,theFile,' ',SumVol/IndexVol:7:0);
   Close(infile);
END; {PROCESS}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{MAIN PROGRAM}
begin
     CheckCommandLine;
(*     ProtectPrinter(LPT1);  { from PRNDRV.INC } *)
     ClrScr;
     Assign(outnum, NumFutFile);
     rewrite(outnum);
     IF (NY IN FundsToDo) or (FundsToDo = [])
         then Process(NYfil,whereY + 1);
     IF (TF IN FundsToDo) or (FundsToDo = [])
         then Process(TFfil,whereY + 1);
(*     RestorePrinter;        { from PRNDRV.INC }     *)
     Flush(out);
     Close(out);
     Flush(outnum);
     Close(outnum);
end.

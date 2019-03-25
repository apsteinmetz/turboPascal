{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

(* FORCE 8087 OPTION OFF *)
{$IFDEF CPU87}
  {$N+}
{$ELSE}
  {$N-}    {No numeric coprocessor}
{$ENDIF}
(* *)

(*  {$DEFINE DEBUG} *)

program WORSTYLD;

Uses
  Crt,
  Dos,
  Calendar;

const maxflow = 400;  {360 should be the most encountered}
      freq    = 2;   {payments per year}
      debug   = FALSE;
      hi      = 2; {for beep  procedure}
      lo      = 1;
      space   = ' ';

type
     PmtStream  = array[0..maxflow] of real;
     typeOfBond = (TSY,GNMA,FHLMC,FNMA,FHLB,CORP);
     index      = 0..maxflow;
     Freqs      = BYTE;

    BondRec = RECORD
                BND                 : PmtStream;

                BondType            : TypeOfBond;

                Mat, Settle,
                Accrual, BaseDate,
                NextCoup, LastCoup  : longint;

                Sinkfreq             : Freqs;
                SinkPer,
                MatFlow, SinkFlow,
                FirstFlow, CallFlow,
                EndSinkFlow,
                ParCallFlow         : integer;

                Balance,
                SinkRate, SinkPrice,
                FirstCallPx,
                PeriodInt, Coupon   : real;
                {Time Settle to Coup / Time Coup to Coup }
                PeriodFrac :  real;

              end;

var
    price,
    yield,
    CallPx, RemBal,
    AvgLife    : real;
    pMat,
    pCoup,
    pPrice,
    pNext,
    lMat,
    lCoup,
    lPrice,
    lNext,
    err,
    n,i        : integer;
    out        : Text;
    TheBond    : BondRec;
    ADate      : longint;
    Quit       : Boolean;
    tempstr,
    WorkStr    : String;
    infile,
    outfile    : Text;

{$IFDEF DEBUG}
  DiscFlow  : ARRAY[0..MaxFlow] of real;
{$ENDIF}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Terminate(ErrMsg : String);
begin
   close(infile);
   close(outfile);
   writeln(ErrMsg);
   HALT;
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure ParseLine(str : String; i : integer; VAR start, len : integer);
const
  space = #32;
type
  StateType = (BetweenVar, InVar);

var
  count,j  : integer;
  State    : StateType;


begin
  j     := 1;
  count := 1;
  if str[1] = space then
    State := BetweenVar
    else State := InVar;
  repeat
  CASE State of
     BetweenVar : begin
                    while str[j] = space do inc(j);
                    inc(state);
                  end;
     InVar      : begin
                    Start := j;
                    while str[i] <> space do inc(j);
                    len := j - Start;
                    inc(count);
                    inc(state);
                  end;
     end; {CASE}
  until j > i;   {we've reached paramstr}

end; {parseline]

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure FindParamLocs;
var
   i : integer;
   done : BOOLEAN;

begin
   i    := 1;
   done := FALSE;
   repeat
   if length(paramstr(i)) > 0 then
   begin
      CASE i of
         1 : ParseLine(WorkStr,i,pMat,LMat);
         2 : ParseLine(WorkStr,i,pPrice,LPrice);
         3 : ParseLine(WorkStr,i,pCoup,LCoup);
         4 : ParseLine(WorkStr,i,pNext,LNext);
         else done := TRUE;
         end; {case}
      inc(i);
   end;
   until done;
   if i < 5 then Terminate('Missing Variable in line of input file');
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FlowCount(Base,Flow : longint) : integer;
{compute the number of cash flows to any security}
{base should be number 1}

begin
   Base := Date(month(Base),day(Flow),year(Base));
   FlowCount := round((Flow - Base)/(365.25/freq));
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Fixdate (VAR suspect : longint ; base  : longint);
{ensure month doesn't slip because of dates at beginning or end of it}

var
   shift : integer;

begin
   { two loops are most required }
   shift := 15;  {15 days oughta be enough}
   while (month(suspect) mod freq) <> (month(base) mod freq) do
     begin
       suspect := suspect + shift;
       shift := shift * -2;  { orig date minus orig shift }
     end;
   suspect := Date(month(suspect),day(base),year(suspect));
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FlowDate(base  : longint;
                  FlowNum : integer) : longint;

{compute the date of an ordinal cash flow}
var
   tempdate : longint;

begin
   tempDate := base + round(FlowNum * 365.25/freq);
   FixDate(tempdate,base);
   Flowdate := tempdate;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Order(VAR A, B :longint);
var
   temp : longint;
begin
   if A > B then
   begin
     temp := B;
     B := A;
     A := temp;
   end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure FindPeriodFrac(VAR B : BondRec);
var
   temp : real;
begin
  with B do
  begin
     CASE BondType of
     CORP :
     begin
        temp := month(settle) - month(BaseDate) - 1;
        if month(settle) < month(BaseDate) then
          temp := temp + 12;
        PeriodFrac := (temp * 30 + day(settle) + 30 - day(BaseDate))/180;
     end;
     TSY :
        PeriodFrac := (NextCoup - Settle) / (NextCoup - LastCoup);
     end; {CASE}
  end; {With}
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure FindSemiCoups(VAR B : BondRec);
var
   AltMonth      : integer;
   temp          : longint;

begin
  with B do
  begin
   if month(mat) = 12 then AltMonth := 6
     else AltMonth := (month(mat) + 6) mod 12;
   LastCoup := date(month(mat),day(mat),year(settle));
   NextCoup := date(AltMonth,day(mat),year(settle));
   Order(LastCoup,NextCoup);   {arrange in order }

   if NextCoup <= settle then   {both behind settle}
   begin
      LastCoup := NextCoup;
      NextCoup := NextCoup + 182;
      FixDate(NextCoup,mat);
   end
   else
     if LastCoup > settle then
     begin
       {both ahead of settle}
        NextCoup := LastCoup;
        LastCoup := LastCoup - 182;
        FixDate(LastCoup,mat);
     end;
     { if LastCoup <= settle < NextCoup don't change anything }
  end; {with B do}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Accrued(VAR B : BondRec) : real;

begin
  with B do
  begin
     CASE  BondType OF
     GNMA:
        Accrued := (day(settle) - 1) * (coupon/36000.0);
     CORP:
        begin;
           FindSemiCoups(B);
           Accrued := PeriodFrac * coupon/(freq * 100);
        end;
    end; {CASE}
  end; {with B do}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Power(base,raise : real) : real;

begin
   Power  := exp(ln(base) * raise)
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Makebond( VAR B : BondRec;
                    numflows : integer;
                    VAR CallPrice : real;
                    VAR RemainBal :real);

var   n  : integer;
      T,
      PeriodInt,
      PrinPay,
      lnMoPay,
      Interest,
      SchedPay,
      SumFlows,
      CumSinkPay,
      PrePay       : real;
      CoupDate     :daterec;
      SinkFlag     : boolean;


begin
  with B do
  begin
     SumFlows   := 0;
     AvgLife    := 0;
     CumSinkPay := 0;
     for n := 1 to numflows do
       begin
          PrinPay := 0;

       { Do the SINKING FUND STUFF }
          SinkFlag := FALSE;
          if ( n < SinkFlow) then      { sink has not started}
                RemainBal := Balance
          else
             if n > EndSinkFlow then      { sink is over}
                RemainBal :=
                  Balance - SinkRate *
                     trunc((EndSinkFlow - SinkFlow) / SinkFreq + 1)

             else { we're in torpedo range }
               if ((SinkFreq = 2) AND (n mod 2 = SinkPer))
                     OR (SinkFreq = 1 ) then   { now do a sink }
               begin
                 SinkFlag := TRUE;
                 { no error checking for negative balance }
                     CumSinkPay :=
                        SinkRate * trunc( (n - SinkFlow) / SinkFreq +1 );
                 RemainBal := Balance - CumSinkPay;
                 PrinPay   := SinkRate * SinkPrice;
               end;

     { Do the INTEREST ACCRUAL stuff}
         if n < FirstFlow then
             Interest := 0
         else
             if SinkFlag then
             { add back the sink to do the interest }
                Interest  := PeriodInt * (RemainBal + SinkRate)
             else
                Interest := PeriodInt * RemainBal;

      { Do the CALL Stuff }
          if (n = numflows) and (n >= CallFlow) then
          begin
            if n < ParCallFlow then
            begin
             { bond is called, compute call price }

             CallPrice := ( (FirstCallPx - 100) *
                   (1-  (n - CallFlow)
                       /(ParCallFlow-CallFlow)  ) +100) / 100
            end
            else CallPrice := 1;
            PrinPay := PrinPay + (RemainBal * CallPrice);
          end;

          If RemainBal < 0 then
          begin
             RemainBal := 0;
             BND[n] := 0;
          end
          else
             BND[n]     := PrinPay + Interest;
          SumFlows  := SumFlows + PrinPay;
          AvgLife   := AvgLife + (PrinPay * n);

{$IFDEF DEBUG}
     if n = Sinkflow then write('Sink');
     if n = EndSinkflow then write('EndSink');
     write(n:3,RemainBal:5:3);
     write(' ',PrinPay:6:4,' ',Interest:6:4);
     writeln;
{$ENDIF}
       end; { for n := 1 to numflows }
     AvgLife := AvgLife / SumFlows;
 end; {with B}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function priceBND( B : BondRec;
                   numflows : integer ;
                   yield : real         ): real;

{discount all cash flows to compute a
 present value}

var  DiscSum,
     PV         :  real;
     i          :  index;

begin
  with B do
  begin
(*   yield    := (power(yield/200+1,1/6) -1) * 1200;  {CBE to monthly} *)

    yield    := ln(1 + yield/200); {intermediate result, saves time}
    DiscSum  := BND[1];
    for i    := 2 to numflows do
        begin
          PV := BND[i] / exp(yield*(i-1));
          DiscSum := DiscSum + PV;
{$IFDEF DEBUG} DiscFlow[i] := PV;  {$ENDIF}
        end;
    DiscSum  := DiscSum / exp(yield*(1-PeriodFrac));
    priceBND := DiscSum;   {this includes accrued interest}
  end; {with B do}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function DurationBND( B : BondRec;
                   numflows : integer ;
                   yield : real         ): real;

{discount all cash flows to a monthly paying instrument to compute a
 modified MacCauly Duration value}

var  DiscSum,
     Dur, PV  :  real;
     i        :  index;

begin
  with B do
  begin
(*    yield    := (power(yield/200+1,1/6) -1) * 1200;  {CBE to monthly} *)
    yield    := ln(1 + yield/200); {intermediate result, saves time}
    DiscSum  := BND[1];
    Dur      := BND[1];
    for i    := 2 to numFlows do
        begin
          PV      := BND[i] / exp(yield*(i-1));
          DiscSum := DiscSum + PV;
          Dur     := Dur + (PV * i);
        end;
    DiscSum  := DiscSum / exp(yield*(1-PeriodFrac));
    DurationBND := Dur/(DiscSum * 12 * exp(yield));
  end; {with b do}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function YieldBND(B : BondRec; numflows : integer):real;
  {iteration routine to find yield - quite slow}

const maxiter   = 50;
      tolerance = 0.0003;

var   low,high,incr,
      upper,lower,
      Ayield,
      pricecalc  :  real;
      n          :  integer;
      done       :  boolean;

begin
  with B do
  begin
     low       := 1;
     n         := 0;
     high      := 2.0; { highest allowable yld = 100% }{ Coupon/BND[0] + 1.0; }
     incr      := (high - low)/2;
     upper     := BND[0] + tolerance;
     lower     := BND[0] - tolerance;
     done      := false;
     repeat   {goal seeking}
       n := n + 1;
       Ayield    := low + incr;
       pricecalc := priceBND(B,numflows,Ayield);
       if pricecalc < lower then incr := incr/2
         else if pricecalc > upper then low := low + incr
             else done := true;
       if n = maxiter then done := true;
   until done;  {goal seeking}
     yieldBND := Ayield;
  end; {with B do}
end;

{-------------------------------------------------------------}
function GetAnswer(QueryString :String;
                   VAR OldDefault : String ) : Boolean;
{ unsophisticated input processor }

var response : string;

begin
  write(QueryString,' [',OldDefault,'] ');
  readln(response);
  if response <> '' then
  begin
     OldDefault := response;
     GetAnswer := TRUE;
  end
  else GetAnswer := FALSE;
end;
{-------------------------------------------------------------}
procedure CheckReal(VAR numstr: string; VAR num : real);
var
  err : integer;

begin
  if pos('.',numstr) = 0 then numstr := numstr + '.0';
  val(numstr,num,err);
  if err > 0 then writeln('real number error');
end;

{-------------------------------------------------------------}
procedure CheckByte(VAR numstr: string; VAR num : Byte);
var
  err : integer;

begin
  val(numstr,num,err);
  if err > 0 then writeln('Byte error');
end;
{-------------------------------------------------------------}

{MAIN PROGRAM}
begin
    {INITIALIZE}

 TheBond.SinkFlow := 1;
 TheBond.SinkRate := 0.0;
 TheBond.SinkPrice := 1.0; { no option to change yet }
 TheBond.SinkFreq := 2;    {2 coups between sinks}

 TheBond.FirstCallPx := 100.0;
 TheBond.settle := today;
 TheBond.Balance := 1;  {100% remaining}
 TheBond.BondType := CORP;

 readln(infile,WorkStr);  {get first line}
 FindParamLocs;  {find variable locations}
 reset(infile);           {go back to beginning of file}

while not EOF(InFile) do
 with TheBond DO
 begin
    readln(infile,WorkStr);
    tempstr := copy(WorkStr,pMat,lMat);
    Mat := ParseDateStr(tempstr);
    if Mat = 0 then terminate('Maturity is Bad');
    FindSemiCoups(TheBond); {Just to  force finding theoretical Base}
    BaseDate := LastCoup;

    {restore proper NextCoup}
    tempstr := copy(WorkStr,pNext,lNext);
    NextCoup := ParseDateStr(tempstr);
    if NextCoup = 0 then terminate('Next Coupon Date is Bad');
    Accrual := NextCoup -182;
    FixDate(Accrual,Mat);
    FindPeriodFrac(TheBond);

    val(copy(WorkStr,pPrice,lPrice),Price,err);
    if err <> 0 then terminate('Price is Bad');
   val(copy(WorkStr,pCoup,lCoup),Coupon,err);
    if err <> 0 then terminate('Coupon is Bad');


    MatFlow     := flowcount(BaseDate,Mat);
    ParCallFlow := MatFlow;
    FirstFlow   := flowcount(BaseDate,NextCoup);
(*
    if ans[6] = '' then
      if BaseDate <> Accrual then
      begin
        {set default First Call Date to Accrual}
        ans[6] := ans[2];
        CallFlow := flowcount(BaseDate,Accrual);
        ans[7] := '100.0';
        FirstCallPx := 100.0;
      end
      else
*)
      begin
        {set default First Call Date to final Mat}
        CallFlow := Matflow;
        FirstCallPx := 100.0;
      end;

{zero the array}

    for n := 0 to MaxFlow do BND[n] := 0;

    PeriodInt := Coupon/200;
     BND[0] := price/100 * Balance;
     if FirstFlow = 1 then
         BND[0] := BND[0] + (accrued(TheBond) * Balance);
      MakeBond(TheBond,n,CallPx,RemBal);

      Yield := YieldBnd(Thebond,n);
      writeln(yield:6:3);
      writeln(OutFile,yield:6:3);
 end; {with TheBond do}
end.

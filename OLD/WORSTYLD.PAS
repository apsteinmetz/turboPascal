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
      numvars = 13;
      freq    = 2;   {payments per year}
      debug   = FALSE;
      hi      = 2; {for beep  procedure}
      lo      = 1;
      space   = ' ';

type
     PmtStream  = array[0..maxflow] of real;
     typeOfBond = (TSY,GNMA,FHLMC,FNMA,FHLB,CORP);
     index      = 0..maxflow;
     StrArray   = Array[0..numvars] of String;
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
    n,i        : integer;
    out        : Text;
    TheBond    : BondRec;
    ADate      : longint;
    Ans        : StrArray;
    Quit       : Boolean;

{$IFDEF DEBUG}
  DiscFlow  : ARRAY[0..MaxFlow] of real;
{$ENDIF}

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
 Quit := FALSE;
 ans[0] := 'Y';  { do another? }
 for n := 0 to numvars do Ans[n] := '';  {clear answer strings array}
 TheBond.SinkFlow := 1;
 TheBond.SinkRate := 0.0;
 TheBond.FirstCallPx := 100.0;
 ans[1] := datestring(today,1);
 TheBond.settle := today;
 ans[12] := '1';
 TheBond.SinkFreq := 2;  {2 coups between sinks}
 ans[13] := '100';
 TheBond.Balance := 1;  {100% remaining}

{$IFDEF DEBUG} for n := 0 to maxflow do DiscFlow[n] := 0; {$ENDIF}

repeat
 ClrScr;
 with TheBond DO
 begin
    BondType := CORP;

    if GetAnswer('Settlement Date?',ans[1]) then
           Settle := ParseDateStr(ans[1]);

    if GetAnswer('Accrual (or Previous Coupon) Date?',ans[2]) then
        Accrual := ParseDateStr(ans[2]);

{$IFDEF DEBUG} Accrual := date(9,1,1987); {$ENDIF}

    if GetAnswer('Final Maturity Date?',ans[3]) then
        Mat := ParseDateStr(ans[3]);

{$IFDEF DEBUG} Mat := date(9,1,2001); {$ENDIF}

    { These are dependent on all of the above }
    FindSemiCoups(TheBond); {Just to  force finding theoretical Base}
    BaseDate := LastCoup;
{XX}    writeln(month(LastCoup):5); readln;
    {restore proper NextCoup}
    NextCoup := Accrual+182;
    FixDate(NextCoup,Mat);
    FindPeriodFrac(TheBond);


    MatFlow   := flowcount(BaseDate,Mat);
    FirstFlow  := flowcount(BaseDate,NextCoup);

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
      begin
        {set default First Call Date to final Mat}
        ans[6] := ans[3];
        CallFlow := Matflow;
        ans[7] := '100.0';
        FirstCallPx := 100.0;
      end;

    If GetAnswer('Price?',ans[4]) then
        CheckReal(ans[4],Price);

{$IFDEF DEBUG} Price := 70.0; {$ENDIF}

    if GetAnswer('Coupon?',ans[5]) then
        CheckReal(ans[5],Coupon);

{$IFDEF DEBUG} Coupon := 8.5; {$ENDIF}

    if GetAnswer('First Call Date?',ans[6]) then
      CallFlow   := flowcount(BaseDate,ParseDateStr(ans[6]));

    If GetAnswer('First Call Price?',ans[7]) then
        CheckReal(ans[7],FirstCallPx);

    if GetAnswer('Par Call Date?',ans[8]) then
      ParCallFlow   := flowcount(BaseDate,ParseDateStr(ans[8]));
    if ans[8] {still} = '' then ParCallFlow := MatFlow;

    if GetAnswer('First (or next) Sink Date?',ans[9]) then
      SinkFlow   := flowcount(BaseDate,ParseDateStr(ans[9]));

    If GetAnswer('Percent of original issue outstanding?',ans[13]) then
    begin
        CheckReal(ans[13],Balance);
        Balance := Balance/100;
    end;

{$IFDEF DEBUG} Balance := 0.935; {$ENDIF}

(* {$IFDEF DEBUG} SinkFlow := flowcount(BaseDate,date(5,15,1988)); {$ENDIF} *)
      SinkPer := SinkFlow mod 2;

    if GetAnswer('Sink Rate (%)?',ans[10]) then
    begin
      CheckReal(ans[10],SinkRate);
      SinkRate := SinkRate/100;
    end;

{$IFDEF DEBUG} SinkRate := 0.065; {$ENDIF}

     if GetAnswer('Last Sink Date?',ans[11]) then
      EndSinkFlow   := flowcount(BaseDate,ParseDateStr(ans[11]));

{$IFDEF DEBUG} EndSinkFlow := flowcount(BaseDate,date(5,15,1992)); {$ENDIF}

    If GetAnswer('Sink Frequency (1 or 2 per year)?',ans[12]) then
    begin
       CheckByte(ans[12],SinkFreq);
      { now convert SinkFreq to the number of coup dates between sinks}
       if SinkFreq = 2 then SinkFreq := 1
         else SinkFreq := 2;   { bogus answer defaults to yearly sink }
    end;

    SinkPrice := 1.0; { no option to change yet }

    {zero the array}
    for n := 0 to MaxFlow do BND[n] := 0;

    PeriodInt := Coupon/200;
     BND[0] := price/100 * Balance;
     if FirstFlow = 1 then
         BND[0] := BND[0] + (accrued(TheBond) * Balance);

{write headers}
ClrScr;
writeln('YIELD TO WORST CALCULATOR');
write('settle:',datestring(settle,1));
write('  Accrual (or Prev. Coup):',datestring(Accrual,1));
write('  mat:',datestring(flowdate(BaseDate,matflow),1));
writeln;
writeln;
write('Price:',Price:7:3);
write('  Coupon: ',Coupon:7:3);
writeln;
writeln;
write('First Call:',datestring(flowdate(BaseDate,CallFlow),1));
write('  First Call Px: ',FirstCallPx:7:3);
write('  Par Call:',datestring(flowdate(BaseDate,ParCallFlow),1));
writeln;
writeln;
write('Sink Start:',datestring(flowdate(BaseDate,SinkFlow),1));
write('  SinkRate:',SinkRate*100:6:2,'%');
write('  Sink End:',datestring(flowdate(BaseDate,EndSinkFlow),1));
writeln;
writeln;
for n := 1 to 2 do
begin
   write('Call Date':11);
   write('Yield':6);
   write('CallPx':10);
   write('RemBal':7);
end;
writeln;

     for n := CallFlow to MatFlow do
     begin
        MakeBond(TheBond,n,CallPx,RemBal);
        Yield := YieldBnd(Thebond,n);

{$IFDEF DEBUG}
readln;
        if (n = MatFlow) or (n = CallFlow) then
        begin
        writeln('Yield: ',yield:6:2);
        writeln('1-PeriodFrac: ',1-periodFrac:6:4);
        writeln('DiscFactor: ',1/power((1+coupon/2),(1-periodfrac)):6:2);
           { display cash flows to maturity }
           for i := 0 to n do
           begin
              write(DateString(FlowDate(BaseDate,i),1));
              write(BND[i]:7:4,'  ');
              if i mod 2 = 0 then writeln;
           end;
           writeln;
        end;
 {$ENDIF}

        Write(DateString(FlowDate(BaseDate,n),1):11);
        write(yield:6:2,'%');
        Write(CallPx *100:10:3,RemBal*100:6:1);
        if n mod 2 = 0 then writeln;

     end;
  end; {with TheBond}
  if GetAnswer('Do Another',ans[0]) then
     if upcase(ans[0,1]) = 'N' then Quit := TRUE;
until Quit;
end.

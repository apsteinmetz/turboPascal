UNIT Bondage;
{updated to delphi 2.0 compatibility}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
interface

uses MathLib0, Calendar;

{ These routines cover only "simple" bonds right now.  That is: they pay
a constant semiannual coupon between now and maturity.  The only
principal repayment is at maturity
}

CONST
  { Pay Types for compounding }
  SemiAnnl = 2;
  Annl     = 1;
  Monthly  = 12;

TYPE
     MONEY =  DOUBLE;

     BondType = (TSY,CORP,MUNI,MBS);
     BondRec     = RECORD
                   Issue    : string;
                   NumFlows : integer;
                   Mkt,
                   Cpn,
                   Pmt,
                   BulletPayPx,
                   Accrued    : MONEY;
                   EstMat,
                   Mat, Setl,
                   NextPmt,
                   PrevPmt    : DATEINT;
                   CASE BType : BondType OF
                      MBS : ( SMM    : myFloat;
                              Factor : MONEY;
                              Delay  : INTEGER);
                 end;

procedure IncMonth(VAR ADate : DATEINT; Increment : INTEGER);
{ increase/decrease ADate by Increment months }

function FirstPay(Settle, Maty : DATEINT) : DATEINT;
{date of first cashflow}

Procedure Accrue(VAR B : BondRec);
{figures accrued interest}

procedure Makebond(Settle, Mature : DATEINT; Coupon : MONEY; VAR B : BondRec);

function priceBond(B : BondRec; yield :myFloat) : MONEY;

function Duration(B : BondRec; yield : myFloat; VAR AL : myFloat): myFloat;

function YieldBond(Bond: BondRec; Px : MONEY) :myFloat;
  {iteration routine to find yield - quite slow}

Procedure MatBond(VAR Bond : BondRec; Yld : myFloat; Px : MONEY);
{ estimates Maturity given price and yield.  Error increases as price
  approaches par.  At par the result is meaningless }

function ReinvestCoups( Bond : BondRec;
                        SellDate : DATEINT;
                        ReinvRate : myFloat) : MONEY;

function TotalReturn(Bond              : BondRec;
                     BuyDate, SellDate : DATEINT;
                     BuyYld, SellYld,
                     ReinvRate         : myFloat     ): myFloat;

function Compound( Return : myFloat; CmpndPer : INTEGER ) : myFloat;

function Annualize(Return : myFloat; StartDate, EndDate : DATEINT) : myFloat;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
implementation
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

CONST
   SemiYr = 182.625;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FlowCount(First, Mat : MONEY) : integer;
{compute the number of cash flows}

begin
   FlowCount := 1 + round((Mat - First)/SemiYr);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure IncMonth(VAR ADate : DATEINT; Increment : INTEGER);
{ increase/decrease ADate by Increment months }

VAR m,d,y : INTEGER;

BEGIN
   d := day(ADate);
   m := month(ADate) + Increment;
   y := year(ADate);
   REPEAT
      if m > 12 then
      begin
          m := m - 12;
          y := y + 1;
      end;
   UNTIL m < 13;
   REPEAT
      if m < 1 then
      begin
          m := m + 12;
          y := y - 1;
      end;
   UNTIL m > 0;
   ADate := mdy2date(m,d,y);
end; {IncMonth}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FirstPay(Settle, Maty : DATEINT) : DATEINT;
{date of first cashflow}

VAR
    TestDate : DATEINT;

begin
   TestDate := mdy2date(month(Maty),day(Maty),year(settle));
   If TestDate > Settle then
   begin
     repeat IncMonth(TestDate,-6) until TestDate <= Settle;
     IncMonth(TestDate,6);
   end
   else
     If TestDate <= Settle then
        repeat IncMonth(TestDate,6) until TestDate > Settle;
   FirstPay := TestDate;
end; {FirstPay}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Procedure Accrue(VAR B : BondRec);

begin
with B do
    CASE BType OF
      TSY :
        Accrued := (Cpn/2.0) * (Setl-PrevPmt)/(NextPmt-PrevPmt);
      MBS :
        Accrued := (Cpn/360.0) * Day(Setl)-1;
       CORP :  { NOT CORRECT }
        Accrued := (Cpn/2.0) * (Setl-PrevPmt)/180;

    end; {case}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Makebond(Settle, Mature : DATEINT; Coupon : MONEY; VAR B : BondRec);

begin
  WITH B DO
  BEGIN
     Cpn := Coupon;
     Mat := Mature;
     Setl := Settle;
     Pmt := Cpn/200;
     BulletPayPx := 100;  { payment at maturity at par }
     NextPmt := FirstPay(Setl,Mat);
     PrevPmt := NextPmt;
     IncMonth(PrevPmt,-6);
     numflows  := flowcount(NextPmt,mat);
  END;
  Accrue(B);
end; {MakeBond}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function priceBond(B : BondRec; yield :myFloat) : MONEY;
{discount all cash flows to compute present value}
{includes accrued interest}
{ express yield as N.NN, not 0.0NNN }
var
     Basis,
     DiscSum  :  MONEY;
     i        :  integer;

  begin
  with B do
  begin
    Basis := (NextPmt - Setl)/(NextPmt-PrevPmt);
    yield   := ln(1 + yield/200); {intermediate result, saves time}
    DiscSum := 0;
    for i   := 1 to numFlows do
        begin
          DiscSum := DiscSum + pmt / exp(yield*(i-1));
        end;
    DiscSum := DiscSum + (BulletPayPx/100) / exp(yield*(numflows-1));
    DiscSum  := DiscSum / exp(yield*Basis);
    PriceBond := DiscSum;   {this includes accrued interest}
  end; {with}
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Duration(B : BondRec; yield : myFloat; VAR AL : myFloat): myFloat;
{discount all cash flows to compute a
 modified MacCauly Duration value}

var  DiscSum,
     Basis,
     SumFlows,
     pp, Dur, PV  :  MONEY;
     i            :  integer;

begin
  SumFlows := 0;
  AL       := 0;
  with B do
  begin
    Basis    := (NextPmt - Setl)/(NextPmt-PrevPmt);
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
    PP := (BulletPayPx/100);
    PV := PP / exp(yield*(numflows-1+basis));
    Dur := Dur + (PV * (numflows-1)); { numerator }
    DiscSum := DiscSum + PV;
    AL  := (Basis + (AL + pp * numflows)/(SumFlows+pp)) / 2;
    Duration := Dur/(DiscSum * 2 * exp(yield));
  end;
end; {Duration}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function YieldBond(Bond: BondRec; Px : MONEY) : myFloat;
  {iteration routine to find yield - quite slow}

const maxiter   = 25;
      tolerance = 0.0003;

var   low,high,incr,
      upper,lower,
      Ayield,
      GrossPx,
      pricecalc  :  MONEY;
      n          :  integer;
      done       :  boolean;

begin
  n         := 0;
  GrossPX   := (Px + Bond.Accrued)/100;
  high      := Bond.Cpn/GrossPx +1;
  low       := 1.00;
  incr      := (high - low)/2;
  upper     := GrossPx + tolerance;
  lower     := GrossPx - tolerance;
  done      := false;
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

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Procedure MatBond(VAR Bond : BondRec; Yld : myFloat; Px : MONEY);

const maxiter   = 40;
      tolerance = 0.0003;
      DEBUG     = FALSE;

var   low,high,incr : DATEINT;
      upper,lower,
      GrossPx,
      pricecalc  :  MONEY;
      n          :  integer;
      done       :  boolean;

begin
  n         := 0;
  GrossPX   := (Px + Bond.Accrued)/100; {*}
  high      := mdy2date(1,1,2060); { max maturity 1/1/2060 } {*}
  low       := Today; {*}
  incr      := ROUND((high - low)/2);
  upper     := GrossPx + tolerance;
  lower     := GrossPx - tolerance;
  done      := false;
    repeat   {goal seeking}
       n := n + 1;
       Bond.EstMat  := round(low + incr);
       Bond.numflows := FlowCount(Bond.NextPmt,Bond.EstMat);
       pricecalc := priceBond(Bond,Yld);

       if debug then writeln(n:3,incr:5,' ',
                             datestring(low,ShortForm),' ',
                             datestring(Bond.EstMat,1),
                             pricecalc*100-Bond.Accrued:9:3);

       if Yld < Bond.Cpn then
          if pricecalc < lower then low := low + incr
            else if pricecalc > upper then incr := incr div 2
               else done := true;
       if Yld > Bond.Cpn then
          if pricecalc > upper then low := low + incr
            else if pricecalc < lower then incr := incr div 2
               else done := true;

       if n = maxiter then done := true;
    until done;  {goal seeking}
end;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
function ReinvestCoups( Bond : BondRec;
                        SellDate : DATEINT;
                        ReinvRate : myFloat) : MONEY;
VAR
  HoldPer,
  temp : MONEY;

BEGIN
  temp := 0;
  ReinvRate := ReinvRate/200;
  WHILE SellDate >= Bond.nextpmt DO
  BEGIN
     HoldPer := (SellDate - Bond.nextpmt) / 182.625;
     temp := temp + Bond.pmt * power((1+ReinvRate),HoldPer);
     {now jump to next payment}
     IncMonth(Bond.nextpmt,6);
  END;
  ReinvestCoups := temp;
END; {ReinvestCoups}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
function TotalReturn(Bond              : BondRec;
                     BuyDate, SellDate : DATEINT;
                     BuyYld, SellYld,
                     ReinvRate         : myFloat     ): myFloat;


VAR
  Endpx,
  Invest, Redeem : MONEY;

BEGIN
   MakeBond(BuyDate,Bond.mat,Bond.Cpn,Bond);
   Invest := PriceBond(Bond,BuyYld);
   Redeem := ReinvestCoups(Bond,SellDate,ReinvRate);
   MakeBond(SellDate,Bond.mat,Bond.Cpn,Bond);
   EndPx := PriceBond(Bond,SellYld);
   Redeem := Redeem + EndPx;
   TotalReturn := Redeem/Invest - 1.0;
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
function Compound( Return : myFloat; CmpndPer : INTEGER ) : myFloat;

BEGIN
         {adjust for semiannual compounding }
         Compound := CmpndPer * ( power(Return+1,1/CmpndPer) -1 );
END; { Compound }

{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
function DeCompound( Return : MONEY;
                     CmpndPer : INTEGER;
                     StartDate, EndDate : MONEY ) : MONEY;

CONST
  YearLength = 365.25;

VAR
  PeriodsRecip : MONEY;


BEGIN
    PeriodsRecip := YearLength /( CmpndPer * (EndDate-StartDate));
    DeCompound := ( power(1+Return,PeriodsRecip) - 1 );
END; { DeCompound }

{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
function Annualize(Return : myFloat; StartDate, EndDate : DATEINT) : myFloat;
CONST
  YearLength  = 365.25;
  CompoundPer = SemiAnnl;

BEGIN
     Return := DeCompound(Return,CompoundPer, StartDate, EndDate);
     Annualize := Return * CompoundPer;
END; { Annualize }

{+++++++++++++++++++++++++++++++++++++++++++++++++++++}
BEGIN
END.

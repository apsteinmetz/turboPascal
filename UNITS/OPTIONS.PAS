UNIT Options;
{ Black/Scholes or Cox/Ross European Option Pricing }

(*  {$DEFINE DEBUG } *)

interface

{not$I FLOAT.INC}

USES MathLib0;  {Float, Power, Normal, Binomial}

TYPE
  OptValRec = RECORD
      CallPX, PutPX,
      CallDelta, PutDelta : myFloat;
  END;


PROCEDURE BlackScholes( SecPx,  { Price of bond or future }
                       Strike, { Strike Price }
                       Yield,  { Yield if coupon bearing }
                       Term,   { time to expiration in years }
                       RFRate, { risk free rate}
                       Vol     { annualized volatility } : myFloat;
                       VAR Results  : OptValRec );

PROCEDURE CoxRoss    ( SecPx,  { Price of bond or future }
                       Strike, { Strike Price }
                       Yield,  { Yield if coupon bearing }
                       Term,   { time to expiration in years }
                       RFRate, { risk free rate }
                       Vol     : myFloat;
                       VAR Results  : OptValRec );

PROCEDURE CoxRoss2    ( SecPx,  { Price of bond or future }
                       Strike, { Strike Price }
                       Yield,  { Yield if coupon bearing }
                       Term,   { time to expiration in years }
                       RFRate, { risk free rate }
                       Vol     : myFloat;
                       VAR Results  : OptValRec );

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

PROCEDURE BlackScholes( SecPx,  { Price of bond or future }
                       Strike, { Strike Price }
                       Yield,  { Yield if coupon bearing }
                       Term,   { time to expiration in years }
                       RFRate, { risk free rate }
                       Vol     : myFloat;
                       VAR Results  : OptValRec );

VAR
  eYT, eRT, vrt, D1, ND1, ND2 : myFloat;

BEGIN
 IF NOT (Yield > 0.0) THEN  { Security is a futures contract }
    Yield := RFRate;
eYT := exp(-Term*Yield);
{ discount rate }
eRT := exp(-Term*RFRate);

{ adjust for positive or negative carry }
SecPx := SecPX *  eYT/erT  { exp((RFRate - Yield) * Term) }  ;

vrt := Vol * Sqrt(Term);
D1 := ln(SecPx/Strike) / Vrt + 0.5 * Vrt;
ND1 := Normal(D1);
ND2 := Normal(D1 - Vrt);

WITH Results DO
   BEGIN
      CallPx := eRT * (SecPx * ND1 - Strike * ND2);
      PutPX  := CallPx - eRT * (SecPx - Strike);

      CallDelta := eYT * ND1;
      PutDelta  := 1-CallDelta;
   END; {with}

END; { BlackScholes }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE CoxRoss    ( SecPx,  { Price of bond or future }
                       Strike, { Strike Price }
                       Yield,  { Yield if coupon bearing }
                       Term,   { time to expiration in years }
                       RFRate, { risk free rate }
                       Vol     : myFloat;
                       VAR Results  : OptValRec );
CONST
  Steps = 25;   { arbitrary iteration count }

  { Steps! adjusted for myFloating point hardware }
  {$IFOPT N+}
     FactN = 1.551121004333098e25;
  {$ELSE}
     FactN = 1.5511210043e25;
  {$ENDIF}

VAR
  j,
  MinSteps  : INTEGER;   { minium steps needed to be in the money }
  ExpectedVal, Prob,
  eYT, eRT, up,dn, p,
  Call  : myFloat;

BEGIN
  IF NOT (Yield > 0.0) THEN  { Security is a futures contract }
     Yield := RFRate;
  eYT := exp(-Term*Yield);
  { discount rate}
  eRT := exp(-Term*RFRate);

  { adjust for positive or negative carry }
  SecPx := SecPX * eYT/eRT;

  { convert annual volatility to volatility per step }
  Vol := Vol / sqrt(Steps/Term);

  MinSteps := trunc( ln(Strike/SecPx) / Vol);
  IF MinSteps < 0 THEN MinSteps := 0;

  { expected up and down moves }
  up := exp(Vol);
  dn := 1/up;
  p := (1-dn)/(up-dn);  { prob. of an up move }

  Call := 0.0; { initialize }
  Prob := 0.0;

  FOR j := MinSteps to Steps DO BEGIN
     { expected value of an outcome }
     ExpectedVal := (SecPx * power(up,j) * power(dn,Steps-j) - Strike) * eRT;
     { Ignore negative expected values.}
     IF ExpectedVal < 0.0 THEN
        ExpectedVal := 0.0
     ELSE BEGIN
        { probability of an outcome }
        Prob :=  FastBinomial(Steps,j, p, FactN);
     END;
     { Sumation}
     Call := Call + (Prob * ExpectedVal);
  END;

WITH Results DO
   BEGIN
      CallPx := Call;
      PutPX  := CallPx - (SecPx - Strike) * eRT;

      CallDelta := 0;  { don't know how to compute this from CRR model }
      PutDelta  := 0;
   END; {with}

END; { CoxRoss }

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE CoxRoss2 ( SecPx,  { Price of bond or future }
                     Strike, { Strike Price }
                     Yield,  { Yield if coupon bearing }
                     Term,   { time to expiration in years }
                     RFRate, { risk free rate }
                     Vol     : myFloat;
                     VAR Results  : OptValRec);

PROCEDURE AltCoxRoss(CALL : BOOLEAN);
{ A more or less straight port of the (sloppy) Meisner code }

CONST
  Steps       = 30;
  StepsPlus1  = 31;
  Outcomes    = 61; {steps * 2 +1}

VAR
  OptVals  : ARRAY[1..StepsPlus1] OF myFloat;
  EndPrice  : ARRAY[1..Outcomes] OF myFloat;
  IntrVals  : ARRAY[1..Outcomes] OF myFloat;

  Future    : BOOLEAN;

  p, pComp  : myFloat;   { prob. of an up move and it's complement }
  TN, IntrVal,
  R_D, Up_Dn,
  UP, DN,
  Delta, Premium,
  move  : myFloat;
  j, k, i : WORD;

BEGIN
  Future := (abs(Yield) < 0.0001);  { is a future if yield = 0 }

  { adjust inputs for time and precompute some constants   }
  { we are using binomial stepwise compounding rather than }
  { continuous as with the Black/Shcholes                  }
  TN :=  Term / Steps;
  RFRate := 1 + (RFRate *  TN);
  Yield := Yield * TN * 100; { turn back into a coupon or dividend }
  UP := 1 + (Vol * sqrt(TN));
  DN := 1/UP;

  R_D := RFRate - DN; { numerator of "expected" growth of any investment }
  Up_Dn := UP - DN;   { denominator of "expected" growth of any investment }

  { make arrays of ending values and intrinsic values }
  EndPrice[StepsPlus1] := SecPx;
  IntrVals[StepsPlus1] := SecPx-Strike;
  move := 1;
  FOR i := 1 to Steps DO BEGIN
      move := move * up;       { equiv to (1+up) raised to the i }
      j := StepsPlus1 + i;
      k := StepsPlus1 - i;
      EndPrice[j] := SecPx * move;
      IntrVals[j] := EndPrice[j] - Strike;
      EndPrice[k] := SecPx / move;
      IntrVals[k] := EndPrice[k] - Strike;
  END; {FOR}

  { assign intrinsic values as initial option values }
  FOR i := 1 to StepsPlus1 DO BEGIN
     IntrVal := IntrVals[2*i-1];    { index is always odd }
     OptVals[i] := 0;
     IF Call AND (IntrVal > 0) THEN
         OptVals[i] :=  IntrVal
     ELSE
        IF NOT CALL AND (IntrVal < 0) THEN
           OptVals[i] := -IntrVal;
  END;

  { Prob. of an UP move }
  { some precomputation is possible in Futures case }
  IF Future THEN BEGIN
    p     := (1-dn)/Up_Dn;  { will be close to 0.5 }
    pComp := 1 - p;
  END;

  { Works backward down the binomial tree }
  FOR i := Steps DOWNTO 1 DO BEGIN
     IF i = 1 THEN Delta := (OptVals[2] - OptVals[1]) / (SecPx * Up_Dn);
     FOR j := 1 to i DO BEGIN
         k := Steps - i + 2*j;
         IntrVal := IntrVals[k];

         { Prob. of an UP move }
         IF NOT Future THEN BEGIN
            { adjust carry to reflect price at this node }
            { this is a current yield calculation, YTM would be better }
            { actually:  (1+r-y) * dn/(up-dn)  adjusts the prob of     }
            { an up move by the carry, positive or negative           }
            p     := ( r_d - ( Yield / EndPrice[k] ) ) / Up_Dn;
            pComp := 1-p;
         END;

         { expected option value discounted one period }
         OptVals[j] := ( p*OptVals[j+1] +
                              pComp * OptVals[j] ) / RFRate;

         { test for early exercise}
         IF Call AND (OptVals[j] <  IntrVal) THEN
              OptVals[j] :=  IntrVal
         ELSE
            IF NOT CALL AND (OptVals[j] < -IntrVal) THEN
               OptVals[j] := -IntrVal;
     END;
  END;
  IF CALL THEN BEGIN
    Results.CallPx := OptVals[1];
    Results.CallDelta := Delta;  END
  ELSE BEGIN
    Results.PutPx := OptVals[1];
    Results.PutDelta := -Delta;
  END;
END;  { Alt CoxRoss }


BEGIN  {CoxRoss2}
  AltCoxRoss(TRUE);  {call}
  AltCoxRoss(FALSE); {put}
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
BEGIN
END.
PROGRAM CurvModl;

{$I FLOAT.INC}

 {$DEFINE DEBUG}

uses MathLib0;

CONST
   r_default = 0.10;
   v_default = 0.20;

   Periods = 20;     { periods }

VAR
   r,    { one period rate }
   v,   { volatility in percent per period }

  F,
  SpotRate,
  PsubN       : Float;
  n           : WORD;



{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE GetParams;
VAR
   err : INTEGER;

BEGIN
   val(paramstr(1),v,err);
   IF err > 0 THEN v := v_default;
   val(paramstr(2),r,err);
   IF err > 0 THEN r := r_default;
END;



{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION ExpectedPrice ( Steps  : WORD;  { periods }
                         rate,  { one period rate }
                         Vol     : Float ) : Float;
CONST
  p = 0.5;       {probability of an "up" day.  Hey, it's a random walk. }

VAR
  j            : WORD;
  FutureYield,
  Prob,
  Price,
  u,d,
  Sum, SumY          : Float;

BEGIN



{ expected up and down moves }
(*
{ Additive process (Coin Toss) }
  u :=    Rate * Vol;
  d := - (Rate * Vol);
*)

{ My multiplicative process }
  u := 1 + Vol;
  d := 1 - Vol;


(*
{ Goldman's Multiplicative process }
  u := 1 + Vol;
  d := 1 / (1 + Vol);
*)

(*
{ First Boston Multiplicative process }
  u := exp(Vol);
  d := exp(-Vol);
*)

  Sum := 0.0; { initialize }
  SumY := 0.0;

  FOR j := 0 to Steps DO
  BEGIN

    { possible outcome value }

    { multiplicative }
     FutureYield := (rate * power(u,j) * power(d,Steps-j));
(*)
     { additive }
     FutureYield := rate + j*u + (Steps-j)*d;
*)

    { probability of an outcome }
     Prob :=  Binomial(Steps,j, p);

{$IFDEF DEBUG }
     IF j = Steps-j THEN BEGIN
         Write('   MidPoint ',FutureYield:6:4);
         Write('   prob ',Prob*100:8:6,'%');
         Writeln;
     END;
{$ENDIF}

     Price := Prob * 1/(1+FutureYield);
{     Price := Prob * FutureYield; }

     { Sumation}
     Sum := Sum + Price;
     SumY := SumY + FutureYield * Prob;;

  END;

  ExpectedPrice := Sum;
{  Write(SumY*100:5:2); }
{  ExpectedPrice := 1/(1+Sum); }

END; { FuturePrice }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

BEGIN
   GetParams;
   F := 1 ; { intialize factorial };
   writeln('Initial Rate:',R_default*100:6:2,'%');
   writeln('Volatility:',v_default*100:6:2,'%');
   writeln(
   'Period','Exp. 1 Pd. Price, Rate':25,'Disc. Factor':15,'Disc. Rate':15);
   FOR n := 1 TO Periods DO BEGIN
      PsubN := ExpectedPrice(n-1,r,v);
      F := F * PSubN;
      SpotRate := power(1/F,1/n)-1;
      Write(n:2);
      Write(PsubN:15:4);
      Write((1/PSubN-1)*100:8:2);
      Write(F:20:4);
      Write(SpotRate * 100:15:2);
      Writeln;
   END;



END.
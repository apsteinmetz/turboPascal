UNIT StatLib0;
{$N+,E+}
interface

uses MathLib0;

CONST
   {Used with CreateNormTable}
   NumBands = 100;  {this determines how close an estimator this table is}

TYPE
  DevRec = RECORD
              Deviation,    {std. deviations from mean}
              Difference   { difference from previous deviation } : FLOAT;
           END;


VAR
   NormTable : ARRAY[0..NumBands] OF DevRec;
   { NormTable is an array containing fractions of positive Std. Deviations }
   { from a mean which are evenly spaced in terms of probability in a       }
   { normal distribution                                                    }

{ -------------------------------------------------------------}
function Binomial(n,j : WORD ; p : Float) : Float;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }

{ -------------------------------------------------------------}
function FastBinomial(n,j : WORD ; p, FactN : Float) : Float;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }
{ Assumes factorial of N has already been computed as FactN }

{ -------------------------------------------------------------}
function Normal(Z : Float) : Float;
         { Compute cumulative normal distribution.
           Use a polynomial approximation.}

{------------------------------------------------------------}
procedure CreateNormalTable;
{
To pull out a Std. Dev. from a normal distribution:
  1. Create this table.
  2. Select a random integer, n | 0 < n <= NumBands.
  3. Select a random real, d |  NormTable[n-1] <= d <= NormTable[n].
  4. Select a random integer, s | s=-1, s= 1.
  5. s*d is a deviation from the mean which is randomly distributed.
}

function GetNormalValue : FLOAT;
{ retrieves a value expressed in standard deviations from the mean }
{ from a normal distribution }


implementation
{F+}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Binomial(n,j : WORD ; p : Float) : Float;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }

VAR
  a,b,c,d : Float;

BEGIN
  IF j > n THEN
    Binomial := 0
  ELSE
  BEGIN
    a := Factorial(n);
    b := Factorial(j) * Factorial(n-j);
    c := power(p,j);
    d := power(1-p,n-j);
    Binomial := a / b  * c * d;
  END;
END; { Binomial }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FastBinomial(n,j : WORD ; p, FactN : Float) : Float;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }
{ Assumes factorial of N has already been computed as FactN }

VAR
  b,c,d : Float;

BEGIN
  IF j > n THEN
    FastBinomial := 0
  ELSE
  BEGIN
    b := Factorial(j) * Factorial(n-j);
    c := power(p,j);
    d := power(1-p,n-j);
    FastBinomial := FactN / b  * c * d;
  END;
END; { Binomial }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Normal(Z : Float) : Float;
{Compute cumulative normal distribution.
  Use a polynomial approximation.}

const    CA  =    1.3302740;
         CB  =   -1.8212560;
         CC  =    1.7814780;
         CD  =   -0.3565638;
         CE  =    0.3193815;
         CY  =    0.2316419;
         CZ  =    0.3989423;

var   N, NN, Y1, Z1  : Float;

begin
     Y1     := 1/(1+CY*abs(Z));
     Z1     := CZ * exp(-0.5*sqr(Z));
     { Following two lines could be one formula but floating point }
     { hardware stack can't handle it.}
     N     := (((CA * Y1+CB) * Y1 + CC) * Y1 + CD);
     NN :=  (N * Y1 + CE) * Y1 * Z1;

     if Z > 0 then
        Normal := 1-NN
     else
        Normal := NN
end;  {Normal}
{------------------------------------------------------------}
procedure CreateNormalTable;

CONST
   tolerance = 0.000005;

VAR
   n : Cardinal;
   LowDev,
   HiDev,
   LowProb,
   HiProb  : FLOAT;
   ProbIncr: FLOAT;  {find std devs. every ProbIncr pct. probability}

BEGIN
     LowDev  := 0.0; { 0.0 deviation from mean of distribution }
     HiDev := 0.01; {starting guess}
     LowProb := Normal(LowDev);
     ProbIncr := 0.5 / NumBands; { we're using 50% of the distribution}
     NormTable[0].Deviation := LowDev;
     NormTable[0].Difference := 0;
     for n := 1 to NumBands do
     BEGIN
         HiProb := LowProb + ProbIncr;
         SeekGoal( HiProb,tolerance,HiDev,Normal {function} );
         NormTable[n].Deviation  := HiDev;
         NormTable[n].Difference := HiDev-LowDev;
         LowProb := HiProb;
         LowDev  := HiDev;
     END;
END;

{------------------------------------------------------------}
function GetNormalValue : FLOAT;
{ retrieves a value expressed in standard deviations from the mean }
{ from a normal distribution }
VAR
  n : Cardinal;
  StdDev : FLOAT;

BEGIN
   n := random(100) + 1; {pick segment of distribution 1..100}
   { choose a random deviation within the segemnt.  These are }
   { equally distributed }
   StdDev  :=  NormTable[n].Deviation - NormTable[n].Difference * random;
   { deviations above or below the mean are equally likely }
   IF random(2) = 0 THEN
      StdDev := -StdDev;
   GetNormalValue := StdDev;
END;

{------------------------------------------------------------}
BEGIN {MAIN}
      Randomize;
      CreateNormalTable;
END.

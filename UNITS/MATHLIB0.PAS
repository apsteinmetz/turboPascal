unit MathLib0;
(* copyright 1991 by Art Steinmetz *)
{ a collection of math routines }

interface

TYPE
   myFloat = Double;
   Cardinal = WORD;
   GoalFunc = function(Var1 : myfloat) : myfloat;

VAR
  { Constants defined at run time }
  HalfPI,
  TwoPI ,
  Radian ,
  RadianDiv100,
  ln10,
  sqrt2  : myFloat;

FUNCTION max(a,b : INTEGER) : INTEGER;

FUNCTION min(a,b : INTEGER) : INTEGER;

{ TRIG FUNCTIONS }
{ -------------------------------------------------------------}
FUNCTION ArcCos(X: myFloat): myFloat;

{ -------------------------------------------------------------}
FUNCTION ArcSin(X: myFloat): myFloat;

{ -------------------------------------------------------------}
FUNCTION ArcTanH(X : Real):  Real;

{ -------------------------------------------------------------}

function HexConv(num : LONGINT) : string;

{ -------------------------------------------------------------}
function Power(base,pwr : myFloat) : myFloat;
       { raise BASE to the RAISE power.
         No negative numbers or error checking }

{ -------------------------------------------------------------}
function Factorial(X : WORD) : myFloat;

{ -------------------------------------------------------------}
function Binomial(n,j : WORD ; p : myFloat) : myFloat;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }

{ -------------------------------------------------------------}
function FastBinomial(n,j : WORD ; p, FactN : myFloat) : myFloat;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }
{ Assumes factorial of N has already been computed as FactN }

{ -------------------------------------------------------------}
function Normal(Z : myFloat) : myFloat;
         { Compute cumulative normal distribution.
           Use a polynomial approximation.}

{ -------------------------------------------------------------}
PROCEDURE SeekGoal( Goal, Tolerance : myFloat;
                   VAR Variable : myFloat;
                   TestProc : GoalFunc);

implementation

{F+}
{ ---------------------------------------------------------------}
FUNCTION max(a,b : INTEGER) : INTEGER;
BEGIN
  IF a > b THEN
      max := a
  ELSE
      max := b;
END; {max}

{ ---------------------------------------------------------------}
FUNCTION min(a,b : INTEGER) : INTEGER;
BEGIN
  IF a < b THEN
      min := a
  ELSE
      min := b;
END; {max}

{ -------------------------------------------------------------}
FUNCTION ArcCos(X: myFloat): myFloat;
BEGIN
    IF  ABS(X) < 1  THEN ArcCos:= ARCTAN(SQRT(1-SQR(X))/X)
    ELSE  IF X = 1  THEN ArcCos:=  0
    ELSE  IF X =-1  THEN ArcCos:= PI;
END;   { ArcCos. }

{ -------------------------------------------------------------}
FUNCTION ArcSin(X: myFloat): myFloat;
BEGIN
    IF ABS(X) < 1  THEN ArcSin:= ARCTAN(X/SQRT(1-SQR(X)))
    ELSE IF X = 1  THEN ArcSin:= HalfPI
    ELSE IF X =-1  THEN ArcSin:=-HalfPI;
END;    { ArcSin. }

{ -------------------------------------------------------------}
FUNCTION ArcTanH(X : Real):  Real;
CONST
  fudge = 0.999999;  { ArcTanH(1.0) is undefined }

VAR A,T :  myFloat;
BEGIN
    T:=ABS(X);
    IF NOT (T < 1) THEN
      T := fudge; { should never happen }
    A := 0.5 * LN((1 + T)/(1 - T));
    IF X < 0 THEN ArcTanH := -A ELSE ArcTanH :=A;
END;  { ArcTanH. }

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
    function pwrint(num,pwr : LONGINT) : LONGINT;
    var
      i, temp : LONGINT;

    begin
      temp := 1;
      if pwr > 0 then
      for i := 1 to pwr do temp := temp * num
      else temp := 1;
      pwrint := temp;
    end;

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
function HexConv(num : LONGINT) : string;
const
  base = 16;
  Hex  : string[16] = '0123456789ABCEDF';

var
  temp : string;
  n,
  check,
  digit : LONGINT;


begin {HexConv}
  n := 0;
  temp := '';
{  if num > 4095 then writeln('ERROR! in hex conversion')
  else
}  repeat
    n := n + 1;
    check := pwrint(base,n);
    digit := trunc(num/pwrint(base,n-1)) mod base;
    temp := Hex[digit+1] + temp;
  until check > num;
  if length(temp) < 2 then temp := '0'+temp;
  HexConv := temp;
end; {HexConv}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Power(base,pwr : myFloat) : myFloat;

begin
   Power  := exp(ln(base) * pwr)
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Function Factorial(X : WORD) : myFloat;
{ although not a REAL result we need to allow a large range }
{ should use recursion }

VAR
  i : WORD;
  temp : myFloat;

BEGIN
   temp := X;
   i := X;
   WHILE i > 1 DO
   BEGIN
      i := i-1;
      temp := temp * i;
   END;
   If temp = 0 then temp := 1;
   Factorial := temp;
END; {Factorial}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Binomial(n,j : WORD ; p : myFloat) : myFloat;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }

VAR
  a,b,c,d : myFloat;

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
function FastBinomial(n,j : WORD ; p, FactN : myFloat) : myFloat;
{ probability of "j" outcomes in "n" trials.  Any "j" has liklihood "p" }
{ Assumes factorial of N has already been computed as FactN }

VAR
  b,c,d : myFloat;

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
function Normal(Z : myFloat) : myFloat;
{Compute cumulative normal distribution.
  Use a polynomial approximation.}

const    CA  =    1.3302740;
         CB  =   -1.8212560;
         CC  =    1.7814780;
         CD  =   -0.3565638;
         CE  =    0.3193815;
         CY  =    0.2316419;
         CZ  =    0.3989423;

var   N, NN, Y1, Z1  : myFloat;

begin
     Y1     := 1/(1+CY*abs(Z));
     Z1     := CZ * exp(-0.5*sqr(Z));
     { Following two lines could be one formula but myFloating point }
     { hardware stack can't handle it.}
     N     := (((CA * Y1+CB) * Y1 + CC) * Y1 + CD);
     NN :=  (N * Y1 + CE) * Y1 * Z1;

     if Z > 0 then
        Normal := 1-NN
     else
        Normal := NN
end;  {Normal}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure SeekGoal( Goal, Tolerance : myFloat;
                   VAR Variable : myFloat;
                   TestProc : GoalFunc);

{iteration routine to find a value}

const maxiter   = 25;

var   low,high,incr,
      upper,lower,
      n          :  myFloat;
      done       :  boolean;

begin
  n         := 0;
  high      := Variable;
  low       := 0.00;
  incr      := (high - low)/2;
  upper     := Goal + tolerance;
  lower     := Goal - tolerance;
  done      := false;
    repeat   {goal seeking}
       n        := n + 1;
       Variable := low + incr;
       Goal := TestProc(Variable);
       if Goal > upper then incr := incr/2
         else if Goal < lower then low := low + incr
             else done := true;
       if n = maxiter then done := true;
    until done;  {goal seeking}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

BEGIN
  ln10 := ln(10);
  sqrt2 := sqrt(2);
  HalfPI       := Pi / 2.0;
  TwoPI        := Pi * 2.0;
  Radian       := Pi / 180.0;
  RadianDiv100 := Pi / 18000.0; { PI/180/100  }

END.
{interface
implementation}
end. { MathLib0 }

UNIT ComplexN;
{ some complex number manipulations }

{$I Float.inc}

interface

uses MathLib0;

TYPE
  Complex = RECORD
       Re, Im : REAL;
  END;

VAR
  NearlyZero : FLOAT;
  { default based on presence/absence of math chip }

implementation

procedure Conjugate(C1 : Complex; var C2 : Complex);
begin
  C2.Re := C1.Re;
  C2.Im := -C1.Im;
end; { procedure Conjugate }

function Modulus(var C1 : Complex) : Float;
begin
  Modulus := Sqrt(Sqr(C1.Re) + Sqr(C1.Im));
end; { function Modulus }

procedure Add(C1, C2 : Complex; var C3 : Complex);
begin
  C3.Re := C1.Re + C2.Re;
  C3.Im := C1.Im + C2.Im;
end; { procedure Add }

procedure Sub(C1, C2 : Complex; var C3 : Complex);
begin
  C3.Re := C1.Re - C2.Re;
  C3.Im := C1.Im - C2.Im;
end; { procedure Sub }

procedure Mult(C1, C2 : Complex; var C3 : Complex);
begin
  C3.Re := C1.Re * C2.Re - C1.Im * C2.Im;
  C3.Im := C1.Im * C2.Re + C1.Re * C2.Im;
end; { procedure Mult }

procedure Divide(C1, C2 : Complex; var C3 : Complex);
var
  Dum1, Dum2 : Complex;
  E : Float;
begin
  Conjugate(C2, Dum1);
  Mult(C1, Dum1, Dum2);
  E := Sqr(Modulus(C2));
  C3.Re := Dum2.Re / E;
  C3.Im := Dum2.Im / E;
end; { procedure Divide }

procedure SquareRoot(C1 : Complex; var C2 : Complex);
var
  R, Theta : Float;
begin
  R := Sqrt(Sqr(C1.Re) + Sqr(C1.Im));
  if ABS(C1.Re) < NearlyZero then
    begin
      if C1.Im < 0 then
        Theta := Pi / 2
      else
        Theta := -Pi / 2;
    end
  else
    if C1.Re < 0 then
      Theta := ArcTan(C1.Im / C1.Re) + Pi
    else
      Theta := ArcTan(C1.Im / C1.Re);
  C2.Re := Sqrt(R) * Cos(Theta / 2);
  C2.Im := Sqrt(R) * Sin(Theta / 2);
end; { procedure SquareRoot }

BEGIN
{$IFOPT N+}
  NearlyZero := 1E-015;
{$ELSE}
  NearlyZero := 1E-07;
{$ENDIF}
END.
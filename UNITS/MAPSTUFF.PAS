UNIT MapStuff;
{ needed by cartog2.pas }
{$N+,E+}

interface
USES
   CRT,
   MathLib0,
   Graph;


CONST
   NotVisible : INTEGER = -32767;     { Flag for point visibility   }

TYPE
   Float = SINGLE;

   RenderTypes = (DoGrid, DoMap);
   RenderSet   = SET OF RenderTypes;
   MapTypes    = (NoMap, Merc, Equi, Sino, Hamr, Orth);

   MapRec = RECORD
         Choice        : RenderSet;
         MapType       : MapTypes;
         Phi1, Lambda0 : FLOAT;
   END;

PROCEDURE ProJect( Map : MapRec;
                   Long, Lat, Radius: FLOAT;
                   VAR X, Y : FLOAT);

{ Return screen coordinates according to map coordinates   }
{ and projection type }

(* ============================================================== *)
implementation

{ -------------------------------------------------------------}
FUNCTION ArcCos(X: FLOAT): FLOAT;
BEGIN
    IF  ABS(X) < 1  THEN ArcCos:= ARCTAN(SQRT(1-SQR(X))/X)
    ELSE  IF X = 1  THEN ArcCos:=  0
    ELSE  IF X =-1  THEN ArcCos:= PI;
END;   { ArcCos. }

{ -------------------------------------------------------------}
FUNCTION ArcSin(X: FLOAT): FLOAT;
BEGIN
    IF ABS(X) < 1  THEN ArcSin:= ARCTAN(X/SQRT(1-SQR(X)))
    ELSE IF X = 1  THEN ArcSin:= HalfPI
    ELSE IF X =-1  THEN ArcSin:=-HalfPI;
END;    { ArcSin. }

{ -------------------------------------------------------------}
FUNCTION ArcTanH(X : Real):  Real;
CONST
  fudge = 0.999999;  { ArcTanH(1.0) is undefined }

VAR A,T :  FLOAT;
BEGIN
    T:=ABS(X);
    IF NOT (T < 1) THEN
      T := fudge; { should never happen }
    A := 0.5 * LN((1 + T)/(1 - T));
    IF X < 0 THEN ArcTanH := -A ELSE ArcTanH :=A;
END;  { ArcTanH. }

{ -------------------------------------------------------------}
FUNCTION Meridian(Lambda, Lambda0: FLOAT):FLOAT;
{ Returns difference between current longitude and map center. }
VAR DelLam : FLOAT;
BEGIN
    DelLam := Lambda - Lambda0;
    IF DelLam < -PI THEN DelLam := DelLam + TwoPI
    ELSE
    IF DelLam >  PI THEN DelLam := DelLam - TwoPI;
    Meridian:=DelLam;
END;   { Meridian. }

{ -------------------------------------------------------------}
PROCEDURE Mercator(Lambda, Lambda0, Phi, R : FLOAT; VAR X, Y : FLOAT);
{ For R = 1: -Pi <= X <= Pi, -Pi/2 <= Y <= Pi/2.  }

CONST
    MaxLat : FLOAT =  1.483;   { in radians }
                        { 1.397;}   {~80 degrees. }
                        { 1.483;    ~85 degrees. }
                        { 1.571;    ~90 degrees. }
BEGIN
    (* arbitrarily constrain the max. latitude displayed since *)
    (* higest latitudes go exponential with this projection *)
    IF Phi > MaxLat THEN
       Phi := MaxLat
    ELSE IF Phi < -MaxLat THEN
            Phi := -MaxLat;

    Lambda := Meridian(Lambda, Lambda0);
    X := R * Lambda;
    Y := R * ArcTanH(SIN(Phi));

END;   { Mercator. }

{ -------------------------------------------------------------}
PROCEDURE EquiCyl(Lambda, Lambda0, Phi, Phi1, R : FLOAT; VAR X, Y : FLOAT);
{ For R = 1: -Pi <= X <= Pi, -Pi/2 <= Y <= Pi/2. }
VAR
  offset : FLOAT;

BEGIN
    Lambda := Meridian(Lambda, Lambda0);
    X := R * Lambda;
    Y := R * Phi;

END;   { EquiCyl. }

{ -------------------------------------------------------------}
PROCEDURE Sinusoidal(Lambda, Lambda0, Phi, R : FLOAT; VAR X, Y : FLOAT);
{ For R = 1:  -Pi <= X <= Pi  and  -Pi/2 <= Y <= Pi/2. }
BEGIN
     Lambda := Meridian(Lambda, Lambda0);
     X := R * Cos(Phi) * Lambda ;
     Y := R * Phi;
END;  { Sinusoidal. }

{ -------------------------------------------------------------}
PROCEDURE Hammer(Lambda, Lambda0, Phi, R : FLOAT; VAR X, Y : FLOAT);
{ For R = 1: -2û2 <= X <=2û2  and  - û2 <= Y <= û2. }
VAR K, CosPhi, HalfLambda        : FLOAT;
BEGIN
    HalfLambda := 0.5*Meridian(Lambda, Lambda0);
    CosPhi:=COS(Phi);
    K := R * SQRT2 / SQRT(1 +CosPhi * COS(HalfLambda));
    X := 2 * K * CosPhi * (SIN(HalfLambda));
    Y := K * SIN(Phi);
END;  { Hammer. }

{ -------------------------------------------------------------}
PROCEDURE Orthographic(Lambda, Lambda0, Phi, Phi1, R: FLOAT; VAR X, Y : FLOAT);
{ For R = 1: -2 <= X,Y <= 2. }
VAR CosC, CosL, SinPhi1, CosPhi1, SinPhi, CosPhi, R2 :  Real;
BEGIN
    Lambda :=Meridian(Lambda, Lambda0);  R2:=R+R;
    CosPhi1:=COS(Phi1);   SinPhi1:=SIN(Phi1);
    CosPhi :=COS(Phi);    SinPhi:= SIN(Phi);
    CosL   :=COS(Lambda)*CosPhi;
    CosC   :=SinPhi1 * SinPhi + CosPhi1 * COSL;
    IF CosC >= 0 THEN
    BEGIN
       X :=R2 * CosPhi * SIN(Lambda);
       Y :=R2 * (CosPhi1 * SinPhi - SinPhi1 * COSL);
    END ELSE X:= NotVisible;
END;  { Orthographic. }

(* ----------------------------------------------------- *)
PROCEDURE ProJect( Map : MapRec;
                   Long, Lat, Radius: FLOAT;
                   VAR X, Y : FLOAT);

BEGIN
  WITH Map DO
  BEGIN
    CASE MapType OF
        Merc: MERCATOR(     Long, Lambda0, Lat,       Radius, X, Y);
        Equi: EQUICYL(      Long, Lambda0, Lat, Phi1, Radius, X, Y);
        Sino: SINUSOIDAL(   Long, Lambda0, Lat,       Radius, X, Y);
        Hamr: HAMMER(       Long, Lambda0, Lat,       Radius, X, Y);
        Orth: ORTHOGRAPHIC( Long, Lambda0, Lat, Phi1, Radius, X, Y);
    ELSE
    BEGIN
        X := 0; Y := 0;
    END;
    END;  { CASE...}
  END {WITH};
END {ProJect};

(* ----------------------------------------------------- *)

END {MapStuff}.


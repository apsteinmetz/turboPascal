program LIST0105;
uses Graph, GrafLib0, CRT;

VAR
  radius : REAL;
  NumPoints,
  GMode      : INTEGER;
  center : Vector2;

(* ------------------------------------------------------------------- *)
PROCEDURE Circle(r :REAL);
{ Listing 1.5 }
CONST
  segments = 100;

VAR
  theta,thinc   : REAL;
  i             : INTEGER;
  pt            : Vector2;

BEGIN
   theta := 0;
   thinc := 2*pi / segments {  thinc := 360/ segments } ;
   { Move to first point }
   pt.x := r;
   pt.y := 0.0;
   moveto(pt);
   { draw edges of segment-gon }
   FOR i := 1 TO segments DO
   BEGIN
      theta := theta + thinc;
      pt.x := r*cos(theta);
      pt.y := r*sin(theta);
      lineto(pt);
   END;
END {Circle};

(* ------------------------------------------------------------------- *)
PROCEDURE Spiral(center : Vector2; radius, ang : REAL; n : INTEGER);
{ Listing 1.6 }
CONST
  segments = 100;

VAR
  theta, thinc, r  : REAL;
  i, ptnumber      : INTEGER;
  pt               : Vector2;

BEGIN
   theta := ang;
   thinc := 2*pi/segments;
   { Move to first point }
   pt.x := radius;
   pt.y := 0.0;
   moveto(center);
   ptnumber := segments*n;
   FOR i := 1 TO ptnumber DO
   BEGIN
      theta := theta + thinc;
      r := radius*i/ptnumber;
      pt.x := center.x + r*cos(theta);
      pt.y := center.y + r*sin(theta);
      lineto(pt);
   END;
END {Spiral};

(* ------------------------------------------------------------------- *)
PROCEDURE Twist(center : Vector2; radius, ang : REAL; n : INTEGER);
{ Exercise 1.7 }

VAR
 i : INTEGER;
 frac : REAL;

BEGIN
  frac := 2*pi/n;
  Circle(radius);
  Center.x := 0; Center.y := 0;
  FOR i := 0 TO n-1 DO
    Spiral(Center,radius,ang+frac*i,n);
END {Twist};
(* ------------------------------------------------------------------- *)
PROCEDURE PointToPoint(r : REAL; n : INTEGER);
{ listing 1.7 }
VAR
  pt            : ARRAY[0..100] OF Vector2;
  i,j           : INTEGER;
  theta, thinc  : REAL;

BEGIN
   theta := 0.0;
   thinc := 2*pi/n;
   FOR i := 1 TO n DO
   BEGIN
      pt[i].x := r * cos(theta);
      pt[i].y := r * sin(theta);
      theta := theta + thinc;
   END;
   FOR i := 1 TO n-1 DO
      FOR j := i+1 TO n DO
      BEGIN
         MoveTo(pt[i]);
         LineTo(pt[j]);
      END;
END {PointToPoint};

(* ------------------------------------------------------------------- *)
PROCEDURE BetterPointToPoint(r : REAL; n : INTEGER);

{ doesn't work quite right }
VAR
  pt            : ARRAY[0..99] OF Vector2;
  i,j,k         : INTEGER;
  theta, thinc  : REAL;

BEGIN
   theta := 0.0;
   thinc := 2*pi/n;
   FOR i := 0 TO n DO
   BEGIN
      pt[i].x := r * cos(theta);
      pt[i].y := r * sin(theta);
      theta := theta + thinc;
   END;
   MoveTo(pt[0]);
   FOR i := 0 TO abs(n mod 2 - 1)  DO (* do twice if n is even *)
   BEGIN
      j := i;
      MoveTo(pt[i]);
      FOR k := 0 TO n DIV 2 DO
         REPEAT
            j := (j + k) MOD n;
            LineTo(pt[j]);
            Delay(250);
         UNTIL j = i;
   END;
END {BetterPointToPoint};
(* ------------------------------------------------------------------- *)
(* ------------------------------------------------------------------- *)
BEGIN
(*
  Writeln(' Please Type in Radius');
  Readln(radius);

  Start(0);

  Circle(radius);
  readln; Erase;
  Center.x := 0; Center.y := 0;
  Spiral(Center,radius,0.0,6);
  readln; Erase;
  Twist(Center,radius,0.0,3);

  GMode := GetGraphMode;
  RestoreCRTMode;
  Writeln(' Type in Number Of Points');
  Readln(NumPoints);
  SetGraphMode(Gmode);

  PointToPoint(Radius, NumPoints);
  Finish;
END { LIST0105}.

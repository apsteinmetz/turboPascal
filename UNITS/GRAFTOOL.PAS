unit GrafTool;

interface

uses Graph;

PROCEDURE MakePolyCircle(x,y,radius,numpoints);
CONST
  maxpoints = 50;

TYPE
  Poly := ARRAY[0..49] OF PointType;

VAR
  PolyCircle := Poly;

BEGIN
 radsqrd := radius * radius;
 halfpoints := numpoints div 2;
 scale := radius / numpoints;
 startX := x - scale / 2;
 FOR point := 0 TO halfpoints DO
 BEGIN
    Xpt := StartX + scale * point;
    Ypt := sqrt((Xpt-x) * (Xpt-x) + radsqrd);
    PolyCircle[point].X := round(Xpt);
    PolyCircle[point].Y := round(y  - Ypt);
    PolyCircle[numpoints - point].X := round(Xpt);
    PolyCircle[numpoints - point].Y := round(y  - Ypt);

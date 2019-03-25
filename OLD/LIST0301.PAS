program LIST0301;
{ Rotated square }
uses GrafLib0;
CONST
  n = 20;
  t = 4;

VAR
  pt, ptd : ARRAY[1..4] OF Vector2;
  mu, um  : REAL;
  i,j, nextj : INTEGER;

FUNCTION Tan(x : REAL) : REAL;
BEGIN
  Tan := Sin(x) / Cos(x);
END {Tan};

BEGIN
  pt[1].x :=  1.0; pt[1].y :=  1.0;
  pt[2].x :=  1.0; pt[2].y := -1.0;
  pt[3].x := -1.0; pt[3].y := -1.0;
  pt[4].x := -1.0; pt[4].y :=  1.0;
  start(4.0);
  mu := Tan(t* pi/(4*n) ) / (Tan(t* pi/(4*n)) + 1);
  um := 1.0 - mu;
  FOR i := 1 TO n+1 DO
  BEGIN
     MoveTo(pt[4]);
     FOR j := 1 TO 4 DO
     BEGIN
        LineTo(pt[j]);
        NextJ := (j MOD 4) + 1;
        ptd[j].x := um*pt[j].x + mu*pt[nextj].x;
        ptd[j].y := um*pt[j].y + mu*pt[nextj].y;
     END;
     FOR j := 1 TO 4 DO
        pt[j] := ptd[j];
  END;
  finish;
END {LIST0301}.
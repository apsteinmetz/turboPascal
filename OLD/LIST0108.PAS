program LIST0108;

uses GrafLib0;

VAR
  m,n : INTEGER;
  r   : real;

PROCEDURE Rose(m,n : INTEGER; radius : REAL);
VAR
  inner, outer : ARRAY[1..100] OF Vector2;
  triangle     : Vector2Array;
  i,j          : INTEGER;
  r, theta, thinc  : REAL;

BEGIN
  thinc := 2*pi/n;
  FOR i := 1 TO n DO
  BEGIN
     inner[i].x := 0.0;
     inner[i].y := 0.0;
  END;
  FOR j := 1 TO m DO
  BEGIN
     theta := -j*pi/n;
     r     := radius * j/m;
     FOR i := 1 TO n DO
     BEGIN
        theta := theta + thinc;
        outer[i].x := r * cos(theta);
        outer[i].y := r * sin(theta);
     END;
     FOR i := 1 TO n DO
     BEGIN
       triangle[1] := outer[i];
       triangle[2] := outer[(i mod n) + 1];
       triangle[3] := inner[i];
       SetCol(1);
       PolyFill(3,triangle);
       SetCol(7);
       MoveTo(triangle[1]);
       LineTo(triangle[2]);
       LineTo(triangle[3]);
       LineTo(triangle[1]);
     END;
     FOR i := 1 TO n DO
       inner[i] := outer[i];
  END;

END {Rose};

BEGIN
  Start(0);
  Write('Points on outer circle? ');
  readln(n);
  Write('Levels in circle? ');
  readln(m);
  Write('Radius of circle? ');
  readln(r);
  Rose(m,n,r);
  Finish;
END {LIST0108}.
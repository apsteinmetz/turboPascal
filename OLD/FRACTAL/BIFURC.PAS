PROGRAM bifurc;
{$n+}
{plot bifurcation diagrams }

USES
 GraphPrm;

VAR
  ch : CHAR;
  n : integer;


PROCEDURE Main;
VAR
  r, x, deltaR : DOUBLE;
  Color,
  i, j, row, col : INTEGER;

BEGIN
  SetMode(16);
  r := 0.95;
  FOR j := 0 to 1 DO
  BEGIN
     deltaR := 0.005;
     IF j = 1 THEN
     BEGIN
       Cls(0);
       R := 3.50;
       deltaR := 0.0005;
     END;
     col := 0;
     WHILE col < DisplayWidth DO
     BEGIN
       x := 0.5;
       r := r + deltaR;
       i := 0;
       WHILE i < 256 DO
       BEGIN
         Color := 14 - i mod 2;
         x := r*x*(1-x);
         IF abs(x) > 1000000 THEN
         BEGIN
           i := 255; {Force an Exit }
           col := DisplayWidth;
         END
         ELSE
         BEGIN
           { first formula }
{          row := TRUNC(DisplayHeigth * 1-x); }
           { alternate formula }
           row := TRUNC(DisplayHeight * (1 - 2*x/r));

           IF ((i > 64) AND (row < DisplayHeight) AND (row >=0) AND
              (col >=0) AND (col < DisplayWidth)) THEN
            BEGIN
               plot(col,row,Color);
            END;
         END;
         INC(i);
       END;
       INC(col);
     END;
  END;
  writeln(r:10:5);
  readln;
  SetMode(0); {Restore Text Mode};
END {Main };

BEGIN
  Main;
END.

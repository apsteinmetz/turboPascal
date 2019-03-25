program LIST0109;
{ SPIROGRAPH }
uses
 GrafLib0;

VAR
  inner, outer, dist : INTEGER;

FUNCTION HCF(i,j :INTEGER) : INTEGER;
VAR
  remain : INTEGER;
BEGIN
  REPEAT
    remain := i MOD j;
    i := j;
    j := remain
  UNTIL remain = 0;
  HCF := i;
END {HCF};

(* ---------------------------------------------- *)
PROCEDURE Spirograph(a,b,d : INTEGER);
var
  i,n,ptnumber : INTEGER;
  phi, theta, thinc : REAL;
  pt : Vector2;

BEGIN
   theta := 0.0;
   thinc := 0.02 * pi;
   n := b DIV HCF(a,b);
   ptnumber := n*100;
   pt.x := a-b+d;
   pt.y := 0.0;
   MoveTo(pt);
   FOR i := 1 TO ptnumber DO
   BEGIN
     theta := theta+thinc;
     phi := theta*(a-b)/b;
     pt.x := (a-b)*cos(theta) + d*cos(phi);
     pt.y := (a-b)*sin(theta) - d*sin(phi);
     LineTo(pt);
   END;
END {Spirograph};

BEGIN
  Start(0);
  Write('Radius of outer Disk? ');
  readln(outer);
  Write('Radius of inner Disk? ');
  readln(inner);
  Write('Distance of pencil from center of inner Disk? ');
  readln(dist);
  Spirograph(outer,inner,dist);
  finish;
END {list0109}.
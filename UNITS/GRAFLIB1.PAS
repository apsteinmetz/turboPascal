unit GrafLib1;

interface

uses GrafLib0;

CONST
  VectorArraySize = 32;
  epsilon = 0.0000001;
  { pi = 3.1415926535 already defined in Turbo}

TYPE
  Vector2 = RECORD x,y : INTEGER END;
  Vector2Array  = ARRAY[1..VectorArraySize] OF Vector2;
  RealArray  = ARRAY[1..VectorArraySize] OF REAL;
  IntegerArray  = ARRAY[1..VectorArraySize] OF Integer;

VAR
  horiz, vert, XYScale  : REAL;

FUNCTION fx(x : REAL) : INTEGER;
{ scale units to pixels }

FUNCTION fy(y : REAL) : INTEGER;
{ scale units to pixels }


PROCEDURE MoveTo(pt : Vector2);
{change the current position pointer}

PROCEDURE LineTo(pt : Vector2);
{draw a line for the current point to pixel.  Update the current pointer }

PROCEDURE PolyFill(n : INTEGER; polygon : Vector2Array);
{fill a polygon defined by poly having n vertices }

PROCEDURE Start(horiz : REAL);
{ Set up the graphics display }

(* =========================================================== *)
implementation
CONST
  MaxColorLevel = 63 {with VGA};

VAR
 MaxCol : INTEGER;

FUNCTION fx(x : REAL) : INTEGER;
{ scale units to pixels }
BEGIN
  fx := TRUNC(x*XYScale+nxpix*0.5-0.5);
END {fx};

(*----------------------------------------------------------- *)
FUNCTION fy(y : REAL) : INTEGER;
{ scale units to pixels }
BEGIN
  fy := TRUNC(y*XYScale+nypix*0.5-0.5);
END {fy};

(*----------------------------------------------------------- *)
PROCEDURE MoveTo(pt : Vector2);
{change the current position pointer}
VAR
  pixel : pixelvector;

BEGIN
  pixel.x := fx(pt.x);
  pixel.y := fy(pt.y);
  MovePix(pixel);
END {MoveTo};

(*----------------------------------------------------------- *)
PROCEDURE LineTo(pt : Vector2);
{draw a line for the current point to pixel.  Update the current pointer }
VAR
  pixel : pixelvector;

BEGIN
  pixel.x := fx(pt.x);
  pixel.y := fy(pt.y);
  LinePix(pixel);
END {LineTo};

(*----------------------------------------------------------- *)
PROCEDURE PolyFill(n : INTEGER; polygon : Vector2Array);
{fill a polygon defined by poly having n vertices }
VAR
  i : INTEGER;
  pixelpolygon : pixelarray;

BEGIN
  { tranlate coordinate scheme }
  FOR i := 1 TO n DO
  BEGIN
     pixelpolygon[i].x := fx(polygon[i].x);
     pixelpolygon[i].y := fy(polygon[i].y);
  END;
  PolyPix(n,pixelpolygon);
END {PolyFill};

(*----------------------------------------------------------- *)
PROCEDURE Start;
{ Set up the graphics display }
VAR
  i,
  GraphDriver, GraphMode : INTEGER;

BEGIN
   PrepIt;
   IF horiz < 1 THEN horiz := nxpix;  {default}
   vert := horiz*nypix/nxpix;
   XYScale := (nxpix-1)/horiz;
END {Start};
(*----------------------------------------------------------- *)
BEGIN
  horiz := 0;
END {GraphLib0}.
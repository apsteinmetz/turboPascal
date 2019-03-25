unit GrafLib0;
(* ---------------------------------------------------------------------
     Source : HIGH RESOLUTION GRAPHICS IN PASCAL by Angell & Griffith

     Listing(s): 1.1, 1.3

     Purpose:  Graphics primitives adopted for Turbo Pascal

     Adapted by: Art Steinmetz

----------------------------------------------------------------------- *)

interface

uses GRAPH;

CONST
  (* Pixel Oriented *)
  SizeOfPixelArray = 32;

  (* Cooridate Oriented *)
  VectorArraySize = 32;
  epsilon = 0.0000001;
  { pi = 3.1415926535 already defined in Turbo}

TYPE
  (* Pixel Oriented *)
  PixelVector = RECORD x,y : INTEGER END;
  PixelArray  = ARRAY[1..SizeOfPixelArray] OF PixelVector;

  (* Cooridate Oriented *)
  Vector2       = RECORD x,y : REAL END;
  Vector2Array  = ARRAY[1..VectorArraySize] OF Vector2;
  RealArray     = ARRAY[1..VectorArraySize] OF REAL;
  IntegerArray  = ARRAY[1..VectorArraySize] OF Integer;

VAR
  (* Pixel Oriented *)
  CurrCol         : INTEGER;
  nxpix, nypix    : INTEGER;
  InData, OutData : { File of } TEXT;

  (* Cooridate Oriented *)
  horiz, vert, XYScale  : REAL;

(* Pixel Oriented Procedures *)

PROCEDURE Finish;
{CleanUp}

PROCEDURE SetCol(Col : INTEGER);
{ set color in lookup table }

PROCEDURE Erase;
{ Clear the view port }

PROCEDURE SetPix(pixel : PixelVector);
{ change the pixel to the current color }

PROCEDURE MovePix(pixel : PixelVector);
{change the current position pointer}

PROCEDURE LinePix(pixel : PixelVector);
{draw a line for the current point to pixel.  Update the current pointer }

PROCEDURE PolyPix(n : INTEGER; poly : PixelArray);
{fill a polygon defined by poly having n vertices }

PROCEDURE RGBLog(i : INTEGER; Red, Green, Blue :REAL);
{change the colors in the lookup table.  }
{Use fractional values between 0 and 1.0 }

PROCEDURE PrepIt;
{ Set up the graphics display }

(* Coordinate Oriented Procedures *)

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

PROCEDURE Finish;
{CleanUp}
BEGIN
  { PAUSE } Readln;
  CloseGraph;
END {Finish};

(* Pixel Oriented Procedures *)
(*----------------------------------------------------------- *)
PROCEDURE SetCol(Col : INTEGER);
{ set color in lookup table }
BEGIN
  SetColor(Col);
  SetFillStyle(SolidFill,Col);
  CurrCol := Col;
END;

(*----------------------------------------------------------- *)
PROCEDURE Erase;
{ Clear the view port }
BEGIN
  ClearViewPort;
END {Erase};

(*----------------------------------------------------------- *)
PROCEDURE SetPix(pixel : PixelVector);
{ change the pixel to the current color }
BEGIN
  PutPixel(pixel.X,nypix-1-pixel.Y,CurrCol);
END {SetPix};

(*----------------------------------------------------------- *)
PROCEDURE MovePix(pixel : PixelVector);
{change the current position pointer}
BEGIN
  Graph.MoveTo(pixel.X,nypix-1-pixel.Y);
END {MovePix};

(*----------------------------------------------------------- *)
PROCEDURE LinePix(pixel : PixelVector);
{draw a line for the current point to pixel.  Update the current pointer }
BEGIN
  Graph.LineTo(pixel.X,nypix-1-pixel.Y);
END {LinePix};

(*----------------------------------------------------------- *)
PROCEDURE PolyPix(n : INTEGER; poly : PixelArray);
{fill a polygon defined by poly having n vertices }
VAR
  i : INTEGER;
BEGIN
  { tranlate coordinate scheme }
  FOR i := 1 TO n DO
     poly[i].Y := nypix - 1 - poly[i].Y;

  FillPoly(n,poly);
END;
(*----------------------------------------------------------- *)
PROCEDURE RGBLog(i : INTEGER; Red, Green, Blue :REAL);
{change the colors in the lookup table.  }
{Use fractional values between 0 and 1.0 }
BEGIN
  SetRGBPalette(i, TRUNC(Red   * MaxColorLevel),
                   TRUNC(Green * MaxColorLevel),
                   TRUNC(Blue  * MaxColorLevel));
END {RGBLog};
(*----------------------------------------------------------- *)
PROCEDURE PrepIt;
{ Set up the graphics display }
VAR
  i,
  GraphDriver, GraphMode : INTEGER;

BEGIN
   GraphDriver := Detect;
   InitGraph(GraphDriver, GraphMode,'');
   IF (GraphResult <> grOK) OR (GraphDriver <> VGA) THEN HALT(1);

   FOR i := 0 TO GetMaxColor DO {use the lowest colors in palette register}
      SetPalette(i,i);

   { initial colors }
   RGBLog(0, 0.0, 0.0, 0.0) {Black};
   RGBLog(1, 1.0, 0.0, 0.0) {Red};
   RGBLog(2, 0.0, 1.0, 0.0) {Green};
   RGBLog(3, 1.0, 1.0, 0.0) {Yellow};
   RGBLog(4, 0.0, 0.0, 1.0) {Blue};
   RGBLog(5, 1.0, 0.0, 1.0) {Magenta};
   RGBLog(6, 0.0, 1.0, 1.0) {Cyan};
   RGBLog(7, 1.0, 1.0, 1.0) {White};

   nxpix := GetMaxX+1;
   nypix := GetMaxY+1;
END {PrepIt};

(* Coordinate Oriented Procedures *)
(*----------------------------------------------------------- *)
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

BEGIN
  Graph.MoveTo(fx(pt.x),nypix-1-fy(pt.y));
END {MoveTo};

(*----------------------------------------------------------- *)
PROCEDURE LineTo(pt : Vector2);
{draw a line for the current point to pixel.  Update the current pointer }
VAR
  pixel : pixelvector;

BEGIN
  Graph.LineTo(fx(pt.x),nypix-1-fy(pt.y));
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
     pixelpolygon[i].y := nypix-1-fy(polygon[i].y);
  END;
  FillPoly(n,pixelpolygon);
END {PolyFill};

(*----------------------------------------------------------- *)
FUNCTION Angle(x,y : REAL) :REAL;
{ listing 3.3 }
{ return angle in radians vs. X  axis of line from origin to point (x, y) }
BEGIN
  IF ABS(x) < epsilon       { close enough to zero ?}
    THEN IF abs(y) < epsilon
       THEN Angle := 0.0
    ELSE IF y > 0.0
        THEN Angle := pi * 0.5
        ELSE Angle := pi * 1.5
  ELSE IF x < 0.0
     THEN Angle := arctan(y/x) + pi;
     ELSE Angle := arctan(y/x);
END {Angle};

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
program XJulia;
{from: THE BEAUTY OF FRACTALS by Peitgen & Richter  }
{ pp 189,190. Experiment 1: Basins of Attraction and Julia Sets }
{ Turbo Pascal 4.0 implementation by Art Steinmetz }

{$I FLOAT.INC}

(*
{$S-}  {no stack checking}
{$R-}  {no range checking}
*)

uses CRT,      { KeyPressed, ReadKey }
     Memory,   { installs HeapError checking }
     MathLib0, { Float }
     Graph,    { CloseGraph, DetectGraph, InitGraph, GetMaxColor,
                 GetBkColor, GetMaxX, GetMaxY, GetModeRange,
                 PutPixel, SetFillStyle, FillPoly, SetColor,
                 PointType, GetImage, PutImage }
     Drivers,  { All available graphics drivers }
     JulStuf,  { OpenGraph, InitFields, GetParams }
     GRGetFld, { AddExitKey, Field_Str, Do_Fields, ReleaseFields,
                 NOBOX, LEFT }
     KeyCodes, { ESC, Break, F10 }
     TextDisp,  { ErrorMsg }
     StopWtch;   {StartWatch, SplitTime}
{     ThreeD   }



VAR
   VRes, Hres,
   XWidth, YWidth : INTEGER;
   dx, dy : FLOAT;  { parameter change per pixel }
   GMode,
   ColorRange : INTEGER;
   MoreThanOnePage,
   Symmetry  : BOOLEAN;
   Action     : ActionType;
   Prm        : InputParamRec;
   PrmStr     : PrmStrArray;
   BugFile    : text;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Initialize;

BEGIN
  { set color ranges }
  ColorRange := GetMaxColor - 1;
  IF ColorRange < 1 THEN ColorRange := 1;
  Vres := GetMaxY;
  Hres := GetMaxX;

  { set scaling }
  XWidth := 1;
  YWidth := 1;
  WITH Prm DO
  BEGIN
     IF Hpoints < Hres THEN
     BEGIN
        XWidth := Hres div Hpoints;
        Hres := Hpoints * XWidth;  { rescale }
     END
     ELSE
        Hpoints := Hres;
     IF Vpoints < Vres THEN
     BEGIN
        YWidth := Vres div Vpoints;
        Vres := Vpoints * YWidth;  { rescale }
     END
     ELSE
        Vpoints := Vres;

     dx := (Xmax-Xmin)/(Hpoints-1);
     dy := (Ymax-Ymin)/(Vpoints-1);

     Symmetry := (abs(Xmax+Xmin)<0.0001) AND (abs(Ymax+Ymin)<0.0001);
  END; {WITH}

END; { Initialize }


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE NextPoint(VAR x : FLOAT; VAR y : FLOAT; p,q :FLOAT);
{ Here's the actual formula }

VAR
  tempX : FLOAT;

BEGIN
  tempX := x;
  x := (x-y) * (x+y) + p;  { FLOAT part }
  y := (tempX + tempX) * y + q;  { imaginary part }
END; { NextPoint }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE PutRectangle(x1,y1,x2,y2 : INTEGER; Color : WORD);
VAR
  rect : ARRAY[0..3] OF PointType;

BEGIN
  rect[0].x := x1;
  rect[0].y := y1;
  rect[1].x := x1;
  rect[1].y := y2;
  rect[2].x := x2;
  rect[2].y := y2;
  rect[3].x := x2;
  rect[3].y := y1;
  SetColor(GetBkColor);
  SetFillStyle(SolidFill, Color);
  FillPoly(4 , rect);
END; { PutRectangle }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DrawCompPoints(x,y : INTEGER; Color : WORD);
{ plot image symmetric to the origin }

BEGIN
  PutPixel(x,y,color);
  PutPixel(Prm.Hpoints-x, Prm.Vpoints-y,color);
END; { DrawCompPoints }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DrawCompRect(x1,y1,x2,y2 : INTEGER; Color : WORD);
{ plot image symmetric to the origin }

BEGIN
  PutRectangle( x1,y1,x2,y2,color);
  PutRectangle( Hres-x1, Vres-y1,
                Hres-x2, Vres-y2,
                color);

END; { DrawCompPoints }


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DoPixel(nx,ny : INTEGER);

VAR
 i,
 Color : INTEGER;
 r,
 X, Y  : FLOAT;
 done  : BOOLEAN;

BEGIN
    X := Prm.Xmin + nx * dx;
    Y := Prm.YMin + ny * dy;
    i  := 0;
    done := FALSE;
    REPEAT
       NextPoint(X,Y,Prm.p,Prm.q);
       r := sqr(X) + sqr(Y);
       IF (r > Prm.M) or (i = Prm.K) THEN done := TRUE
       ELSE inc(i);
    UNTIL done;
    IF i = Prm.K THEN
       Color := Black
    ELSE
       Color := ((i div Prm.ColorDivisor) mod ColorRange) + 1;

    IF Symmetry THEN
       DrawCompPoints(nx,ny,Color)
    ELSE
       PutPixel(nx,ny,Color);

END; { DoPixel }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DoRectangle(nx,ny : INTEGER);

VAR
 i, xpos, ypos,
 Color : INTEGER;
 r,
 X, Y  : FLOAT;
 done  : BOOLEAN;

BEGIN
    X := Prm.Xmin + nx * dx;
    Y := Prm.YMin + ny * dy;
    i  := 0;
    done := FALSE;
    REPEAT
       NextPoint(X,Y,Prm.p,Prm.q);
       r := sqr(X) + sqr(Y);
       IF (r > Prm.M) or (i = Prm.K) THEN done := TRUE
       ELSE inc(i);
    UNTIL done;
    IF i = Prm.K THEN
       Color := Black
    ELSE
       Color := (i mod ColorRange) + 1;

    xpos := nx * Xwidth;
    ypos := nx * Ywidth;

    IF Symmetry THEN
       DrawCompRect(xpos,ypos,xpos+Xwidth,ypos+Ywidth,Color)
    ELSE
       PutRectangle(xpos,ypos,xpos+Xwidth,ypos+Ywidth,Color);

END; { DoRectangle }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE  RenderSet;

VAR
  x, y,
  VHigh, Hhigh : INTEGER;
  StopRender : BOOLEAN;


BEGIN

  Hhigh := Prm.Hpoints;
  IF Symmetry THEN
     Vhigh := Prm.Vpoints DIV 2
  ELSE
     Vhigh := Prm.Vpoints;

  y := 0;
  REPEAT
     BEGIN
       StopRender := Abort;  { Check for ^C once each scan line }
       IF NOT StopRender THEN
       FOR x := 0 to Hhigh DO
       (* this ain't workin yet
         IF (XWidth > 1) OR (YWidth > 1) THEN
            DoRectangle(x,y)
         ELSE
        *)
            DoPixel(x,y);
       INC(y);
     END;
  UNTIL (y > Vhigh) OR StopRender;

END; {RenderSet}

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Display;
BEGIN
     Initialize;
     StartWatch;
     IF MoreThanOnePage THEN
     BEGIN
        SetActivePage(1);
        SetVisualPage(1);
     END;
     ClearViewPort;
     RenderSet;
     WaitForExit;
     IF MoreThanOnePage THEN BEGIN
        SetActivePage(0);
        SetVisualPage(0); END
     ELSE BEGIN
       SetUpScreen;
       DisplayFields;
     END;
END;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
BEGIN {MAIN}
(*
Assign(BugFile,'bugs.txt');
rewrite(bugfile);
*)
OpenGraph(Gmode,MoreThanOnePage);
SetGraphMode(GMode);
InitFields(PrmStr);
REPEAT
  Action := GetInput(Prm,PrmStr);
  CASE Action OF
      SwapScreen : IF MoreThanOnePage THEN AltView
                   ELSE
                      MoreThanOnePage := ErrorMsg('Only One Visual Page');
      Render     : Display;
  END; {case}
UNTIL Action = Quit;
Release_Fields;
CLoseGraph;
(*
Close(BugFile);
*)
END. {Julia}

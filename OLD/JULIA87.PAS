program Julia87;
{from: THE BEAUTY OF FRACTALS by Peitgen & Richter  }
{ pp 189,190. Experiment 1: Basins of Attraction and Julia Sets }
{ Turbo Pascal 4.0 implementation by Art Steinmetz }

{$N+}  {math chip}
{$S-}  {no stack checking}
{$R-}  {no range checking}


uses CRT,      { KeyPressed, ReadKey }
     Graph,    { CloseGraph, DetectGraph, InitGraph, GetMaxColor,
                 GetBkColor, GetMaxX, GetMaxY, GetModeRange,
                 PutPixel, SetFillStyle, FillPoly, SetColor }
     Drivers,  { All available graphics drivers }
     Windows,  { OpenWindow, CloseWindow }
     GetField, { AddExitKey, Field_Str, Do_Fields, ReleaseFields,
                 NOBOX, LEFT }
     KeyCodes, { ESC, Break, F10 }
     SaveScrn  {SaveScreen, RestoreScreen}
     ;

(*
CONST     {    suggested values }
  Xmin = -1.25;
  Xmax =  1.25;
  Ymin = -1.25;
  Ymax =  1.25;

  M = 100; { assume infinite attractor if (x^2)(y^2) > M}
  K = 200; { iterations }

  p = 0.32;  { c = p + qi }
  q = 0.04;
*)

TYPE
   InputParamRec = RECORD
        Xmin, Xmax,
        Ymin, Ymax              : REAL;
        M,   { assume infinite attractor if (x^2)(y^2) > M}
        K    { iterations }     : INTEGER;
        p, q { c = p + qi }     : REAL;
        Hpoints,
        Vpoints  {points to render} : INTEGER;
   END;

   StrArray = ARRAY[0..9] OF String;

VAR
   VRes, Hres,
   XWidth, YWidth : INTEGER;
   dx, dy : REAL;  { parameter change per pixel }
   ColorRange : INTEGER;
   done,
   Symmetry  : BOOLEAN;
   Prm        : InputParamRec;
   PrmStr     : StrArray;


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION Abort : BOOLEAN;

BEGIN
  IF KeyPressed THEN
        Abort := ((ReadKey = CHAR(Break)) OR (ReadKey = CHAR(ESC)))
  ELSE Abort := FALSE;
END; { Abort }


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE WaitForExit;
VAR
  ch : CHAR;

BEGIN
  OutText('DONE. PRESS ANY KEY TO EXIT');
  ch := ReadKey;
END; {Wait for Exit}

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure ErrorMsg(msg : string);
CONST
  HalfCols  = 40;
  top       = 12;
  bottom    = 14;

VAR
  Spaces,i,
  left, right,
  len      : INTEGER;
  Error    : BYTE;

procedure Beep;
BEGIN
  Sound(500);
  Delay(500);
  NoSound;
END;

begin
  len := length(msg);
  right := HalfCols + len + 2;
  left  := HalfCols - Len + 2;
  IF left < 1 THEN
  BEGIN
      left  := 1;
      right := HalfCols * 2 - 1;
  END;
  OpenWindow(left,top,right,bottom,White,Red,Error);
  IF Error = 0 THEN
  begin
     {do text centering}
     spaces := ( right-left-2-len ) div 2;
     if spaces > 0 then for i := 1 to spaces do write(' ');
     Write(msg);
     Beep;
     Delay(500);
     CloseWindow;
  end;
  done := FALSE;
end;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE InitFields;
BEGIN
  TextBackground(White);
  ClrScr;
  TextColor(Red);
  GotoXY(2,1);
  Writeln('JULIA SET GENERATOR');
  GotoXY(10,3);
  Write('X,Y Range of -1.5 to 1.5 is plenty');
  GotoXY(10,4);
  Write('If Min`s and Max`s are not equal rendering time will double.');
  GotoXY(20,10);
  Write('Plot points will not exceed screen resolution Use "MAX".');
  GotoXY(20,16);
  Write('c := p + qi.  Choose p and q between -1.0 and 1.0.');

  GotoXY(2,22);
  Write('<Esc> to quit.  <F10> to draw.  <Ctrl>C quits drawing.');

  TextColor(Blue);
  SetUp_Field(White,White,Blue,Black,' ');
  AddExitKey(F10);

  Field_Str(10, 6,6,3,'Min X',PrmStr[0],'N',NOBOX,LEFT);
  Field_Str(10, 8,6,3,'Max X',PrmStr[1],'N',NOBOX,LEFT);
  Field_Str(10,10,6,3,'Min Y',PrmStr[2],'N',NOBOX,LEFT);
  Field_Str(10,12,6,3,'Max Y',PrmStr[3],'N',NOBOX,LEFT);
  Field_Str(50, 6,6,3,'Threshold (use 100)',PrmStr[4],'N',NOBOX,LEFT);
  Field_Str(50, 8,6,3,'Iterations (use 200)',PrmStr[5],'N',NOBOX,LEFT);
  Field_Str(50,12,6,3,'Plot points in X direction',PrmStr[6],'L',NOBOX,LEFT);
  Field_Str(50,14,6,3,'Plot points in Y direction',PrmStr[7],'L',NOBOX,LEFT);
  Field_Str(35,18,6,3,'p:', PrmStr[8],'N',NOBOX,LEFT);
  Field_Str(45,18,6,3,'q:',PrmStr[9],'N',NOBOX,LEFT);

END; {InitFields}

FUNCTION GetInput(VAR Inp : InputParamRec) : BOOLEAN;
VAR
  errcode,
  ExitKey : INTEGER;

BEGIN
REPEAT
  Do_Fields(ExitKey);
 IF ExitKey = ESC THEN
    done := FALSE
 ELSE
   WITH Prm DO
   BEGIN
      done := TRUE;
      Val(PrmStr[0],Xmin,errcode);
      IF errcode > 0 then ErrorMsg('Bad Xmin');
      Val(PrmStr[1],Xmax,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad Xmax');
      Val(PrmStr[2],Ymin,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad Ymin');
      Val(PrmStr[3],Ymax,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad Ymax');
      Val(PrmStr[4],K,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad Threshold');
      Val(PrmStr[5],M,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad Iterations');

      Val(PrmStr[6],Hpoints,errcode);
      IF done THEN
        IF errcode > 0 then
           IF (PrmStr[6] = 'MAX') or (PrmStr[6] = 'max') THEN
               Hpoints := Hres
            ELSE
               ErrorMsg('X Points');

      Val(PrmStr[7],Vpoints,errcode);
      IF done THEN
        IF errcode > 0 then
           IF (PrmStr[7] = 'MAX') or (PrmStr[7] = 'max') THEN
               Vpoints := Vres
            ELSE
               ErrorMsg('Y Points');

      Val(PrmStr[8],p,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad p');
      Val(PrmStr[9],q,errcode);
      IF done THEN IF errcode > 0 then ErrorMsg('Bad q');
   END; {with}

UNTIL (done = TRUE) or (ExitKey = ESC);

GetInput := done;

END; {GetInput }
{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Initialize;

BEGIN
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
PROCEDURE OpenGraph;
VAR
  GraphDriver, LoMode, HiMode   : INTEGER;

BEGIN

  { Register all the drivers }
  if RegisterBGIdriver(@CGADriverProc) < 0 then
    ErrorMsg('CGA driver not found');
  if RegisterBGIdriver(@EGAVGADriverProc) < 0 then
    ErrorMsg('EGA/VGAdriver not found');
  if RegisterBGIdriver(@HercDriverProc) < 0 then
    ErrorMsg('Hercdriver not found');
  if RegisterBGIdriver(@ATTDriverProc) < 0 then
    ErrorMsg('AT&Tdriver not found');
  if RegisterBGIdriver(@PC3270DriverProc) < 0 then
    ErrorMsg('PC 3270driver not found');

  { set graph mode to max res of device (does not support ATT) }
  DetectGraph(GraphDriver,HiMode);
  GetModeRange(GraphDriver,LoMode,HiMode);
  InitGraph(GraphDriver,HiMode,'');

  { set color Range to reserve color 0 for boundary    }
  { (i mod ColorRange + 1) will be choice of Colors }
  {  excluding black }

   ColorRange := GetMaxColor - 1;
   Vres := GetMaxY;
   Hres := GetMaxX;

END; { OpenGraph }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE NextPoint(VAR x : REAL; VAR y : REAL; p,q :REAL);
{ Here's the actual formula }

VAR
  tempX : REAL;

BEGIN
  tempX := x;
  x := sqr(x) - sqr(y) + p;
  y := 2 * tempX * y + q;
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
 X, Y  : REAL;
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
 X, Y  : REAL;
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

BEGIN

  Hhigh := Prm.Hpoints;
  IF Symmetry THEN
     Vhigh := Prm.Vpoints DIV 2
  ELSE
     Vhigh := Prm.Vpoints;

  FOR y := 0 to Vhigh DO
     BEGIN
       IF Abort THEN HALT; { Check for ^C once each scan line }
       FOR x := 0 to Hhigh DO
            DoPixel(x,y);
     END;
END; {RenderSet}

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

BEGIN {MAIN}
InitFields;
REPEAT
  IF GetInput(Prm) THEN
  BEGIN
     SaveScreen;
     OpenGraph;
     Initialize;
     RenderSet;
     WaitForExit;
     CloseGraph;
     RestoreScreen;
  END;
UNTIL NOT Done;
Release_Fields;
END. {Julia87}

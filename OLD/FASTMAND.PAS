PROGRAM FASTMAND;

{$M 30000,0,655360} { boost the stack size }

{$I FLOAT.INC}

{$DEFINE JULIA}

uses MathLib0,  { Float, max, min, sqrt2, ln10 }
     Memory,
     CRT,
     Graph,
     TextDisp,  { WriteInt }
     JulStuf,   { Abort }
     KeyCodes,
     BoundRgn;

CONST
  p = -1.25;
  q = 0;

  DisplayMode = VGAHi;
  AltScan   = TRUE;  { Alternate y-line scans up and down? }
  LimitIter = 500;
  MSetColor = 0;
  LowColor  = 1;
  BorderThreshhold = 5;
  AltColor = White;

VAR
  { screen parmeters }
  XWidth,
  YWidth     : INTEGER; { square image size allowed }
  aspect     : FLOAT;
  TooBig     : WORD;    { don't draw circle bigger than this }

  StopRender : BOOLEAN;
  ExitSave   : POINTER;

  { image paramters }
  XMin,
  YMax       : FLOAT;
  MaxIter    : WORD;
  RecursionMultiple : INTEGER;

  { some "on the fly" constants }
  side,
  Delta,
  recur  : FLOAT;

{ ---------------------------------------------------------------}
PROCEDURE OpenGraph;
VAR
   XAsp, YAsp : WORD;
   ErrorCode,
   GraphDriver, GraphMode : INTEGER;

Begin
   GraphDriver := VGA;
   GraphMode   := DisplayMode;
   InitGraph(GraphDriver,GraphMode,'C:\TP');
   ErrorCode := GraphResult;             { preserve error return }
   if ErrorCode <> grOK then             { error? }
      Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
   XWidth := GetMaxX;
   YWidth := GetMaxY;
   GetAspectRatio(Xasp,YAsp);
   aspect := XAsp/YAsp;
   { any circle bigger than 1/3 screen height is too big }
   TooBig := min(XWidth,YWidth) div 3;
   SetColor(LowColor);
   SetFillStyle(SolidFill,LowColor);
end;

{ ---------------------------------------------------------------}
{$F+} PROCEDURE CleanUp; {$F-}
VAR
   i : WORD;

BEGIN
{   FOR i := 0 TO n DO DISPOSE(MSet[i]); }
   CloseGraph;
   ExitProc := ExitSave;
END; { DiposeArray }

{ ---------------------------------------------------------------}
PROCEDURE DrawGrid(X0,Y0, Xrange, Yrange : FLOAT;
                   x1,y1,x2,y2 : WORD);
CONST
   ticks = 10;

VAR
  valstr : string;
  Xscale, YScale : Float;
  i,
  Xdecimals, Ydecimals,
  Xtick, Ytick : WORD;

BEGIN
  setcolor(LightRed);
  Xdecimals := max(trunc(ln(Xrange) / ln10) * -1, 0) + 2;
  Ydecimals := max(trunc(ln(Yrange) / ln10) * -1, 0) + 2;
  IF x2 > GetMaxX then x2 := GetMaxX;
  IF y2 > GetMaxY then y2 := GetMaxY;
  Rectangle(x1,y1,x2,y2);
  Xtick := round((x2-x1)/ticks);
  Ytick := round((y2-y1)/ticks);
  XScale := Xrange/ticks;
  YScale := Yrange/ticks;
  FOR i := 0 TO ticks DO
  BEGIN
     { do the X range }
     str(X0+XScale*i:5:Xdecimals,valstr);
     MoveTo(x1+Xtick*i,y1);
     LineTo(x1+Xtick*i,y1+Ytick div 4);
     IF i < ticks THEN OutText(valstr);
     MoveTo(x1+Xtick*i,y2);
     LineTo(x1+Xtick*i,y2-Ytick div 5);
     IF i < ticks THEN OutText(valstr);
     { do the Y range }
     str(Y0-YScale*i:5:Ydecimals,valstr);
     MoveTo(x1,y1+Ytick*i);
     LineTo(x1+Xtick div 5,y1+Ytick*i);
     IF i > 0 THEN OutText(valstr);
     MoveTo(x2,y1+Ytick*i);
     LineTo(x2-Xtick div 5,y1+Ytick*i);
     { add another MoveTo to put us on left side of axis }
     MoveTo(x2-45,y1+Ytick*i);
     IF i > 0 THEN OutText(valstr);
  END;
END;
{ ---------------------------------------------------------------}
PROCEDURE Finish;

BEGIN
  IF aspect > 1.0 THEN
      DrawGrid(Xmin,YMax,side, side, 0, 0, XWidth, YWidth)
  ELSE
      DrawGrid(Xmin,YMax,side, side, 0, 0, XWidth, YWidth);
  ReadLn;
END;

{ ---------------------------------------------------------------}
FUNCTION JSetDist(cx,cy : FLOAT; p,q : FLOAT; HighIter : WORD) : FLOAT;
CONST
{$IFOPT N+}
  overflow = 1.699e37;  { close to max range of REAL }
{$ELSE}
  overflow = 1.699e37;  { close to max range of REAL }
{$ENDIF}
  huge     = 10000.0;   { stops iteration }

TYPE
    orbits  = ARRAY[0.. LimitIter] OF FLOAT;
VAR
  iter, i       : WORD;
  x, y, x2, y2 : FLOAT;
  temp,
  xder, yder,
  dist        : FLOAT;
  flag        : BOOLEAN;
  xorbit,
  yorbit      : orbits;

BEGIN
   dist := 0;
   xorbit[0] := 0;
   yorbit[0] := 0;
   iter := 0;
   flag := FALSE;
   x    := cx;
   y    := cy;
   x2   := sqr(x);
   y2   := sqr(y);
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x;
      x := x2 - y2 + p;
      y := 2 * temp * y + q;
      x2 := sqr(x);
      y2 := sqr(y);
      INC(iter);
      xorbit[iter] := x;
      yorbit[iter] := y;
   END; { while }
   IF x2 + y2 > huge THEN
   BEGIN
      xder := 0;
      yder := 0;
      i    := 0;
      flag := FALSE;
      WHILE (i < iter) AND (NOT flag) DO
      BEGIN
         temp := 2 * (xorbit[i] * xder-yorbit[i]*yder)+1;
         yder := 2 * (yorbit[i] * xder+xorbit[i]*yder);
         xder := temp;
         flag := (abs(xder) > overflow) OR (abs(yder) > overflow);
         INC(i);
      END; {while}
      IF NOT flag THEN
        dist := ln(x2+y2)/ln10 * sqrt(x2+y2) / sqrt(sqr(xder) + sqr(yder));
   END; {IF}
   JSetDist := dist;
END; {JSetDist}

{ ---------------------------------------------------------------}
FUNCTION MSetDist(cx,cy : FLOAT; HighIter : WORD) : FLOAT;
CONST
{$IFOPT N+}
  overflow = 1.699e37;  { close to max range of REAL }
{$ELSE}
  overflow = 1.699e37;  { close to max range of REAL }
{$ENDIF}
  huge     = 10000.0;   { stops iteration }

TYPE
    orbits  = ARRAY[0.. LimitIter] OF FLOAT;
VAR
  iter, i       : WORD;
  x, y, x2, y2 : FLOAT;
  temp,
  xder, yder,
  dist        : FLOAT;
  flag        : BOOLEAN;
  xorbit,
  yorbit      : orbits;

BEGIN
   dist := 0;
   x    := 0;
   y    := 0;
   x2   := 0;
   y2   := 0;
   xorbit[0] := 0;
   yorbit[0] := 0;
   iter := 0;
   flag := FALSE;
   WHILE (iter < HighIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x2 - y2 + cx;
      y    := 2 * x * y + cy;
      x    := temp;
      x2   := sqr(x);
      y2   := sqr(y);
      INC(iter);
      xorbit[iter] := x;
      yorbit[iter] := y;
   END; { while }
   IF x2 + y2 > huge THEN
   BEGIN
      xder := 0;
      yder := 0;
      i    := 0;
      flag := FALSE;
      WHILE (i < iter) AND (NOT flag) DO
      BEGIN
         temp := 2 * (xorbit[i] * xder-yorbit[i]*yder)+1;
         yder := 2 * (yorbit[i] * xder+xorbit[i]*yder);
         xder := temp;
         flag := (abs(xder) > overflow) OR (abs(yder) > overflow);
         INC(i);
      END; {while}
      IF NOT flag THEN
        dist := ln(x2+y2)/ln10 * sqrt(x2+y2) / sqrt(sqr(xder) + sqr(yder));
   END; {IF}
   MSetDist := dist;
END; {MSetDist}

{ ---------------------------------------------------------------}
PROCEDURE FillDisk(x, y, pxlrad : WORD ; FillColor : WORD);

VAR
  sumsqr,
  lowX, lowY,
  highX, highY,
  ix, iy  : WORD;

BEGIN
  IF pxlrad < BorderThreshhold THEN
  BEGIN
     SetColor(FillColor);
     Circle(x,y,pxlrad);
     SetFillStyle(SolidFill,FillColor);
     FloodFill(x,y,FillColor);
  END
  ELSE
  BEGIN
     IF pxlrad > TooBig THEN
            pxlrad := TooBig;
     SetColor(LowColor);
     Circle(x,y,pxlrad);
     SetFillStyle(SolidFill,LowColor);
     FloodFill(x,y,LowColor);
  END;
END;

{ ---------------------------------------------------------------}
PROCEDURE MDisk(x,y : WORD);

VAR
  Dist,
  cx,cy   : FLOAT;
  Color,
  IRad    : WORD;

BEGIN
IF StopRender = FALSE THEN
BEGIN
     IF KeyPressed THEN IF Abort THEN StopRender := TRUE;
     IF (x >= 0) AND (x < XWidth) AND
        (y >=0)  AND (y < YWidth) AND
          (GetPixel(x,y) = MSetColor) THEN
     BEGIN
        { scale screen pixel to complex plane }
        cx := Xmin + x * Delta * aspect;
        cy := YMax - y * Delta;
        {$IFDEF JULIA}
        dist := JSetDist(cx,cy,p,q,maxiter);
        {$ELSE}
        dist := MSetDist(cx,cy,maxiter);
        {$ENDIF}
        { scale distance back up to screen pixels }
        irad := round(dist / Delta );
        Color := AltColor;
        IF irad > 1 THEN
                 FillDisk(x,y,irad,Color)
              ELSE IF irad = 1 THEN
                  PutPixel(x,y,AltColor); { use bottom color }
        IF dist > recur THEN
        BEGIN
            IF irad > 1 THEN INC(irad);
            MDisk(x,y+irad);
            MDisk(x,y-irad);
            MDisk(x+irad,y);
            MDisk(x-irad,y);

            irad := trunc(0.5 + irad / Sqrt2);
            MDisk(x+irad,y+irad);
            MDisk(x-irad,y-irad);
            MDisk(x-irad,y+irad);
            MDisk(x+irad,y-irad);

        END; {if}
     END; {if}
END;
END; {MDisk}

{ ---------------------------------------------------------------}
PROCEDURE DisplayHelp;
BEGIN
  RestoreCRTMode;
  Writeln('usage: FASTMAND XMin YMax Side MaxIter RecurMultiple');
END;

{ ---------------------------------------------------------------}
PROCEDURE GetParams;

VAR
  code : INTEGER;

BEGIN
  If paramstr(1) = '?' THEN
  BEGIN
    DisplayHelp;
    Halt;
  END;
  val(paramstr(1),Xmin,code);
  IF code > 0 THEN Xmin := -2.0;
  val(paramstr(2),YMax,code);
  IF code > 0 THEN YMax := 1.2;
  val(paramstr(3),side,code);
  IF code > 0 THEN side := 2.4;
  delta := side / min(XWidth,YWidth); { fractal units per pixel }
  val(paramstr(4),MaxIter,code);
  IF code > 0 THEN MaxIter := 100;
  IF MaxIter > LimitIter THEN MaxIter := LimitIter;
  val(paramstr(5),RecursionMultiple,code);
  IF code > 0 THEN RecursionMultiple := 1;

END;

{ ---------------------------------------------------------------}
PROCEDURE FastM;

VAR
  m, n,
  ix, iy :WORD;

BEGIN
   recur := delta * RecursionMultiple;
   m := 0;
   WHILE NOT ((m > YWidth) OR StopRender) DO
   BEGIN
     IF Abort THEN StopRender := TRUE;
     { skip up and down on screen }
     IF AltScan THEN
        if (m mod 2 = 0) THEN iy := m ELSE iy := YWidth - m
     ELSE
        iy := m;
     ix := 0;
     WHILE NOT ((ix > XWidth) OR StopRender) DO
     BEGIN
         IF KeyPressed THEN IF Abort THEN StopRender := TRUE;
         IF GetPixel(ix,iy) = MSetColor THEN
             MDisk(ix,iy);
         INC(ix);
     END;
     INC(m);
   END;
END; { FastM }

{ ---------------------------------------------------------------}
PROCEDURE ZoomIn;
VAR
  NewX, NewY,
  NewSide     : INTEGER;

BEGIN
   BoundRegion(NewX, NewY, NewSide, White);
   ClearViewPort;
   { scale pixel selection to MSet units }
   Xmin := XMin + NewX * delta *  aspect;
   YMax := YMax - NewY * delta;
   side := NewSide * delta;
   { get new delta }
   delta := side / min(XWidth,YWidth);
END {ZoomIn};

{ ---------------------------------------------------------------}
BEGIN
  { Exit Procedures }
  ExitSave := ExitProc;
  ExitProc := @CleanUp;
  CheckBreak := FALSE;
  StopRender := FALSE;
  OpenGraph;
  GetParams;
  REPEAT
     FastM;
     StopRender := FALSE;
     Finish;
     SetColor(White);
     OutTextXY(50,50,'Do Another? F10 quits.');
     StopRender := (GetKey = F10);
     IF NOT StopRender THEN
     BEGIN
        OutTextXY(50,70,'Precision? <F1>-max, <F3>-min');
        CASE GetKey OF
          F1 : RecursionMultiple := 1;
          F2 : RecursionMultiple := 3;
          F3 : RecursionMultiple := 5;
        END;
        ZoomIn;
     END;
  UNTIL StopRender;
END.

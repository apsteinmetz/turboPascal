PROGRAM FASTMAND;

{$M 35000,0,655360} { boost the stack size }

{$I FLOAT.INC}

uses MathLib0,  { Float, max, min, sqrt2, ln10 }
     Memory,
     CRT,
     Graph,
     TextDisp,  { WriteInt }
     XYStack,   {InitStack, PushXY, PopXY }
     JulStuf;   { Abort }

CONST
  AltScan   = TRUE;  { Alternate y-line scans up and down? }
  MaxRes    = 480;     { square image resolution minus 1}
  LowBoundFactor = 1.0;  { adjust MSetDisk from 0< to 1.0 }
  LimitIter = 501;
  MaxIter   = 500;
  InSet  = TRUE;
  OutSet = FALSE;
  LowColor = 1;
{  ColorBandWidth = 4; }

TYPE
  BoolArray = ARRAY[0..MaxRes] OF BOOLEAN;
  MandArray = ARRAY[0..MaxRes] OF ^BoolArray;


VAR
  XWidth,
  YWidth     : INTEGER;        { square image size allowed }
  DiskStack,
  ExitSave   : POINTER;
  x,y,
  ix, iy     : WORD;
  XMin,
  YMin       : FLOAT;
  RecursionMultiple : INTEGER;
 (* MSet   : MandArray; *)

  { some "on the fly" constants }
  side,
  Delta,
  recur  : FLOAT;

{ ---------------------------------------------------------------}
PROCEDURE OpenGraph;
VAR
   GraphDriver, GraphMode : INTEGER;

Begin
   GraphDriver := VGA   { ATT400 };
   GraphMode   := VGAHi { ATT400HI };
   InitGraph(GraphDriver,GraphMode,'');
   XWidth := GetMaxX;
   YWidth := GetMaxY;
   SetColor(LowColor);
   SetFillStyle(SolidFill,LowColor);
end;
{ ---------------------------------------------------------------}
PROCEDURE SetColors;
VAR
  i : WORD;
BEGIN
  SetPalette(1 ,White);
  SetPalette(2 ,Yellow);
  SetPalette(3 ,LightRed);
  SetPalette(4 ,LightMagenta);
  SetPalette(5 ,Red);
  SetPalette(6 ,Magenta);
  SetPalette(7 ,LightCyan);
  SetPalette(8 ,LightBlue);
  SetPalette(9 ,Cyan);
  SetPalette(10,Blue);
  SetPalette(11,LightGreen);
  SetPalette(12,Green);
  SetPalette(13,Brown);
  SetPalette(14,LightGray);
  SetPalette(15,DarkGray);

END;

{ ---------------------------------------------------------------}
(*
PROCEDURE InitArray;
VAR
  i,j : WORD;

BEGIN
  i := 0;
  WHILE  (MaxAvail-sizeof(BoolArray) > 0) AND (i < maxres) DO
  BEGIN
     NEW(MSet[i]);
     FOR j := 0 TO MaxRes DO
         MSet[i]^[j] := OutSet;
     INC(i);
  END;
  n := i - 1;  { how many rows did we allocate }
  Writeln('HeapLeft',MaxAvail:6,' Rows: ',n:4);

END; { InitArray }
*)
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
     str(Y0+YScale*i:5:Ydecimals,valstr);
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
VAR
  aspect : FLOAT;

BEGIN
{  WHILE PopXY(stack,x,y) DO BEGIN END; }
  aspect := XWidth/YWidth;
  IF aspect > 1.0 THEN
      DrawGrid(Xmin,Ymin,side * aspect, side, 0, 0, XWidth, YWidth)
  ELSE
      DrawGrid(Xmin,Ymin,side, side/aspect, 0, 0, XWidth, YWidth);
  ReadLn;
  Halt;
END;

{ ---------------------------------------------------------------}
FUNCTION MSetDist(cx,cy : FLOAT; HighIter : WORD) : FLOAT;
CONST
  overflow = 1.699e38;  { close to max range of REAL }
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
PROCEDURE FillDisk( { VAR Mand : MandArray; } x, y, pxlrad : WORD);

VAR
  sumsqr,
  lowX, lowY,
  highX, highY,
  ix, iy  : WORD;
(*
  FillColor,
  ColorBand : WORD;
*)

BEGIN
{
  Circle(x,y,pxlrad);
  FloodFill(x,y,LowColor);
}
(*
  ColorBand := pxlrad div ColorBandWidth + 1;
  IF ColorBand > GetMaxColor THEN
     FillColor := GetMaxColor
  else FillColor := ColorBand;
  SetColor(FillColor);
  SetFillStyle(SolidFill,FillColor);
  Circle(x,y,pxlrad);
  FloodFill(x,y,FillColor);
*)

(*
  lowX := max(x - pxlrad, 0);
  lowY := max(y - pxlrad,0);
  highX := min(x + pxlrad, XWidth);
  highY := min(y + pxlrad,YWidth);
  FOR ix := lowX TO highX DO
    FOR iy := lowY TO highY DO
    BEGIN
      sumsqr := sqr(ix-x) + sqr(iy-y);
      IF sqrt(sumsqr) <= irad THEN
      BEGIN
           Mand[ix]^[iy] := InSet;
           PutPixel(ix,iy,LowColor); { use bottom color }
      END;
    END;
*)
END;

{ ---------------------------------------------------------------}
PROCEDURE MDisk(x,y : WORD);

VAR
  Dist,
  cx,cy   : FLOAT;
  IRad    : WORD;

BEGIN
     IF (x >= 0) AND (x < XWidth) AND (y >=0)  AND (y < YWidth) AND
          (GetPixel(x,y) = 0)
     {    (MSet[x]^[y] = OutSet) } THEN
     BEGIN
        { scale screen pixel to complex plane }
        cx := Xmin + x * Delta;
        cy := ymin + y * Delta;
        dist := LowBoundFactor * MSetDist(cx,cy,maxiter);
        { scale distance back up to screen pixels }
        irad := round(dist / Delta );
        IF irad > 1 THEN
                 FillDisk(x,y,irad)
              ELSE IF irad = 1 THEN
                  PutPixel(x,y,LowColor); { use bottom color }
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
        END
        ELSE
           PushXY(DiskStack, x,y);   { stack points closer than recur }
     END; {if}
END; {MDisk}

{ ---------------------------------------------------------------}
PROCEDURE GetParams;

VAR
  code : INTEGER;

BEGIN
  val(paramstr(1),RecursionMultiple,code);
  IF code > 0 THEN HALT;
  val(paramstr(2),Xmin,code);
  IF code > 0 THEN HALT;
  val(paramstr(3),YMin,code);
  IF code > 0 THEN HALT;
  val(paramstr(4),side,code);
  IF code > 0 THEN HALT;

  delta := side / min(XWidth,YWidth); { fractal units per pixel }
{  recur := delta * RecursionMultiple; }

END;

{ ---------------------------------------------------------------}
PROCEDURE FastM;
VAR
  m, n,
  ix, iy :WORD;

BEGIN
   FOR m := 0 to YWidth DO
   BEGIN
   recur := delta * RecursionMultiple;  { reset every scan line }
     { skip up and down on screen }
     IF AltScan THEN
        if (m mod 2 = 0) THEN iy := m ELSE iy := YWidth - m
     ELSE
        iy := m;
     FOR ix := 0 to XWidth DO
     BEGIN
         IF Abort THEN Finish;  { exit on Break or ESC }
         IF GetPixel(ix,iy) = 0
           { MSet[ix]^[iy] = OutSet } THEN
             MDisk(ix,iy);
         { get snazzy by varing recur during runtime }
         IF DiskStack <> NIL THEN
         BEGIN
            recur := recur * 0.75;
            WHILE DiskStack <> NIL DO
            BEGIN
              IF PopXY(DiskStack,x,y) THEN
                  MDisk(x,y);
            END;
         END;
     END;
   END;
END; { FastM }

{ ---------------------------------------------------------------}
BEGIN
  { Exit Procedures }
  ExitSave := ExitProc;
  ExitProc := @CleanUp;
  CheckBreak := FALSE;
  InitXYStack(DiskStack);
  OpenGraph;
{  SetColors; }
  GetParams;
{  InitArray; }
  FastM;
  Finish;
END.

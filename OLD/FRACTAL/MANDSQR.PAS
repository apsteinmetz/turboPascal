PROGRAM MANDSQR;
{usage: MANDSQR XMin YMax Side Iterations ColorDivisor julia p q }

{$N+,E+}
{$M 30000,0,655360} { boost the stack size }


uses MathLib0,  { Float, max, min, sqrt2, ln10 }
     CRT,
     ColrCtrl,   {PaletteControl}
     EGASave,
     Graph,
     TextDisp,  { WriteInt }
     JulStuf,   { Abort }
     KeyCodes,
     MandUtil,    { MaxIter, MSet, JSet }
     BoundRgn,
     GRGetFld;

CONST
  DisplayMode = VGAHi;
  DefaultColorDivisor = 1;
  SaveName = 'D:Mandel.ega';

VAR
  result,
  NewX,
  NewY,
  NewSide,
  XWidth,
  YWidth     : INTEGER;        { square image size allowed }
  ExitSave   : POINTER;
  ColorDiv,
  MaxColor   : WORD;
  aspect     : FLOAT;
  p, q,
  XMin,
  YMax       : FLOAT;
  JULIA,
  StyleContour,
  QUIT,
  StopRender : BOOLEAN;
  ColorTable : ARRAY[0..LimitIter] OF WORD;

  { some "on the fly" constants }
  side,
  Delta   : FLOAT;

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

   MaxColor := GetMaxColor;
end;
{ ---------------------------------------------------------------}
PROCEDURE SetColors;
VAR
  i : WORD;

BEGIN
  (* set palette *)
  GrayScale;

  (* set color lookup table *)
  ColorTable[0] := 0;
  ColorTable[0] := MaxColor;
  FOR i := 1 TO MaxIter -1  DO
    ColorTable[i] := (i DIV ColorDiv) MOD MaxColor + 1;

END;
{ ---------------------------------------------------------------}
{$F+} PROCEDURE CleanUp; {$F-}
VAR
   i : WORD;

BEGIN
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
  setcolor(3 {lightred});
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
PROCEDURE MSetLine(x1,y1,x2,y2 : WORD);

VAR
  escape,
  Color,
  x , y       : WORD;
  cx, cy      : FLOAT;

BEGIN
  Color := 0;
  IF y1 = y2 THEN { scan horizontally }
  BEGIN
     cy := YMax - y1 * Delta;
     FOR x := x1 to x2 DO
     BEGIN
       IF KeyPressed THEN
         IF Abort THEN StopRender := TRUE;
       { scale screen pixel to complex plane }
       cx := Xmin + x * Delta * aspect;

       IF JULIA THEN
         IF StyleContour THEN
            escape :=  JSet(cx,cy,p,q)
         ELSE
            escape :=  JSetBD(cx,cy,p,q)
       ELSE
         IF StyleContour THEN
            escape := MSet(cx,cy)
         ELSE
            escape :=  MSetBD(cx,cy);

       IF escape < MaxIter THEN
         Color := ColorTable[escape]
       ELSE Color := Black;
       PutPixel(x,y1,Color);
     END {for}
  END
  ELSE  { scan vertically }
  BEGIN
     cx := Xmin + x1 * Delta * aspect;
     FOR y := y1 to y2 DO
     BEGIN
       IF KeyPressed THEN
         IF Abort THEN StopRender := TRUE;
       { scale screen pixel to complex plane }
       cy := YMax - y * Delta;
       IF JULIA THEN
         escape :=  JSetBD(cx,cy,p,q)
       ELSE
         escape :=  MSetBD(cx,cy);
       IF escape < MaxIter THEN
         Color := ColorTable[escape]
       ELSE Color := Black;
       PutPixel(x1,y,Color);
     END {for};
  END;
END {MSetLine};

{ ---------------------------------------------------------------}
PROCEDURE MSetRect( x1,y1,x2,y2 : WORD);

VAR
  OneColor : BOOLEAN;
  Color : WORD;
  x, y,
  BisectX,
  BisectY  : WORD;

BEGIN
  IF StopRender = FALSE THEN
  BEGIN
    { Scan existing rectangle }
    OneColor := TRUE;
    Color := GetPixel(x1,y1);
    FOR x := x1 to x2 DO
       IF GetPixel(x,y1) <> Color THEN
            OneColor := FALSE;
    FOR x := x1 to x2 DO
       IF GetPixel(x,y2) <> Color THEN
            OneColor := FALSE;
    FOR y := y1 to y2 DO
       IF GetPixel(x1,y) <> Color THEN
            OneColor := FALSE;
    FOR y := y1 to y2 DO
       IF GetPixel(x2,y) <> Color THEN
            OneColor := FALSE;

    IF OneColor THEN { Fill rectangle up }
    BEGIN
      SetFillStyle(SolidFill,Color);
      Bar(x1,y1,x2,y2);
    END
    ELSE BEGIN  { keep slicing }
      BisectX := (x2 - x1) div 2;
      BisectY := (y2 - y1) div 2;
      IF BisectX > BisectY THEN { divide vertical }
      BEGIN
        IF BisectY > 0 THEN
          BEGIN
            { draw a vertical line and do both halves }
            MSetLine(x1+BisectX,y1,x1+BisectX,y2);
            MSetRect(x1,y1,x1+BisectX,y2);
            MSetRect(x1+BisectX,y1,x2,y2);
          END;
      END
      ELSE BEGIN
        IF BisectX > 0 THEN
          BEGIN
            { draw a horizontal line and do both halves }
            MSetLine(x1,y1+BisectY,x2,y1+BisectY);
            MSetRect(x1,y1,x2,y1+BisectY);
            MSetRect(x1,y1+BisectY,x2,y2);
          END;
      END {IF};
    END;
  END {If StopRender};
END {MSetRect};

{ ---------------------------------------------------------------}
PROCEDURE FastM;

VAR
  m, n,
  ix, iy :WORD;

BEGIN

   MSetLine(0,0,XWidth,0);
   MSetLine(0,YWidth,XWidth,YWidth);
   MSetLine(0,0,0,YWidth);
   MSetLine(XWidth,0,XWidth,YWidth);

   MSetRect(0,0,XWidth,YWidth);

END; { FastM }

(* --------------------------------------------------------- *)
PROCEDURE Zoom;
BEGIN
        BoundRegion(NewX,NewY,NewSide,White);
        ClearViewPort;
        { scale pixel selection to MSet units }
        Xmin := XMin + NewX * delta * aspect;
        YMax := YMax - NewY * delta;
        side := NewSide * delta;
        { get new delta }
        delta := side / min(XWidth,YWidth);
END {Zoom};

{ ---------------------------------------------------------------}
PROCEDURE DisplayHelp;
BEGIN
  RestoreCRTMode;
  Writeln('usage: MANDSQR XMin YMax Side Iterations ColorDivisor julia p q');
END;

{ ---------------------------------------------------------------}
PROCEDURE UseDefaults;
BEGIN
  Xmin := -5.0;  {2.0}
  YMax := 5;  {-1.2}
  side := 10;
  delta := side / min(XWidth,YWidth); { fractal units per pixel }
  MaxIter := 100;
  ColorDiv := DefaultColorDivisor;
  JULIA := FALSE;
  p := 0;  {-1.5 san marco}
  q := 0.0;
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
  val(paramstr(5),ColorDiv,code);
  IF code > 0 THEN ColorDiv := DefaultColorDivisor;
  IF copy(paramstr(6),1,1) = 'j' THEN
      JULIA := TRUE
  ELSE
      JULIA := FALSE;
  IF code > 0 THEN p := -1.5;
  val(paramstr(7),p,code);
  IF code > 0 THEN p := -1.5;
  val(paramstr(8),q,code);
  IF code > 0 THEN q := 0.0;

END;

{ -------------------------------------------------------------- }
PROCEDURE SaveTopLine(VAR ptr : POINTER);
BEGIN
   GetMem(ptr,ImageSize(0,0,GetMaxY,10));
   GetImage(0,0,GetMaxY,10,ptr^);
END;

{ -------------------------------------------------------------- }
PROCEDURE RestoreTopLine(VAR ptr : POINTER);
BEGIN
   PutImage(0,0,ptr^,NormalPut);
   FreeMem(ptr,SizeOf(ptr^)  { ImageSize(0,0,GetMaxY,10) });
END;

{ -------------------------------------------------------------- }
PROCEDURE ShowMenu(it1,it2,it3,it4,it5 : STRING);
BEGIN
  Bar(0,0,10,GetMaxY);
  OutTextXY(0,0,it1 + ' ' + it2 + ' ' + it3+ ' ' + it4+ ' ' + it5);
END;

{ -------------------------------------------------------------- }
PROCEDURE Prompt(PromptString : String; VAR num : FLOAT);
VAR
  tempstr : string;
  code    : integer;
  tempnum : FLOAT;

BEGIN
  Bar(0,0,10,GetMaxY);
  OutTextXY(0,0,PromptString + ' ');
  GetString(TextWidth(PromptString + ' '),0,White,Black,0,0,
                    tempstr,'N',code);

  val(tempstr,tempnum,code);
  IF code > 0 THEN
    BEEP
  ELSE
    num := tempnum;
END;

{ -------------------------------------------------------------- }
PROCEDURE PromptInt(PromptString : String; VAR num : WORD);
VAR
  tempstr : string;
  code    : integer;
  tempnum : WORD;

BEGIN
  Bar(0,0,10,GetMaxY);
  OutTextXY(0,0,PromptString + ' ');
  GetString(TextWidth(PromptString + ' '),0,White,Black,0,0,
                    tempstr,'N',code);

  val(tempstr,tempnum,code);
  IF code > 0 THEN
    BEEP
  ELSE
    num := tempnum;
END;

{ -------------------------------------------------------------- }
PROCEDURE GetParams3;
VAR
    item : INTEGER;
BEGIN
    ShowMenu('XMin','YMax','Side','MaxIter','Color_Divisor');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
      'X' : BEGIN
              Prompt('Maximum X:',Xmin);
            END;
      'Y' : BEGIN
              Prompt('Minimum Y:',YMax);
            END;
       'S' : BEGIN
               Prompt('Side:',side);
               delta := side / min(XWidth,YWidth); { fractal units per pixel }
             END;
       'M' : BEGIN
               PromptInt('Max Iterations:',MaxIter);
             END;
       'C' : BEGIN
               PromptInt('ColorDivisor:',ColorDiv);
             END;
    END;
END {GetParams3};

{ -------------------------------------------------------------- }
PROCEDURE GetParamsJ;
VAR
  item : INTEGER;
BEGIN
    Julia := TRUE;
    ShowMenu('p(real)','q(imaginary)','','','');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
      'P' : BEGIN
              Prompt('p (real):',p);
            END;
      'Q' : BEGIN
              Prompt('q (imaginary):',q);
            END;
    END;
END {GetParamsJ};

{ -------------------------------------------------------------- }
PROCEDURE GetParamsStyle;
VAR
  item : INTEGER;
BEGIN
    ShowMenu('Contour','Binary_Decomposition','','','');
    Item := GetKey;
    IF Item < 255 THEN
    CASE chr(Item) OF
      'C' : StyleContour := TRUE;
      'B' : StyleContour := FALSE;
    END;
END {GetParamsStyle};

{ -------------------------------------------------------------- }
PROCEDURE GetParams2;
VAR
  item : INTEGER;
BEGIN
    ShowMenu('Paramters','Mandelbrot','Julia','Style','Zoom');
    Item := GetKey;
    IF Item < 255 THEN
    CASE chr(Item) OF
      'P' : GetParams3;
      'M' : Julia := FALSE;
      'J' : GetParamsJ;
      'S' : GetParamsStyle;
      'Z' : Zoom;
    END;
END {GetParams2};

{ ---------------------------------------------------------------}
PROCEDURE ProcessKeypress;

VAR
  item : INTEGER;
  image : POINTER;

BEGIN
  IF (GetKey = ord('/')) THEN
  BEGIN
    SaveTopLine(image);
    ShowMenu('File','Draw','Control','Palette','Quit');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
      'F' : BEGIN {Disabled} END;
      'D' : BEGIN FastM END;
      'C' : BEGIN GetParams2 END;
      'P' : BEGIN PaletteControl END;
      'Q' : BEGIN Quit := TRUE END;
    END;
    RestoreTopLine(image);
  END;
END {ProcessKeyPress};

{ ---------------------------------------------------------------}
BEGIN
  { Exit Procedures }
  ExitSave := ExitProc;
  ExitProc := @CleanUp;
  CheckBreak := FALSE;
  StopRender := FALSE;
  OpenGraph;
  IF paramcount > 1 THEN
     GetParams
  ELSE
     UseDefaults;

  SetColors;
  REPEAT
     SetFillStyle(SolidFill,9);
     FloodFill(10,10,Blue);
     FastM;
     StopRender := FALSE;
     Finish;
     PaletteControl;
     SetColor(1);
{     result := WriteEGAScreen(SaveName); }
     OutTextXY(50,50,'Do Another? F10 quits.');
     StopRender := (GetKey = F10);
     IF NOT StopRender THEN
     BEGIN
        OutTextXY(50,70,'Precision? <F1>-max, <F3>-min');
        CASE GetKey OF
          F1 : MaxIter := 200;
          F2 : MaxIter := 100;
          F3 : MaxIter := 50;
        END;
     END;
  UNTIL StopRender;
END.

PROGRAM MANDSQR2;
{usage: MANDSQR2 XMin YMax Side Iterations ColorDivisor julia p_real q }

{$N+,E+}
{$M 30000,0,655360} { boost the stack size }


uses MathLib0,  { Float, max, min, sqrt2, ln10 }
     CRT,
     ColrCtrl,   {PaletteControl}
     Graph,
     TextDisp,  { WriteInt, Beep }
     KeyCodes,
     MandUtil,    { MaxIter, MSet, JSet }
     BoundRgn,
     GRGetFld,
     VideoEGA,  { links to EGA/VGA driver }
     StrUtil;

CONST
  DisplayMode = VGAMed;
  DefaultColorDivisor = 1;
  SaveName = 'D:Mandel.ega';
  PaletteFile = 'c:\dl\fractal\sine16.map';

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
  temp,
  aspect     : FLOAT;
  p_real, q_img,
  XMin,
  YMax       : FLOAT;
  JULIA,
  StyleContour,
  QUIT,
  StopRender : BOOLEAN;
  ColorTable : ARRAY[0..LimitIter] OF WORD;
  image : POINTER;

  { some "on the fly" constants }
  side,
  Delta   : FLOAT;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION Abort : BOOLEAN;

BEGIN
  IF KeyPressed THEN
        Abort := ((ReadKey = CHAR(Break)) OR (ReadKey = CHAR(ESC)))
  ELSE Abort := FALSE;
END; { Abort }
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
PROCEDURE FreshScreen;
BEGIN
  ClearViewPort;
  SetFillStyle(SolidFill,9);
  SetColor(Blue);
  Rectangle(0,0,GetMaxX,GetMaxY);
  FloodFill(10,10,Blue);
END {FreshScreen};

{ ---------------------------------------------------------------}
PROCEDURE AssignPalette;
VAR
  i,red,green,blue,err : INTEGER;
  redB,greenB,blueB     : BYTE;
  infile : TEXT;
  instr : STRING;

BEGIN
  assign(infile,PaletteFile);
  reset(infile);
  readln(infile);
  i := 0;
  WHILE NOT eof(infile) DO
  BEGIN
    readln(infile,instr);
    val(compress(copy(instr,1,9),' '),red,err);
    val(compress(copy(instr,9,9),' '),green,err);
    val(compress(copy(instr,18,9),' '),blue,err);
    SetRGBPalette(i,red,green,blue);
    GetRGBPalette(i,redb,greenb,blueB);
    inc(i);
  END;
  Close(infile);
END;
{ ---------------------------------------------------------------}
PROCEDURE SetColors;

{ logarithmic color scale }
VAR
  LnIterRng : FLOAT;
  ClrRng,
  StartBiClr,
  i : WORD;

BEGIN
  (* set palette *)
{  GrayScale;    }
  AssignPalette;
  StartBiClr := 16;

  (* set color lookup table *)
  ColorTable[0] := 0;
  LnIterRng := ln(MaxIter - StartBiClr);
  ClrRng := MaxColor - 2;

  ColorTable[MaxIter] := 0;
  FOR i := StartBiClr+1 TO MaxIter-1  DO
    ColorTable[i] := Trunc(ln(i - StartBiClr) / LnIterRng * ClrRng) + 2;

  FOR i := 1  TO StartBiClr  DO
    ColorTable[i] := i mod 2;
END;

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
            escape :=  JSet(cx,cy,p_real,q_img)
         ELSE
            escape :=  JSetBD(cx,cy,p_real,q_img)
       ELSE
         IF StyleContour THEN
            escape := MSet(cx,cy)
         ELSE
            escape :=  MSetBD(cx,cy);

       PutPixel(x,y1,ColorTable[escape]);
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
         IF StyleContour THEN
            escape :=  JSet(cx,cy,p_real,q_img)
         ELSE
            escape :=  JSetBD(cx,cy,p_real,q_img)
       ELSE
         IF StyleContour THEN
            escape := MSet(cx,cy)
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
   StopRender := FALSE;
   FreshScreen;
   MSetLine(0,0,XWidth,0);
   MSetLine(0,YWidth,XWidth,YWidth);
   MSetLine(0,0,0,YWidth);
   MSetLine(XWidth,0,XWidth,YWidth);

   MSetRect(0,0,XWidth,YWidth);

END; { FastM }

(* --------------------------------------------------------- *)
PROCEDURE Zoom;
BEGIN
    Finish;
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
  Writeln('usage: MANDSQR XMin YMax Side Iterations ColorDivisor julia p_real q');
END;

{ ---------------------------------------------------------------}
PROCEDURE UseDefaults;
BEGIN
  Xmin := -2.0;  {-2.0}
  YMax := 1.2;  {1.2}
  side := 2.4;
  delta := side / min(XWidth,YWidth); { fractal units per pixel }
  MaxIter := 100;
  ColorDiv := DefaultColorDivisor;
  JULIA := FALSE;
  p_real := 1.0;  {-1.5 san marco}
  q_img := 1.0;
  StyleContour := TRUE;
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
  IF code > 0 THEN p_real := -1.5;
  val(paramstr(7),p_real,code);
  IF code > 0 THEN p_real := -1.5;
  val(paramstr(8),q_img,code);
  IF code > 0 THEN q_img := 0.0;

END;

{ -------------------------------------------------------------- }
PROCEDURE SaveTopLine(VAR ptr : POINTER);
Var
 size : WORD;
BEGIN
   IF ptr = NIL THEN  { we haven't already gotten the memory }
   BEGIN
      size := ImageSize(0,0,GetMaxX,10);
      IF MaxAvail < size THEN
      BEGIN
        CloseGraph;
        WriteLn('Cannot allocate heap');
        HALT(2);
      END
      ELSE
        GetMem(ptr,size);
   END;
   GetImage(0,0,GetMaxX,10,ptr^);
END;

{ -------------------------------------------------------------- }
PROCEDURE RestoreTopLine(VAR ptr : POINTER);
BEGIN
   IF ptr <> NIL THEN
       PutImage(0,0,ptr^,NormalPut);
END;

{ -------------------------------------------------------------- }
PROCEDURE ShowMenu(it1,it2,it3,it4,it5 : STRING);
BEGIN
  SetFillStyle(SolidFill,Blue);
  Bar(0,0,GetMaxX,10);
  SetColor(White);
  OutTextXY(0,0,it1 + ' ' + it2 + ' ' + it3+ ' ' + it4+ ' ' + it5);
END;

{ -------------------------------------------------------------- }
PROCEDURE ShowInitPrompt;
BEGIN
  SetFillStyle(SolidFill,Blue);
  Bar(0,0,GetMaxX,10);
  SetColor(White);
  OutTextXY(0,0,'Type "/" for Menu');
END;

{ -------------------------------------------------------------- }
PROCEDURE Prompt(PromptString : String; VAR num : FLOAT);
CONST
  decimals = 5;

VAR
  tempstr : string;
  width,
  code    : integer;
  tempnum : FLOAT;

BEGIN
  { figure out number of places to left of decimal point }
  IF abs(num) > 0 THEN
      width := TRUNC(ln(abs(num))/ln10) + 1 + decimals
  ELSE
      width := 2 + decimals;

  { make room for minus sign }
  IF num < 0 then INC(width);
  SetFillStyle(SolidFill,Blue);
  Bar(0,0,GetMaxX,10);
  OutTextXY(0,0,PromptString + ' ');
  str(num:width:decimals,tempstr);
  GetString(Length(PromptString + ' '),0,White,Black,20,0,
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
  width,
  tempnum,
  code     : integer;

BEGIN
  { figure out number of places to left of decimal point }
  width := TRUNC(ln(abs(num))/ln(10));
  { make room for minus sign }
  IF num < 0 then INC(width);
  SetFillStyle(SolidFill,Blue);
  Bar(0,0,GetMaxX,10);
  OutTextXY(0,0,PromptString + ' ');
  str(num:width,tempstr);
  GetString(Length(PromptString + '  '),0,White,Black,20,0,
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
  item := 0;
  REPEAT
    ShowMenu('XMin','YMax','Side','MaxIter','Color_Divisor');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
      'X' : BEGIN
              Prompt('Minimum X:',Xmin);
            END;
      'Y' : BEGIN
              Prompt('Maximum Y:',YMax);
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
  UNTIL (item = ESC);
END {GetParams3};

{ -------------------------------------------------------------- }
PROCEDURE GetParamsJ;
VAR
  item : INTEGER;
BEGIN
    item := 0;
    Julia := TRUE;
    REPEAT
       ShowMenu('p(real)','q(imaginary)','','','');
       Item := GetKey;
       IF Item < 255 THEN
       CASE upcase(chr(Item)) OF
         'P' : BEGIN
              Prompt('p_(real):',p_real);
            END;
         'Q' : BEGIN
                 Prompt('q_(imaginary):',q_img);
               END;
        END;
    UNTIL (Item = ESC);
END {GetParamsJ};

{ -------------------------------------------------------------- }
PROCEDURE GetParamsStyle;
VAR
  item : INTEGER;
BEGIN
    ShowMenu('Contour','Binary_Decomposition','','','');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
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
    CASE upcase(chr(Item)) OF
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

BEGIN
  IF (GetKey = ord('/')) THEN
  BEGIN
    ShowMenu('File','Draw','Control','Palette','Quit');
    Item := GetKey;
    IF Item < 255 THEN
    CASE upcase(chr(Item)) OF
      'F' : BEGIN { result := WriteEGAScreen(SaveName); } END;
      'D' : BEGIN FastM; SaveTopLine(image); END;
      'C' : BEGIN GetParams2 END;
      'P' : BEGIN PaletteControl END;
      'Q' : BEGIN Quit := TRUE END;
    END;
    IF (image <> NIL) THEN RestoreTopLine(image);
  END;
END {ProcessKeyPress};

{ ---------------------------------------------------------------}
{$F+} PROCEDURE CleanUp; {$F-}
VAR
   i : WORD;

BEGIN
   CloseGraph;
   IF image <> NIL THEN
   BEGIN
     FreeMem(image,ImageSize(0,0,GetMaxX,10));
     image := NIL;
   END;

   ExitProc := ExitSave;

END; { CleanUp }
{ ---------------------------------------------------------------}
BEGIN
  { Exit Procedures }

  ExitSave := ExitProc;
  ExitProc := @CleanUp;

  CheckBreak := FALSE;
  StopRender := FALSE;
  image := NIL;
  QUIT := FALSE;
  GRGetFld.SetUp_Field(White,White,Black,Black,#219);
  OpenGraph;
  IF paramcount > 1 THEN
     GetParams
  ELSE
     UseDefaults;
  SetColors;
  FreshScreen;
  ShowInitPrompt;
  SaveTopLine(image);
  REPEAT
    IF KeyPressed THEN
         ProcessKeyPress;
  UNTIL QUIT;
  CloseGraph;
  Writeln(MSetHit:6,MSetNoHit:6,sumiter/MsetHit:6:0);

END.

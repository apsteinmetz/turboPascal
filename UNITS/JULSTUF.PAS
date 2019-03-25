unit JULSTUF;

interface

{$I FLOAT.INC }
{$I TEXTMODE.INC }

uses CRT,
     MathLib0, KeyCodes, Graph, GRGetFld,
     TextDisp, {WriteT}
     StopWtch;

CONST
   FieldQuant = 10;

TYPE
   InputParamRec = RECORD
        Xmin, Xmax,
        Ymin, Ymax              : FLOAT;
        M,   { assume infinite attractor if (x^2)(y^2) > M}
        K    { iterations }     : INTEGER;
        p, q { c = p + qi }     : FLOAT;
        Hpoints,
        Vpoints  {points to render} : INTEGER;
        ColorDivisor : INTEGER;

   END;

   PrmStrArray = ARRAY[0..FieldQuant] OF String;

   ActionType = (Render,Compute,Quit,SwapScreen);

FUNCTION Abort : BOOLEAN;

PROCEDURE SetupScreen;

PROCEDURE InitFields(VAR PrmStr : PrmStrArray);

FUNCTION GetInput( VAR Prm : InputParamRec;
                   VAR PrmStr : PrmStrArray) : ActionType;


PROCEDURE OpenGraph(VAR GraphMode : INTEGER;
                   VAR MoreThanOnePage : BOOLEAN);

PROCEDURE AltView;

PROCEDURE WaitForExit;

implementation

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
  t  : String;

BEGIN

  Str(SplitTime:5:2,t);
  WriteT(30,1,'Elapsed Time '+t+' PRESS <Enter> TO EXIT');
  Readln;
END; {Wait for Exit}


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE AltView;

VAR
  ch : CHAR;

BEGIN
  SetActivePage(1);
  SetVisualPage(1);
  ch := ReadKey;
  SetActivePage(0);
  SetVisualPage(0);
END;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE SetupScreen;
BEGIN
{$IFDEF TEXTMODE}
  ClrScr;
  Textmode(CO80);
  OpenWindow(1,1,79,24,red,white,error);
{$ELSE}
  ClearViewPort;
  SetBkColor(White);
  SetPalette(1,Blue);
  SetPalette(2,Green);
  SetPalette(3,Red);
  SetColor(Red);
{$ENDIF}
  WriteT(2,1,'JULIA SET GENERATOR');
  WriteT(10,3,'X,Y Range of -1.5 to 1.5 is plenty');
  WriteT(10,4,'If Min`s and Max`s are not equal rendering time will double.');
  WriteT(20,10,'Plot points will not exceed screen resolution Use "MAX".');
  WriteT(20,16,'c := p + qi.  Choose p and q between -1.0 and 1.0.');

  WriteT(2,22,'<Esc> to quit.  <F10> to draw.  <Ctrl>C quits drawing.');
  WriteT(2,23,'<F9> to toggle to screen with previous image (EGA,VGA only).');

{$IFDEF TEXTMODE}
  TextColor(Blue);
{$ELSE}
  SetColor(Blue);
{$ENDIF}

END;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE InitFields(VAR PrmStr : PrmStrArray);
VAR
  i : WORD;

BEGIN
  SetupScreen;
{$IFDEF TEXTMODE}
  SetUp_Field(White,Red,Green,0,' ');
{$ELSE}
  SetUp_Field(White,Red,Green,White,#219);
{$ENDIF}
  AddExitKey(F10);
  AddExitKey(F9);

  { insert default values }
  FOR i := 0 TO FieldQuant DO PrmStr[i] := '';
  PrmStr[0] := '-1.5';
  PrmStr[1] := '1.5';
  PrmStr[2] := '-1.5';
  PrmStr[3] := '1.5';
  PrmStr[4] := '100';
  PrmStr[5] := '200';
  PrmStr[6] := '50';
  PrmStr[7] := '50';
  PrmStr[8] := '0.50';
  PrmStr[9] := '0.50';
  PrmStr[10] := '1';

  Field_Str(10, 6,6,2,'Min X',PrmStr[0],'N',NOBOX,LEFT);
  Field_Str(10, 8,6,2,'Max X',PrmStr[1],'N',NOBOX,LEFT);
  Field_Str(10,10,6,2,'Min Y',PrmStr[2],'N',NOBOX,LEFT);
  Field_Str(10,12,6,2,'Max Y',PrmStr[3],'N',NOBOX,LEFT);
  Field_Str(50, 6,6,2,'Threshold (use 100)',PrmStr[4],'N',NOBOX,LEFT);
  Field_Str(50, 8,6,2,'Iterations (use 200)',PrmStr[5],'N',NOBOX,LEFT);
  Field_Str(50,12,6,2,'Plot points in X direction',PrmStr[6],'L',NOBOX,LEFT);
  Field_Str(50,14,6,2,'Plot points in Y direction',PrmStr[7],'L',NOBOX,LEFT);
  Field_Str(30,18,8,2,'p:', PrmStr[8],'N',NOBOX,LEFT);
  Field_Str(45,18,8,2,'q:',PrmStr[9],'N',NOBOX,LEFT);
  Field_Str(30,20,6,2,'Color Changes (1 = max):',PrmStr[10],'N',NOBOX,LEFT);

  DisplayFields;

END; {InitFields}

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION GetInput( VAR Prm : InputParamRec;
                   VAR PrmStr : PrmStrArray) : ActionType;


CONST
  SillyRes = 2000;  { number sure to exceed device resolution }

VAR
  errcode,
  ExitKey : INTEGER;
  done    : BOOLEAN;

BEGIN
REPEAT
  Do_Fields(ExitKey);

  done := TRUE;
  IF (ExitKey = F10) THEN
  WITH Prm DO
  BEGIN
      Val(PrmStr[0],Xmin,errcode);
      IF errcode > 0 then done := ErrorMsg('Bad Xmin');
      Val(PrmStr[1],Xmax,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Xmax');
      Val(PrmStr[2],Ymin,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Ymin');
      Val(PrmStr[3],Ymax,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Ymax');
      Val(PrmStr[4],K,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Threshold');
      Val(PrmStr[5],M,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Iterations');

      Val(PrmStr[6],Hpoints,errcode);
      IF done THEN
        IF errcode > 0 then
           IF (PrmStr[6] = 'MAX') or (PrmStr[6] = 'max') THEN
               Hpoints := SillyRes
            ELSE
               done := ErrorMsg('X Points');

      Val(PrmStr[7],Vpoints,errcode);
      IF done THEN
        IF errcode > 0 then
           IF (PrmStr[7] = 'MAX') or (PrmStr[7] = 'max') THEN
               Vpoints := SillyRes
            ELSE
               done := ErrorMsg('Y Points');

      Val(PrmStr[8],p,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad p');
      Val(PrmStr[9],q,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad q');
      Val(PrmStr[10],ColorDivisor,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Color Divisor');
   END; {with}

UNTIL done = TRUE;

CASE ExitKey OF
   F9  : GetInput := SwapScreen;
   F10 : GetInput := Render;
   ESC : GetInput := Quit;
END; {case}

END; {GetInput }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE OpenGraph(VAR GraphMode : INTEGER;
                   VAR MoreThanOnePage : BOOLEAN);

VAR
  GraphDriver, LoMode, HiMode   : INTEGER;
  done : BOOLEAN;

BEGIN
(*
  { Register all the drivers }
  if RegisterBGIdriver(@CGADriverProc) < 0 then
    done := ErrorMsg('CGA driver not found');
  if RegisterBGIdriver(@EGAVGADriverProc) < 0 then
    done := ErrorMsg('EGA/VGAdriver not found');
  if RegisterBGIdriver(@HercDriverProc) < 0 then
    done := ErrorMsg('Hercdriver not found');
  if RegisterBGIdriver(@ATTDriverProc) < 0 then
    done := ErrorMsg('AT&Tdriver not found');
  if RegisterBGIdriver(@PC3270DriverProc) < 0 then
    done := ErrorMsg('PC 3270driver not found');
*)
  { set graph mode to max res of device (does not support ATT) }
  DetectGraph(GraphDriver,HiMode);
  GetModeRange(GraphDriver,LoMode,HiMode);


  MoreThanOnePage := FALSE;

  CASE GraphDriver OF
     CGA, MCGA        : GraphMode := LoMode;
     EGAMono,HercMono : GraphMode := LoMode;
     ATT400           : GraphMode := LoMode;
     PC3270           : GraphMode := LoMode;
     EGA, EGA64, VGA  : BEGIN
                          GraphMode := HiMode  (* could be HiMode *);
                          MoreThanOnePage := (GraphMode = 1);
                        END;
  END; {CASE}

  InitGraph(GraphDriver,GraphMode,'');
  RestoreCRTMode;


END; { OpenGraph }

BEGIN
END.
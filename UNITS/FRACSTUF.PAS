unit FRACSTUF;
{ support stuff for fracland }

interface

{$I FLOAT.INC }
{$I TEXTMODE.INC }{ 40 COL flag }

uses CRT,
     Drivers,
     FracSurf,
     MathLib0, { Float }
     KeyCodes,
     Graph,
     {$IFDEF TextMode }
       GetField,
     {$ELSE}
       GRGetFld,
     {$ENDIF}
     ThreeD,
     TextDisp,
     Windows,
     StopWtch;

CONST
   FieldQuant = 6;

TYPE
   InputParamRec =  RECORD
           Algorithm   : AlgorithmType;
           DisplayType : CHAR;
           Tilt,
           Rota,
           Altitude,
           Azimuth     : INTEGER;
           Dimension   : FLOAT;
      END;

   PrmStrArray = ARRAY[0..FieldQuant] OF String;

   ActionType = (Render,Compute,Quit,SwapScreen);

PROCEDURE InitFields(VAR PrmStr : PrmStrArray);

FUNCTION GetInput( VAR Prm : InputParamRec;
                   VAR PrmStr : PrmStrArray;
                   VAR Srf : Surface ) : ActionType;

PROCEDURE InsertDefaults( VAR PrmStr : PrmStrArray);

PROCEDURE SetupScreen;

PROCEDURE OpenGraph(VAR GraphMode : INTEGER;
                   VAR MoreThanOnePage : BOOLEAN);

PROCEDURE AltView;

PROCEDURE WaitForExit;

implementation

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
PROCEDURE InsertDefaults( VAR PrmStr : PrmStrArray);
VAR
  i : WORD;

BEGIN
  { insert default values }
  FOR i := 0 TO FieldQuant DO PrmStr[i] := '';
  PrmStr[0] := 'V';
  PrmStr[1] := '1.5';
  PrmStr[2] := 'W';
  PrmStr[3] := '15';
  PrmStr[4] := '15';
  PrmStr[5] := '70';
  PrmStr[6] := '0';
END;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE SetupScreen;
VAR
  error : BYTE;

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

  WriteT(2,2,'FRACTAL LANDSCAPE GENERATOR');
  WriteT(2,10,'Display Type.');
  WriteT(2,11,'Map, Wire Frame, Shaded or Animate.');
  WriteT(25,17,'Applies to Shaded Only');
  WriteT(2,20,'<F8> to compute surface.');
  WriteT(2,21,'<Esc> to quit.  <F10> to draw.  <Ctrl>C quits drawing.');
  WriteT(2,22,'<F9> to toggle to screen with previous image (EGA,VGA only).');

{$IFDEF TEXTMODE}
  TextColor(Blue);
{$ELSE}
  SetColor(Blue);
{$ENDIF}

END;

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE InitFields(VAR PrmStr : PrmStrArray);


BEGIN
  SetupScreen;
{$IFDEF TEXTMODE}
  SetUp_Field(White,Red,Green,0,' ');
{$ELSE}
  SetUp_Field(White,Red,Green,White,#219);
{$ENDIF}
  AddExitKey(F10);
  AddExitKey(F8);
  AddExitKey(F9);
  Field_Str(40, 6,1,2,'(V)oss or (F)FC Algorithm',PrmStr[0],'L',NOBOX,LEFT);
  Field_Str(40, 8,6,2,'Fractal Dimension (0..2)',PrmStr[1],'N',NOBOX,LEFT);
  Field_Str(20,12,1,2,'(M/W/S/A)',PrmStr[2],'L',NOBOX,LEFT);
  Field_Str(20,14,3,2,'Tilt',PrmStr[3],'N',NOBOX,LEFT);
  Field_Str(20,16,3,2,'Rotation',PrmStr[4],'N',NOBOX,LEFT);
  Field_Str(40,18,3,2,'Solar Altitute',PrmStr[5],'N',NOBOX,LEFT);
  Field_Str(40,19,3,2,'Azimuth',PrmStr[6],'N',NOBOX,LEFT);

  DisplayFields;

END; {InitFields}

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION GetInput( VAR Prm : InputParamRec;
                   VAR PrmStr : PrmStrArray;
                   VAR Srf : Surface ) : ActionType;



VAR
  errcode,
  ExitKey : INTEGER;
  done    : BOOLEAN;

BEGIN
REPEAT
  Do_Fields(ExitKey);

  done := TRUE;
  IF (ExitKey = F8) OR (ExitKey = F10) THEN
   WITH Prm DO
   BEGIN
      errcode := pos('VvFf',PrmStr[0]);
      IF done THEN IF errcode > 0 then  done := ErrorMsg('V or F Only')
         ELSE
           IF upcase(PrmStr[0][1]) = 'F' THEN
                Algorithm := FFC ELSE Algorithm := Voss;
      Val(PrmStr[1],Dimension,errcode);
      IF done THEN
         IF errcode > 0 THEN done := ErrorMsg('Bad Dimension')
           { convert Fractal D to dimension used by routine }
          ELSE Dimension := 2.0 - Dimension;


      errcode := pos('MmWwSsAa',PrmStr[2]);
      IF done THEN IF errcode > 0 then  done := ErrorMsg('M,W,S, or A Only')
         ELSE  DisplayType := upcase(PrmStr[2][1]);

      Val(PrmStr[3],Tilt,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Tilt');
      Val(PrmStr[4],Rota,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Rotation');
      Val(PrmStr[5],Altitude,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Altitude');
      Val(PrmStr[6],Azimuth,errcode);
      IF done THEN IF errcode > 0 then done := ErrorMsg('Bad Azimuth');
   END; {With}
UNTIL done = TRUE;

CASE ExitKey OF
   F8  : GetInput := Compute;
   F9  : GetInput := SwapScreen;
   F10 : GetInput := Render;
   ESC : GetInput := Quit;
END; {case}

END; {GetInput }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE OpenGraph( VAR GraphMode : INTEGER;
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
                          GraphMode := 1; {could be HiMode}
                          MoreThanOnePage := (GraphMode = 1);
                        END;
  END; {CASE}

  InitGraph(GraphDriver,GraphMode,'');

  RestoreCRTMode;


END; { OpenGraph }

BEGIN
END.
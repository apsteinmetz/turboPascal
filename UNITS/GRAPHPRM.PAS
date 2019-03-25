UNIT GraphPrm;
{ Graphic Primitives from FRACTALS IN C }

{ ===========================================================}
interface
{ ===========================================================}

VAR
  DisplayWidth,
  DisplayHeight : INTEGER;

  HalfWidth,
  HalfHeight : INTEGER;

PROCEDURE SetMode(mode : BYTE);
{ set video mode }

PROCEDURE Plot(x,y,color : WORD);

PROCEDURE DrawLine(x1,y1,x2,y2,color : INTEGER);
{ on a 640x400 display with center 0,0 coordinate system}

PROCEDURE Cls(color : WORD);
{clear screen}

{ ===========================================================}
implementation
{ ===========================================================}
USES
  GRAPH
(*,  Dos {Intr, registers} *)
;

PROCEDURE SetMode(mode : BYTE);
{ set video mode }


VAR
{  regs : registers;}
  grDriver : Integer;
  grMode   : Integer;
  ErrCode  : Integer;

  begin
  IF Mode = 0 THEN
     CloseGraph
  ELSE
  BEGIN
    grDriver := Detect;
    InitGraph(grDriver,grMode,'');
    ErrCode := GraphResult;
    if ErrCode <> grOk THEN HALT;
  END;
(*
  regs.AH := 0;
  regs.AL := mode;
  Intr($10,regs);
*)
END {SetMode};

PROCEDURE Plot(x,y,color : WORD);
BEGIN
  PutPixel(x,y,color);
END {Plot};

PROCEDURE DrawLine(x1,y1,x2,y2,color : INTEGER);
BEGIN
  SetColor(color);
  x1 := HalfWidth + x1;
  x2 := HalfWidth + x2;
  y1 := HalfHeight - y1;
  y2 := HalfHeight - y2;
  Line(x1,y1,x2,y2);
END;

PROCEDURE Cls(color : WORD);
{clear screen}
BEGIN
  SetBkColor(color);
  ClearViewPort;
END {CLS};

BEGIN
  SetMode(16);
  DisplayHeight := GetMaxY;
  DisplayWidth  := GetMaxX;
  HalfWidth := DisplayWidth div 2;
  HalfHeight := DisplayHeight div 2;

  CloseGraph;
END {GraphPrm}.


UNIT MAXRES;
{ intitialize ATT Hi-Res graphic routines }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
interface
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

uses
   Graph;

PROCEDURE InitATTGraph;
FUNCTION InitNormGraph : BOOLEAN;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
implementation
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

var GraphDriver, GraphMode, ErrorCode : integer;

PROCEDURE InitATTGraph;

begin
  GraphDriver := ATT400;
  GraphMode   := ATT400HI;
  InitGraph(GraphDriver,GraphMode,'');
end;

FUNCTION InitNormGraph : BOOLEAN;

begin
  GraphDriver := Detect;
  InitGraph(GraphDriver,GraphMode,'');
  ErrorCode := GraphResult;
  IF ErrorCode = GrOK THEN
    InitNormGraph := TRUE
  ELSE
    InitNormGraph := FALSE;

end;

begin
end.
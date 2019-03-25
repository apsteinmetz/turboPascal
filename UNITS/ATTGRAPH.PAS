UNIT ATTGRAPH;
{ intitialize ATT Hi-Res graphic routines }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
interface
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

uses
   Graph;

PROCEDURE InitATTGraph;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
implementation
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

PROCEDURE InitATTGraph;
var GraphDriver, GraphMode : integer;

begin
  GraphDriver := ATT400;
  GraphMode   := ATT400HI;
  InitGraph(GraphDriver,GraphMode,'');
end;

begin
end.
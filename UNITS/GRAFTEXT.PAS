UNIT GrafText;
(* valid only in graphics mode *)

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
interface

uses GRAPH,
      MaxRes;

procedure WriteLine;
procedure WriteString(s : STRING);  { word wrap is on }
procedure WriteInt(int : LONGINT; minlength : INTEGER);
procedure WriteReal(r : Real; minlength, dec : INTEGER);
procedure SetBaseLine(b : INTEGER);
{ pixels between lines }

(* some graphic text routines *)
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
implementation

VAR
  BaseLine : INTEGER;

procedure WriteLine;

begin
  MoveTo(0,GetY + TextHeight('AA') + BaseLine);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure WriteString(s : STRING);

BEGIN
  if GetX + TextWidth(s) > GetMaxX then WriteLine;
  OutText(s);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure WriteInt(int : LONGINT; minlength : INTEGER);
var
  s : STRING;
BEGIN
  str(int:minlength,s);
  WriteString(s);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure WriteReal(r : Real; minlength, dec : INTEGER);
var
  s : STRING;
BEGIN
  str(r:minlength:dec,s);
  WriteString(s);
END;

procedure SetBaseLine(b : INTEGER);

BEGIN
  BaseLine := b;
END;

BEGIN
  SetBaseLine(1);
END.
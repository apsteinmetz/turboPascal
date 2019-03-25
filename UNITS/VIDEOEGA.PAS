unit VideoEGA;
interface

USES Graph;

implementation

procedure EgaVgaDriverProc; external;
{$L EGAVGA.OBJ }

BEGIN
IF RegisterBGIdriver(@EGAVGADriverProc) < 0 then
  BEGIN
      Writeln('EGA/VGA driver not found');
      HALT;
  END;
end.

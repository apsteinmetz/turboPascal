UNIT LinkBGI;
{register those graphics modes you might use}

interface

uses Graph,   { library of graphics routines }
     Drivers, { all the BGI drivers }
     Fonts;   { all the BGI fonts }

TYPE
  GraphModes = (CGA,EGAVGA,ATT,Hercules,PC3270);
  GraphModeSet = SET OF GraphModes;


PROCEDURE InstallGraphicsModes(modes : GraphModeSet);

(*================================================================== *)
implementation

var
  GraphDriver, GraphMode, Error : integer;


procedure Abort(Msg : string);
begin
  Writeln(Msg, ': ', GraphErrorMsg(GraphResult));
  Halt(1);
end;


PROCEDURE InstallGraphicsModes(modes : GraphModeSet);

begin
  { Register all the drivers }
  IF CGA IN modes THEN
    if RegisterBGIdriver(@CGADriverProc) < 0 then
      Abort('CGA');
  IF EGAVGA IN modes THEN
    if RegisterBGIdriver(@EGAVGADriverProc) < 0 then
      Abort('EGA/VGA');
  IF Hercules IN modes THEN
    if RegisterBGIdriver(@HercDriverProc) < 0 then
      Abort('Herc');
  IF ATT IN modes THEN
    if RegisterBGIdriver(@ATTDriverProc) < 0 then
      Abort('AT&T');
  IF PC3270 IN modes THEN
    if RegisterBGIdriver(@PC3270DriverProc) < 0 then
      Abort('PC 3270');
END;

end.

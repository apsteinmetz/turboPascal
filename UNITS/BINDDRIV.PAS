UNIT BindDriv;

interface
uses Graph, Drivers;

implementation

PROCEDURE ErrorMsg(msg : string);
BEGIN
  Writeln(msg);
END;

BEGIN
  { Register all the drivers }
  if RegisterBGIdriver(@CGADriverProc) < 0 then
    ErrorMsg('CGA driver not found');
  if RegisterBGIdriver(@EGAVGADriverProc) < 0 then
    ErrorMsg('EGA/VGAdriver not found');
  if RegisterBGIdriver(@HercDriverProc) < 0 then
    ErrorMsg('Hercdriver not found');
  if RegisterBGIdriver(@ATTDriverProc) < 0 then
    ErrorMsg('AT&Tdriver not found');
  if RegisterBGIdriver(@PC3270DriverProc) < 0 then
    ErrorMsg('PC 3270driver not found');
END {BINDRIV}.

UNIT SaveScrn;
{saves and restores a text screen}
interface

uses CRT, DOS;

PROCEDURE SaveScreen;

PROCEDURE RestoreScreen;

implementation

TYPE
 ScrnBlock = ARRAY[1..2000] of Integer;

VAR
  Screen     : ^ScrnBlock;
  ScreenData : ScrnBlock;
  I          : Byte;
  Regs       : Registers;

PROCEDURE SaveScreen;
BEGIN
  Intr($11,Regs);
  IF (Lo(Regs.AX) AND $30) = $30 THEN
    Screen := Ptr($B000,0)
  ELSE
    Screen := Ptr($B800,0);
  ScreenData := Screen^;
End;

PROCEDURE RestoreScreen;
BEGIN
  Screen^ := ScreenData;
END;

BEGIN
END.
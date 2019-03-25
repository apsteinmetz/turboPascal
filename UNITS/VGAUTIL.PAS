(*
#: 158462 S2/Turbo Pascal v.5
    02-Feb-89  12:31:53
Sb: #158453-SetRGBPalette
Fm: John Sieraski (Sysop) 76117,2022
To: Art Steinmetz 76044,3204

Art,
  Here's a few routines for reading and setting the DAC registers on MCGA
and VGA cards.  All of this information can be found in the book
"Programmer's Guide to IBM PC & PS/2 Video Systems" by Richard Wilton.
*)

UNIT VgaUtil;
interface

uses
  Dos;
type
  RGBColor   = record
                 Red, Green, Blue : byte;
               end;
  VGAPalette = array[0..255] of RGBColor;
var
  VGAPal : VGAPalette; { Stores entire DAC block }
  RGBVal : RGBColor;   { Stores single DAC register }

procedure ReadSingleDAC(DACNum : byte; var RGBVal : RGBColor);

procedure SetSingleDAC(DACNum : byte; RGBVal : RGBColor);

procedure ReadDACBlock(Start, Count : integer; var VGAPal : VGAPalette);

procedure SetDACBlock(Start, Count : integer; var VGAPal : VGAPalette);

(* ============================================================= *)
implementation

procedure ReadSingleDAC(DACNum : byte; var RGBVal : RGBColor);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10; AL := $15;
    BX := DACNum;
    Intr($10, Regs);
    with RGBVal do
    begin
      Red := DH; Green := CH; Blue := CL;
    end;
  end;
end;

(* +++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
procedure SetSingleDAC(DACNum : byte; RGBVal : RGBColor);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10; AL := $10;
    BX := DACNum;
    with RGBVal do
    begin
      DH := Red; CH := Green; CL := Blue;
    end;
    Intr($10, Regs);
  end;
end;

(* +++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
procedure ReadDACBlock(Start, Count : integer; var VGAPal : VGAPalette);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10; AL := $17;
    BX := Start;
    CX := Count;
    ES := Seg(VGAPal);
    DX := Ofs(VGAPal);
  end;
  Intr($10, Regs);
end;

(* +++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
procedure SetDACBlock(Start, Count : integer; var VGAPal : VGAPalette);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10; AL := $12;
    BX := Start;
    CX := Count;
    ES := Seg(VGAPal);
    DX := Ofs(VGAPal);
  end;
  Intr($10, Regs);
end;

BEGIN
END {VgaUtil}.
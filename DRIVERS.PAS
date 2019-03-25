
{ Copyright (c) 1985, 1989 by Borland International, Inc. }

unit Drivers;
{ Sample unit to accompany BGILINK.PAS. This unit links the BGI graphics
  driver into a single TPU file. This makes it easy to link the driver files
  directly into an .EXE file. See BGILINK.PAS for more information.
}
interface
(*
procedure ATTDriverProc;
procedure CgaDriverProc;
procedure HercDriverProc;
procedure PC3270DriverProc;
*)
procedure EgaVgaDriverProc;

implementation
(*
procedure ATTDriverProc; external;
{$L ATT.OBJ }

procedure CgaDriverProc; external;
{$L CGA.OBJ }

procedure HercDriverProc; external;
{$L HERC.OBJ }

procedure PC3270DriverProc; external;
{$L PC3270.OBJ }
*)
procedure EgaVgaDriverProc; external;
{$L EGAVGA.OBJ }
end.

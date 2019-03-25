unit EGASave;
(*
------------------------------------------------------------------
 This unit provides all of the routines necessary for saving and
 restoring EGA (640x350) 16 color graphics screens to and from
 RAM and/or a disk files.

 Author     : John Sieraski (Borland technical support)
 Last update: 11/17/88
 Ware-ness  : Released to the public domain by the author
------------------------------------------------------------------
*)


interface

const
  BitMapSize = 28000; { Size in bytes of each EGA bit plane    }
  MaxBitMaps = 4;     { Number of Bit planes in video mode $10 }
  OK         = 0;     { Signals that everything is OK }

type
  BitMapBuffer = array[1..BitMapSize] of byte;          { An EGA bit plane  }
  EGABuffer    = array[1..MaxBitMaps] of ^BitMapBuffer; { A Full EGA screen }
  Str12        = string[12];                            { For DOS filenames }
(*
procedure SaveEGAScreen(Buffer : EGABuffer);
{ Saves an EGA (640x350) 16 color graphics screen into Buffer }

procedure RestoreEGAScreen(Buffer : EGABuffer);
{ Restores an EGA (640x350) 16 color graphics screen image from Buffer }

function WriteEGAScreen(FileName : Str12) : integer;
{ Saves an EGA (640x350) 16 color graphics screen into a file }

function ReadEGAScreen(FileName : Str12) : integer;
{ Restores an EGA (640x350) 16 color graphics screen from a file }

function AllocateBuffer(var Buffer : EGABuffer) : boolean;
{ Allocates a "Buffer" variable on the Heap using GetMem }

procedure DisposeBuffer(var Buffer : EGABuffer);
{ Frees a "Buffer" variable from the Heap using FreeMem }
*)
implementation

const
  EGABase : pointer = Ptr($A000, $0000); { Base of EGA graphics memory }

  AddrReg     = $3CE; { Port address of EGA graphics 1 & 2 address register }
  SetResetReg = $3CF; { Port address of EGA Set/Reset register }
  ReadMapReg  = $04;  { Index of EGA Read Map select register }
  SeqAddrReg  = $3C4; { Port address of EGA sequencer address register }
  ResetReg    = $3C5; { Port address of EGA sequencer reset register }
  MapMaskReg  = $02;  { Index of EGA sequencer Map Mask register }

procedure EnableMapRead(Map : byte);
{ Enables reading from one of the EGA's Bit planes 1..4 }
begin
  Port[AddrReg] := ReadMapReg;
  Port[SetResetReg] := Pred(Map)
end;

procedure SaveEGAScreen(Buffer : EGABuffer);
var
  BitMap : integer;
begin
  for BitMap := 1 to MaxBitMaps do
  begin
    EnableMapRead(BitMap);
    Move(EGABase^, Buffer[BitMap]^, BitMapSize)
  end
end; { SaveEGAScreen }

function Exists(FileName : Str12) : boolean;
{ Returns true if FileName specifies a disk file that already exists }
var
  F  : file;
  OK : boolean;
begin
  if FileName = '' then  { A null filename indicates standard output }
    Exists := true
  else
    begin
      Assign(F, FileName);
      {$I-}
      Reset(F);
      {$I+}
      OK := IOResult = 0;
      if OK then
        begin
          Exists := true;
          Close(F);
        end
      else
        Exists := false;
    end;
end; { Exists }

function WriteEGAScreen(FileName : Str12) : integer;
{ Saves an EGA (640x350) 16 color graphics screen into a file }
var
  BitMap     : integer;
  ScreenFile : file;
  Result     : integer;

function IOError : boolean;
begin
  Result := IOResult;
  if Result <> 0 then
    IOError := true
  else
    IOError := false;
end;

begin
  Assign(ScreenFile, FileName);
  {$I-}
  Rewrite(ScreenFile, 1);
  {$I+}
  if IOError then
  begin
    WriteEGAScreen := Result;      { return error code }
    Exit;
  end;
  for BitMap := 1 to MaxBitMaps do
  begin
    EnableMapRead(BitMap);
    {$I-}
    BlockWrite(ScreenFile, EGABase^, BitMapSize);
    {$I+}
    if IOError then
    begin
      WriteEGAScreen := Result;    { return error code }
      Close(ScreenFile);
      Exit;
    end;
  end;
  Close(ScreenFile);
  WriteEGAScreen := OK;
end;  { WriteEGAScreen }

function MapsSelected : byte;
{ Returns the number of bit planes enabled for writing }
var
  BitMap        : integer;
  MemByte       : byte;
  EnabledPlanes : byte;
begin
  EnabledPlanes := 0;
  Port[AddrReg] := ReadMapReg;
  for BitMap := 0 to 3 do
  begin
    Port[SetResetReg] := BitMap;
    MemByte := byte(EGABase^);         { Read a dummy byte from bit plane }
    byte(EGABase^) := not(MemByte);    { Write the byte back inverted     }
    if byte(EGABase^) <> MemByte then  { This plane is selected }
    begin
      EnabledPlanes := EnabledPlanes or (1 shl BitMap);
      byte(EGABase^) := MemByte;       { Reset original byte read }
    end;
  end;
  MapsSelected := EnabledPlanes;
end; { MapsSelected }

procedure EnableMapWrite(Map : byte);
{ Enables writing to one of the EGA's Bit planes 1..4 }
begin
  Port[SeqAddrReg] := MapMaskReg;
  Port[ResetReg] := 1 shl Pred(Map);
end;

procedure RestoreEGAScreen(Buffer : EGABuffer);
var
  BitMap      : integer;
  MapsEnabled : byte;
begin
  MapsEnabled := MapsSelected; { Save originally selected write planes }
  for BitMap := 1 to MaxBitMaps do
  begin
    EnableMapWrite(BitMap);
    Move(Buffer[BitMap]^, EGABase^, BitMapSize);
  end;
  Port[ResetReg] := MapsEnabled;  { Restore originally selected write planes }
end; { RestoreEGAScreen }

function ReadEGAScreen(FileName : Str12) : integer;
{ Restores an EGA (640x350) 16 color graphics screen from a file }
var
  BitMap      : integer;
  MapsEnabled : byte;
  ScreenFile  : file;
  Result      : integer;

function IOError : boolean;
begin
  Result := IOResult;
  if Result <> 0 then
    IOError := true
  else
    IOError := false;
end;

begin
  if not Exists(FileName) then
  begin
    ReadEGAScreen := 2;      { return "file not found" error code }
    Exit;
  end;
  Assign(ScreenFile, FileName);
  {$I-}
  Reset(ScreenFile, 1);
  {$I+}
  if IOError then
  begin
    ReadEGAScreen := Result; { return error code }
    Exit;
  end;
  MapsEnabled := MapsSelected; { Save originally selected write planes }
  for BitMap := 1 to MaxBitMaps do
  begin
    EnableMapWrite(BitMap);
    {$I-}
    BlockRead(ScreenFile, EGABase^, BitMapSize);
    {$I+}
    if IOError then
    begin
      ReadEGAScreen := Result; { return error code }
      Close(ScreenFile);
      Exit;
    end;
  end;
  Close(ScreenFile);
  Port[ResetReg] := MapsEnabled;  { Restore originally selected write planes }
  ReadEGAScreen := OK;
end; { ReadEGAScreen }

function AllocateBuffer(var Buffer : EGABuffer) : boolean;
var
  BitMap : integer;
begin
  if MaxAvail >= longint(MaxBitMaps*BitMapSize) then
    begin
      for BitMap := 1 to MaxBitMaps do
        GetMem(Buffer[BitMap], BitMapSize);
      AllocateBuffer := true;
    end
  else
    AllocateBuffer := false;
end; { AllocateBuffer }

procedure DisposeBuffer(var Buffer : EGABuffer);
var
  BitMap : integer;
begin
  for BitMap := 1 to MaxBitMaps do
    if Buffer[BitMap] <> Nil then
    begin
      FreeMem(Buffer[BitMap], BitMapSize);
      Buffer[BitMap] := Nil;
    end;
end; { DisposeBuffer }

end.

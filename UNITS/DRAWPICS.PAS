{$R-,S-,I-}
unit DrawPics;
  (* A unit to load graphical pictures                    *)
  (* Formats supported :                                  *)
  (* BSAVE Pic Format                     320 x 200 x 004 *)
  (* PC/Microsoft Paintbrush .PCX files : 320 x 200 x 004 *)
  (* PC/Microsoft Paintbrush .PCX files : 640 x 350 x 016 *)
  (* PC/Microsoft Paintbrush .PCX files : 320 x 200 x 256 *)

interface

const
  PaletteExt : string[04] = '.PAL'; {palette file extension}

type
  DrawError      = (NoError, IOError, BadFormat, PaletteMissing);

var
  LastDrawMode   : Word;

function FindLastDrawMode : Word;
  { DOS call 10, 0F; Read Video Mode }
  inline($B4/$0F/                 { MOV AH, 0F  }
         $CD/$10/                 { INT 10      }
         $24/$7F/                 { AND AL, 7F  -- mask high bit set by EGA}
         $30/$E4);                { XOR AH, AH  -- pass back only AL}

procedure DrawMode(ModeNum : Word);

function DrawPic(FileName : string) : DrawError;

  (*-------------------------------------------------------------------------*)

implementation

  procedure SetDrawMode(ModeNum : Word);
    { DOS call 10, 00; Set Video Mode }
  inline($58/                     { POP AX     -- Put ModeNum in AX }
         $B4/$00/                 { MOV AH, 00 }
         $CD/$10);                { INT 10     }

  procedure DrawMode(ModeNum : Word);
  begin
    if LastDrawMode <> ModeNum then begin
      SetDrawMode(ModeNum);
      LastDrawMode := FindLastDrawMode;
    end;
  end;

  {.PA}
  function MapsSelected : Byte;
    { Returns the number of bit planes enabled for writing }
  const
    EgaBase        = $A000;       { Base address of EGA graphics memory    }
    AddrReg        = $3CE;        { Port address of EGA graphics 1 & 2 address register }
    SetResetReg    = $3CF;        { Port address of EGA Set/Reset register }
    ReadMapReg     = $04;         { Index of EGA Read Map select register }
  var
    BitMap         : Integer;
    MemByte        : Byte;
    EnabledPlanes  : Byte;
  begin
    EnabledPlanes := 0;
    Port[AddrReg] := ReadMapReg;
    for BitMap := 0 to 3 do
      begin
        Port[SetResetReg] := BitMap;
        MemByte := Mem[EgaBase:0000]; { Read a dummy byte from bit plane }
        Mem[EgaBase:0000] := not(MemByte); { Write the byte back inverted }
        if Mem[EgaBase:0000] <> MemByte then { This plane is selected }
          begin
            EnabledPlanes := EnabledPlanes or (1 shl BitMap);
            Mem[EgaBase:0000] := MemByte; { Reset original byte read }
          end;
      end;
    MapsSelected := EnabledPlanes;
  end;

  procedure WriteToEGAScreen(BitMap : Integer; Address : Pointer;
                             From : Pointer; Reps : Word);
  const
    SeqAddrReg     = $3C4;        { Port address of EGA sequencer address register }
    ResetReg       = $3C5;        { Port address of EGA sequencer reset register }
    MapMaskReg     = $02;         { Index of EGA sequencer Map Mask register }
  var
    MapsEnabled    : Byte;
  begin
    MapsEnabled := MapsSelected;  { Save originally selected write planes }

    { Enables writing to one of the EGA's Bit planes 1..4 }
    Port[SeqAddrReg] := MapMaskReg;
    Port[ResetReg] := 1 shl Pred(BitMap);
    Move(From^, Address^, Reps);

    Port[ResetReg] := MapsEnabled; { Restore originally selected write planes }
  end;

  {.PA}
  function Draw_BSAVE_Format(FileName : string) : Boolean;
  type
    PICHdr         = string[7];
  const
    Picval : PICHdr = #$FD#$00#$B8#$00#$00#$00#$40;
  var
    fp             : file;
    Picheader      : PICHdr;
    actually_read  : Integer;
    CGABuf : Byte absolute $B800 : $0000; {screen location for CGA}
  begin
    Draw_BSAVE_Format := False;
    Assign(fp, FileName);
    Reset(fp, 1);
    if IoResult <> 0 then Exit;
    Picheader[0] := #7;
    BlockRead(fp, Picheader[1], 7, actually_read);
    if Picheader = Picval then begin
      Draw_BSAVE_Format := True;
      DrawMode($04);
      BlockRead(fp, CGABuf, 16384, actually_read);
    end;
    Close(fp);
  end;

  {.PA}
const
  inbuf          = 16384;         {amount to read at a time}

type
  PCXtypes       = (idunno, cga, t320x200x256, ega);

  PCXHdr = record
             manufacturer   : Byte;
             version        : Byte;
             encode_mode    : Byte;
             bits_per_pixel : Byte;
             start_x        : Word;
             start_y        : Word;
             end_x          : Word;
             end_y          : Word;
             x_resolution   : Word;
             y_resolution   : Word;
             palette_RGB    : array[1..48] of Byte;
             vmode          : Byte; {ignored}
             planes         : Byte;
             bytes_per_line : Word;
             unused         : array[1..60] of Byte;
           end;

  BigArray       = array[0..MaxInt] of Byte;

var
  ABuf : BigArray absolute $A000 : $0000; {screen location for EGA}
  CGABuf : BigArray absolute $B800 : $0000; {screen location for CGA}
  fp             : file;
  hold           : array[1..inbuf] of Byte;
  athold         : Word;
  filebytes      : LongInt;
  header         : PCXHdr;

  {.PA}
  procedure encget(var inbyte : Byte; var Reps : Word);
  var
    actually_read  : Integer;
  begin
    Inc(athold);
    Dec(filebytes);
    if athold > inbuf then begin
      BlockRead(fp, hold, inbuf, actually_read);
      athold := 1;
    end;

    { $c0 masks first two bytes for 11xxxxxx --- $c0 = ($c0 and hold[athold])}
    if hold[athold] >= $c0 then begin
      { $3f masks last five bytes for xxx11111 }
      Reps := $3f and hold[athold];
      Inc(athold);
      Dec(filebytes);
      if athold > inbuf then begin
        BlockRead(fp, hold, inbuf, actually_read);
        athold := 1;
      end;
    end
    else
      Reps := 1;

    inbyte := hold[athold];
  end;

  {.PA}
  procedure ReadPaint(readtype : PCXtypes);
  const
    DrawAt : array[1..4] of Word = (0, 80, 160, 240);
  var
    byte_cnt       : Integer;
    ScanCount      : Word;
    ScanEven       : Boolean;
    Startat        : Word;
    Reps           : Word;
    data           : Byte;
    EGARow         : array[0..639] of Byte;
    BitPlane       : Word;

  begin
    athold := inbuf;
    byte_cnt := 0;
    ScanCount := 0;
    ScanEven := True;
    Startat := $0000;
    BitPlane := 1;

    while filebytes > 0 do begin
      encget(data, Reps);

      case readtype of
        t320x200x256 :
          begin                   {this section for 256 color 320x200}
            FillChar(ABuf[byte_cnt], Reps, data);
            Inc(byte_cnt, Reps);
          end;
        ega :
          begin                   {this section for 16 color 640x350}
            FillChar(EGARow[byte_cnt], Reps, data);
            Inc(byte_cnt, Reps);

            { see if we have filled a row; THEN write it }
            if (byte_cnt >= 320) or (filebytes = 0) then begin
              for BitPlane := 1 to 4 do
                WriteToEGAScreen(BitPlane, @ABuf[Startat], @EGARow[DrawAt[BitPlane]], 80);
              Dec(byte_cnt, 320);
              if byte_cnt > 0 then Move(EGARow[320], EGARow[0], byte_cnt);
              Inc(Startat, 80);
            end;
          end;
        cga :
          begin                   {this section for CGA}
            FillChar(CGABuf[Startat+byte_cnt], Reps, data);
            Inc(byte_cnt, Reps);

            { see if we have filled a row }
            if byte_cnt = 80 then begin
              byte_cnt := 0;
              ScanEven := not ScanEven;
              if ScanEven then begin
                Inc(ScanCount, 80);
                Startat := $0000+ScanCount;
              end
              else
                Startat := $2000+ScanCount;
            end
          end;
      end;
    end;
  end;

  {.PA}
  procedure SetPaletteBlock(SegBlock, OfsBlock : Word);
    { DOS Call 10, 10, 12 -- Set Block of Color Registers }
  inline($B8/$12/$10/             { MOV AX, $1012 }
         $BB/$00/$00/             { MOV BX, 0     -- first register to set }
         $B9/$00/$01/             { MOV CX, 256   -- # registers to set    }
         $5A/                     { POP DX        -- offset of block       }
         $07/                     { POP ES        -- segment of block      }
         $CD/$10);                { INT 10        }

  function ChangePalette256(PaletteName : string) : DrawError;
  type
    ColorType = record
                  Rvalue         : Byte;
                  Gvalue         : Byte;
                  Bvalue         : Byte;
                end;
    PaletteType    = array[0..255] of ColorType;
  var
    PalTable       : PaletteType;
    Pfile          : file of PaletteType;
    PeriodAt       : Byte;
  begin
    ChangePalette256 := NoError;
    PeriodAt := Pos('.', PaletteName);
    if PeriodAt > 0 then PaletteName[0] := Chr(Pred(PeriodAt));
    PaletteName := PaletteName+PaletteExt;
    Assign(Pfile, PaletteName);
    Reset(Pfile);
    if IoResult = 0 then begin
      Read(Pfile, PalTable);
      Close(Pfile);
      SetPaletteBlock(Seg(PalTable), Ofs(PalTable));
    end
    else ChangePalette256 := PaletteMissing;
  end;

  {.PA}
  procedure SetEGAColor(SetColor : Word);
    { DOS Call 10, 10, 00 -- Set Color Register }
  inline($B8/$00/$10/             { MOV AX, $1000 }
         $5B/                     { POP BX        -- BL: color, BH: value }
         $CD/$10);                { INT 10        }

  procedure ChangePaletteEGA;
  const
    SetBit1        = 32;
    SetBit2        = 4;
    SetBits        = 36;
  type
    BxReg = record bl : Byte; bh : Byte; end;
  var
    Count          : Byte;
    SubCount       : Word;
    S              : BxReg;
    SetColor       : Word absolute S;
  begin
    Count := 0;
    repeat
      S.bl := Count div 3;        {bl is color number 0-15}
      S.bh := 0;                  {bh is color value 0 to 63}
      {set Red (32,4), Green (16,2), or Blue (8,1)}
      for SubCount := 0 to 2 do begin
        Inc(Count);
        case header.palette_RGB[Count] of
          0 : S.bh := S.bh or 0;
          85 : S.bh := S.bh or (SetBit1 shr SubCount);
          170 : S.bh := S.bh or (SetBit2 shr SubCount);
          255 : S.bh := S.bh or (SetBits shr SubCount);
        end;
      end;
      SetEGAColor(SetColor);
    until Count = 48;
  end;

  {.PA}
  function DrawPic(FileName : string) : DrawError;
  var
    PCXtype        : PCXtypes;
    Result         : DrawError;
    actually_read  : Integer;
  begin
    DrawPic := NoError;
    Result := NoError;
    if Draw_BSAVE_Format(FileName) then Exit;

    Assign(fp, FileName);
    Reset(fp, 1);
    if IoResult <> 0 then Result := IOError;

    filebytes := FileSize(fp);

    Dec(filebytes, 128);
    BlockRead(fp, header, 128, actually_read);

    {Determine PCX type}
    PCXtype := idunno;
    if header.manufacturer = $0A then
      case header.bits_per_pixel of
        8 : PCXtype := t320x200x256;
        2 : PCXtype := cga;
        1 : PCXtype := ega;
      end;

    case PCXtype of
      idunno : Result := BadFormat;
      t320x200x256 : begin
                       DrawMode($13);
                       Result := ChangePalette256(FileName);
                     end;
      cga : DrawMode($04);
      ega : begin
              DrawMode($10);
              ChangePaletteEGA;
            end;
    end;

    if Result = NoError then ReadPaint(PCXtype);

    Close(fp);
    if IoResult <> 0 then Result := IOError;
    DrawPic := Result;
  end;

begin
  LastDrawMode := FindLastDrawMode;
end.

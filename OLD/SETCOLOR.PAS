PROGRAM SetPal;

uses graph, KeyCodes, MathLib0, DOS;

TYPE
  RGBRec = RECORD
             RedVal, GreenVal, BlueVal : INTEGER;
           END;
CONST
   MaxColors = 15;

   EGAColors : ARRAY[0..MaxColors] OF RGBRec = (
       (RedVal:$00;GreenVal:$00;BlueVal:$00),
       (RedVal:$00;GreenVal:$00;BlueVal:$FC),
       (RedVal:$24;GreenVal:$FC;BlueVal:$24),
       (RedVal:$00;GreenVal:$FC;BlueVal:$FC),

       (RedVal:$FC;GreenVal:$14;BlueVal:$14),
       (RedVal:$B0;GreenVal:$00;BlueVal:$FC),
       (RedVal:$70;GreenVal:$48;BlueVal:$00),
       (RedVal:$C4;GreenVal:$C4;BlueVal:$C4),

       (RedVal:$34;GreenVal:$34;BlueVal:$34),
       (RedVal:$00;GreenVal:$00;BlueVal:$70),
       (RedVal:$00;GreenVal:$70;BlueVal:$00),
       (RedVal:$00;GreenVal:$70;BlueVal:$70),

       (RedVal:$70;GreenVal:$00;BlueVal:$00),
       (RedVal:$70;GreenVal:$00;BlueVal:$70),
       (RedVal:$FC;GreenVal:$FC;BlueVal:$24),
       (RedVal:$FC;GreenVal:$FC;BlueVal:$FC)
);

(* ++++++++++++++++++++++++++++++++++++ *)
function Int2Str(L : LongInt) : string;
{ Converts an integer to a string for use with OutText, OutTextXY }
var
  S : string;
begin
  Str(L, S);
  Int2Str := S;
end; { Int2Str }

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE OpenGraph;
VAR
  Driver, Mode : INTEGER;

BEGIN
  Driver := VGA;
  Mode   := VGAHi;
  InitGraph(Driver,Mode,'');
END;

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE InitializePalette;
VAR
  n : WORD;
BEGIN
  FOR n := 0 TO MaxColors DO
    SetPalette(n,n+16);
END {InitializePalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE DisplayPalette(XOfs,YOfs : INTEGER);
VAR
  n : WORD;

BEGIN
  FOR n := 0 TO 15 DO
  BEGIN
    SetFillStyle(SolidFill,n);
    Bar(XOfs,YOfs+(n*20)+4,XOfs+30,YOfs+20+(n*20));
  END;
  SetLineStyle(SolidLn,0,ThickWidth);
  Rectangle(XOfs-4,YOfs-4,XOfs+34,YOfs+324);
END {DisplayPalette};

(* ++++++++++++++++++++++++++++++++++++ *)


PROCEDURE GetVGAColor(DAC : WORD; VAR RedVal, GreenVal, BlueVal : BYTE);
CONST
  VGAIntr = $00 { What is it? };

VAR
  regs: Registers;

BEGIN
  WITH regs DO
  BEGIN
    AH := $10;
    AL := $15;
    BX := DAC;
  END;
  Intr(VGAIntr,regs);
  WITH regs DO
  BEGIN
    RedVal   := DH;
    GreenVal := CH;
    BlueVal  := CL;
  END;
END {GetVGAColor};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE RestoreDefaultPalette;
VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  FOR n := 0 TO MaxColors DO
     WITH EGAColors[n] DO
        SetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);

END {RestoreDefaultPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE WriteDefaultPalette;
VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  FOR n := 0 TO MaxColors DO
     WITH EGAColors[n] DO
        Writeln(n:3,RedVal:4,GreenVal:4,BlueVal:4);

END {RestoreDefaultPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE SetPalette(XOfs,YOfs : INTEGER);
CONST
  PenColor  = 14;
  MaxColorVal    = 63;

VAR
  Key : INTEGER;
  OldEntry,
  n   : WORD;
  RedVal,
  GreenVal,
  BlueVal   : BYTE;
  palette   : PaletteType;
  ColStr    : String;

BEGIN
  GetPalette(palette);
  RedVal  := 0;
  BlueVal  := 0;
  GreenVal := 0;
  SetLineStyle(SolidLn,0,ThickWidth);
  n := 0;
  OldEntry := 0;
  SetWriteMode(XORPut);
  WHILE Key <> PgUp DO
  BEGIN
    SetColor(PenColor);
    Rectangle(XOfs-4,YOfs+(n*20)+2,XOfs+34,YOfs+22+(n*20));
    OldEntry := n;
(*
    GetVGAColor(palette.Colors[n],RedVal,BlueVal,GreenVal);
*)
    Key := GetKey;
    CASE Key OF
      DownArrow : n  := min(n + 1,15);
      UpArrow   : n  := max(n - 1, 0);
      F1  : RedVal   := min(RedVal + 1,MaxColorVal);
      F2  : RedVal   := max(RedVal - 1,0);
      F3  : GreenVal := min(GreenVal + 1,MaxColorVal);
      F4  : GreenVal := max(GreenVal - 1,0);
      F5  : BlueVal  := min(BlueVal + 1,MaxColorVal);
      F6  : BlueVal  := max(BlueVal - 1,0);
      ESC : RestoreDefaultPalette;
    END {CASE};
    Rectangle(XOfs-4,YOfs+(OldEntry*20)+2,XOfs+34,
                 YOfs+22+(OldEntry*20));
    IF (Key >= F1) AND (Key < F7) THEN
    BEGIN
       SetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
       ColStr := Int2Str(RedVal);
       SetColor(0);
       OutTextXY(XOfs-4,YOfs+326,#219+#219+#219);
       SetColor(PenColor);
       OutTextXY(XOfs-4,YOfs+326,ColStr);

       ColStr := Int2Str(GreenVal);
       SetColor(0);
       OutTextXY(XOfs-4,YOfs+336,#219+#219+#219);
       SetColor(PenColor);
       OutTextXY(XOfs-4,YOfs+336,ColStr);

       ColStr := Int2Str(BlueVal);
       SetColor(0);
       OutTextXY(XOfs-4,YOfs+346,#219+#219+#219);
       SetColor(PenColor);
       OutTextXY(XOfs-4,YOfs+346,ColStr);
    END;
  END {While};
  SetWriteMode(CopyPut);
END {SetPalette};


BEGIN
  OpenGraph;
  InitializePalette;
  DisplayPalette(40,20);
  SetPalette(40,20);
  CloseGraph;

WriteDefaultPalette;
END {SetPal}.


UNIT ColrCtrl;
(*
--------------------------------------------------------------
   Adds a pop-up palette control to any 16 color VGA program
   Allows 256K color choices.
      created: 2/2/89 by Art Steinmetz / CIS: 76044,3204
      Use at will but please leave my name in.  Thanks.

   Intructions:  Call PaletteControl while in any VGA mode.
      Up/Down arrows scroll through palette entries.
      F1/F2  Increase/Decrease Red   level.
      F3/F4  Increase/Decrease Green level.
      F5/F6  Increase/Decrease Blue  level.
      Shift-F(1..6)  Increase/Decrease Color level
          for all palette entries (useful for monitor
          color correction )
      Esc to restore original VGA colors.
      G to invoke grey scale.
      <End> to accept changes and exit.

   Change global variables XOffset and YOffset to adjust palette
      control position.
-----------------------------------------------------------------
*)

interface

USES
     Graph { Bar, GetImage, GetPalette, ImageSize, OutTextXY,
             PaletteType, PutImage, Rectangle, SetColor,
             SetFillStyle, SetLineStyle, SetRGBPalette,
             SetWriteMode }
     ,
     KeyCodes { GetKey, F1,F2,F3,F4,F5,F6,ESC, UpArrow, DownArrow}
              { SF1,SF2,SF3,SF4,SF5,SF6 }
     ,
     DOS      { Intr, Registers}
     ;

CONST
   MaxColors = 15;
TYPE
   RGBRec = RECORD
             RedVal, GreenVal, BlueVal : BYTE;
           END;

   RGBArray = ARRAY[0..MaxColors] OF RGBRec;
VAR
  XOffset,
  YOffset : INTEGER;

PROCEDURE PaletteControl;
(* see instructions above *)

PROCEDURE GetOrigPalette;
(*
  If you modify the palette outside of user control call this procedure
  so the ESC key on the palette control will cause reversion to
  that palette
*)

PROCEDURE GetRGBPalette(ColorNum : INTEGER;
                          VAR RedVal, GreenVal, BlueVal : BYTE);
(* complement of Borland's SetRGBPalette procedure *)

PROCEDURE GetVGAPalette(VAR p : RGBArray);

PROCEDURE GrayScale;
(* Change palette to levels of gray *)

PROCEDURE RestoreDefaultPalette;
(* Revert to original VGA startup colors *)

(*==========================================================*)
implementation

CONST
   PenColor  = 14;

CONST
   DefaultColors : RGBArray = (
       (RedVal: 0;GreenVal: 0;BlueVal: 0),
       (RedVal: 0;GreenVal: 0;BlueVal:42),
       (RedVal: 0;GreenVal:42;BlueVal: 0),
       (RedVal: 0;GreenVal:42;BlueVal:42),
       (RedVal:42;GreenVal: 0;BlueVal: 0),
       (RedVal:42;GreenVal: 0;BlueVal:42),
       (RedVal:42;GreenVal:21;BlueVal: 0),
       (RedVal:42;GreenVal:42;BlueVal:42),
       (RedVal:21;GreenVal:21;BlueVal:21),
       (RedVal:21;GreenVal:21;BlueVal:63),
       (RedVal:21;GreenVal:63;BlueVal:21),
       (RedVal:21;GreenVal:63;BlueVal:63),
       (RedVal:63;GreenVal:21;BlueVal:21),
       (RedVal:63;GreenVal:21;BlueVal:63),
       (RedVal:63;GreenVal:63;BlueVal:21),
       (RedVal:63;GreenVal:63;BlueVal:63)
);

   MaxColorVal = 63;
   increase  = TRUE;
   decrease  = FALSE;

TYPE
   RGBSelect = (RED, GREEN, BLUE);

VAR
  OrigImage : POINTER;
  CharHeight,
  BoxHeight,
  Size : Word;
  OrigColors : RGBArray;


(* ++++++++++++++++++++++++++++++++++++ *)
function Int2Str(L : LongInt) : string;
{ Converts an integer to a string for use with OutText, OutTextXY }
var
  S : string;
begin
  Str(L, S);
  Int2Str := S;
end; { Int2Str }

{ ---------------------------------------------------------------}
FUNCTION max(a,b : INTEGER) : INTEGER;
BEGIN
  IF a > b THEN
      max := a
  ELSE
      max := b;
END; {max}

{ ---------------------------------------------------------------}
FUNCTION min(a,b : INTEGER) : INTEGER;
BEGIN
  IF a < b THEN
      min := a
  ELSE
      min := b;
END; {max}

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE DisplayPalette;
VAR
  pal : PaletteType;
  n : WORD;

BEGIN
  GetPalette(pal);
  FOR n := 0 TO 15 DO
  BEGIN
    SetFillStyle(SolidFill,n);
    Bar(XOffset+8,YOffset+(n*BoxHeight)+2,
          XOffset+38, YOffset+trunc(BoxHeight-2)+(n*BoxHeight));
  END;
  SetLineStyle(SolidLn,0,ThickWidth);
  Rectangle(XOffset+4,YOffset,XOffset+42,YOffset+(BoxHeight*16)+(CharHeight*3)+2);
  { put in labels }
  OutTextXY(XOffset+8,YOffset+BoxHeight*16+2  ,'R:');
  OutTextXY(XOffset+8,YOffset+BoxHeight*16+CharHeight+2,'G:');
  OutTextXY(XOffset+8,YOffset+BoxHeight*16+CharHeight*2+2,'B:');
END {DisplayPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE GetRGBPalette(ColorNum : INTEGER;
                          VAR RedVal, GreenVal, BlueVal : BYTE);

CONST
  VGAIntr = $10;

VAR
  DAC : WORD;
  regs: Registers;

BEGIN
  IF (ColorNum > 255) OR (ColorNum < 0) THEN
      DAC := 0
  ELSE
     DAC := ColorNum;
  regs.AH := $10; { Get color register function call}
  regs.AL := $15; { Get color register function call}
  regs.BX := DAC; { Register to retrieve }
  Intr(VGAIntr,regs);
  RedVal   := regs.DH;
  GreenVal := regs.CH;
  BlueVal  := regs.CL;
END {GetRGBPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE GetVGAPalette(VAR p : RGBArray);
var
  n : integer;

BEGIN
  FOR n := 0 TO MaxColors DO
      GetRGBPalette(n,p[n].RedVal,p[n].GreenVal,p[n].BlueVal);
END;

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE RestoreDefaultPalette;
VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  FOR n := 0 TO MaxColors DO
     WITH DefaultColors[n] DO
        SetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
END {RestoreDefaultPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE GetOrigPalette;
VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  FOR n := 0 TO MaxColors DO
     WITH OrigColors[n] DO
        GetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
END {GetOrigPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE RestoreOrigPalette;
VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  FOR n := 0 TO MaxColors DO
     WITH OrigColors[n] DO
        SetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
END {RestoreOrigPalette};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE GrayScale;

VAR
  n : WORD;
  palette   : PaletteType;

BEGIN
   GetPalette(palette);
   FOR n := 0 TO MaxColors DO
       SetRGBPalette(palette.Colors[n],n*4,n*4,n*4);
END {GrayScale};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE ShowColorNums(RedVal, GreenVal, BlueVal : INTEGER);
CONST
  pad = #219+#219;

VAR
  ColStr    : String;

BEGIN
   ColStr := Int2Str(RedVal);
   SetColor(0);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+2,pad);
   SetColor(PenColor);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+2,ColStr);

   ColStr := Int2Str(GreenVal);
   SetColor(0);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+CharHeight+2,pad);
   SetColor(PenColor);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+CharHeight+2,ColStr);

   ColStr := Int2Str(BlueVal);
   SetColor(0);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+CharHeight*2+2,pad);
   SetColor(PenColor);
   OutTextXY(XOffset+24,YOffset+BoxHeight*16+CharHeight*2+2,ColStr);
END {ShowColorNums};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE GlobalColorChange(RGB : RGBSelect; change : INTEGER);
VAR
  n,
  RedVal,
  GreenVal,
  BlueVal   : BYTE;
  pal       : PaletteType;

BEGIN
GetPalette(pal);
FOR n := 0 TO MaxColors DO
BEGIN
    GetRGBPalette(pal.Colors[n],RedVal,GreenVal,BlueVal);
    CASE RGB OF
      RED   : RedVal   := max(0,min(RedVal  +change,MaxColorVal));
      GREEN : GreenVal := max(0,min(GreenVal+change,MaxColorVal));
      BLUE  : BlueVal  := max(0,min(BlueVal +change,MaxColorVal));
    END;
    SetRGBPalette(pal.Colors[n],RedVal,GreenVal,BlueVal);
END {FOR};
END {GlobalColorChange};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE ModifyColors;
CONST
  MaxColorVal = 63;
  Step        = 1;

VAR
  Key : INTEGER;
  OldEntry,
  n   : WORD;
  RedVal,
  GreenVal,
  BlueVal   : BYTE;
  palette   : PaletteType;

BEGIN
  GetPalette(palette);
  RedVal  := 0;
  BlueVal  := 0;
  GreenVal := 0;
  SetLineStyle(SolidLn,0,ThickWidth);
  n := 0;
  OldEntry := 0;
  SetWriteMode(XORPut);
  WHILE Key <> EndKey DO
  BEGIN
    SetColor(PenColor);
    Rectangle(XOffset+4,YOffset+(n*BoxHeight),
                XOffset+42,YOffset+BoxHeight+(n*BoxHeight));
    OldEntry := n;

    GetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
    ShowColorNums(RedVal,GreenVal,BlueVal);
    Key := GetKey;
    CASE Key OF
      DownArrow : n  := min(n + 1,15);
      UpArrow   : n  := max(n - 1, 0);
      F1  : RedVal   := min(RedVal   + Step,MaxColorVal);
      F2  : RedVal   := max(RedVal   - Step,0);
      F3  : GreenVal := min(GreenVal + Step,MaxColorVal);
      F4  : GreenVal := max(GreenVal - Step,0);
      F5  : BlueVal  := min(BlueVal  + Step,MaxColorVal);
      F6  : BlueVal  := max(BlueVal  - Step,0);
      SF1  : GlobalColorChange(Red,1);
      SF2  : GlobalColorChange(Red,-1);
      SF3  : GlobalColorChange(Green,1);
      SF4  : GlobalColorChange(Green,-1);
      SF5  : GlobalColorChange(Blue,1);
      SF6  : GlobalColorChange(Blue,-1);
      ESC : RestoreOrigPalette;
      ord('G') : GrayScale;
      ord('g') : GrayScale;
    END {CASE};
    Rectangle(XOffset+4,YOffset+(OldEntry*BoxHeight),
               XOffset+42, YOffset+BoxHeight+(OldEntry*BoxHeight));
    IF (Key >= F1) AND (Key < F7) THEN
       SetRGBPalette(palette.Colors[n],RedVal,GreenVal,BlueVal);
  END {While};
  SetWriteMode(CopyPut);
END {ModifyColors};

(* ++++++++++++++++++++++++++++++++++++ *)
PROCEDURE PaletteControl;
BEGIN
  IF GetMaxY < 300 THEN
     BoxHeight := 8
  ELSE
       IF GetMaxY < 400 THEN
           BoxHeight := 15
       ELSE
           BoxHeight := 20;
  CharHeight := round(TextHeight('X') * 1.25);
  Size := ImageSize(XOffset,YOffset-2,
                      XOffset+44,YOffset+(BoxHeight*16)+(CharHeight*3));
  IF MaxAvail >= Size THEN
  BEGIN
    GetMem(OrigImage,Size);
    GetImage(XOffset,YOffset-2,XOffset+44,YOffset+370,OrigImage^);
    DisplayPalette;
    ModifyColors;
    PutImage(XOffset,YOffset-2,OrigImage^,NormalPut);
    FreeMem(OrigImage,Size);
  END;
END {PaletteControl};

(* ++++++++++++++++++++++++++++++++++++ *)

BEGIN
  OrigColors := DefaultColors;
  XOffset := 20;
  YOffset := 20;
END {ColrCtrl}.


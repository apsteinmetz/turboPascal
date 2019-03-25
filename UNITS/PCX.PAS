unit PCX;

interface

uses graph, ColrCtrl;


procedure SaveScreen(x1, y1, x2, y2 : INTEGER; FileName : String);

(*================================================== *)
implementation

CONST
   ColorOrMono : INTEGER = 1;
   GrayScale   : INTEGER = 2;


TYPE
  ModeType = (ModeDetect, Mono, CGA, EGA, VGA);
  filetype     = TEXT;
  Chr2 = ARRAY[0..1] OF BYTE;

{ --------------------------------------------------------------- }
PROCEDURE WriteInt(VAR pic : filetype; num : INTEGER);
{ write a 2-byte integer in a file of char}

BEGIN
  write(pic,Chr2(Num)[0]);
  write(pic,Chr2(Num)[1]);
END {WriteInt};

{ --------------------------------------------------------------- }
PROCEDURE WriteHeader(VAR pic: filetype);

BEGIN
  write(pic,$0a);
  write(pic,$05);
  write(pic,$01);
  write(pic,$04);

END {WriteHeader};
{ --------------------------------------------------------------- }
PROCEDURE WritePalette(VAR pic: filetype; GMode : ModeType);

VAR
  pal : RGBArray;
  N : INTEGER;

BEGIN
  GetVGAPalette(pal);
  FOR n := 0 TO 16 DO
  BEGIN
    write(pic,pal[n].RedVal*4);
    write(pic,pal[n].GreenVal*4);
    write(pic,pal[n].BlueVal*4);
  END;

END {};
{ --------------------------------------------------------------- }
PROCEDURE   WriteData(VAR pic: filetype);
BEGIN
END {};
{ --------------------------------------------------------------- }
procedure SaveScreen(x1, y1, x2, y2 : INTEGER; FileName : String);

CONST
  BitPlanes = $04;

var
   pic : filetype;
   Palette : array[0..15] OF BYTE;
   ch, ch1, old_ch  : BYTE;
   red, green, blue : BYTE;
   n,
   startline, endline,
   BytesPerLine,
   endcount               : INTEGER;

begin
   assign(pic,FileName);
   rewrite(pic);

   WriteHeader(pic);

   { screen coords }
   WriteInt(pic,x1);
   WriteInt(pic,y1);
   WriteInt(pic,x2);
   WriteInt(pic,y2);
   WriteInt(pic,Graph.GetMaxX);
   WriteInt(pic,Graph.GetMaxy);

   WritePalette(pic,ModeDetect);

  { other picture data }
  write(pic,$00); { reserved }
  write(pic,$04); { number of bit planes }
  startline := X1 DIV 8;
  endline   := X2 DIV 8 + 1;
  BytesPerLine := endline - startline;
  endcount := startline + BytesPerLine * 4 + 1;
  writeInt(pic,BytesPerLine);
  writeInt(pic,ColorOrMono);

  { pad to end of header block }
  FOR n := 70 to 127 DO
    write(pic,$00);

   WriteData(pic);
END;

BEGIN
END.
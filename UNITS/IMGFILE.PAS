unit ImgFile;

interface

uses Graph;

TYPE
     ImgData = ARRAY[0..$8888] OF BYTE;
     ImgRec = RECORD
                 ImgPtr      : ^ImgData;
                 LastColor   : BYTE;
                 Location    : WORD;
                 RunCount    : SHORTINT;
                 InRepeat    : BOOLEAN;
               END;

PROCEDURE StartImage( VAR img : ImgRec; rows, cols : WORD);

PROCEDURE AddToImage (VAR img : ImgRec; Color : BYTE);
{ simple byte run encoding }

PROCEDURE SaveImage(filename : string; img : ImgRec);

PROCEDURE RetrieveImage(filename : string; VAR img : ImgRec);

PROCEDURE DisplayImage(img : ImgRec);

implementation

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE StartImage( VAR img : ImgRec; rows, cols : WORD);

BEGIN
  WITH img DO
  BEGIN
    ImgPtr^[0] := rows;
    ImgPtr^[1] := cols;
    Location := 2;
    InRepeat := FALSE;
    RunCount := 0;
    LastColor := 0;
  END;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE AddToImage (VAR img : ImgRec; Color : BYTE);
{ simple byte run encoding }

VAR
  Offset : WORD;
  InRepeat : BOOLEAN;

BEGIN
WITH Img DO
BEGIN
   IF (Color = LastColor) THEN
      IF InREPEAT THEN
        INC(RunCount)
      ELSE  BEGIN
      { end literal copy, start repeat }
        ImgPtr^[Location] := RunCount; { put run count into img array }
        {adding 1 to Runcount before div ensures BYTE alignment}
        INC(Location,1 + (RunCount+1) div 2);
        RunCount := 0;
        InRepeat := True;
      END
   ELSE
     IF InREPEAT THEN BEGIN
     {stop repeat, start literal copy}
        ImgPtr^[Location]     := -RunCount;  {neg run is a repeat }
        ImgPtr^[Location + 1] := LastColor; { put repeat color into array }
        INC(Location,2);
        RunCount := 0;
        InRepeat := FALSE; END
     ELSE BEGIN
        Offset := Location + (RunCount div 2);
        { just another color }
        IF RunCount MOD 2 = 0 THEN
           ImgPtr^[Offset] := Color shl 4
        ELSE
           ImgPtr^[Offset] := ImgPtr^[Offset] OR Color;
        INC(RunCount);
     END;
   LastColor := Color;
END; {With }
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE SaveImage(filename : string; img : ImgRec);
VAR
  n : LONGINT;
  Outfile : FILE OF BYTE;

BEGIN
  Assign(outfile,filename);
  Rewrite(outfile);
  FOR n := 0 TO img.Location DO
      Write(outfile,img.ImgPtr^[n]);
  Close(outfile);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE RetrieveImage(filename : string; VAR img : ImgRec);
VAR
  infile : FILE OF BYTE;

BEGIN
  Assign(infile,filename);
  Reset(infile);
  img.Location := 0;
  WHILE NOT EOF(infile) DO
  BEGIN
      Read(infile,img.ImgPtr^[img.Location]);
      INC(img.Location);
  END;
  Close(infile);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE DisplayImage(img : ImgRec);

VAR
  Color,   HighLocation, n,
  rows, cols, x,y : WORD;

    PROCEDURE DoPixel;
    BEGIN
       PutPixel(x,y,color);
       INC(x);
       IF x > cols THEN
       BEGIN
         INC(y);
         x := 0;
       END;
    END; { DoPixel }

BEGIN   {displayimage}
  WITH img DO
  BEGIN
     rows := imgptr^[0];
     cols := imgptr^[1];
     x := 0;
     y := 0;
     HighLocation := Location;
     Location := 2;
     REPEAT
       RunCount := imgptr^[Location];
       IF RunCount < 0 THEN {repeat} BEGIN
          color := imgptr^[Location + 1];
          FOR n := 0 to -RunCount - 1 DO DoPixel;
          INC(Location,2); END
       ELSE BEGIN
          INC(Location);
          FOR n := 0 to RunCount - 1 DO
          BEGIN
            IF n MOD 2 = 0 THEN
                Color := imgptr^[Location + n div 2] shr 4
            ELSE
                Color := imgptr^[Location + n div 2] AND $FF;
            DoPixel;
          END;
       END;
     UNTIL Location > HighLocation
 END; { with }
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
BEGIN
END.
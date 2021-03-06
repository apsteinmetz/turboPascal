UNIT BOUNDRGN;

interface

uses GRAPH,
     CRT,       { KeyPressed }
     KeyCodes,
     MathLib0;  {max, min}


PROCEDURE BoundRegion( VAR x1 : INTEGER;
                     VAR y1 : INTEGER;
                     VAR Side : INTEGER;
                     color : INTEGER);

implementation

(*
{ ---------------------------------------------------------------}
PROCEDURE OpenGraph;
VAR
   ErrorCode,
   GraphDriver, GraphMode : INTEGER;

Begin
   GraphDriver := VGA   { ATT400 };
   GraphMode   := VGAHi { ATT400HI };
   InitGraph(GraphDriver,GraphMode,'');
   ErrorCode := GraphResult;             { preserve error return }
   if ErrorCode <> grOK then             { error? }
      Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
   SetColor(Blue);
end;
*)
{ ---------------------------------------------------------------}

PROCEDURE BoundRegion( VAR x1 : INTEGER;
                     VAR y1 : INTEGER;
                     VAR Side : INTEGER;
                     color : INTEGER);
CONST
   YSide = 10;
   Incr = 10;

VAR
   X2, Y2,
   XSide,
   OrigColor,
   Key,
   RegionSize : INTEGER;
   Aspect     : REAL;
   Img        : POINTER;

{ returns location of crosshair when enter is pressed }

BEGIN
   OrigColor := GetColor;
   SetColor(color);
   Aspect := GetMaxX / GetMaxY;

   X1 := GetMaxX div 2;
   Y1 := GetMaxY div 2;
   XSide := trunc(YSide * Aspect);
   RegionSize := ImageSize( X1,Y1, X2 , Y2);
   { locate the upper left corner }
   GetMem(Img,RegionSize);
   REPEAT
      X2 :=  X1 + trunc(YSide * Aspect);
      Y2 :=  Y1 + YSide;
      GetImage(X1, Y1, X2, Y2, Img^);
      Rectangle(X1, Y1, X2, Y2);
      REPEAT UNTIL KeyPressed;  { busy wait }
      Key := GetKey;
      { restore old image }
      PutImage(X1,Y1,Img^,CopyPut);
      CASE Key OF
         UpArrow    :  Y1 := max( 0, Y1 - Incr);
         DownArrow  :  Y1 := min( Y1+Incr, GetMaxY );
         LeftArrow  :  X1 := max( 0, X1 - Incr);
         RightArrow :  X1 := min( X1+Incr, GetMaxX );
      END;  { else do nothing }
   UNTIL Key = Enter;
   { put rectangle back for next operation }
   Rectangle(X1, Y1, X2, Y2);
   FreeMem(Img, RegionSize);
   SetWriteMode(XORPut);
   REPEAT
      REPEAT UNTIL KeyPressed;  { busy wait }
      { erase old image via XOR }
      Rectangle(X1,Y1,X2,Y2);
      Key := GetKey;
      CASE Key OF
         UpArrow    :  Y2 := max( Y1+Yside, Y2 - Incr);
         DownArrow  :  Y2 := min( Y2+Incr, GetMaxY );
         LeftArrow  :  X2 := max( X1+XSide, X2 - Incr);
         RightArrow :  X2 := min( X2+Incr, GetMaxX );
      END;  { else do nothing }

      { ensure marked area equals screen aspect ratio }
      IF (Key = UpArrow) OR (Key = DownArrow) THEN
           X2 := X1 + round((Y2-Y1)* Aspect)
       ELSE
           Y2 := Y1 + round((X2-X1) / Aspect);

      { redraw }
      Rectangle(X1,Y1,X2,Y2);
   UNTIL Key = Enter;

   {routine is done so erase via XOR }
   Rectangle(X1,Y1,X2,Y2);
   { restore draw mode }
   SetWriteMode(XORPut);
   { restore color }
   SetColor(OrigColor); {restore original color}

   { return YSIDE value }
   Side := Y2 - Y1;
  END; { BoundRegion }

BEGIN
END.
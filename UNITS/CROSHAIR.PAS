
uses GRAPH,
     CRT,       { KeyPressed }
     KeyCodes,
     MathLib0;  {max, min}

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
{ ---------------------------------------------------------------}

PROCEDURE BoundRegion( VAR x1 : INTEGER;
                     VAR y1 : INTEGER;
                     VAR Side : INTEGER;
                     color : INTEGER);
CONST
   YSide = 10;
   Incr = 5;

VAR
   X2, Y2,
   OrigColor,
   Key,
   RegionSize : WORD;
   Aspect     : REAL;
   Img        : POINTER;

{ returns location of crosshair when enter is pressed }

BEGIN
   OrigColor := GetColor;
   SetColor(color);
   Aspect := GetMaxX / GetMaxY;

   X1 := GetMaxX div 2;
   Y1 := GetMaxY div 2;
   X2 :=  X1 + trunc(YSide * Aspect);
   Y2 :=  Y1 + YSide;

   RegionSize := ImageSize( X1,Y1, X2 , Y2);
   { locate the upper left corner }
   GetMem(Img,RegionSize);
   REPEAT
      GetImage(X1, Y1, X2, Y2, Img^);
      Rectangle(X1, Y1, X2, Y2);
      REPEAT UNTIL KeyPressed;  { busy wait }
      Key := GetKey;
      PutImage(X1,Y1,Img^,CopyPut);
      CASE Key OF
         UpArrow    :  Y1 := min( 0, Y1 - 1);
         LeftArrow  :  X1 := min( 0, X1 - 1);
         RightArrow :  Y1 := max( Y1+1, GetMaxY );
         DownArrow  :  X1 := max( X1+1, GetMaxX );
      END;  { else do nothing }
   UNTIL Key = Enter;
   FreeMem(Img, RegionSize);
   SetWriteMode(XORPut);
   REPEAT
      REPEAT UNTIL KeyPressed;  { busy wait }
      { erase old image via XOR }
      Rectangle(X1,Y1,X2,Y2);
      Key := GetKey;
      CASE Key OF
         UpArrow    :  Y2 := max( Y1+Yside, Y2 - Incr);
         LeftArrow  :  X2 := max( X1+trunc(Yside*Aspect), X2 - Incr);
         RightArrow :  Y2 := min( Y2+Incr, GetMaxY );
         DownArrow  :  X2 := min( X2+Incr, GetMaxX );
      END;  { else do nothing }
      { ensure marked area equals screen aspect ratio }
      X2 := min(X2,trunc((Y2-Y1) * Aspect));
      Y2 := min(Y2,trunc((X2-X1) / Aspect));
      { redraw }
      Rectangle(X1,Y1,X2,Y2);
   UNTIL Key = Enter;

   {routine is done so erase via XOR }
   Rectangle(X1,Y1,X2,Y2);
   { restore draw mode }
   SetWriteMode(XORPut);
   { restore color }
   SetColor(OrigColor); {restore original color}

   { return SIDE value }
   Side := Y1 - Y2;
  END; { BoundRegion }


{----------------------------------------------}
VAR
  X1,Y1, Side : INTEGER;

BEGIN
  OpenGraph;
  BoundRegion(X1,Y1,Side, White);
  Writeln(X1:4,Y1:4,Side:4);

END.
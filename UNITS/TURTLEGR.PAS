UNIT TurtleGr;
{ turtle routines }

{$N+}

interface

TYPE
{ ================================================================== }
  TurtleRec = RECORD
     { Don't touch these things }
     { The Procedures handle everything }
     X,
     Y      : SINGLE;
     StepSize,
     Theta  : SINGLE;
     Draw   : BOOLEAN;
  END;

     { Use these procedures }
     PROCEDURE Init(VAR t : TurtleRec; StartX,StartY : SINGLE);
     { Position turtle at pixel (X,Y) }

     PROCEDURE Turn(VAR t : TurtleRec; angle : SINGLE);
     { rotate turtle to an angle RELATIVE to current direction. }

     PROCEDURE ChangeStep(VAR t : TurtleRec; PixelsPerStep : SINGLE);

     PROCEDURE StartDrawing(VAR t : TurtleRec);
     { Make Turtle Movements visible }

     PROCEDURE StopDrawing(VAR t : TurtleRec);
     { Make Turtle movements invisible }

     PROCEDURE Step(VAR t : TurtleRec);
     { Move Turtle One Step according to step size and angle }

     PROCEDURE Point(VAR t : TurtleRec; X1,Y1,X2,Y2 : SINGLE);
     {point turtle parallel to line described by x1,y1-x2,y2}

{ ================================================================== }

implementation

USES
  GraphPrm {LineDraw};

VAR
  HaPiRadian : SINGLE;

{ ------------------------------------------------------------ }
PROCEDURE Init(VAR t : TurtleRec;StartX,StartY : SINGLE);
BEGIN
  t.x := StartX;
  t.y := StartY;
  t.StepSize := 1;
  t.Theta := 0;
  t.Draw := FALSE;
END;

{ ------------------------------------------------------------ }
PROCEDURE Turn(VAR t : TurtleRec; angle : SINGLE);
BEGIN
  t.Theta := (t.Theta + angle);

  { ensure a valid angle }
  REPEAT
  IF t.Theta >= 360.0 THEN
      t.Theta := t.Theta - 360.0
  ELSE IF t.Theta < 0.0 THEN
      t.Theta := 360.0 + t.Theta;
  UNTIL (t.Theta < 360.0) AND NOT (t.Theta < 0.0)
END;

{ ------------------------------------------------------------ }
PROCEDURE ChangeStep(VAR t : TurtleRec; PixelsPerStep : SINGLE);
BEGIN
  t.StepSize := PixelsPerStep;
END;

{ ------------------------------------------------------------ }
PROCEDURE StartDrawing(VAR t : TurtleRec);
BEGIN
  t.Draw := TRUE;
END;

{ ------------------------------------------------------------ }
PROCEDURE StopDrawing(VAR t : TurtleRec);
BEGIN
  t.Draw := FALSE;
END;

{ ------------------------------------------------------------ }
PROCEDURE Step(VAR t : TurtleRec);
VAR
  OldX, OldY : SINGLE;

BEGIN
  OldX := t.X;
  OldY := t.Y;
  t.X := t.X + t.StepSize * cos(t.Theta*HaPiRadian);
  t.Y := t.Y + t.StepSize * sin(t.Theta*HaPiRadian);
  IF t.Draw THEN
    DrawLine(TRUNC(OldX),TRUNC(OldY),TRUNC(t.X),TRUNC(t.Y),15);
END;

{ ------------------------------------------------------------ }
PROCEDURE Point(VAR t : TurtleRec; X1,Y1,X2,Y2 : SINGLE);

BEGIN
  IF (X2-X1) = 0 THEN
       IF Y2 > Y1 THEN
         t.Theta :=  90.0
       ELSE
         t.Theta := 270.0
  ELSE
    t.Theta := ArcTan((Y2-Y1)/(X2-X1)) / HaPiRadian;
    IF X1 > X2 THEN
       t.Theta := t.Theta + 180;
END;

{ ------------------------------------------------------------ }
BEGIN
  HaPiRadian := Pi / 180.0;
END.
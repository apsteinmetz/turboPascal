UNIT TurtleO;
{ OOP turtle routines }

{$N+}

interface

TYPE
{ ================================================================== }
  TurtleObj = OBJECT
     { Don't touch these things }
     X,
     Y      : SINGLE;
     StepSize,
     Theta  : SINGLE;
     Draw   : BOOLEAN;

     { Use these procedures }
     CONSTRUCTOR Init(StartX,StartY : SINGLE);

     PROCEDURE Turn(angle : SINGLE);

     PROCEDURE ChangeStep(PixelsPerStep : SINGLE);

     PROCEDURE StartDrawing;

     PROCEDURE StopDrawing;

     PROCEDURE Step;
     { Move Turtle One Step according to step size and angle }

     PROCEDURE Point(X1,Y1,X2,Y2 : SINGLE);
     {point turtle parallel to line described by x1,y1-x2,y2}

     DESTRUCTOR Done;

END {TurtleObj };
{ ================================================================== }

implementation

USES
  GraphPrm {LineDraw};

VAR
  HaPiRadian : SINGLE;

{ ------------------------------------------------------------ }
CONSTRUCTOR TurtleObj.Init(StartX,StartY : SINGLE);
BEGIN
  x := StartX;
  y := StartY;
  StepSize := 1;
  Theta := 0;
  Draw := FALSE;
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.Turn(angle : SINGLE);
BEGIN
  Theta := (Theta + angle);

  { ensure a valid angle }
  REPEAT
  IF Theta >= 360.0 THEN
      Theta := Theta - 360.0
  ELSE IF Theta < 0.0 THEN
      Theta := 360.0 + Theta;
  UNTIL (Theta < 360.0) AND NOT (Theta < 0.0)
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.ChangeStep(PixelsPerStep : SINGLE);
BEGIN
  StepSize := PixelsPerStep;
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.StartDrawing;
BEGIN
  Draw := TRUE;
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.StopDrawing;
BEGIN
  Draw := FALSE;
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.Step;
VAR
  OldX, OldY : SINGLE;

BEGIN
  OldX := x;
  OldY := y;
  X := X + StepSize * cos(Theta*HaPiRadian);
  Y := Y + StepSize * sin(Theta*HaPiRadian);
  IF Draw THEN
    DrawLine(TRUNC(OldX),TRUNC(OldY),TRUNC(x),TRUNC(y),15);
END;

{ ------------------------------------------------------------ }
PROCEDURE TurtleObj.Point(X1,Y1,X2,Y2 : SINGLE);

BEGIN
  IF (x2-x1) = 0 THEN
       IF y2 > y1 THEN
         theta :=  90.0
       ELSE
         theta := 270.0
  ELSE
    theta := ArcTan((y2-y1)/(x2-x1)) / HaPiRadian;
    IF x1 > x2 THEN
       theta := theta + 180;
END;

DESTRUCTOR TurtleObj.Done;
BEGIN
END;

{ ------------------------------------------------------------ }
BEGIN
  HaPiRadian := Pi / 180.0;
END.
UNIT Turtle;

{$N+}

interface

VAR
  TurtlePace,
  TurtleX,
  TurtleY,
  TurtleTheta  : SINGLE;

PROCEDURE TurtleTurn(angle : SINGLE);

PROCEDURE TurtleStep;

FUNCTION TurtlePoint(X1,Y1,X2,Y2 : SINGLE) : SINGLE;

implementation

VAR
  HaPiRadian : SINGLE;

PROCEDURE TurtleTurn(angle : SINGLE);
BEGIN
  TurtleTheta := (TurtleTheta + angle);

(*
  { ensure a valid angle }
  REPEAT
  IF TurtleTheta > 360.0 THEN
      TurtleTheta := TurtleTheta - 360.0
  ELSE IF TurtleTheta < 0.0 THEN
      TurtleTheta := 360.0 + TurtleTheta;
  UNTIL (TurtleTheta < 360.0) AND NOT (TurtleTheta < 0.0)
*)
END;

PROCEDURE TurtleStep;
BEGIN
  TurtleX := TurtlePace * cos(TurtleTheta*HaPiRadian);
  TurtleY := TurtlePace * sin(TurtleTheta*HaPiRadian);
END;



FUNCTION TurtlePoint(X1,Y1,X2,Y2 : SINGLE) : SINGLE;
VAR
  theta : SINGLE;

BEGIN
  IF (x2-x1) = 0 THEN
       IF y2 > y1 THEN
         theta :=  90.0
       ELSE
         theta := 270.0
  ELSE
    theta := TRUNC(ArcTan((y2-y1)/(x2-x1)) / HaPiRadian);
  TurtlePoint := theta;
END;

BEGIN
  HaPiRadian := Pi / 180.0;
END.
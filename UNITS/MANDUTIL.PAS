UNIT mandutil;
{ Various estimators for Mandelbrot and Julia Sets }
{$I FLOAT.INC}

interface

uses MathLib0,
     MapStuff {ArcCos};

CONST
  LimitIter = 500;
  { Global limit to iterations of all functions }

VAR
  MaxIter : WORD;
  { User specified iteration count.  May not exceed LimitIter }

  (* test variables *)
  MSetHit, MSetNoHit, sumiter : WORD;

FUNCTION JSet(cx,cy : FLOAT; p, q : FLOAT) : WORD;
{ returns iterations before escape or MaxIter if in Set}

FUNCTION MSet(cx,cy : FLOAT) : WORD;
{ returns iterations before escape or MaxIter if in Set}

FUNCTION JSetDist(cx,cy : FLOAT; p,q : FLOAT) : FLOAT;
{distance on complex plane to Set}

FUNCTION MSetDist(cx,cy : FLOAT) : FLOAT;
{distance on complex plane to Set}

FUNCTION MSetBD(cx,cy : FLOAT) : WORD;
{ Binary decomposition.  Returns either 0 or Maxiter }

FUNCTION JSetBD(cx,cy : FLOAT; p, q : FLOAT) : WORD;
{ Binary decomposition.  Returns either 0 or Maxiter }

implementation
{$DEFINE AI}

{$IFDEF AI}
CONST
  RequiredRep = 5;

VAR
  LastPeriod, NumRep,
  LastX, LastY,
  CheckEvery, Periodicity : INTEGER;

{$ENDIF}

VAR
  PiAndHalf : FLOAT;


{ ---------------------------------------------------------------}
{$IFDEF AI}
FUNCTION CheckPeriodicity( VAR x,y : FLOAT) : BOOLEAN;

VAR
  retval : BOOLEAN;
  curX, curY : INTEGER;

BEGIN
   (* constrain our scale to a coarsness *similar* to the screen *)
   (* resolution.  Effect is loosen periodicty requirement *)
   curX := TRUNC(X * 300.0);
   curY := TRUNC(Y * 300.0);

   retval := FALSE;
   (* Is this point the same as the one I sampled earlier? *)
   IF ((CurX = Lastx) AND (CurY = Lasty)) THEN
   BEGIN

      (* Is the number of iterations between now and when I last
         saw this point the same as the time before? *)
      IF (LastPeriod = Periodicity) THEN
      (* Has this pattern repeated itself 'RequiredRep' times? *)
         if (NumRep = RequiredRep) THEN
            retval := TRUE  (* Yep, return TRUE *)
         ELSE
            NumRep := Succ(NumRep) (* no, but we're one closer *)

      (* Nope, keep looking - maybe is will settle out *)
      ELSE
      BEGIN
         LastPeriod := Periodicity;
         Periodicity := 1;
      END;
   END

   (* Not the same point. Time to pick a new sample point? *)
   ELSE
   BEGIN
	if (Periodicity >= CheckEvery) THEN
        BEGIN
           CheckEvery := CheckEvery * 2;  (* Look for larger patterns *)
           Periodicity := 1;
           Lastx := CurX;
           Lasty := CurY;
           NumRep := 0;
        END
        ELSE
          Periodicity := Succ(Periodicity);
   END;
   CheckPeriodicity := retval;
END (* Check*);
{$ENDIF}
{ ---------------------------------------------------------------}
FUNCTION JSet(cx,cy : FLOAT; p, q : FLOAT) : WORD;

CONST
  huge = 100.0;

VAR
  iter       : WORD;
  temp,
  x, y, x2, y2 : FLOAT;

BEGIN
   x    := cx;
   y    := cy;
   x2   := sqr(x);
   y2   := sqr(y);
   iter := 0;
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x;
      x := x2 - y2 + p;
      y := 2 * temp * y + q;
      x2 := sqr(x);
      y2 := sqr(y);
      INC(iter);
   END; { while }
   JSet := iter;
END {JSet};

{ ---------------------------------------------------------------}
FUNCTION JSetBD(cx,cy : FLOAT; p, q : FLOAT) : WORD;

CONST
  huge = 100.0;

VAR
  iter       : WORD;
  temp,
  theta,
  x, y, x2, y2 : FLOAT;

BEGIN
   x    := cx;
   y    := cy;
   x2   := sqr(x);
   y2   := sqr(y);
   iter := 0;
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      x2 := sqr(x);
      y2 := sqr(y);
      temp := x;
      x := x2 - y2 + p;
      y := 2 * temp * y + q;
      INC(iter);
   END; { while }

   { now figure out the decomposition }
   IF (x = 0) THEN
       JSetBD := MaxIter
   ELSE
   BEGIN
       theta := arccos(abs(x)/(X2 + Y2));
       IF (X < 0) THEN
       BEGIN
          IF (Y>=0) THEN
            theta := theta + HalfPi
          ELSE
           theta := theta + Pi;
       END
       ELSE IF (Y<0) THEN
           theta := theta + PiAndHalf;

       IF (theta > 0) AND (theta <= pi) THEN
         JSetBd := MaxIter
       ELSE
         JSetBD := 0;
   END;
END {JSetBD};

{ ---------------------------------------------------------------}
FUNCTION MSet(cx,cy : FLOAT) : WORD;

CONST
  huge = 10000.0;

VAR
  iter       : WORD;
  temp,
  x, y, x2, y2 : FLOAT;
  Bail : BOOLEAN;

BEGIN
   {$IFDEF AI}
   (* periodicity check stuff *)
   Bail := FALSE;
   NumRep := 0;
   Periodicity := 1;
   LastPeriod := 1;   (* First assume a periodicity of 1 *)
   CheckEvery := 3;   (* Look for small patterns first *)
   Lastx := 0;
   Lasty := 0;
   (* end periodicity check stuff *)
   {$ENDIF}

   x    := 0;
   y    := 0;
   x2   := 0;
   y2   := 0;
   iter := 0;
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x2 - y2 + cx;
      y    := 2 * x * y + cy;
      x    := temp;
      x2   := sqr(x);
      y2   := sqr(y);
      INC(iter);
      {$IFDEF AI}
      IF CheckPeriodicity(x,y) THEN
      BEGIN
         bail := TRUE;
         sumiter := sumiter + iter;
         INC(MSetHit);
         iter := MaxIter;
      END;
      {$ENDIF}
   END; { while }
   IF (iter = MaxIter) AND NOT BAIL THEN
     INC(MSetNoHit);
   MSet := iter;
END {MSet};

{ ---------------------------------------------------------------}
FUNCTION MSetBD(cx,cy : FLOAT) : WORD;

CONST
  huge = 10000.0;

VAR
  iter       : WORD;
  temp,
  theta,
  x, y, x2, y2 : FLOAT;

BEGIN
   x    := 0;
   y    := 0;
   x2   := 0;
   y2   := 0;
   iter := 0;
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x2 - y2 + cx;
      y    := 2 * x * y + cy;
      x    := temp;
      x2   := sqr(x);
      y2   := sqr(y);
      INC(iter);
   END; { while }

   { now figure out the decomposition }
   IF (X = 0) OR (iter = MaxIter) THEN
       MSetBD := MaxIter
   ELSE
   BEGIN
       theta := arccos(abs(x)/(X2 + Y2));
       IF (X < 0) THEN
       BEGIN
          IF (Y>=0) THEN
            theta := theta + HalfPi
          ELSE
           theta := theta + Pi;
       END
       ELSE IF (Y<0) THEN
           theta := theta + PiAndHalf;

       IF (theta > 0) AND (theta <= pi) THEN
         MSetBD := 0
       ELSE
         MSetBD := MaxIter;
   END;
END {MSetBD};

{ ---------------------------------------------------------------}
FUNCTION JSetDist(cx,cy : FLOAT; p,q : FLOAT) : FLOAT;
CONST
{$IFOPT N+}
  overflow = 1.699e37;  { close to max range of REAL }
{$ELSE}
  overflow = 1.699e37;  { close to max range of REAL }
{$ENDIF}
  huge     = 10000.0;   { stops iteration }

TYPE
    orbits  = ARRAY[0.. LimitIter] OF FLOAT;
VAR
  iter, i       : WORD;
  x, y, x2, y2 : FLOAT;
  temp,
  xder, yder,
  dist        : FLOAT;
  flag        : BOOLEAN;
  xorbit,
  yorbit      : orbits;

BEGIN
   dist := 0;
   xorbit[0] := 0;
   yorbit[0] := 0;
   iter := 0;
   flag := FALSE;
   x    := cx;
   y    := cy;
   x2   := sqr(x);
   y2   := sqr(y);
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x;
      x := x2 - y2 + p;
      y := 2 * temp * y + q;
      x2 := sqr(x);
      y2 := sqr(y);
      INC(iter);
      xorbit[iter] := x;
      yorbit[iter] := y;
   END; { while }
   IF x2 + y2 > huge THEN
   BEGIN
      xder := 0;
      yder := 0;
      i    := 0;
      flag := FALSE;
      WHILE (i < iter) AND (NOT flag) DO
      BEGIN
         temp := 2 * (xorbit[i] * xder-yorbit[i]*yder)+1;
         yder := 2 * (yorbit[i] * xder+xorbit[i]*yder);
         xder := temp;
         flag := (abs(xder) > overflow) OR (abs(yder) > overflow);
         INC(i);
      END; {while}
      IF NOT flag THEN
        dist := ln(x2+y2)/ln10 * sqrt(x2+y2) / sqrt(sqr(xder) + sqr(yder));
   END; {IF}
   JSetDist := dist;
END; {JSetDist}

{ ---------------------------------------------------------------}
FUNCTION MSetDist(cx,cy : FLOAT) : FLOAT;
CONST
{$IFOPT N+}
  overflow = 1.699e37;  { close to max range of REAL }
{$ELSE}
  overflow = 1.699e37;  { close to max range of REAL }
{$ENDIF}
  huge     = 10000.0;   { stops iteration }

TYPE
    orbits  = ARRAY[0.. LimitIter] OF FLOAT;
VAR
  iter, i       : WORD;
  x, y, x2, y2 : FLOAT;
  temp,
  xder, yder,
  dist        : FLOAT;
  flag        : BOOLEAN;
  xorbit,
  yorbit      : orbits;

BEGIN
   dist := 0;
   x    := 0;
   y    := 0;
   x2   := 0;
   y2   := 0;
   xorbit[0] := 0;
   yorbit[0] := 0;
   iter := 0;
   flag := FALSE;
   WHILE (iter < MaxIter) AND (x2 + y2 < huge) DO
   BEGIN
      temp := x2 - y2 + cx;
      y    := 2 * x * y + cy;
      x    := temp;
      x2   := sqr(x);
      y2   := sqr(y);
      INC(iter);
      xorbit[iter] := x;
      yorbit[iter] := y;
   END; { while }
   IF x2 + y2 > huge THEN
   BEGIN
      xder := 0;
      yder := 0;
      i    := 0;
      flag := FALSE;
      WHILE (i < iter) AND (NOT flag) DO
      BEGIN
         temp := 2 * (xorbit[i] * xder-yorbit[i]*yder)+1;
         yder := 2 * (yorbit[i] * xder+xorbit[i]*yder);
         xder := temp;
         flag := (abs(xder) > overflow) OR (abs(yder) > overflow);
         INC(i);
      END; {while}
      IF NOT flag THEN
        dist := ln(x2+y2)/ln10 * sqrt(x2+y2) / sqrt(sqr(xder) + sqr(yder));
   END; {IF}
   MSetDist := dist;
END {MSetDist};

{--------------------------------------------------}
BEGIN
  MaxIter := 100; { nice default number }
  PiAndHalf := Pi + HalfPi;
  {$IFDEF AI}
  MSetHit := 0;
  MSetNoHit := 0;
  sumiter := 0;
  {$ENDIF}
END {MandUtil}.
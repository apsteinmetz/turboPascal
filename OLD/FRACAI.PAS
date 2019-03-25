PROGRAM FRACAI;
(* requires EGAVGA.BGI in current directory *)

{$N+,E+}

uses Graph, Crt;

CONST
(* To make this program stupid, change the IQ to zero *)
  IQ = 1;

  Scale = 0.35;
  RequiredRep = 5;

VAR
 i, j, iInit, jInit, Temp : DOUBLE;
 OffsetX, OffsetY,
 AspectX, AspectY : DOUBLE;
 LastPeriod, NumRep,
 CheckEvery, Periodicity : INTEGER;
 Lastx, Lasty, Midx, Midy, x, y, n : INTEGER;
 avgbailout : LONGINT;
 escaped, MSetHit, MSetNoHit : INTEGER;

 f : text;

PROCEDURE ResetAI;
BEGIN
   Lastx := 0;
   Lasty := 0;
   NumRep := 0;
   Periodicity := 1;
   LastPeriod := 1;   (* First assume a periodicity of 1 *)
   CheckEvery := 3;   (* Look for small patterns first *)
END (* ResetAI *);


FUNCTION Check : INTEGER;
VAR
  retval : INTEGER;

BEGIN
   retval := 0;
   (* Convert 'i' & 'j' to screen coord *)
   x := TRUNC((i - OffsetX) / AspectX) + MidX;
   y := TRUNC((j - OffsetY) / AspectY) + MidY;
   writeln(f,x:5,y:5);


   (* Check for overflow *)
   if ((x > 1000) OR (x < -1000) OR (y > 1000) OR (y < -1000)) then
      retval := n
   ELSE
   BEGIN (* no overflow *)

   (* XOR pixel to screen *)
   if (x > 0) OR (y > 0) THEN
   BEGIN
        PutPixel(x, y, getpixel(x,y) XOR 15);
   END;

   (* Am I supposed to be intellegent about this? *)
   if (IQ = 0) THEN

      (* Nope.  Act stupid and keep iterating! *)
      retval := 0
   ELSE
   BEGIN (* act smart *)
   (* Is this point the same as the one I sampled earlier? *)
   IF ((x = Lastx) AND (y = Lasty)) THEN
   BEGIN

      (* Is the number of iterations between now and when I last
         saw this point the same as the time before? *)
      IF (LastPeriod = Periodicity) THEN
      BEGIN
         (* Has this pattern repeated itself 'RequiredRep' times? *)
         if (NumRep = RequiredRep) THEN
            retval := Periodicity;  (* Yep, return the periodicity *)
         NumRep := Succ(NumRep);
      END

      (* Nope, keep looking - maybe is will settle out *)
      ELSE
      BEGIN
         LastPeriod := Periodicity;
         Periodicity := 1;
      END;
   END

   (* Time to pick a new sample point? *)
   ELSE
   BEGIN
	if (Periodicity >= CheckEvery) THEN
        BEGIN
           CheckEvery := CheckEvery * 2;  (* Look for larger patterns *)
           Periodicity := 1;
           Lastx := x;
           Lasty := y;
           NumRep := 0;
        END
        ELSE
          Periodicity := Succ(Periodicity);
   END;
   END; (* act smart *)
   END; (* no overflow *)
   Check := retval;
END (* Check*);

FUNCTION ChkPoint : INTEGER;
VAR
  Ret : INTEGER;

BEGIN

   i := iInit;
   j := jInit;
   ResetAI;
   n := 1;
   REPEAT
      Temp := (i * i) - (j * j);
      j := (2 * i * j) + jInit;
      i := Temp + iInit;
      Ret := Check;
      INC(n)
   UNTIL (Ret > 0) OR (n > 2000);
   IF (Ret > 0) THEN
      ChkPoint := Ret
   ELSE
      ChkPoint := 14;

   (* check  efficiency *)
   IF (Ret = n-1) THEN INC(escaped) ELSE
      IF (n > 2000) THEN INC(MsetNoHit) ELSE
      BEGIN
        INC(MSetHit);
        avgbailout := avgBailout + n;
      END;

END (* ChkPoint *);

PROCEDURE PlotPoint(x, y : INTEGER);

BEGIN
   iInit := (AspectX * (x - MidX)) + OffsetX;
   jInit := (AspectY * (y - MidY)) + OffsetY;
   (* draw the orbit *)
   N := ChkPoint;
   (* erase the same orbit *)
   n := ChkPoint;
   if (n > 14) THEN
      n := 14;
   PutPixel(x, y,n);
END (* PlotPoint *);

PROCEDURE main;

VAR
  Done : BOOLEAN;
  grError,
  GraphMode, GraphDriver :INTEGER;

BEGIN
   assign(f,'Period.pas');
   rewrite(f);
   escaped := 0;
   MSetHit := 0;
   MSetNoHit := 0;
   avgbailout := 0;
   OffsetX := -0.5;
   OffsetY := 0.0;
   GraphDriver := 1;
   GraphMode := VGA;
   InitGraph(GraphMode,GraphDriver,'');
   GrError := GraphResult;
   IF GrError < grOk THEN
   BEGIN
     GraphMode := EGA;
     InitGraph(GraphMode,GraphDriver,'');
     GrError := GraphResult;
     IF GrError < grOk THEN
     BEGIN
         writeln(GraphErrorMsg(GrError));
         HALT(1);
     END;
   END;

   Midx := GetMaxX DIV 2;
   Midy := GetMaxY DIV 2;

   AspectX := (Scale * 10.0) / GetMaxX;
   AspectY := (Scale * 7.0) / GetMaxY;

   OffsetX := OffsetX + 1.0 / GetMaxX;
   OffsetY := OffsetY + 1.0 / GetMaxY;

   Done := FALSE;
   Randomize;
   WHILE NOT Done DO
   BEGIN
      x := random(GetMaxX+1);
      y := random(GetMaxY+1);
      if (getpixel(x, y) = Black) THEN
         PlotPoint(x, y);
      IF keypressed THEN
         Done := (ReadKey = chr(27));
   END;
   CloseGraph;
   Close(f);
   Writeln('Points outside set: ',escaped:5);
   Writeln('Points inside set: ',MSetHit + MSetNoHit:5);
   Writeln('Points in set discovered early (percent): ',MSetHit / (MSetNoHit + MSetHit)*100:4:0);
   Writeln('Average iterations at discovery: ',(avgbailout / (MSetHit + MSetNoHit)):8:0);
END (* main *);

BEGIN
  Main;
END.
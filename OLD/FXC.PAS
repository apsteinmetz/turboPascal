PROGRAM fxc (* display currency reciprocals over a range *);

CONST
  defaultIncr = 0.1;
  ScreenLines = 23;
  DefaultFact = 100;

VAR
   FX,
   Start,
   Center,
   Increment : REAL;
   Factor,
   n, err    : WORD;

(* --------------------------------------------------------- *)
PROCEDURE ShowHelp;
BEGIN
  Writeln('Usage: FXC ExchRate [Increment] [Factor]');
  HALT;
END (* ShowHelp *);

(* --------------------------------------------------------- *)
PROCEDURE GetParams(VAR ExchRate, incr : REAL; VAR Fact : WORD);
BEGIN
  if paramcount > 0 THEN
  BEGIN
    val(paramstr(1),ExchRate,err);
    If err > 0 THEN ShowHelp;
    val(paramstr(2),incr,err);
    If err > 0 THEN
      incr := DefaultIncr;
    val(paramstr(3),Fact,err);
    If err > 0 THEN
      Fact := DefaultFact;
  END
  ELSE
    ShowHelp;
END (* GetParams *);


(* --------------------------------------------------------- *)
BEGIN (* MAIN *)
   GetParams(Center, Increment, Factor);
   Start := Center - Increment * (ScreenLines DIV 2);
   FOR n := 0 to ScreenLines-1 DO
   BEGIN
      FX := Start + n*Increment;
      IF n = ScreenLines DIV 2 THEN Write('*');
      Writeln(FX:10:3,1/FX*Factor:10:3);
   END;
END (* FXC *).

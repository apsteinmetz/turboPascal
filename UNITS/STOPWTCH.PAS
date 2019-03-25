UNIT StopWtch;


interface

{$DEFINE float}

uses DOS; { GetTime }

TYPE

{$ifdef float}
  MyType = REAL;
{$else}
  MyType = INTEGER;
{$ENDIF}

VAR
  T2, T3,
  ST, ET : MyType;

PROCEDURE StartWatch;

FUNCTION SplitTime : MyType;

PROCEDURE StopWatch;

FUNCTION ElapsedTime : MyType;

PROCEDURE ResetWatch;

implementation

TYPE
   TimeRec = RECORD
      H, M, S, uS : WORD;
   END;

VAR
  T : TimeRec;

FUNCTION ConvertToSecs(T : TimeRec) : MyType;
BEGIN
  ConvertToSecs := (T.H * 3600 + T.M * 60 + T.S) + T.uS/100;
END;



PROCEDURE StartWatch;

BEGIN
   GetTime(T.H,T.M,T.S,T.uS);
   ST := ConvertToSecs(T);
END;

FUNCTION SplitTime : MyType;
BEGIN
   GetTime(T.H,T.M,T.S,T.uS);
   T2 := ConvertToSecs(T) - ST;
   SplitTime := T2;
END; {SplitTime}

PROCEDURE StopWatch;
BEGIN
   GetTime(T.H,T.M,T.S,T.uS);
   ET := ET + ConvertToSecs(T) - ST;
END; {StopWatch}

FUNCTION ElapsedTime : MyType;
BEGIN
   ElapsedTime := ET;
END;

PROCEDURE ResetWatch;
BEGIN
  ET := 0;
END;

BEGIN
  ResetWatch;
END.

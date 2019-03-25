(*
COMPILER     TYPE  SPEED(secs)
--------     ----  -----------
T-Pascal     REAL      9.833
T-Pascal     SINGLE    1.800  (clearly, the hardware is used)
T-Pascal     DOUBLE    1.800  (clearly, the hardware is used)
*)

PROGRAM FLOAT;
{$N+,E+}
uses DOS;



VAR I: INTEGER;
    x,y: DOUBLE;

    Time : LONGINT;
    H,M,S,Ms : WORD;
    H1,M1,S1,Ms1 : WORD;

BEGIN
    GetTime(H,M,S,Ms);
    x:= 1.0;
    FOR I:= 1 TO 5000 DO
    BEGIN
        y := sin(x);
        y := ln(x);
	y:= exp(x);
	y:= sqrt(x);
	y:= arctan(x);
	x:= x + 0.01
    END;
    GetTime(H1,M1,S1,Ms1);
    Time :=        (H1*3600 + M1*60 + S1) * 100 + Ms1;
    Time := Time - ((H*3600 + M*60 + S) * 100 + Ms);
    Writeln(Time:10);
END {FLOAT}.

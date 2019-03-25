{$R-}    {Range checking off}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N+,E+}    {Numeric coprocessor IS present}

PROGRAM Cartog;
{ This program plots geographic data from the file
  WORLD.DAT and coordinate grids on the Mercator,
  Equidistant Cylindrical, Sinusoidal, Hammer, and
  Orthographic map projections.
}

Uses
  Crt ,
  Graph,
  MathLib0,
  MapStuff;

CONST
      FileName = 'WORLD2.DAT';

TYPE  LLRec      = RECORD
          Connected  : BOOLEAN;
          Longi, Lati: INTEGER;
      END;

VAR   Map         : MapRec;
      Quit        : BOOLEAN;

(* ----------------------------------------------------- *)
FUNCTION SetRadius(MapType : MapTypes) : INTEGER;
BEGIN
    CASE MapType OF
        Hamr : SetRadius := GetMaxY DIV 6;
        Orth : SetRadius := GetMaxY DIV 4;
    ELSE
      SetRadius := GetMaxY DIV 7;
    END {CASE};
END {SetRadius};

{ -------------------------------------------------------------}
PROCEDURE Beep;
{ Sounds a tone when map is complete. }
BEGIN
    Sound(880);  Delay(250);  NoSound;
END;

{ -------------------------------------------------------------}
PROCEDURE PlotPt( VAR LastPtVis: BOOLEAN; XP, YP : INTEGER;
                  VAR LastX, LastY : INTEGER);
{ Draws a line from the last point to the current (XP,YP) if it is visible. }

BEGIN
    IF LastPtVis THEN
       Line(LastX,LastY,Xp,YP);
    LastX:=XP;
    LastY:=YP;
    LastPtVis:=TRUE;
END; { PlotPt. }

{ -------------------------------------------------------------}

PROCEDURE DrawOrthoCircle(Radius, MidX, MidY : INTEGER);

VAR A, R2, RA, XN, YN,
    X, Y,
    SINDT, COSDT         : FLOAT;
    XP,YP, LastX, LastY  : INTEGER;
    LastPtVis            : BOOLEAN;

BEGIN
    A:=0;                           { Draw circular outline }
    LastPtVis:=False;
    R2:=Radius + Radius;
    RA:= R2 * (MidX / MidY);
    SINDT:= 0.05996400648;
    COSDT:= 0.99820053993;
    X:=1.0;   Y:=0.0;
    XP:= MidX + ROUND(RA);
    YP:= MidY;
    PlotPt(LastPtVis,XP,YP,LastX, LastY);
    WHILE A <= TwoPI DO
    BEGIN                           { Compute points on the circle }
       XN:= X * COSDT - Y * SINDT;
       YN:= X * SINDT + Y * COSDT;
       X:= XN;  Y:= YN;
       XP:= MidX + ROUND(X*RA);
       YP:= MidY + ROUND(Y*R2);
       PlotPt(LastPtVis,XP,YP,LastX, LastY);
       A:= A+0.06;
    END; { While. }

END {DrawOrthoCircle};

(* -------------------------------------------------------------- *)
PROCEDURE DrawGrid(Map : MapRec);

VAR MLine, Parallel, incr : INTEGER;
    XP, YP, LastX, LastY,
    Radius,
    MidX, MidY     : INTEGER;
    LONGR, LATR,
    X, Y,
    Aspect : FLOAT;
    LastPtVis            : BOOLEAN;

BEGIN
    MidX := GetMaxX DIV 2;
    MidY := GetMaxY DIV 2;
    Aspect := GetMaxX / GetMaxY;
    Radius := SetRadius(Map.MapType);

    (* DRAW MERIDIANS *)
    LastX := 0;
    MLine := -180;
    IF (DoGrid IN Map.Choice) THEN
      incr := 30
    ELSE
      incr := 360;

    WHILE MLine <= 180 DO BEGIN
       LastPtVis:=FALSE;
       LONGR:= MLine * Radian;
       FOR Parallel := -9 to 9 DO BEGIN

       LATR := (Parallel * 10) * Radian;

       ProJect( Map, LONGR, LATR, Radius, X, Y);

       IF X > NotVisible THEN
       BEGIN
             XP:=ROUND(X*Aspect)+ MidX;
             IF ABS(LastX-XP) > 100 THEN LastPtVis:=FALSE;
             YP:= MidY-ROUND(Y);
             PlotPt(LastPtVis,XP,YP,LastX, LastY);
       END

       END {FOR n};
       MLine := MLine + incr;
    END {FOR MLine};


    { DRAW PARALLELS }
    LastX := 0;
    Parallel := -90;
    IF (DoGrid IN Map.Choice) THEN
      incr := 30
    ELSE
      incr := 180;

    WHILE (Parallel <= 90) DO BEGIN
       LastPtVis:= FALSE;
       LATR  := Parallel  * Radian;
       MLine := -180;
       WHILE MLine <= 180 DO BEGIN

       LONGR := MLine * Radian;

       ProJect( Map, LONGR, LATR, Radius, X, Y);

       IF X > NotVisible THEN
       BEGIN
             XP:=ROUND(X*Aspect)+ MidX;
             YP:= MidY-ROUND(Y);
             IF (ABS(LastX-XP) > 100) AND (Map.MapType = Hamr) THEN
                 LastPtVis:=FALSE;
             IF ABS(LastY-YP) > 100 THEN LastPtVis:=FALSE;
             PlotPt(LastPtVis,XP,YP,LastX, LastY);
       END;

       MLine := Mline + 5;
       END {FOR n};
       Parallel := Parallel + incr;
    END {FOR MLine};

    IF (Map.MapType = Orth) THEN
        DrawOrthoCircle(Radius, MidX, MidY);

END;  { DrawGrid. }

(* ------------------------------------------------------------- *)
PROCEDURE DrawMap(Map : MapRec);
VAR
    LL          : LLRec;
    DataFile    : FILE OF LLRec;
    MidX, MidY,
    Radius,
    XP, YP,
    LastY, LastX : INTEGER;
    LONGR, LATR,
    X, Y,
    Aspect       : FLOAT;
    LastPtVis,
    XIT          : BOOLEAN;

BEGIN
    LastPtVis:=FALSE;
    LastX:=0;
    XIT := FALSE;
    Aspect := GetMaxX / GetMaxY;
    MidX := GetMaxX DIV 2;
    MidY := GetMaxY DIV 2;
    Radius := SetRadius(Map.MapType);

    ASSIGN(DataFile, FileName);
    RESET(DataFile);
    WHILE NOT (EOF(DataFile) OR XIT) DO
    BEGIN
       READ(DataFile, LL);
       IF KeyPressed THEN XIT := TRUE;
       LONGR:=LL.Longi * RadianDiv100;
       LATR :=LL.Lati  * RadianDiv100;

       LastPtVis:= LL.Connected;

       ProJect(Map, LONGR, LATR, Radius, X, Y);

       IF X > NotVisible THEN
       BEGIN
             XP:=ROUND(X*Aspect)+ MidX;
             IF ABS(LastX-XP) > 100 THEN LastPtVis:=FALSE;
             YP:= MidY-ROUND(Y);
             PlotPt(LastPtVis,XP,YP,LastX, LastY);
       END ELSE LastPtVis:=FALSE;
     END;
END;  { DrawMap. }

(* ------------------------------------------------------------- *)
PROCEDURE ShowTitleScreen;
BEGIN
        ClrScr;
        GOTOXY(24,1);  WRITE('C A R T O G');
        GOTOXY(1,24);
        WRITE('':4,'Copyright 1987 by Robert Miller and Francis Reddy');
        GOTOXY(1,3);
        WRITELN(' ':4,'To PLOT:  Choose a projection.  Enter the Central ');
        WRITELN(' ':4,'Meridian of the map (180 to -180 degrees, longitudes');
        WRITELN(' ':4,'west of Greenwich negative). If applicable, enter');
        WRITELN(' ':4,'the Standard Parallel (90 to -90 degrees, southern');
        WRITELN(' ':4,'latitudes negative). The file WORLD.DAT must also be');
        WRITELN(' ':4,'on the logged drive. A tone means the map is done.');
        WRITELN;
        WRITELN(' ':4,'Any key ABORTS plot.  Hit return to restore MENU.');
        WRITELN;
        WRITELN;
        WRITE(' ':6,'1. Mercator');
        WRITELN(' ':21,'4. Hammer');
        WRITE(' ':6,'2. Equidistant Cylindrical');
        WRITELN(' ':6,'5. Orthographic');
        WRITELN(' ':6,'3. Sinusoidal');
        WRITELN;
END {ShowTitleScreen};

(* -------------------------------------------------------- *)
PROCEDURE SetUpDisplay;
VAR
      GraphMode,
      GraphDriver : INTEGER;

BEGIN
   GraphDriver := VGA;
   GraphMode   := VGAHi;
   InitGraph(GraphDriver,GraphMode,'');
END;

(* ------------------------------------------------------------- *)
PROCEDURE GetParameters(VAR Quit : BOOLEAN; VAR Map : MapRec);

VAR Resp    : CHAR;
    NumResp : INTEGER;

BEGIN

      Map.MapType:=Merc;
      Map.Choice := [];
      Map.Phi1    := 0;
      Map.Lambda0 := 0;

      ShowTitleScreen;
      { get projection type }
      WRITE(' ':8,'Projection number (1-5) or 0 to quit:   ');
      READLN(NumResp);
      Map.MapType := MapTypes(NumResp);

      Quit := (Map.MapType = NoMap);

      IF NOT Quit THEN
      BEGIN
           { Select what to render }
           WRITELN;
           WRITE(' ':8,'Plot grid, continents or both (G/C/B)?  ');
           Readln(Resp);
           Resp:=UPCASE(Resp);
           CASE Resp OF
             'G' : Map.Choice := [DoGrid];
             'C' : Map.Choice := [DoMap];
             'B' : Map.Choice := [DoGrid,DoMap];
           END;

           { Get position coordinates }
           IF (DoMap IN Map.Choice) THEN
           BEGIN
             WRITE(' ':8,'Central Longitude of Map (default = 0): ');
             READLN(NumResp);
             Map.Lambda0 := NumResp * Radian;
             IF (Map.MapType = Orth) THEN
             BEGIN
                WRITE(' ':8,'Central Latitude  of Map (default = 0): ');
                READLN(NumResp);
                IF NumResp = 90 THEN
                  Map.Phi1 := HalfPI
                ELSE
                  Map.Phi1:= NumResp * Radian;
             END;
           END;
      END {IF NOT Quit};

END {GetParmeters};

(* ---------------------  MAIN  PROGRAM  ------------------ *)

BEGIN
    Quit := FALSE;
    WHILE NOT Quit DO
    BEGIN
      GetParameters(Quit,Map);
      IF NOT Quit THEN
      BEGIN
           IF NOT (Map.Choice = []) THEN
           BEGIN
              SetUpDisplay;
              DrawGrid(Map);
              IF (DoMap IN Map.Choice) THEN
                 DrawMap(Map);
              Beep;
              REPEAT UNTIL KeyPressed;
             CloseGraph;
           END
           ELSE
           BEGIN
              Beep;
           END;
      END { if not quit } ;
    END;  { WHILE not quit }
END.

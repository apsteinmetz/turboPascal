{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N+}    {Numeric coprocessor IS present}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

PROGRAM Cartog;
{ This program plots geographic data from the file
  WORLD.DAT and coordinate grids on the Mercator,
  Equidistant Cylindrical, Sinusoidal, Hammer, and
  Orthographic map projections.
}

Uses
  Crt ,
  Graph  ;

CONST Sqrt2        = 1.4142135623731;
      PI           = 3.1415926535898;
      HalfPI       = 1.5707963267949;
      TwoPI        = 6.2831853071796;
      Radian       = 1.7453292519943E-2;
      RadianDiv100 = 1.7453292519943E-4; { PI/180/100, needed to convert }
                                         { data in WORLD.DAT to radians  }

CONST XCENTER    : INTEGER = 320;        { ATT Graphics constants.       }
      YCENTER    : INTEGER =  240;       { Screen center X and Y         }
      ASPECT     : REAL    = 1.33;        { 640x400 aspect ratio          }
      R          : REAL    =  40;        { Default map radius            }
      NotVisible : INTEGER = -32767;     { Flag for point visibility     }

TYPE  LLREC      = RECORD
      CODE       : ARRAY[0..1] OF CHAR;
      LONGI, LATI: INTEGER; END;

VAR   LL         : LLREC;
      LLF        : FILE OF LLREC;

VAR   LastX, LastY, XP, YP    : INTEGER; { Save variables for plotting }
      COLOR_GLB               : INTEGER;
      GraphMode,
      GraphDriver             : INTEGER;

VAR   I, J, K, MapType, M, X1,Y1,
      X2, Y2, SX, SY, CENTER  : INTEGER;

VAR   L, L1, LONGR, LSTEP,
      B, LATR, BSTEP, X, Y,
      PHI1, Lambda0           : REAL;

VAR   XX, YY, SA, SB          : REAL;

VAR   LastPtVis, GRID         : BOOLEAN;
VAR   CH                      : CHAR;

FUNCTION ArcCos(X: REAL): REAL;
BEGIN
    IF  ABS(X) < 1  THEN ArcCos:= ARCTAN(SQRT(1-SQR(X))/X)
    ELSE  IF X = 1  THEN ArcCos:=  0
    ELSE  IF X =-1  THEN ArcCos:= PI;
END;   { ArcCos. }

FUNCTION ArcSin(X: REAL): REAL;
BEGIN
    IF ABS(X) < 1  THEN ArcSin:= ARCTAN(X/SQRT(1-SQR(X)))
    ELSE IF X = 1  THEN ArcSin:= HalfPI
    ELSE IF X =-1  THEN ArcSin:=-HalfPI;
END;    { ArcSin. }

FUNCTION ArcTanH(X : Real):  Real;
VAR A,T :  REAL;
BEGIN
    T:=ABS(X);
    IF T < 1 THEN
    BEGIN
       A := 0.5 * LN((1 + T)/(1 - T));
       IF X < 0 THEN ArcTanH := -A ELSE ArcTanH :=A;
    END;
END;  { ArcTanH. }

FUNCTION Meridian(Lambda, Lambda0: REAL):REAL;
{ Returns difference between current longitude and map center. }
VAR DelLam : REAL;
BEGIN
    DelLam := Lambda - Lambda0;
    IF DelLam < -PI THEN DelLam := DelLam + TwoPI
    ELSE
    IF DelLam >  PI THEN DelLam := DelLam - TwoPI;
    Meridian:=DelLam;
END;   { Meridian. }

PROCEDURE Mercator(Lambda, Lambda0, Phi, R : REAL; VAR X, Y : REAL);
{ For R = 1: -Pi <= X <= Pi, -Pi/2 <= Y <= Pi/2.  }
CONST MaxLat : REAL = 1.397;   {~80 degrees. }
     { REAL = 1.483;    ~85 degrees. }
BEGIN
    IF ABS(Phi) < MaxLat THEN
    BEGIN
       Lambda := Meridian(Lambda, Lambda0);
       X := R * Lambda;
       Y := R * ArcTanH(SIN(Phi));
    END
    ELSE X := NotVisible;
END;   { Mercator. }

PROCEDURE EquiCyl(Lambda, Lambda0, Phi, Phi1, R : REAL; VAR X, Y : REAL);
{ For R = 1: -Pi <= X <= Pi, -Pi/2 <= Y <= Pi/2. }
BEGIN
    Lambda := Meridian(Lambda, Lambda0);
    X := R * Lambda * COS(Phi1);
    Y := R * Phi;
END;   { EquiCyl. }

PROCEDURE Sinusoidal(Lambda, Lambda0, Phi, R : REAL; VAR X, Y : REAL);
{ For R = 1:  -Pi <= X <= Pi  and  -Pi/2 <= Y <= Pi/2. }
BEGIN
     Lambda := Meridian(Lambda, Lambda0);
     X := R * Cos(Phi) * Lambda ;
     Y := R * Phi;
END;  { Sinusoidal. }

PROCEDURE Hammer(Lambda, Lambda0, Phi, R : REAL; VAR X, Y : REAL);
{ For R = 1: -2û2 <= X <=2û2  and  - û2 <= Y <= û2. }
VAR K, CosPhi, HalfLambda        : REAL;
BEGIN
    HalfLambda := 0.5*Meridian(Lambda, Lambda0);
    CosPhi:=COS(Phi);
    K := R * SQRT2 / SQRT(1 +CosPhi * COS(HalfLambda));
    X := 2 * K * CosPhi * (SIN(HalfLambda));
    Y := K * SIN(Phi);
END;  { Hammer. }

PROCEDURE Orthographic(Lambda, Lambda0, Phi, Phi1, R: REAL; VAR X, Y : REAL);
{ For R = 1: -2 <= X,Y <= 2. }
VAR CosC, CosL, SinPhi1, CosPhi1, SinPhi, CosPhi, R2 :  Real;
BEGIN
    Lambda :=Meridian(Lambda, Lambda0);  R2:=R+R;
    CosPhi1:=COS(Phi1);   SinPhi1:=SIN(Phi1);
    CosPhi :=COS(Phi);    SinPhi:= SIN(Phi);
    CosL   :=COS(Lambda)*CosPhi;
    CosC   :=SinPhi1 * SinPhi + CosPhi1 * COSL;
    IF CosC >= 0 THEN
    BEGIN
       X :=R2 * CosPhi * SIN(Lambda);
       Y :=R2 * (CosPhi1 * SinPhi - SinPhi1 * COSL);
    END ELSE X:=NotVisible;
END;  { Orthographic. }

PROCEDURE Beep;
{ Sounds a tone when map is complete. }
BEGIN
    Sound(880);  Delay(250);  NoSound;
END;

PROCEDURE PlotPt(VAR LastPtVis: BOOLEAN);
{ Draws a line from the last point to the current (XP,YP) if it is visible. }
VAR IX,IY: INTEGER;
LABEL XIT;
BEGIN
    IX:=ROUND(XP); IY:=ROUND(YP);
    IF LastPtVis THEN Line(LastX,LastY,IX,IY);
    LastX:=IX; LastY:=IY;
    LastPtVis:=TRUE;
  XIT:
END; { PlotPt. }

PROCEDURE CoordinateGrid(OUTLINE: BOOLEAN; MapType: INTEGER);
CONST LatitudeSpacing  = 30;
      LongitudeSpacing = 30;

VAR Longitude, Latitude, LatLimit,
    MaxLat, LongIncr, LatIncr      : INTEGER;
VAR LL, PP, A, R2, RA, XN, YN,
    SINDT, COSDT                   : REAL;
BEGIN
    CASE MapType OF
       1: BEGIN   MaxLat:=80;  LongIncr:=360;  LatIncr:=160;    END;
       2: BEGIN   MaxLat:=90;  LongIncr:=360;  LatIncr:=180;    END;
       3: BEGIN   MaxLat:=90;  LongIncr:=360;  LatIncr:=5;      END;
    4..5: BEGIN   Maxlat:=90;  LongIncr:=5;    LatIncr:=5;      END;
    END;  { CASE...}

    LL:=0;  PP:=Phi1;
    IF OUTLINE THEN
    BEGIN
        IF MapType = 5 THEN PP:=0;
        LatLimit:=MaxLat;              { Draw only extreme latitudes }
                                       { to make map outline         }
    END
    ELSE LatLimit:= MaxLat DIV LatitudeSpacing*LatitudeSpacing;

    Latitude:=LatLimit;

    WHILE Latitude >= -LatLimit DO      { Draw parallels }
    BEGIN
       LATR:=Latitude*Radian;
       LastPtVis:=FALSE;

       Longitude:=-180;
       WHILE Longitude <= 180 DO
       BEGIN
          LONGR:=Longitude*Radian;

          CASE MapType OF
          1: BEGIN MERCATOR(LONGR, LL, LATR, R, X, Y);      END;
          2: BEGIN EQUICYL(LONGR, LL, LATR, PP, R, X, Y);   END;
          3: BEGIN SINUSOIDAL(LONGR, LL, LATR, R, X, Y);    END;
          4: BEGIN HAMMER(LONGR, LL, LATR, R, X, Y);        END;
          5: BEGIN ORTHOGRAPHIC (LONGR, LL, LATR, PP, R, X, Y); END;
          END;  { CASE...}

          IF X > -300 THEN
          BEGIN
             XP:=ROUND(X*ASPECT)+XCENTER;
             YP:=YCENTER-ROUND(Y);
             PlotPt(LastPtVis);
          END ELSE LastPtVis:=FALSE;

          Longitude:=Longitude+LongIncr;
       END;

       IF OUTLINE THEN
            Latitude:=Latitude-2*MaxLat
       ELSE
            Latitude:=Latitude-LatitudeSpacing;
       END;

       IF OUTLINE THEN LL:=0 ELSE LL:=Lambda0;

       Longitude:=-180;                   { Draw meridians }

       IF MapType >= 4 THEN MaxLat:=90;
       WHILE Longitude <= 180 DO
       BEGIN
          LONGR:=Longitude*Radian;
          LastPtVis:=FALSE;
          Latitude:=MaxLat;
          WHILE Latitude >= -MaxLat DO
          BEGIN
             LATR:=Latitude*Radian;

             CASE MapType OF
             1: BEGIN MERCATOR(LONGR, LL, LATR, R, X, Y);      END;
             2: BEGIN EQUICYL(LONGR, LL, LATR, PP, R, X, Y);   END;
             3: BEGIN SINUSOIDAL(LONGR, LL, LATR, R, X, Y);    END;
             4: BEGIN HAMMER(LONGR, LL, LATR, R, X, Y);        END;
             5: BEGIN ORTHOGRAPHIC( LONGR, LL, LATR, PP, R, X, Y); END;
             END;  { CASE...}

          IF X > -300 THEN
          BEGIN
             XP:=ROUND(X*ASPECT)+XCENTER;
             YP:=YCENTER-ROUND(Y);
             PlotPt(LastPtVis);
          END ELSE LastPtVis:=FALSE;

          Latitude:=Latitude-LatIncr;
     END;

     IF OUTLINE THEN
          Longitude:=Longitude+360
     ELSE
          Longitude:=Longitude+LongitudeSpacing;
 END;

 IF OUTLINE AND (MapType=5) THEN
 BEGIN
    A:=0;                           { Draw circular outline }
    LastPtVis:=False;
    R2:=R + R;
    RA:= R2 * Aspect;
    SINDT:= 0.05996400648;
    COSDT:= 0.99820053993;
    X:=1;   Y:=0;
    XP:= ROUND(XCENTER + RA);
    YP:= ROUND(YCENTER);
    PlotPt(LastPtVis);
    WHILE A <= TwoPI DO
    BEGIN                           { Compute points on the circle }
       XN:= X * COSDT - Y * SINDT;
       YN:= X * SINDT + Y * COSDT;
       X:= XN;  Y:= YN;
       XP:= XCENTER + ROUND(X*RA);
       YP:= YCENTER + ROUND(Y*R2);
       PlotPt(LastPtVis);
       A:= A+0.06;
    END; { While. }
  END;
END;  { CoordinateGrid. }

PROCEDURE DrawMap(MapType: INTEGER);
VAR Latitude, Longitude : REAL;
VAR LastX : INTEGER;
LABEL XIT;
BEGIN
    LastPtVis:=FALSE; LastX:=0;

    ASSIGN(LLF, '\TP\PROGS\WORLD.DAT');  RESET(LLF);
    WHILE NOT EOF(LLF) DO
    BEGIN
       READ(LLF, LL);
       IF KeyPressed THEN GOTO XIT;
       LONGR:=LL.LONGI * RadianDiv100;
       LATR :=LL.LATI  * RadianDiv100;

       IF LL.CODE = 'LS' THEN LastPtVis:=FALSE;
       IF (LL.CODE = 'S ') OR (LL.CODE = 'LS') THEN
       BEGIN
          CASE MapType OF
          1: BEGIN MERCATOR(LONGR, Lambda0, LATR, R, X, Y);      END;
          2: BEGIN EQUICYL(LONGR, Lambda0, LATR, Phi1, R, X, Y); END;
          3: BEGIN SINUSOIDAL(LONGR, Lambda0, LATR, R, X, Y);    END;
          4: BEGIN HAMMER(LONGR, Lambda0, LATR, R, X, Y);        END;
          5: BEGIN ORTHOGRAPHIC(LONGR, Lambda0, LATR, Phi1, R, X, Y);  END;
          END;  { CASE...}

          IF X > -300 THEN
          BEGIN
             XP:=ROUND(X*ASPECT)+XCENTER;
             IF ABS(LastX-XP) > 100 THEN LastPtVis:=FALSE;
             YP:= YCENTER-ROUND(Y);
             PlotPt(LastPtVis);  LastX:=XP;
          END ELSE LastPtVis:=FALSE;
       END;
    END;
 XIT:
END;  { DrawMap. }

(* ---------------------  MAIN  PROGRAM  ------------------ *)

VAR RESP : CHAR;
LABEL XIT;
BEGIN
    MapType:=1;
    WHILE MapType > 0 DO      (*       MENU       *)
    BEGIN
        ClrScr;

        GOTOXY(24,1);  WRITE('C A R T O G');
        LowVideo;
{! 1. Th^e effects of HighVideo,LowVideo,NormVideo are different in Turbo 4.0.}
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
        NormVideo;
{! 2. Th^e effects of HighVideo,LowVideo,NormVideo are different in Turbo 4.0.}
        WRITELN;
        WRITELN;
        WRITE(' ':6,'1. Mercator');
        WRITELN(' ':21,'4. Hammer');
        WRITE(' ':6,'2. Equidistant Cylindrical');
        WRITELN(' ':6,'5. Orthographic');
        WRITELN(' ':6,'3. Sinusoidal');
        WRITELN;
        WRITE(' ':8,'Projection number (1-5) or 0 to quit:   ');
        READLN(MapType);
        If MapType = 0 THEN GOTO XIT;

        WRITELN;
        WRITE(' ':8,'Central Longitude of Map (default = 0): ');
        Lambda0:=0;
        READLN(Lambda0);  Lambda0:=Lambda0*Radian;

        IF (MapType = 2) OR (MapType = 5) THEN
        BEGIN
            WRITE(' ':8,'Central Latitude  of Map (default = 0): ');
            Phi1:=0;  READLN(Phi1);
            IF Phi1 = 90 THEN Phi1 := HalfPI
            ELSE
            Phi1:=Phi1*Radian;
        END;

        IF MapType >= 4 THEN R:=83 ELSE R:=70;
        WRITE(' ':8,'Plot grid, continents or both (G/C/B)?  ');
        READLN(RESP);  RESP:=UPCASE(RESP);
        GRID:=(RESP ='G') OR (RESP = 'B');
        GraphDriver := VGA   { ATT400 };
        GraphMode   := VGAHi { ATT400HI };
        InitGraph(GraphDriver,GraphMode,'');
(*
        HiRes;  HiResColor(15);            { Set CGA Graphics Mode }
*)
        IF GRID THEN CoordinateGrid(FALSE,  MapType);
        CoordinateGrid(TRUE, MapType);

        IF (RESP = 'B') OR (RESP = 'C') THEN DrawMap(MapType);
      Beep;
    XIT:

    IF MapType > 0 THEN
       While NOT KeyPressed DO ;           { Wait for key strike }
      CloseGraph;
(*    TEXTMODE(BW80);                        { Return to Text Mode }
*)
    ClrScr;
    END;  { WHILE MapType > 0...}
END.


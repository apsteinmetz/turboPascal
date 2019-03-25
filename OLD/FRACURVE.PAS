PROGRAM Fracurve;
{$n+}
{$R+}
{
  USAGE: FRACURVE <DataFile> <Sides> <Level>
  where <DataFile> is the file containing the turn angles of the generator
  <Sides> is the number of sides on the a regular polygon initiatior
  <Level> is the depth of the recursion
}


Uses GraphPrm,  TurtleO;

CONST
  MaxGeneratorFacets = 50;
  MaxInitiatorSides  = 20;
  Triangle = 3;
  Square   = 4;

TYPE

  InitiatorRec = RECORD
     Sides : BYTE { number of sides };
     { points on a 1..-1 grid. Will be scaled to display size }
     x,y  : ARRAY[1..MaxInitiatorSides+1] OF SINGLE;
  END;

  VonKochRec = RECORD
     Facets  : BYTE   {number of facets};
     Divisor : SINGLE { segment length per initator side };
     { sequence of turtle turn angles }
     Angle : ARRAY[1..MaxGeneratorFacets] OF SINGLE;
  END;

VAR
  i, level,
  sides     : BYTE;
{ T         : TurtleObj; }
  Initiator : InitiatorRec;
  Generator : VonKochRec;

{ -------------------------------------------------------- }
FUNCTION LineLength(x1,y1,x2,y2 : SINGLE) : SINGLE;

BEGIN
  LineLength :=  sqrt(sqr(x2-x1) + sqr(y2-y1));
END;

{ -------------------------------------------------------- }
PROCEDURE ScalePoint(VAR x,y : SINGLE);
BEGIN
  x := x * HalfWidth;
  y := y * HalfHeight;
END;

{ -------------------------------------------------------- }
PROCEDURE ScaleInitiator(VAR I : InitiatorRec);
VAR
  n : WORD;

BEGIN
  FOR n := 1 TO I.Sides+1 DO
    ScalePoint(I.x[n],I.y[n]);
END;

{ -------------------------------------------------------- }
PROCEDURE DrawInitiator(PGon : InitiatorRec);
VAR
  k : INTEGER;
  T : TurtleObj;

BEGIN
WITH PGon DO
BEGIN
  T.init(x[1],y[1]);
  T.ChangeStep(LineLength(x[1],y[1],x[2],y[2]));
  T.StartDrawing;
  FOR k := 1 TO Sides DO
  BEGIN
      T.Point(x[k],Y[k],x[k+1],Y[k+1]);
      T.Step;
    END;
END;
END;


{ -------------------------------------------------------- }
PROCEDURE Generate( x1,y1,x2,y2 : SINGLE;
                    Level : INTEGER;
                    VAR Gen : VonKochRec);

VAR
 T : TurtleObj;
 i, j, k    : INTEGER;
 Xpoints,
 Ypoints : ARRAY[0..MaxGeneratorFacets] OF SINGLE;

BEGIN
  Level := Level - 1;
  T.Init(x1,y1);
  T.ChangeStep(LineLength(x1,y1,x2,y2) / Gen.Divisor);
  Xpoints[0] := x1;
  Ypoints[0] := y1;
  Xpoints[Gen.Facets] := x2;
  Ypoints[Gen.Facets] := y2;
  T.Point(x1,y1,x2,y2);
  FOR i := 1 TO Gen.Facets - 1 DO
  BEGIN
    T.Turn(Gen.Angle[i]);
    T.Step;
    Xpoints[i] := T.x;
    Ypoints[i] := T.y;
  END;

  IF Level > 0 THEN
     FOR j := 0 TO Gen.Facets - 1 DO
     BEGIN
       x1 := Xpoints[j];
       x2 := Xpoints[j+1];
       y1 := Ypoints[j];
       y2 := Ypoints[j+1];
       Generate(x1,y1,x2,y2,Level,Gen);
     END

  ELSE
     FOR k := 0 TO Gen.Facets - 1 DO
        DrawLine(TRUNC(Xpoints[k]),TRUNC(Ypoints[k]),
            TRUNC(Xpoints[k+1]),TRUNC(Ypoints[k+1]),15);

END {Generate};

{ -------------------------------------------------------- }
PROCEDURE Initialize(VAR PGon : InitiatorRec; PolySides : WORD);
{ creates a regular polygon scaled to display size }

CONST
  SizeFactor = 1.75;

VAR
  PolyAngle,
  StepSize,
  x0,y0      : SINGLE;
  i : WORD;
  T : TurtleObj;

BEGIN
  PolyAngle := 360 / PolySides;
  StepSize := DisplayHeight/PolySides * SizeFactor;
  x0 := StepSize / 2 {offset to the right};
  y0 := -DisplayHeight/(2*Pi) * SizeFactor;
  T.Init(x0,y0);
  T.ChangeStep(StepSize);

  PGon.sides := PolySides;

  {set start and end point the same }
  PGon.x[1] := x0;
  PGon.y[1] := y0;
  PGon.x[PolySides+1] := x0;
  PGon.y[PolySides+1] := y0;

  FOR i := 2 to PolySides DO
  BEGIN
    T.Turn(PolyAngle);
    T.Step;
    PGon.x[i] := T.x;
    PGon.y[i] := T.y;
  END;
END;

{ -------------------------------------------------------- }
PROCEDURE GetParams( VAR Gen : VonKochRec;
                     VAR Sides, Level : BYTE);
VAR
  vkfile : TEXT;
  instr : STRING;
  err, i : INTEGER;

  PROCEDURE NextDataLine;
  {skip lines with ';' as comments}
  BEGIN
    REPEAT
        readln(vkfile,instr)
    UNTIL pos(';',instr) = 0;
  END;

BEGIN
 val(paramstr(2),Sides,err);
 val(paramstr(3),Level,err);
 assign(vkFile,paramstr(1));
 reset(vkFile);
 NextDataLine;
 val(instr,Gen.Divisor,err);
 Gen.Facets := 0;
 WHILE NOT eof(vkFile) DO
 BEGIN
   inc(Gen.Facets);
   NextDataLine;
   val(instr,Gen.angle[Gen.Facets],err);
   IF err > 0 THEN dec(Gen.Facets);
 END;
END;

{ -------------------------------------------------------- }

BEGIN

(*
  Write('What Data File? ');
  Read(level);
  IF level < 1 THEN level := 1;

  Write('Enter Level (number from 1 to 10) ');
  Read(level);
  IF level < 1 THEN level := 1;

  Write('How many Initiator Sides? (number from 3 to 20) ');
  Read(Sides); Readln;
  IF Sides < 3 THEN Sides := 3;
  IF Sides > 20 THEN Sides := 20;
*)

  GetParams(Generator,Sides,Level);
  Initialize(Initiator,Sides);

  setmode(16);
  cls(0);

  IF Level = 0 THEN
     DrawInitiator(Initiator)
  ELSE
    FOR i := 1 TO Initiator.Sides DO
      generate(Initiator.x[i],Initiator.Y[i],
               Initiator.x[i+1],Initiator.y[i+1],level, Generator);

  ReadLn;
  SetMode(0);
END.

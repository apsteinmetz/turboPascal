program FRACSC3D;
{$M 50000, 0, 655360}
{$I Float.INC}

uses MathLib0,
     Sculpt3D,
     FracSurf { DoFractal, AlgorithmType };

CONST
  Size  = 4;
  Size2 = 8; { 2 * Size }
  ReliefFactor = 0.5;  { between 0 and 1 }

TYPE
  Surface       = ARRAY[0..Size,0..Size] OF WORD;
  SculptSurface = ARRAY[0..Size,0..Size] OF VertexPtr;
  SculptPerim   = SculptSurface {ARRAY[0..4*Size-1]     OF VertexPtr }
    (* will become psuedo 2D array *);
  SurfPtr = ^Surface;
  SculptSurfacePtr = ^SculptSurface;
  SculptPerimPtr   = ^SculptPerim;

VAR
  Floating     : BOOLEAN;
  TerrainObj   : ObjectRec;
  Terrain      : ObjectPtr;
  FractalSurf  : SurfPtr;


{ --------------------------------------------------------- }
FUNCTION ndx(i,j : WORD) : WORD;
{ Converts perimeter indicies of 2D array to 1D }
{ for max speed no error checking on indicies! }

BEGIN
   ndx := i + j + (ORD(j > i) * Size2);
END;

{ --------------------------------------------------------- }
PROCEDURE ConnectToGround( obj : ObjectPtr;
                           x, y : WORD;
                           Surf : SculptSurfacePtr;
                           Perim : SculptPerimPtr );
VAR
  prop : FaceProperty;

BEGIN

    { link edges of x side to floor }
    IF (x = 0) OR (x = Size) THEN
    BEGIN
      { link to vertex directly below }
      Link(obj, Surf^[x,y], Perim^[x,y], prop);
      IF y < Size THEN
         { also link to vertex adjacent to make triangle }
         Link(obj, Surf^[x,y], Perim^[x,y+1], prop);
      { END; }
    END;

    { link edges of y side to floor }
    IF (y = 0) OR (y = Size) THEN
    BEGIN
      { link to vertex directly below }
      Link(obj, Surf^[x,y], Perim^[x,y], prop);
      IF x < Size THEN
          { also link to vertex adjacent to make triangle }
          Link(obj, Surf^[x,y], Perim^[x+1,y], prop);
      { END; }
    END;

    { connect the edges of the floor }
    IF (Y = 0) AND (x < Size) THEN
    BEGIN
        Link(obj, Perim^[x,0], Perim^[x+1,0],prop);
        Link(obj, Perim^[x,Size], Perim^[x+1,Size],prop);
    END
    ELSE IF (Y < Size) { x must = 0 } THEN
    BEGIN
        Link(obj, Perim^[0,y], Perim^[0,y+1],prop);
        Link(obj, Perim^[Size,y], Perim^[Size,y+1],prop);
    END;
END {ConnectToGround};

{ --------------------------------------------------------- }
PROCEDURE MakeFractalObject(obj : ObjectPtr; SurfB : SurfPtr);

VAR
  Surf  : SculptSurfacePtr;
  Perim : SculptPerimPtr;
  x, y  : WORD;
  prop  : FaceProperty;

BEGIN
  { allocate surface structures }
  GetMem(Surf,SizeOf(SculptSurface));
  GetMem(Perim,SizeOf(SculptPerim));
  IF (Surf = NIL) OR (Perim=NIL) THEN
  BEGIN
    Writeln('Not Enough Memory!');
    Halt;
  END;

  { initialize vertex structures for surface }
  FOR x := 0 TO Size DO
      FOR y := 0 TO Size DO
      BEGIN
         IF NOT Floating AND
            ( (x=0) OR (y=0) OR (x=Size) OR (y=size) )  THEN
         BEGIN
              { make floor perimeter vertices }
              Perim^[x,y] := NewVertex(x, y, 0, obj^.vertices);
              obj^.vertices := Perim^[x,y];
         END;
         { put altitude data in vertices }
         Surf^[x,y] := NewVertex(x,y,SurfB^[x,y],obj^.vertices);
         obj^.vertices := Surf^[x,y];
      END;
  { END; }

  { Okay, we've transfered the data so get rid of the orig. surface }
  FreeMem(SurfB,SizeOf(Surface));

  { make triangles and link vertices on surface }
  FOR x := 0 TO Size DO
  BEGIN
      FOR y := 0 TO Size DO
      BEGIN
          IF x < Size THEN
             { link to adjacent vertex on x axis }
             Link(obj, Surf^[x,y], Surf^[x+1,y], prop);
          {END;}

          IF y < Size THEN
             { link to adjacent vertex on y axis }
             Link(obj, Surf^[x,y], Surf^[x,y+1], prop);
          {END;}

          IF (x < Size) AND (y < Size) THEN
             { link to diagonally adjacent vertex to make triangle }
             Link(obj, Surf^[x,y], Surf^[x+1,y+1], prop);
          {END;}
          IF NOT Floating AND
              ( (x=0) OR (y=0) OR (x=Size) OR (y=Size) ) THEN
             ConnectToGround(obj, x, y, Surf, Perim);

      END { FOR y };
  END  { FOR x };
  FreeMem(Surf,SizeOf(SculptSurface));
  FreeMem(Perim,SizeOf(SculptPerim));

END {MakeFractalObject};

VAR
  x, y : WORD;
BEGIN
  Floating := (paramstr(1) = 'F');
  NewObject(TerrainObj);
  Terrain := @TerrainObj;
  GetMem(FractalSurf,SizeOf(Surface));
  IF FractalSurf = NIL THEN
  BEGIN
      Writeln('Not enough memory for fractal surface');
      HALT;
  END;
  Writeln('Computing Fractal');
{  DoFractal(FractalSurf^, ReliefFactor, Voss); }
  FOR x := 0 TO Size DO
    FOR y := 0 TO Size DO
      FractalSurf^[x,y] := 10;
  Writeln('Making Object');
  MakeFractalObject(Terrain,FractalSurf);
  Writeln('Euler Number:',GetEulerNum);
  WriteLn('Done');
END.
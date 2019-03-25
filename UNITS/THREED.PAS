unit THREED;

{$I FLOAT.INC}

{$R+ Range checking }
{$S+ Stack checking }

 interface

 USES
   CRT,
   graph,
   MathLib0,  { Float }
   Memory;

 CONST
  size = 2; {Max array index}
  cell = 7;  { smallest screen dimension / size }

TYPE
  surface = array[0..size, 0..size] of longint;

  OrientRec =  RECORD
            tilt, rota : WORD;
            Xdiff, Ydiff,
            Zdiff         : longint;
            CTilt, STilt,
            CRota,SRota,
            XMean,Zmean, YMean :    Float;
        end;

   SurfaceRec = RECORD
        Orient  : OrientRec;
        size    : WORD; {max XY dimension of surface }
        surfptr : ^surface;
    END;

PROCEDURE mapDisp(surface : surfacerec);

PROCEDURE GetOrientation(VAR srf : SurfaceRec; Atilt, rotation : WORD);

FUNCTION GetSeaLevel( srf : SurfaceRec;
                      Splitpct : WORD {pct "below water" } ) : LONGINT;

PROCEDURE FlatSea(VAR srf: SurfaceRec; SeaLevel : LONGINT);

PROCEDURE project(VAR pt : PointType; srf : SurfaceRec; r,c : WORD);

PROCEDURE Animate(srf : SurfaceRec);

PROCEDURE shaded(srf : SurfaceRec; altitude, azimuth : WORD);

PROCEDURE wireframe(srf : SurfaceRec; stepsize : longint);

{=======================================================================}
implementation

CONST
  grayscale : ARRAY[0..8] of  FillPatternType =
                        (($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF),
                         ($FF,$77,$FF,$DD,$FF,$77,$FF,$DD),
                         ($FF,$55,$FF,$55,$FF,$55,$FF,$55),
                         ($BB,$55,$EE,$55,$BB,$55,$EE,$55),
                         ($AA,$55,$AA,$55,$AA,$55,$AA,$55),
                         ($AA,$11,$AA,$44,$AA,$11,$AA,$44),
                         ($AA,$00,$AA,$00,$AA,$00,$AA,$00),
                         ($88,$00,$22,$00,$88,$00,$22,$00),
                         ($00,$00,$00,$00,$00,$00,$00,$00));

TYPE

  rect = record
          topleft,topright,
          botright,botleft,
          dummy             : PointType;  {always set dummy := topleft }
        end;

  Rhombus = ARRAY[0..4] OF PointType;
            { always set [4] := [0] to close figure }

  Vector = ARRAY[1..3] OF Float;


  twohts = array[1..2] of longint;
  levarray = array[0..8] of longint;

VAR
  DegToRad  : FLOAT;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE minmax(VAR mm : twohts ; srf : SurfaceRec);

{Min surface height is minmax[1], max is minmax[2]}
  var
   r, c, altitude : longint;

begin
  mm[1] := maxlongint;
  mm[2] := -maxlongint;
  for r := 0 to size do
   for c := 0 to size do
    begin
     altitude := srf.surfptr^[r, c];
     if altitude < mm[1] then
        mm[1] := altitude;
     if altitude > mm[2] then
        mm[2] := altitude;
    end;
 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE MakeRect(VAR r : rect; topl, botr : PointType);
begin
  r.topleft    := topl;
  r.botright   := botr;
  r.topright.X := botr.x;
  r.topright.Y := topl.y;
  r.botleft.X  := topl.x;
  r.botleft.Y  := botr.y;
  r.dummy      := topl;   { close figure }
end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 PROCEDURE paintpt (row, col : longint);
{Fill a cell x cell square with penpat}

VAR
  pt , Pt2 : PointType;
  rct : rect;

 begin
  pt.x := row * cell;
  pt.y := col * cell;
  pt2.x := (row + 1) * cell;
  pt2.y := (col + 1) * cell;
  MakeRect(rct,pt,pt2);

  FillPoly(5, rct);

 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
  FUNCTION DTR(X:Float):Float;
    begin
     DTR := X / (DegToRad * 100)
    end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE GetOrientation(VAR srf : SurfaceRec; Atilt, rotation : WORD);
VAR
  mm : twohts;

BEGIN
   minmax(mm,srf);
   with srf.Orient do
   begin
     Tilt := (ATilt + 180) mod 360;
     Rota := Rotation mod 360;
     CTilt := Cos(DTR(Tilt));
     STilt := Sin(DTR(Tilt));
     CRota := Cos(DTR(Rota));
     SRota := Sin(DTR(Rota));
     Zdiff := abs(mm[2] - mm[1]);
     Zmean := (mm[1] + mm[2])/2;
     Xmean := size / 2;
     Ymean := size /2;
     Xdiff := size;
     Ydiff := size;
   end;
end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
FUNCTION GetSeaLevel( srf : SurfaceRec;
                      Splitpct : WORD {pct "below water" } ) : LONGINT;

BEGIN
   GetSeaLevel := trunc( srf.orient.Zmean +
         srf.orient.Zdiff * (splitpct/100 - 0.50) );
END;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE FlatSea(VAR srf: SurfaceRec; SeaLevel : LONGINT);
  var
   r, c : longint;

 begin
  for r := 0 to size do
   for c := 0 to size do
     if srf.surfptr^[r, c] < SeaLevel then
      srf.surfptr^[r, c] := SeaLevel
 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE project(VAR pt : PointType; srf : SurfaceRec; r,c : WORD);

const ZoomFactor = 1.3;


var
   X2, Y2, Z2,
   X3, Y3     : Float;

begin
  with srf.Orient do
  begin
     X2 := (c-Xmean) / XDiff;
     Y2 := (r-Ymean) / YDiff;
     if ZDiff = 0 then Z2 := 0
     else
       Z2 := (srf.surfptr^[r,c] - Zmean) / ZDiff;
     X3 := X2 * CRota - Y2 * SRota;
     Y3 := Z2 * CTilt - (X2 * SRota + Y2 * CRota) * STilt;
     pt.X := Round(GetMaxX * (DegToRad * X3 * ZoomFactor + 0.5));
     pt.Y := Round(GetMaxY * (DegToRad * Y3 * ZoomFactor+ 0.5));
   end; {with}
end; {proj}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE projectXYZ( VAR pt : PointType;
                      Orientation : OrientRec;
                      X,Y,Z : FLOAT);

const ZoomFactor = 1.3;


var
   X2, Y2, Z2,
   X3, Y3     : Float;

begin
  with Orientation do
  begin
     X2 := (X-Xmean) / XDiff;
     Y2 := (Y-Ymean) / YDiff;
     if ZDiff = 0 then Z2 := 0
     else
       Z2 := (Z - Zmean) / ZDiff;
     X3 := X2 * CRota - Y2 * SRota;
     Y3 := Z2 * CTilt - (X2 * SRota + Y2 * CRota) * STilt;
     pt.X := Round(GetMaxX * (DegToRad * X3 * ZoomFactor + 0.5));
     pt.Y := Round(GetMaxY * (DegToRad * Y3 * ZoomFactor+ 0.5));
   end; {with}
end; {projextXYZ}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE shade ( srf : SurfaceRec;
                  solar : Vector;
                  row, col : longint);
{Selects a gray shade for a patch}
  var
   i : longint;
   dim, ill, normlen : Float;
   normal : Vector;

 begin
  dim := 100 / srf.orient.Zdiff;
  {Cross product of two vectors}
  normal[1] := -dim * (srf.surfptr^[row, col] - srf.surfptr^[row + 1, col]);
  normal[2] := -dim * (srf.surfptr^[row, col] - srf.surfptr^[row, col + 1]);
  normal[3] := 1;
  normlen := sqrt(sqr(normal[1]) + sqr(normal[2]) + sqr(normal[3]));
    {Vector length }
  for i := 1 to 3 do
   normal[i] := normal[i] / normlen; {Normalize vector}
  ill := 0;
  for i := 1 to 3 do
   ill := ill + solar[i] * normal[i]; {Dot product of normal and solar}
  if ill < 0 then
   setfillpattern(grayscale[0],Green)
  else
   setfillpattern(grayscale[round(ill * 7.9)],Green); {Set gray level}
 end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 PROCEDURE shadeframe(srf : SurfaceRec; solar : Vector);
{Shades surface}
  var
   r, c : longint;
   patch : Rhombus;
   SeaLevel : LONGINT;

 begin
  SeaLevel := GetSeaLevel(srf,50);
{  FlatSea(srf,SeaLevel); }
  SetColor(0);
  for r := 0 to size - 1 do
   for c := 0 to size - 1 do
    begin
     IF srf.surfptr^[r,c] > SeaLevel THEN BEGIN
        project(patch[0], srf,r , c);
        project(patch[1], srf,r,c + 1);
        project(patch[2], srf,r + 1, c + 1);
        project(patch[3], srf,r + 1, c);
        patch[4] := patch[0]; { close polygon }
        shade(srf, solar, r, c); {Get shade of patch}
        FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     END
     ELSE BEGIN
        projectXYZ(patch[0], srf.orient,c, r, SeaLevel);
        projectXYZ(patch[1], srf.orient,c + 1, r, SeaLevel);
        projectXYZ(patch[2], srf.orient,c + 1, r + 1, SeaLevel);
        projectXYZ(patch[3], srf.orient,c, r + 1, SeaLevel);
        patch[4] := patch[0]; { close polygon }
        setfillpattern(grayscale[0],Blue);
        FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     END;
    end;
 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE mapDisp(surface : surfacerec);

  var
   i : word;
   Pt, Pt2 : PointType;
   rct : rect;
   sum, row, col, levl, range : longint;
   lev : array[0..8] of longint;
   mm : twohts;
   legend : string;

begin
  range := surface.orient.Zdiff;
  sum := trunc(surface.orient.Zmean - (surface.orient.Zdiff / 2));
  levl := (range div 9) + 1; {Eight height zones, spearated by levl}
  for i := 0 to 8 do
   begin
    sum := sum + levl;
    lev[i] := sum; {Nine height zones, lev[1]-lev[8]}
   end;
{Legend}
  for i := 0 to 8 do
   begin
    SetFillPattern(GrayScale[i],GetMaxColor);
    pt.x := 625;
    pt.y := 10 + i * 15;
    pt2.x := 639;
    pt2.y := i * 15 + 20;
    MakeRect(rct,pt,pt2);
    FillPoly(sizeof(rect) div sizeof(PointType), rct);
    DrawPoly(sizeof(rect) div sizeof(PointType), rct);
    Str(lev[i]:8,legend);
    OutTextXY(625, i * 15 + 20,legend);
    SetTextJustify(LeftText,TopText); { restore defaults }
   end;
{Map}

  for row := 0 to size do
   for col := 0 to size do
    begin
     i := 0;
     while (surface.surfptr^[row, col] > lev[i]) do
      i := i + 1; {Compare height to zones}
      SetFillPattern(GrayScale[i],GetMaxColor);
      {Choose pattern corresponding to zone}
     paintpt(row, col);
    end;

end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE wireframeB(srf : SurfaceRec; stepsize : longint);
{Draws wireframe of surface}
  var
   r, c,
   highcount  : LONGINT;
   patch : Rhombus;
 begin

 { enclose plotting area }
  project(patch[0],srf,0,0);
  project(patch[1],srf,0,size);
  project(patch[2],srf,size,size);
  project(patch[3],srf, size,0);
  patch[4] := patch[0];
  DrawPoly(sizeof(rhombus) div sizeof(PointType), patch);

  highcount := size div stepsize;
  { plot the rows }
  FOR c := 0 to highcount DO
    FOR r := 0 TO highcount DO BEGIN
     {Define patch}
     project(patch[0], srf,(r * stepsize), (c * stepsize));
     project(patch[1], srf,(r * stepsize), (c+1) * stepsize);
     project(patch[2], srf,(r+1) * stepsize, (c+1) * stepsize);
     project(patch[3], srf,((r+1) * stepsize), (c* stepsize));
     patch[4] := patch[0];
     SetFillPattern(grayscale[8],Black);  { cover up behind }
     FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     DrawPoly(sizeof(rhombus) div sizeof(PointType), patch);
   END;
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE wireframe(srf : SurfaceRec; stepsize : longint);
{Draws wireframe of surface}
  var
   r, c,
   highcount  : longint;
   patch : Rhombus;
   NewRow : BOOLEAN;
 begin
  highcount := size div stepsize;
  { plot the rows }
  for c := 0 to highcount do
  begin
   NewRow := TRUE;
   for r := 0 to highcount do
    begin
     project(patch[0], srf,(r * stepsize), (c * stepsize));
     If NewRow then
     begin
       MoveTo(patch[0].X,patch[0].Y);
       NewRow := FALSE;
     end
     else
     {$IFDEF HIDDEN }
     begin
        HiddenLineTo(patch[0].X,patch[0].Y);
        MoveTo(patch[0].X,patch[0].Y);
     end;
     {$ELSE }
        LineTo(patch[0].X,patch[0].Y);
     {$ENDIF }
    end;
   end;
  { plot the columns }
  for r := 0 to highcount do
  begin
   NewRow := TRUE;
   for c := 0 to highcount do
    begin
     project(patch[0], srf,(r * stepsize), (c * stepsize));
     If NewRow then
     begin
       MoveTo(patch[0].X,patch[0].Y);
       NewRow := FALSE;
     end
     else
     {$IFDEF HIDDEN }
     begin
        HiddenLineTo(patch[0].X,patch[0].Y);
        MoveTo(patch[0].X,patch[0].Y);
     end;
     {$ELSE }
        LineTo(patch[0].X,patch[0].Y);
     {$ENDIF }
    end;
  end;
 end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE shaded(srf : SurfaceRec; altitude, azimuth : WORD);
{Gets solar vector, and shades surface}
 var
   alt, az : FLOAT;
  solar    : Vector;
  ch       : CHAR;

 begin
  alt := Altitude;
  alt := alt * pi / 180;
  az := Azimuth;
  az := az * pi / 180;
  {Convert az/alt to three component unit vector}
  solar[3] := sin(alt);
  solar[2] := sin(az) * cos(alt);
  solar[1] := cos(az) * cos(alt);
  shadeframe(srf, solar); {Shade surface}

 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE Animate(srf : SurfaceRec);
var
  err : INTEGER;
  tiltstr, rotastr : String;
  ch : CHAR;

BEGIN
with srf.Orient do
  begin
  repeat
    ClearViewPort;
    wireframe(srf, 8);
    str(tilt:3,tiltstr);
    str(rota:3,rotastr);
    OutTextXY(1,1,'Tilt: '+tiltstr+' Rotation: '+rotastr+
        '  Use Arrow keys. Hit "Q" to exit');
    Ch := ReadKey;
    CASE Ch OF
     #0:            { FUNCTION keys }
      begin
        ch := readkey;
        case Ch of
          #72: Tilt := (Tilt + 10 + 360) mod 360; { Up }
          #75: Rota := (Rota + 10 + 360) mod 360; { Left }
          #77: Rota := (Rota - 10 + 360) mod 360; { Right }
          #80: Tilt := (Tilt - 10 + 360) mod 360; { Down }
        end;
      end;
     #3 : BEGIN END;
    END; {CASE}
     CTilt := Cos(DTR(Tilt));
     STilt := Sin(DTR(Tilt));
     CRota := Cos(DTR(Rota));
     SRota := Sin(DTR(Rota));

  until (ch = #81) OR (ch = #113); { "Q" }
 end {with};
end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
(*
PROCEDURE ReadFile( DataFile : String);

BEGIN
{ read data file
 writeln('Reading data file.');
 assign(srfile,DataFile);
 reset(srfile);
 for row := 0 to size do
   for col := 0 to size do
     read(srfile, srf.surfptr^[row, col]);
 close(srfile);

END;
*)

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

BEGIN {MAIN}
  DegToRad := 180/pi/100;
END. {ThreeD}

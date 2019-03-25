{_______________________________________________________________

Fractal Landscape Generator

Accompanies "Mimicking Mountains," by Tom Jeffery,
BYTE, December 1987, page 337

revised:
12/11/87 by Art Steinmetz
   Version for IBM Turbo Pascal v.4.0
   Combines 3-D.pas, Map.pas
   Uses more flexible 3-D plotting routines.  Sped up wireframe.
______________________________________________________________
}

program FraclLand;
{Wireframe or shaded representation of a fractal surface}

(*
{$DEFINE DEBUG}
{$DEFINE HIDDEN} { USE HIDDEN LINE ALGORITHM }
*)
{$ifdef CPU87}
  {$N+}
{$else}
  {$N-}
{$endif}

{$R+ Range checking }
{$S+ Stack checking }
 uses
   Break, Crt, graph, MaxRes, FracSurf;


 const
  size = 64; {Max array index}
  cell = 6;  { smallest screen dimension / size }

  ScrWidth  = 640;  { Pixel Range depending on Screen Res = 640 | 320 }
  ScrHeight = 400;
  DegToRad  = 0.5729579; { 180 / Pi / 100 }

  datafile = 'd:SURFACE.FKL';
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

 type
{$ifdef CPU87}
   MyReal = REAL {extended};
{$else}
   MyReal = Real;
{$endif}

  Rhombus = ARRAY[0..4] OF PointType;
            { always set [4] := [0] to close figure }
  rect = record
          topleft,topright,
          botright,botleft,
          dummy             : PointType;  {always set dummy := topleft }
        end;

  twohts = array[1..2] of longint;
  levarray = array[0..8] of longint;

  OrientRec =  RECORD
            tilt, rota  : integer;
            Xdiff, Ydiff,
            Zdiff         : longint;
            CTilt, STilt,
            CRota,SRota,
            XMean,Zmean, YMean :    MyReal;
        end;

 var
  srf : surface;
  ans : string[10];
  srfile : file of longint;
  Method  : AlgorithmType;
  lineloc  : integer;
  Roughness : MyReal;
  col, row,
  range, cont     : longint;
  Orientation     : OrientRec;
  Hidden,
  OK        : BOOLEAN;

  Pt, pt2 : PointType;

  solar : array[1..3] of MyReal;
  az, alt : MyReal;
  rct : rect;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure WriteText(s : string);
var
  Hgt : integer;

begin
   Hgt := TextHeight('XXX');
   OutTextXY(0,lineloc,s);
   lineloc := lineloc + Hgt * 2;
   GotoXY(10,lineloc div (Hgt*2));
end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 procedure SetUpDrawing;
 begin
  InitNormGraph;
  SetTextStyle(DefaultFont,HorizDir,1);
  SetTextJustify(LeftText,TopText);
end;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure ClearDisplay;
begin
   ClearDevice;
   lineloc := TextHeight('XXX') div 2;
   SetColor(White);
end;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure ZeroArray;
begin
 for row := 0 to size do
   for col := 0 to size do
     srf[row, col] := 0;
end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure minmax(VAR mm : twohts);

{Min surface height is minmax[1], max is minmax[2]}
  var
   r, c : longint;

 begin
  mm[1] := maxlongint;
  mm[2] := -maxlongint;
  for r := 0 to size do
   for c := 0 to size do
    begin
     if srf[r, c] < mm[1] then
      mm[1] := srf[r, c];
     if srf[r, c] > mm[2] then
      mm[2] := srf[r, c];
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
 procedure paintpt (row, col : longint);
{Fill a cell x cell square with penpat}
 begin
  pt.x := row * cell;
  pt.y := col * cell;
  pt2.x := (row + 1) * cell;
  pt2.y := (col + 1) * cell;
  MakeRect(rct,pt,pt2);

  FillPoly(sizeof(rect) div sizeof(PointType), rct);

 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure mapDisp;
  var
   i : word;
   sum, row, col, levl, range : longint;
   lev : array[0..8] of longint;
   mm : twohts;
   legend : string;

begin
  minmax(mm);
  range := mm[2] - mm[1];
  sum := mm[1]; {Min height of surface}
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
    SetTextJustify(RightText,BottomText);
    OutTextXY(625, i * 15 + 20,legend);
   end;
{Map}

  for row := 0 to size do
   for col := 0 to size do
    begin
     i := 0;
     while (srf[row, col] > lev[i]) do
      i := i + 1; {Compare height to zones}
      SetFillPattern(GrayScale[i],GetMaxColor);
      {Choose pattern corresponding to zone}
     paintpt(row, col);
    end;

end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
  Function DTR(X:MyReal):MyReal;
    begin
     DTR := X / (DegToRad * 100)
    end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE GetOrientation;

BEGIN
   with Orientation do
   begin
     WriteText('Tilt? (0-359): ');
     readln(Tilt);
     WriteText('Rotation? (0-359): ');
     readln(Rota);
     Tilt := (Tilt + 180) mod 360;
     Rota := Rota mod 360;
     CTilt := Cos(DTR(Tilt));
     STilt := Sin(DTR(Tilt));
     CRota := Cos(DTR(Rota));
     SRota := Sin(DTR(Rota));
   end;
end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure SplitAltitude( VAR srf : surface;
               mm : twohts;
               splitpct : INTEGER {pct < 0 "below water" } );
VAR
   r,c    : INTEGER;
   adjust : LONGINT;

BEGIN
   adjust := mm[1] + trunc((mm[2]-mm[1]) * splitpct/100);
   for r := 0 to size do
     for c := 0 to size do
      srf[r, c] := srf[r,c] - adjust;
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 function rangefind : longint;
{Finds the difference between the highest}
{and lowest points on the surface}
  var
   min, max, r, c : longint;

 begin
  min := maxlongint;
  max := -maxlongint;
  for r := 0 to size do
   for c := 0 to size do
    begin
     if srf[r, c] < min then
      min := srf[r, c];
     if srf[r, c] > max then
      max := srf[r, c];
    end;

  with Orientation do
  begin
     Zdiff := max - min;
     Zmean := (max+min)/2;
     Xmean := size / 2;
     Ymean := Xmean;
     Xdiff := size;
     Ydiff := size;
  end;


  rangefind := max - min;

 end;

{$IFDEF HIDDEN }
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
Procedure PlotHidden(X,Y,LastX,LastY,XTst: longint);
var
   YTst       : longint;
   Visible    : Boolean;
   Low, High  : ARRAY[1..ScrWidth] of integer;

    {+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
     Procedure ClearArray;
     var
       I:  integer;
     begin
        for I := 1 to ScrWidth do
        begin
          Low[I]  := ScrHeight;
          High[I] := 0;
       end;
     end;

begin
     Visible := False;
     YTst := Round(LastY + (XTst-LastX) * (Y - LastY) / (X - LastX));
     If Low[XTst] > YTst then
     begin
          Low[Xtst] := Ytst;
          Visible := True;
     end;
     If High[Xtst] < Ytst then
     begin
          High[Xtst] := Ytst;
          Visible := True;
     end;
     If Visible then PutPixel(Xtst,Ytst,White);
end;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure HiddenLineTo(X,Y : integer);
var
   N, Xlast, Ylast : integer;
begin
  XLast := GetX;
  YLast := GetY;
  If X < XLast then
      for N := XLast downto X do PlotHidden(X,Y,XLast,Ylast,N)
         else
           for N := XLast to X do PlotHidden(X,Y,XLast,YLast,N)
end;

{$ENDIF}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
Procedure proj(VAR pt : PointType; r, c : longint);

const ZoomFactor = 1.3;


var
   X2, Y2, Z2,
   X3, Y3     : MyReal;

begin
  with Orientation do
  begin
     X2 := (c-Xmean) / XDiff;
     Y2 := (r-Ymean) / YDiff;
     if ZDiff = 0 then Z2 := 0
     else
       Z2 := (srf[r,c] - Zmean) / ZDiff;
     X3 := X2 * CRota - Y2 * SRota;
     Y3 := Z2 * CTilt - (X2 * SRota + Y2 * CRota) * STilt;
     pt.X := Round(ScrWidth * (DegToRad * X3 * ZoomFactor + 0.5));
     pt.Y := Round(ScrHeight * (DegToRad * Y3 * ZoomFactor+ 0.5));
   end; {with}
end; {proj}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure shade (row, col : longint);
{Selects a gray shade for a patch}
  var
   i : longint;
   dim, ill, normlen : MyReal;
   normal : array[1..3] of MyReal;
 begin
  dim := 100 / range;
{Cross product of two vectors}
  normal[1] := -dim * (srf[row, col] - srf[row + 1, col]);
  normal[2] := -dim * (srf[row, col] - srf[row, col + 1]);
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
 procedure shadeframe;
{Shades surface}
  var
   r, c : longint;
   patch : Rhombus;
 begin
  SetColor(0);
  for r := 0 to size - 1 do
   for c := 0 to size - 1 do
    begin
     proj(patch[0],r, c);
     proj(patch[1],r,c + 1);
     proj(patch[2],r + 1, c + 1);
     proj(patch[3],r + 1, c);
     patch[4] := patch[0]; { close polygon }
     if srf[r,c] > 0 then
     begin
        shade(r, c); {Get shade of patch}
        FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     end
     else
     begin
        setfillpattern(grayscale[0],Blue);
        FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     end;
    end;
 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 procedure wireframe(stepsize : longint);
{Draws wireframe of surface}
  var
   r, c,
   highcount  : longint;
   patch : Rhombus;
   NewRow : BOOLEAN;
 begin
(*  { enclose plotting area }
  proj(patch[0],0,0);
  proj(patch[1],0,size);
  proj(patch[2],size,size);
  proj(patch[3],size,0);
  patch[4] := patch[0];
  DrawPoly(sizeof(rhombus) div sizeof(PointType), patch);
*)
  highcount := size div stepsize;
  { plot the rows }
  for c := 0 to highcount do
  begin
   NewRow := TRUE;
   for r := 0 to highcount do
    begin
     proj(patch[0],(r * stepsize), (c * stepsize));
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
     proj(patch[0],(r * stepsize), (c * stepsize));
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
(*   Draw many polygons
     {Define patch}
     proj(patch[0],(r * stepsize), (c * stepsize));
     proj(patch[1],(r * stepsize), (c+1) * stepsize);
     proj(patch[2],(r +1) * stepsize, (c +1) * stepsize);
     proj(patch[3],((r+1) * stepsize, (c* stepsize));
     patch[4] := patch[0];
     SetFillPattern(grayscale[8],Black);  { cover up behind }
     FillPoly(sizeof(rhombus) div sizeof(PointType), patch);
     DrawPoly(sizeof(rhombus) div sizeof(PointType), patch);
  end;
*)

 end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
 procedure shaded;
{Gets solar vector, and shades surface}
 var
   ch : CHAR;

 begin
  WriteText('Solar altitude?' );
  readln(alt);
  alt := alt * 3.14159 / 180;
  WriteText('Solar azimuth?');
  readln(az);
  az := az * 3.14159 / 180;
{Convert az/alt to three component unit vector}
  solar[3] := sin(alt);
  solar[2] := sin(az) * cos(alt);
  solar[1] := cos(az) * cos(alt);
  shadeframe; {Shade surface}
(*  savedrawing('surf'); {Save drawing to disk} *)

 end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure Animate;
var
  ch : CHAR;

BEGIN
with Orientation do
  begin
  repeat
    ClearDisplay;
    wireframe(8);
    Ch:=ReadKey;
    CASE Ch OF
     #0:            { Function keys }
      begin
        ch := readkey;
        case Ch of
          #72: Tilt := Tilt + 10; { Up }
          #75: Rota := Rota + 10; { Left }
          #77: Rota := Rota - 10; { Right }
          #80: Tilt := Tilt - 10; { Down }
        end;
      end;
     #3 : BEGIN END;
    END; {CASE}
     CTilt := Cos(DTR(Tilt));
     STilt := Sin(DTR(Tilt));
     CRota := Cos(DTR(Rota));
     SRota := Sin(DTR(Rota));

  until ch = #81;
 end {with};
end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}

begin
 CheckBreak := TRUE;
 Hidden := TRUE;
 setupdrawing;
(*
 {read data file}
 writeln('Reading data file.');
 assign(srfile,DataFile);
 reset(srfile);
 for row := 0 to size do
   for col := 0 to size do
     read(srfile, srf[row, col]);
 close(srfile);
*)
repeat
  ClearDisplay;
  WriteText('(V)oss or (F)FC Algorithm? ');
  readln(ans);
  if (ans = 'F') then Method := FFC
    else Method := Voss;
  repeat
    WriteText('Roughness Factor (0.0 to 1.0): ');
    {$I-}
    readln(Roughness);
    {$I+}
    OK := (IOResult=0);
    if not OK then WriteText('Bad numeric format! Use form n.n');
  until OK;
  WriteText('Computing Fractal Surface');
  {$IFDEF DEBUG}
  ZeroArray;
  {$ELSE}
  DoFractal(srf,Roughness, Method);

 for row := 0 to size do    { compensate for inexplicably high values }
    for col := 0 to size do
        srf[row,col] := srf[row,col] - 100000;

  {$ENDIF}

  repeat
    WriteText('(M)ap, (W)ire, (S)haded, or (Q)uit? ');
    GotoXY(whereX,WhereY); readln(ans);
    if (ans = 'W') or  (ans = 'S') or (ans = 'A') then
    begin
      GetOrientation;
      WriteText('finding range');
      range := rangefind;
    end;
    ClearDisplay;
    if ans = 'M' then mapdisp
       else if ans = 'W' then wireframe(1)
         else if ans = 'S' then shaded
           else if ans = 'A' then Animate ;
    MoveTo(0,0);
    if ans <> 'Q' then
    begin
      WriteText('(A)nother view, (N)ew Fractal or (Q)uit.');
      ans := ReadKey;
    end;
   until (ans = 'Q') or (ans = 'N');
until ans = 'Q'
end.

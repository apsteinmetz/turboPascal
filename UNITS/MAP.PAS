{_______________________________________________________________

MAP.PAS Accompanies "Mimicking Mountains," by Tom Jeffery,
BYTE, December 1987, page 337
______________________________________________________________}

program Map;
{$DEFINE IBM}  {As opposed to Mac Pascal of original}
uses
   Crt, Graph, ATTGraph {PreInitialized ATT Driver.};

 const
  size = 64;
  cell = 6;  { smallest screen dimension / size }
  datafile = 'SURFACE.FKL';
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
  twohts = array[1..2] of longint;
  levarray = array[0..8] of longint;
  rect = record
          topleft,topright,
          botright,botleft,
          dummy             : PointType;  {always set dummy := topleft }
        end;

 var
  srf : array[0..size, 0..size] of longint;
  Srfilename, ans : string[30];
  srfile : file of longint;
  col, row, cont : longint;
  Pt, pt2 : PointType;
  rct : rect;

 procedure SetUpDrawing;
  var
   R : Rect;
begin
  InitATTGraph;
  SetTextStyle(DefaultFont,HorizDir,1);
  SetTextJustify(CenterText,TopText);

  OutTextXY(320,0,'MAP');
end;

procedure minmax(VAR mm : twohts);

{Min surface height is minmax[1], max is minmax[2]}
  var
{   mm : twohts; }
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
{  minmax := mm;}
 end;

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

begin
 setupdrawing;
 repeat

  assign(srfile,DataFile);
  reset(srfile);
  writeln('reading file');
  for row := 0 to size do
   for col := 0 to size do
    read(srfile, srf[row, col]);
  close(srfile);
  writeln('done reading');

  mapdisp; {Draw Map}

  OutTextXY(30,380,'Again?');
  readln(ans);

 until ans[1] = 'n';
  CloseGraph;
end.

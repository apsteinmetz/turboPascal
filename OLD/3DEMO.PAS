{   A three dimensional graphics demonstration program     }
{   Written 2/11/1988 by Gus Smedstad                      }
{   3-d primitives provided by TRI_D.TPU, by Gus Smedstad  }
{$N-}
uses Crt, graph, tri_d;

const tablemax = 12;  { Maximum number of color/pattern combinations needed }
type  ObjInfo = record
                 Name  : String[10];  { name of object }
                 center: vector;      { center point for rotation }
                 data  : pointer;     { Tri_D information }
                end;


var colortable : array[1..tablemax] of FillSettingsType;
                  { Table to provide 'generic' colors for all monitors }
    Object     : array[0..5] of ObjInfo;
                  { Objects.  Global for simplicity. }
    paging     : boolean;          { True if graphics card supports paging }

procedure ChangeColor(front, back : integer);
begin
  SetPolyColors(colortable[front].pattern, colortable[front].color,
                colortable[back].pattern, colortable[back].color)
 end;


{ -----  Routines to draw the five objects  ----- }

procedure Ring(x,y,z, radius : real; step : integer);  { draw a cylinder }
var cosine : array[0..20] of real;
    sine   : array[0..20] of real;
    i      : integer;
    p      : array[1..4] of vector;
begin
  ChangeColor(1,2);
  for i := 0 to step do begin
    cosine[i] := cos(i * 2 * pi / step);
    sine[i] := sin(i * 2 * pi / step);
   end;
  for i := 1 to step do begin
    p[1][0] := radius * cosine[i-1] + x;
    p[1][1] := radius * sine[i-1] + y;
    p[1][2] := z;
    p[2][0] := radius * cosine[i] + x;
    p[2][1] := radius * sine[i] + y;
    p[2][2] := z;
    p[3] := p[2];
    p[3][2] := radius * 2 + z;
    p[4] := p[1];
    p[4][2] := radius * 2 + z;
    MakePolygon(p,4);
   end
 end;

procedure Hemisphere(x, y, z, radius : real; step : integer);
var cosine : array[0..30] of real;
    sine   : array[0..30] of real;
    i, j   : integer;
    F, H   : real;
    oldH   : real;
    oldF   : real;
    p      : array[1..4] of vector;
begin
  ChangeColor(3,4);
  step := step * 2;
  for i := 0 to step do begin
    cosine[i] := cos(i * 2 * pi / step);
    sine[i] := sin(i * 2 * pi / step);
   end;
  F := 0;
  H := radius;
  for i := 1 to (step div 2) do begin
    oldF := F;
    oldH := H;
    F := radius * sin(i * pi / step);
    H := radius * cos(i * pi / step);
    for j := 1 to step do begin
      p[1][0] := oldF * cosine[j-1] + x;
      p[1][1] := oldH + y;
      p[1][2] := oldF * sine[j-1] + z;
      p[2][0] := F * cosine[j-1] + x;
      p[2][1] := H + y;
      p[2][2] := F * sine[j-1] + z;
      p[3][0] := F * cosine[j] + x;
      P[3][1] := H + y;
      p[3][2] := F * sine[j] + z;
      p[4][0] := oldF * cosine[j] + x;
      p[4][1] := oldH + y;
      p[4][2] := oldF * sine[j] + z;
      MakePolygon(p,4)
     end
   end
 end;

procedure House(x,y,z, size : real);
var front,
    back : array[0..4] of vector;
    side : array[0..3] of vector;
    i, l: integer;
begin
  back[0,0] := -size; back[0,1] := 0;      back[0,2] := -size;
  back[1,0] := size;  back[1,1] := 0;      back[1,2] := -size;
  back[2,0] := size;  back[2,1] := size/2; back[2,2] := -size;
  back[3,0] := 0;     back[3,1] := size;   back[3,2] := -size;
  back[4,0] := -size; back[4,1] := size/2; back[4,2] := -size;
  for i := 0 to 4 do begin
    back[i,0] := back[i,0] + x;
    back[i,1] := back[i,1] + y;
    back[i,2] := back[i,2] + z;
   end;
  for i := 0 to 4 do begin
    front[i][0] := back[i][0];
    front[i][1] := back[i][1];
    front[i][2] := back[i][2] + size * 2;
   end;
  l := 4;
  ChangeColor(5,5);
  for i := 0 to 4 do begin
    side[0] := back[l];
    side[1] := back[i];
    side[2] := front[i];
    side[3] := front[l];
    MakePolygon(side,4);
    l := i;
   end;
  ChangeColor(6,6);
  MakePolygon(back,5);
  MakePolygon(front,5);
 end;

procedure Rect(x, y1, z1, y2, z2 : real);
var p : array[1..4] of vector;
begin
  p[1][0] := x;  p[1][1] := y1;  p[1][2] := z1;
  p[2][0] := x;  p[2][1] := y2;  p[2][2] := z1;
  p[3][0] := x;  p[3][1] := y2;  p[3][2] := z2;
  p[4][0] := x;  p[4][1] := y1;  p[4][2] := z2;
  ChangeColor(7,8);
  MakePolygon(p,4);
 end;

procedure Pyramid(x,y,z, scale : real);
var bottom : array[1..4] of vector;
    tip    : vector;
    old    : vector;
    i      : integer;
begin
  bottom[1][0] := x+scale/2;  bottom[1][1] := y; bottom[1][2] := z-scale/2;
  bottom[2][0] := x+scale/2;  bottom[2][1] := y; bottom[2][2] := z+scale/2;
  bottom[3][0] := x-scale/2;  bottom[3][1] := y; bottom[3][2] := z+scale/2;
  bottom[4][0] := x-scale/2;  bottom[4][1] := y; bottom[4][2] := z-scale/2;
  ChangeColor(9,9);
  MakePolygon(bottom,4);
  tip[0] := x;  tip[1] := y+scale;  tip[2] := z;
  old := bottom[4];
  for i := 1 to 4 do begin
    ChangeColor((i mod 2) + 10,(i mod 2) + 10);
    MakeTriangle(old,tip,bottom[i]);
    old := bottom[i]
   end
 end;


{ ----- Initialize graphics card, create color table, create objects -----}

procedure CreateObjects;
const Zero : vector = (0,0,0);
var i : integer;
begin
  SetLineStyle(SolidLn,0,1);
  with Object[0] do begin
    center[0] := 0;
    center[1] := 0;
    center[2] := 30;
    name := 'Viewpoint';
    SetViewPoint(center[0],center[1],center[2]);
   end;
  SetViewDirection(0,0,0);
  with Object[1] do begin
    MakeObject(data);
    Ring(-7,7,0,3,12);
    center[0] := -7; center[1] := 7; center[2] := 0;
    name := 'Cylinder';
   end;
  with Object[2] do begin
    MakeObject(data);
    Hemisphere(7,7,0,6,8);
    center[0] := 7; center[1] := 7; center[2] := 0;
    name := 'Hemisphere';
   end;
  with Object[3] do begin
    MakeObject(data);
    Pyramid(-15,-7,0,7);
    center[0] := -15; center[1] := -7; center[2] := 0;
    name := 'Pyramid';
   end;
  with Object[4] do begin
    MakeObject(data);
    House(0,-7,0,4);
    Center[0] := 0; center[1] := -7; center[2] := 0;
    name := 'House';
   end;
  with Object[5] do begin
    MakeObject(data);
    Rect(15,-12,4,-3,-4);
    Center[0] := 15;  Center[1] := -7; Center[2] := 0;
    name := 'Plane';
   end;
  CloseObject;   { We're finished making objects }
 end;

procedure Init;
var colormax : integer;
    c, s, i  : integer;
    GraphDriver, GraphMode : integer;
begin
  GraphDriver := Detect;
  InitGraph(GraphDriver, GraphMode, '');
  if GraphResult <> grOK then begin
    Writeln('Graphics initialization error: ', GraphErrorMsg(GraphDriver));
    Halt(1);
   end;
  SetViewPort(0,TextHeight(' ')*2 + 4,GetmaxX,GetmaxY,True);
  paging := (GraphDriver = HercMono) or (GraphDriver = EGA) or
            (GraphDriver = EGA64)    or (GraphDriver = VGA);
  c := 1;
  s := SolidFill;
  colormax := GetMaxColor;
  for i := 1 to TableMax do begin   { cycle through colors and fill styles }
    Colortable[i].pattern := s;
    Colortable[i].color := c;
    c := succ(c);
    if C > colormax then begin
      c := 1;
      s := s + 1;
      if s = UserFill then s := SolidFill
     end
   end;
  SetScale(2);
  SetCenter(GetmaxX div 2, GetmaxY div 2);
  CreateObjects;
 end;

{ Show the menu at the top of the screen }
procedure showmenu(o : integer; rot: boolean);
begin
  SetViewPort(0,0,GetmaxX,TextHeight(' ')*2 + 4,False);
  ClearViewport;
  SetColor(GetMaxColor);
  OuttextXY(0,0,
   ' 1-5 object  Rotate  Move  Viewpoint  Hide edges  Clear  Quit');
  Moveto(0,TextHeight(' '));
  if rot then Outtext('Rotate ') else Outtext('Move ');
  Outtext(Object[o].Name);
  Outtext('  Dir: <arrow keys> <page up>: add Z  <page down>: subtract Z');
  SetViewPort(0,TextHeight(' ')*2 + 4,GetmaxX,GetmaxY,True);
 end;

{ --- Move an object or the viewpoint by dx, dy, and dz --- }
procedure MoveOb(obj : integer; dx, dy, dz : real);
begin
  with object[obj] do begin
    center[0] := center[0] + dx;            { We're keeping track of this }
    center[1] := center[1] + dy;            { so we know what point to    }
    center[2] := center[2] + dz;            { rotate the object about.    }
    if obj > 0 then
      MoveObject(data,dx,dy,dz)
     else
      SetViewPoint(center[0],center[1],center[2]);
   end
 end;

procedure RotOb(obj : integer; ThetaX, ThetaY, ThetaZ : real);
var Theta : vector;
    delta : vector;
    i     : integer;
begin
  if obj = 0 then
    RotateViewDirection(-ThetaX, ThetaY, -ThetaZ)
   else begin
     { We don't want to move it, just rotate. }
    for i := 0 to 2 do delta[i] := 0;
    Theta[0] := ThetaX;
    Theta[1] := ThetaY;
    Theta[2] := ThetaZ;
    with object[obj] do RotateObject(data,Theta,Center,delta);
   end
 end;   { That's all there is to it. }


procedure ResetData;
var i : integer;
begin
  CloseObject;
  for i := 1 to 5 do with Object[i] do DeleteObject(Data);
  ClearDevice;
  CreateObjects;
 end;

var ch       : char;     { Holds last keypress }
    obj      : integer;  { Current object # }
    angle    : real;     { increment for rotations }
    NewMenu  : boolean;  { Do we need to change the menu? }
    EraseScr : boolean;  { Do we need to erase the screen ? }
    rot      : boolean;  { Are we rotating or moving objects? }
    done     : boolean;
    Page     : integer;
    i        : integer;
begin
  Init;
  angle := pi/10;   { Set the increment for rotations }
  obj := 0;         { start with the viewpoint}
  page := 0;
  rot := false;
  done := false;
  NewMenu := True;
  repeat            { Main loop - repeat until we're bored }
    if NewMenu then ShowMenu(obj, rot);
    EraseScr := False;
    NewMenu := False;
    Ch := Readkey;
    if ch = #0 then begin  { Special key - presumed to be an arrow key. }
      if (obj > 0) then
        EraseObject(Object[obj].data)
       else
        EraseScr := true;  { If we're moving the viewpoint, we need a new }
                           { screen }
      case ord(readkey) of
        $48 : if rot then                 { Up arrow }
                RotOb(obj,-angle,0,0)
               else
                MoveOb(obj,0,1,0);
        $49 : MoveOb(obj,0,0,-1);         { page up }
        $4b : if rot then                 { Left arrow }
                RotOb(obj,0,-angle,0)
               else
                MoveOb(obj,-1,0,0);
        $4d : if rot then                 { Right Arrow }
                RotOb(obj,0,angle,0)
               else
                MoveOb(obj,1,0,0);
        $50 : if rot then                 { down arrow }
                RotOb(obj,angle,0,0)
               else
                MoveOb(obj,0,-1,0);
        $51 : MoveOb(obj,0,0,1);          { page down }
       end;
      if Obj > 0 then DrawObject(object[obj].data);
     end
     else begin
      NewMenu := True;   { All of these change the menu }
      case upcase(ch) of
       '1'..'5' : begin
                   if obj > 0 then with Object[obj] do begin
                     ObjectStyle(data,SolidLn,0,1);   { Redraw the previous }
                     DrawObject(data);                { selection }
                    end;
                   obj := ord(ch) - ord('0');   { set object }
                   with Object[obj] do begin
                     EraseObject(data);             { Redraw it with dashes }
                     ObjectStyle(data,DashedLn,0,1);
                     DrawObject(data)
                    end;
                  end;
       'V'      : begin
                   if obj > 0 then with object[obj] do begin
                     ObjectStyle(data,SolidLn,0,1);  { Redraw the previous }
                     DrawObject(data)                { selection }
                    end;
                   obj := 0;
                  end;
       'M'      : rot := false;
       'R'      : rot := True;
       'C'      : begin
                    EraseScr := True;
                    ResetData;
                    obj := 0;
                   end;
       #27, 'Q' : done := true;
       'H'      : begin
                   SetDrawMode(true,true);     { change to hidden-edges }
                   Regenerate;                 { draw it }
                   repeat until keypressed;    { wait for next key }
                   EraseScr := true;           { those filled polygons }
                   SetDrawMode(false,true);    { reset to wireframe }
                  end;
       end  { of Case upcase(ch) }
     end;
    if EraseScr then begin        { redraw the screen }
      if paging then begin
        SetVisualPage(page);      { if we've got pages, use other page. }
        SetActivePage(1-page);
       end;
      NewMenu := True;
      ClearDevice;
      regenerate;
      if paging then begin
        SetVisualPage(1-page);    { Let 'em look at our finished image }
        page := 1-page;           { Alternate pages }
       end;
     end
   until done;
  CloseGraph;
 end.

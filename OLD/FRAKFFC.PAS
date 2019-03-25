_______________________________________________________________



FRAKFFC.PAS Accompanies "Mimicking Mountains," by Tom Jeffery, 

BYTE, December 1987, page 337

______________________________________________________________



program fractal_ffc;
 const
  size = 64; {Maximum index of array}
 var
  row, col, n, step, st : longint;
  srf : array[0..size, 0..size] of longint; {The surface file}
  ans : string[10];
  srfile : file of longint;
  H : real; {Roughness factor}
  stepfactor : real;

 function gauss : real;
{Returns a gaussian variable with mean = 0, variance = 1}
{Polar method due to Knuth, vol. 2, pp. 104, 113 }
{but found in "Smalltalk-80, Language and Implementation",}
{Goldberg and Robinson, p. 437.}
  var
   i : integer;
   sum, v1, v2, s : real;
 begin
  sum := 0;
  repeat
   v1 := (random / maxint);
   v2 := (random / maxint);
   s := sqr(v1) + sqr(v2);
  until s < 1;
  s := sqrt(-2 * ln(s) / s) * v1;
  gauss := s;
 end;

 procedure hordetail (row : longint);
{Calculates new points for one row}
  var
   disp, i, col : longint;
 begin
  col := 0;
  while col < size do
   begin
    disp := Round(100 * (gauss * stepfactor)); {Random displacement}
    srf[row, col + step] :=

        (srf[row, col] + srf[row, col + 2 * step]) div 2; {Midpoint}
    srf[row, col + step] := srf[row, col + step] + disp;{New point}
    col := col + 2 * step;
   end;
 end;


 procedure verdetail (col : longint);
{Calculates  new points for one column}
  var
   disp, i, row : longint;
 begin
  row := 0;
  while row < size do
   begin
    disp := Round(100 * (gauss * stepfactor)); {Random displacement}
    srf[row + step, col] :=

          (srf[row, col] + srf[row + 2 * step, col]) div 2; {Midpoint}
    srf[row + step, col] := srf[row + step, col] + disp; {New point}
    row := row + 2 * step;
   end;
 end;

 procedure centdetail (row : longint);
{Calculates new points for centers of all cells in a row}
  var
   disp, i, col : longint;
 begin
  col := step;
  while col < size do
   begin
    disp := Round(100 * (gauss * stepfactor)); {Random displacement}
    srf[row, col] :=

          (srf[row, col - step] + srf[row, col + step]

             + srf[row - step, col]

                  + srf[row + step, col]) div 4; {Center Point}
    srf[row, col] := srf[row, col] + disp; {New point}
    col := col + 2 * step;
   end;
 end;

 procedure detail;
{Calculates new points at current step size}
  var
   i, row, col : longint;
 begin
  row := 0;
  col := 0;
  while row <= size do
   begin
    hordetail(row);
    row := row + 2 * step;
   end;
  while col <= size do
   begin
    verdetail(col);
    col := col + 2 * step;
   end;
  row := step;
  while row <= size - step do
   begin
    centdetail(row);
    row := row + 2 * step;
   end;
 end;

 procedure newsurface;
  var
   row, col : longint;
 begin
  step := size;
  stepfactor := exp(2 * H * ln(step));
  srf[0, 0] := Round(100 * (gauss * stepfactor));
  srf[0, size] := Round(100 * (gauss * stepfactor));
  srf[size, 0] := Round(100 * (gauss * stepfactor));
  srf[size, size] := Round(100 * (gauss * stepfactor));
  repeat
   step := step div 2; {Go to smaller scale}
   write('step = ');
   writeln(step);
   stepfactor := exp(2 * H * ln(step)); {Factor proportional to step size}
   detail; {Calculate all new points at current step size}
  until step = 1;
 end;

begin
 showtext;
 write('H = ?');{Set roughness}
 readln(H);
 open(srfile, NewfileName('Surface File'));
 st := tickcount;
 randseed := st;  {Randomize}
 newsurface; {Calculate surface}
 for row := 0 to size do
  for col := 0 to size do
   write(srfile, srf[row, col]); {Store surface in file}
 close(srfile);
 st := (tickcount - st) div 3600;
 write(st);
 writeln(' minutes');
end.

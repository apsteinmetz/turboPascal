{_______________________________________________________________

FRAKVOSS.PAS Accompanies "Mimicking Mountains," by Tom Jeffery,
BYTE, December 1987, page 337

______________________________________________________________}

unit fracsurf
interface
{$N+}

VAR
  size : longint  { compute size x size surface. 64 is recommended }
  datafile : string  {file to store array in}

program fractalVoss;
 const
  size = 64; {Maximum index of array}
  datafile = 'D:SURFACE.FKL';
type
   AlgorithmType = (Voss, FFC);

 var
  row, col, n, step, st : longint;
  srf : array[0..size, 0..size] of longint; {The surface file}
  srfile : file of longint;
  H : extended; {Roughness factor}
  stepfactor : extended;
  BadInput : BOOLEAN;

 function gauss : extended;
{Returns a gaussian variable with mean = 0, variance = 1}
{Polar method due to Knuth, vol. 2, pp. 104, 113 }
{but found in "Smalltalk-80, Language and Implementation",}
{Goldberg and Robinson, p. 437.}
  var
   i : integer;
   sum, v1, v2, s : extended;
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

 procedure horintpol (row : longint);
{Interpolates midpoints for 1 row}
  var
   i, col : longint;
 begin
  col := 0;
  while col < size do
   begin
    srf[row, col + step] := (srf[row, col] + srf[row, col

           + 2 * step]) div 2; {New point}
    col := col + 2 * step;
   end;
 end;


 procedure verintpol (col : longint);
{Interpolates midpoints for 1 column}
  var
   i, row : longint;
 begin
  row := 0;
  while row < size do
   begin
    srf[row + step, col] := (srf[row, col]

           + srf[row + 2 * step, col]) div 2; {New point}
    row := row + 2 * step;
   end;
 end;

 procedure centintpol (row : longint);
{Interpolates center points for all cells in a row}
  var

   i, col : longint;
 begin
  col := step;
  while col < size do
   begin
    srf[row, col] := (srf[row, col - step] + srf[row, col + step]

            + srf[row - step, col] + srf[row + step, col]) div 4;
{New point}
    col := col + 2 * step;
   end;
 end;

 procedure intpol;
{Interpolates all midpoints at current step size}
  var
   i, row, col : longint;
 begin
  row := 0;
  col := 0;
  while row <= size do
   begin
    horintpol(row);
    row := row + 2 * step;
   end;
  while col <= size do
   begin
    verintpol(col);
    col := col + 2 * step;
   end;
  row := step;
  while row <= size - step do
   begin
    centintpol(row);
    row := row + 2 * step;
   end;
 end;
{+++++++++++++++++++++++++++++++++++++++++++++++++}
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

{+++++++++++++++++++++++++++++++++++++++++++++++++}
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

{+++++++++++++++++++++++++++++++++++++++++++++++++}
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

{+++++++++++++++++++++++++++++++++++++++++++++++++}
 procedure FFCDetail;
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

{+++++++++++++++++++++++++++++++++++++++++++++++++}
 procedure VossDetail;
{Adds random displacement to all points at current step size}
  var
   r, c, disp : longint;
 begin
  r := 0;
  while r <= size do
   begin
    c := 0;
    while c <= size do
     begin
      disp := Round(100 * (gauss * stepfactor));
      srf[r, c] := srf[r, c] + disp;
      c := c + step;
     end;
    r := r + step;
   end;
 end;

 procedure newsurface(Algo : AlgorithmType);
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
   if Algo = Voss then
   begin
     intpol;
     VossDetail;
   end
   else FFCDetail;
  until step = 1;
 end;

begin
 repeat
    write('H = ?'); {Set roughness}
 {$I-}
    readln(H);
 {$I+}
    BadInput := (IOResult <> 0);
    if BadInput then writeln('Wrong form.  Enter in the form 0.n.');
 until not BadInput;

  assign(srfile, datafile);
  rewrite(srfile);

 Randomize;
 newsurface(Voss); {Calculate surface}
 for row := 0 to size do
   for col := 0 to size do
     write(srfile, srf[row, col]); {Store surface in file}
 close(srfile);
end.

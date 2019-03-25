{_______________________________________________________________

FRAKVOSS.PAS Accompanies "Mimicking Mountains," by Tom Jeffery,
FRAKFFC.PAS
BYTE, December 1987, page 337

revised:
12/11/87 by Art Steinmetz
   Version for IBM Turbo Pascal v.4.0
   Combined FFC and Voss algorithms in one module

______________________________________________________________}


unit fracsurf;
{$I FLOAT.INC}

interface

uses MathLib0;

CONST
  size = 64;    { compute size x size surface. 64 is recommended }


type
   AlgorithmType = (Voss, FFC);
   surface = array[0..size, 0..size] of longint;

procedure DoFractal(VAR srf : surface;
                        H : float; { roughness factor between 0 and 1 }
                        Algo : AlgorithmType);

procedure SaveFractal(srf : surface;
                      { optional filename to store array in }
                      datafile : string);


implementation

 var
  row, col, n, step, st : longint;
  stepfactor : float;

function gauss : float;
{Returns a gaussian variable with mean = 0, variance = 1}
{Polar method due to Knuth, vol. 2, pp. 104, 113 }
{but found in "Smalltalk-80, Language and Implementation",}
{Goldberg and Robinson, p. 437.}
  var
   i : integer;
   sum, v1, v2, s : float;
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

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure DoFractal( var srf : surface;
                     H       : float;
                     algo    : AlgorithmType);


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

 procedure newsurface;
 begin
  step := size;
  stepfactor := exp(2 * H * ln(step));
  { nail down the corners }
  srf[0, 0]       := Round(100 * (gauss * stepfactor));
  srf[0, size]    := Round(100 * (gauss * stepfactor));
  srf[size, 0]    := Round(100 * (gauss * stepfactor));
  srf[size, size] := Round(100 * (gauss * stepfactor));
  repeat
     step := step div 2; {Go to smaller scale}
     { optional computing progress report goes here }
     stepfactor := exp(2 * H * ln(step)); {Factor proportional to step size}
     if Algo = Voss then
     begin
       intpol;
       VossDetail;
     end
     else FFCDetail;
  until step = 1;
 end;


begin { DoFractal }
 Randomize;
 newsurface; {Calculate surface}
end;


procedure SaveFractal(srf :surface; datafile : string);
var
  srfile : file of surface;

begin
 assign(srfile, datafile);
 rewrite(srfile);
 write(srfile, srf); {Store surface in file}
(*  ALTERNATE WAY OF WRITING
 for row := 0 to size do
   for col := 0 to size do
     begin
     write(srfile, srf { srf[row, col] }); {Store surface in file}
     write(srf[row, col]:8);
   end;
*)
 close(srfile);
end;

procedure ReadFractal(srf :surface; datafile : string);
var
  srfile : file of surface;

begin
 assign(srfile, datafile);
 reset(srfile);
 read(srfile, srf);
 close(srfile);
end;

begin
end.

program FracTest;

uses FracSurf;

var
  row, col : integer;
  Surf     : surface;

begin
   DoFractal(Surf,0.6,Voss);
   for row := 1 to 64 do
      for col := 1 to 64 do
         Write(Surf[row,col]-100000:10,' ');
end.
var
  value : real;
  code : integer;

begin

  val(paramstr(1),value,code);
  if code = 0 THEN
  BEGIN
     writeln(sin(value):5:2)
     writeln(cos(value):5:2)
     writeln(tan(value):5:2)
  ELSE
    writeln('error');
end.

uses DrawPics;

VAR
  err : DrawError;

BEGIN
  err := DrawPic(paramstr(1));
  IF err > NoError THEN
    Writeln('Error:',ORD(err))
  ELSE
    readln;
END.

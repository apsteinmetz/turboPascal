PROGRAM TestWindows;
(* A demo program for the WINDOWS unit *)

USES Crt, Windows;

CONST NewLine : string[2] = ^M^J;
      Esc : char = ^[;
VAR   Str: array[1..3] of string[50];
      NumWindows : byte;
      Key : char;
      Error : boolean;
begin
  Str[1] := '  This is the first window opened...';
  Str[2] := '  This is the second window opened...';
  Str[3] := '  And this is the third.';
  NumWindows := 0;
  TextMode(CO80);
  ClrScr;
  OpenWindow(1,23,79,25,Blue,Lightgray,Error);
  if not(Error) then begin
    Write('         Type an alphanumeric Key, or press <Esc> to');
    Write(' close a window.');
  end;
  OpenWindow(30,10,70,15,Yellow,Green,Error);
  if not(Error) then begin
    Write(NewLine,NewLine,Str[1]);
    NumWindows := NumWindows + 1
  end;
  OpenWindow(5,2,50,8,LightRed,Black,Error);
  if not(Error) then begin
    Write(Str[2]);
    NumWindows := NumWindows + 1
  end;
  OpenWindow(20,12,55,16,White,Magenta,Error);
  if not(Error) then begin
    WriteLn(Str[3]);
    NumWindows := NumWindows + 1
  end;
  while NumWindows>0 do begin
    Key := ReadKey;
    if Key = #0 then Key := ReadKey  (* discard function & cursor keys *)
    else if Key = ^M then Writeln
    else if Key = Esc then begin
      NumWindows := NumWindows -1;
      CloseWindow
    end
    else Write(Key)
  end (* while NumWindows > 0 *);
  CloseWindow  (* close the help window *)
end.

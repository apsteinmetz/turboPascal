uses getfield,Crt;

Var
  ReturnVal : Integer;
  TempStr  : Array[1..10] of string;

begin
  ClrScr;
  WriteLn('This demo shows the use of Getfiled.Tpu');
  WriteLn('Use the Up Dn Arrow keys to move back and forth through the');
  WriteLn('fields and edit your mistakes');
  WriteLn('Hit return on the last field to exit the GetField mode');
  WriteLn('    Or strike PgDn at any time to exit');
  WriteLn('    Or strike ESC at any time to exit');
  WriteLn('The name field converts everything to uppercase');
  WriteLn('The ZipCode Field only allows numeric entry');
  WriteLn('All others allow anything');
  GotoXY(30,10); Write('Name :');
  GotoXY(27,12); Write('Address :');
  GotoXY(30,14); Write('City :');
  GotoXY(29,16); Write('State :');
  GotoXY(45,16); Write('ZipCode :');

{------ Here's an example of the caling sequence for getfield ------}

  SetUp_Field($30,$07,' ',True);          { Optional }

  Field_Str(37,10,25,3,TempStr[1],'U');
  Field_Str(37,12,25,3,TempStr[2],'L');
  Field_Str(37,14,15,3,TempStr[3],'L');
  Field_Str(37,16,2,3,TempStr[4],'U');
  Field_Str(55,16,5,3,TempStr[5],'N');

  Do_Fields(ReturnVal);

  Release_Fields;

{----- That's all there is to it ------------------------------------}

  ClrScr;
  GotoXY(1,10);
  WriteLn('The last KeyPressed had a value of ',ReturnVal);
  WriteLn('You Entered :');
  WriteLn;
  TextAttr := $30;
  for ReturnVal := 1 to 5 do
    WriteLn(TempStr[ReturnVal]);
end.

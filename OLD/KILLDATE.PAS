program DATEKILL;
{ deletes Fidomail BBS messages by date }

uses FileOps;

CONST
  rootpath = 'c:\msg\';
  ValidChars : set of 0..127 = [32..127];

  CutOffDay = 16;
  CutOffMonth = 'Oct';

VAR
  Dir : POINTER;
  filename : string;
  infile    : file;

{---------------------------------------------------------}
PROCEDURE Abort(msg :string);
begin
  writeln(msg);
  HALT;
end;

{---------------------------------------------------------}
function ExtractDate(var infile : file) : string;
CONST
  startpos = 144;
  strlength   = 20;

VAR
  ch      : CHAR;
  datestr : string;
  Buffer  : ARRAY[0..255] OF CHAR;
  recsread,
  n       : WORD;
  Quit    : BOOLEAN;

BEGIN
  n := 0;
  BlockRead(infile,Buffer,2,recsread);
  IF recsread < 1 THEN Abort('nothing read');
  REPEAT
    ch := Buffer[startpos+n];
    Quit := NOT (BYTE(ch) IN ValidChars);
    datestr[n+1] := ch;
    INC(n);
  UNTIL (n = StrLength) OR Quit;
  datestr[0] := CHAR(n-1);
  ExtractDate := datestr;
END;
{---------------------------------------------------------}
FUNCTION CheckDate(datestr : string) : BOOLEAN;
CONST
  digits : set of CHAR = ['0'..'9',' '];

VAR
  day,
  code,
  n : WORD;
  month : string;

BEGIN
  n := 1;
  IF NOT (datestr[n] IN digits) THEN n := 5;
  val(copy(datestr,n,2),day,code);
  month := copy(datestr,n+3,3);
  IF day < CutOffDay THEN
    CheckDate := FALSE
  ELSE
     CheckDate := TRUE;

END;
{---------------------------------------------------------}

PROCEDURE ProcessFile(name : string);
VAR
  datestr : String;
BEGIN
  Assign(infile,name);
  Reset(infile);
  datestr := ExtractDate(infile);
  Close(infile);
  IF NOT CheckDate(datestr) THEN
  BEGIN
    Writeln('Erasing: ',name);
    Erase(infile);
  END;
END;


{---------------------------------------------------------}
BEGIN  { main }
  CheckPath(rootpath+paramstr(1));
  GetDirectory('*.msg',Dir,filename);
  IF Dir = NIL THEN Abort('directory error');
  IF filename <> nofile THEN ProcessFile(filename);
  REPEAT
      filename :=  GetNextFile(Dir);
      IF filename <> nofile THEN ProcessFile(filename);
  UNTIL filename = nofile;
END.
UNIT StrUtil;
{ some string utilites }

interface

TYPE
   SearchPattern = RECORD
                      str : string;
                      strlen : BYTE;
                      code : SHORTINT;
                   END;


procedure StartStringSearch(InputStr : string; VAR sr : SearchPattern);
{ initialize search variables }

function StringSearch(ch : CHAR; VAR sr : SearchPattern) : BOOLEAN;

function Capitalize(s : String) : String;

function StripTrail(s : String;StripChar : CHAR) : String;

function Compress(s : String;StripChar : CHAR) : String;

implementation
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

procedure StartStringSearch(InputStr : string; VAR sr : SearchPattern);
{ initialize search variables }

BEGIN
  sr.code := 1;
  sr.str := InputStr;
  sr.strlen := length(sr.str);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function StringSearch(ch : CHAR; VAR sr: SearchPattern) : BOOLEAN;
{ code = 0  success
  code > 0 search in process }

BEGIN
  IF sr.code > 0 THEN BEGIN
     IF ch = sr.str[sr.code] THEN
       sr.code := sr.code + 1
     ELSE
       sr.code := 1;
  END;
  IF sr.code > sr.strlen THEN BEGIN
     sr.code := 1;
     StringSearch := TRUE; END
  ELSE
     StringSearch := FALSE;
END;

function Capitalize(s : String) : String;
  var
    i : Integer;
  begin
    for i := 1 to Length(s) do
      s[i] := UpCase(s[i]);
    Capitalize := s;
end;

function StripTrail(s : String;StripChar : CHAR) : String;
VAR
  i : BYTE;

BEGIN
i := ORD(s[0]);
WHILE s[i] = StripChar DO
  BEGIN
    dec(i);
    s[0] := CHR(i);
  END;
StripTrail := s;

END;

function Compress(s : String;StripChar : CHAR) : String;
VAR
  tempstr : STRING;
  i,j : BYTE;

BEGIN
  j := 0;
  tempstr := '';
  FOR i := 1 to ORD(s[0]) DO
  BEGIN
    IF NOT (s[i] = StripChar) THEN
    BEGIN
       INC(j);
       tempstr[j] := s[i]
    END;
  END;
  tempstr[0] := chr(j);
Compress := tempstr;
END;

END.


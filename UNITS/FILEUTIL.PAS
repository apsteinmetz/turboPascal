 UNIT FileUtil;

interface

uses DOS, CRT;

function Exists(name: STRING):Boolean;

PROCEDURE ChooseFile (VAR NameOfFile : STRING);


procedure BackUpFile(origfilename, tempfilename : STRING);
{leave unaltered file with a '.BAK' extension
 Rename tempfilename as old file name.}

implementation


  function Exists(name: STRING):Boolean;
  var
    Fil: file;
  begin
    If length(name) < 1 THEN Exists := FALSE
    ELSE BEGIN
      Assign(Fil,name);
      {$I-}
      Reset(Fil);
      Close(Fil);
      {$I+}
      Exists := (IOresult = 0);
    END;

  end; {exist}

PROCEDURE ChooseFile (VAR NameOfFile : STRING);
begin
   Writeln ('Name of file (include extension)?'); ClrEol;
   Readln(NameOfFile);ClrEol;

   if NOT Exists(NameOfFile) then
   BEGIN
        writeln('File ',NameOfFile,' does not exist here.');ClrEol;
        writeln('Choose again or <Ctrl><Break> to exit.');ClrEol;
        writeln;
        Choosefile(NameOfFile); (* recursive call *)
   END;

end; {choosefile}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure BackUpFile(origfilename, tempfilename : STRING);
{leave unaltered file with a '.BAK' extension
 Rename TEMP file as old file name.}

var temp     : STRING;
    tempfile : file;
begin
   if pos('.',origfilename)<>0 then
      temp := copy(origfileName,1,pos('.',origfilename)-1)+ '.BAK'
   else
      temp := origfilename + '.BAK';
   if Exists(temp) then
      begin
        Assign(tempfile,temp);
        Erase(tempfile);
      end;
   (* assign original to backup *)
   Assign(tempfile,origfilename);
   Rename(tempfile,temp);
   (* assign temp to original *)
   Assign(tempfile,tempfilename);
   Rename(tempfile,origfilename);
end; {BackUpFile}

BEGIN
END.
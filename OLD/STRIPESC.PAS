{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program STRIPESC;
{
  Strip printer codes and non printing chars from text file.
  Leave:   <TAB>
           <FF>
           <CR>
           <LF>
  Alters a text file <file>.<ext>.  The original remains as
  <file>.BAK.  Type STRIPESC. You will be prompted for the file
  name.
}
uses
  CRT,
  DirUtil {Dir, NextName} ;

CONST
  { set of chars TEXFILT will pass }
  PassableChars = [Chr(9),Chr(10),Chr(12),Chr(13),' '..'~'];
  ESC = #27;

type AnyStr    = string[80];
     delimters = (LF,CR,NONE,GOOD);

var FileToRead, OutFile : text;
    NameOfFile          : anystr;
    currfile            : integer;


  function Exist(name: anystr):Boolean;
  var
    Fil: file;
  begin
    Assign(Fil,name);
    {$I-}
    Reset(Fil);
    Close(Fil);
    {$I+}
    Exist := (IOresult = 0);
{! 1. IOResult^ now returns different values corresponding to DOS error codes.}
  end; {exist}


Procedure ChooseFile(currentfile : integer);
begin
   GotoXY(1,1);
   if currentfile = 0 then begin
         Writeln ('Name of file (include extension)?');ClrEol;
         Readln(NameOfFile);ClrEol;
         end
     else begin
        NameOfFile := paramstr(currentfile);
        GotoXY(1,3);
     end;

   if Exist(NameOfFile) then begin
        Writeln('Processing ',NameOfFile);
        Assign(FileToRead,NameOfFile);
        Assign(OutFile,'text.tmp');
        Reset(FileToRead);
        Rewrite(Outfile);
        end
     else begin
        writeln('File ',NameOfFile,' does not exist here.');ClrEol;
        writeln('Choose again or <Ctrl><Break> to exit.');ClrEol;
        writeln;
        Choosefile(0);
     end;

end; {choosefile}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Swapfile;
{leave unaltered file with a '.BAK' extension
 Rename TEMP file as old file name.}

var temp     : anystr;
    tempfile : text;
begin
   if pos('.',nameOfFile)<>0 then
      temp := copy(NameofFile,1,pos('.',nameOfFile)-1)+ '.BAK'
   else
      temp := nameOfFile + '.BAK';
   if Exist(temp) then
      begin
        Assign(tempfile,temp);
        Erase(tempfile);
{        Close(tempfile); }
      end;
   Rename(FileToRead,temp);
   Rename(OutFile,NameOfFile);
end; {swapfile}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function ChangeLines : boolean;

var  chrA  : char;
     Skip  : BOOLEAN;  {skip printable char after <ESC> }

begin  { CHANGELINES }
Skip := FALSE;
while not eof(FileToRead) do
  begin
     read(FileToRead,ChrA);
     IF NOT Skip THEN
         Skip := (ChrA = ESC);
     IF (chrA IN PassableChars) THEN
        IF NOT Skip THEN
          write(Outfile,chrA)
        ELSE
          Skip := FALSE; { reset for next char }
  end;
close(fileToRead);
close(OutFile);
ChangeLines := TRUE;
end; {changeLines}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{MAIN  PROGRAM}
BEGIN
ClrScr;
if paramcount = 0 then
  begin
   ChooseFile(0);
   if ChangeLines then SwapFile;
  end
  else
  BEGIN
    Dir(paramstr(1));
    NameOfFile := NextName;
    WHILE NameOfFile <> '' DO
    begin
      Writeln('Processing ',NameOfFile);
      Assign(FileToRead,NameOfFile);
      Assign(OutFile,'text.tmp');
      Reset(FileToRead);
      Rewrite(Outfile);
      if ChangeLines then SwapFile;
      NameOfFile := NextName;
    end;
  END;
END.

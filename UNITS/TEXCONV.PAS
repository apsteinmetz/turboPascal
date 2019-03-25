{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program TEXCONV;
{
  Use this to convert Amiga created text files that you
  have downloaded to an IBM PC so you can read them.
  Adds CR/LF to  files that have only LF, only CR or
  no readable line delimters at all at line end.

  I can't seem to find any consistancy to which delimters
  are or are not present.  Hopefully this program can
  handle any case.

  Alters a text file <file>.<ext>.  The original remains as
  <file>.BAK.  Type TEXCONV. You will be prompted for the file
  name.
}
uses
  CRT, Graph;
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
const wrapCount   = 69;
      TabSpaces   = '      ';  { convert Tab to six spaces }

var  chrA         : char;
     line         : anystr;
     l,chrCount   : integer;
     LFInFile     : delimters;
     wrapOn       : boolean;

{~~ internal to ChangeLines ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
   procedure TestLines(var DelimitPresent:delimters);
   {Check for line delimiters}

   const maxSearch = 100; {characters before DelimitPresent = false}

   var   HasLF,HasCR : boolean;

   begin
     chrCount := 0;
     hasLF := false;
     hasCR := false;
     clrscr;
     while (chrCount < maxSearch) and (not eof(FileToRead)) do
        begin
          read(FileToRead,ChrA);
          chrCount := chrCount + 1;
          if chrA = chr(10) then HasLF := true;
          if chrA = chr(13) then HasCR := true;
          if chrA = chr(10) then write(#31);
          if chrA = chr(13) then write(#17);
          write(chrA);
        end;
   if  HasLF and not HasCR then DelimitPresent := LF
     else if  HasCR and not HasLF then DelimitPresent := CR
        else if not HasLF and not HasCR then DelimitPresent := NONE
           else  {file has both cr and lf}
             begin
                  writeln('FILE DOES NOT NEED ALTERING');
                  close(fileToRead);
                  close(OutFile);
                  erase(OutFile); {erase the temp file}
                  DelimitPresent := GOOD;
             end;
   writeln;
   if (DelimitPresent = LF) or (DelimitPresent = NONE) then
         writeln('LineFeeds are present')
      else if DelimitPresent <> GOOD
        then writeln('No LineFeeds found in first',maxSearch:4,' characters');
   reset(fileToRead);
   end; {TestLines}

{~~ internal to ChangeLines ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
   procedure NewLine;
   begin
       l := l + 1;
       gotoXY(7,3);write(l);
       writeln(OutFile,Line);
       Line := ''
   end; {NewLine}

begin
  l := 0;
   line := '';
(*
  TestLines(LFInFile); {?}
*)

LFInFile := LF;

  If LFInFile <> GOOD then begin
      gotoXY(1,3);
      write('Line: ');
      ClrEOL;
  end;
  CASE LFInFile of
  LF..CR : begin
              while not eof(FileToRead) do
              begin
                read(FileToRead,ChrA);
                if (chrA<>chr(10)) and (chrA<>chr(13)) then
                    Line := Line + chrA {build line until LF}
                 else newLine; {start new line when LF found}
              end; {at EOF}
              writeln(Outfile,line);
              close(OutFile);
           end; {case LF or CR}

  NONE : begin
         chrCount := 0;
         wrapOn  := False;
         while not eof(FileToRead) do
         begin
           read(FileToRead,ChrA);
           chrCount := chrCount + 1;
           if chrCount > wrapCount-1 then wrapOn := True; {newline at nxt spc}
           if wrapOn and (chrA = ' ') then {start new line at next word break}
             begin
               newLine;
               chrCount := 0;
               wrapOn   := false;
             end
             else if chrA = chr(9) then
                     Line := Line + TabSpaces
                   else Line := Line + chrA; {normally just build line}
         end; {at EOF}
         writeln(Outfile,line);
         close(OutFile);
         end; {case NONE}
END; {CASE}
close(fileToRead);
IF LFInFile = GOOD then ChangeLines := FALSE
   else ChangeLines := TRUE;
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
  for currfile := 1 to paramcount do
  begin
   ChooseFile(currfile);
   if ChangeLines then SwapFile;
  end;
END.

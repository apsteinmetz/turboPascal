{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}

unit FileOps;

interface
uses
     CRT,      { AssignCRT }
     DOS,      {FindFirst, FindNext, SearchRec}
     Printer;  {PRN}

CONST
   nofile = '';
procedure GetDirectory(pattern : string;
                       VAR Dir : POINTER;
                       VAR firstfilename : string);
{ DIR = NIL if error }

function  GetNextFile(VAR Directory : POINTER) : string;
{ returns '' if nothing }

procedure StripExtension(VAR name: string);

function Exist(NameofFile: string):Boolean;

procedure DirectOutput(VAR out : TEXT);

procedure CheckPath(path : string);


implementation

var
   dest     : char;
   infile   : file;
   out      : text;
   Directory : string;
   n        : integer;
   ExitPtr  : Pointer;


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure GetDirectory(pattern : string;
                       VAR Dir : POINTER;
                       VAR firstfilename : string);
{ DIR = NIL if error }

var
   DirInfo : SearchRec;

begin
   FindFirst(pattern,Archive,DirInfo);
   IF DOSError <> 0 THEN
      Dir := NIL
   ELSE
   BEGIN
      firstfilename := DirInfo.Name;
      Dir           := @DirInfo;
   END;
END; {GetDirectory}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function  GetNextFile(VAR Directory : POINTER) : string;
{ returns '' if nothing }

var
   DirInfo : ^SearchRec;

begin
   DirInfo := Directory;
   FindNext(DirInfo^);
   IF DOSError <> 0 THEN
        GetNextFile := ''
   ELSE
       GetNextFile := DirInfo^.Name;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure StripExtension(VAR name: string);
CONST
  dot = '.';

BEGIN
   name := copy(name,1,pos(dot,name)-1);
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function Exist(NameofFile: string):Boolean;
var
    Fil: file;
  begin
    Assign(Fil,NameOfFile);
    {$I-}
    Reset(Fil);
    close(Fil);
    {$I+}
    Exist := (IOresult = 0);
end; {exist}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}


procedure DirectOutput(VAR out : TEXT);
var
   answer : string;

begin
  write('Direct Output to (S)creen, (P)rinter or (F)ile? ');
  readln(answer);
  dest := upcase(answer[1]);
  case dest of
     'S' : AssignCRT(out);
     'P' : Assign(out,'PRN');
     'F' : begin
             write('Enter name of File: ');
             readln(answer);
             assign(out,answer);
             if exist(answer) then
             begin
               write('FILE EXISTS!  Overwrite it? ');
               readln(answer);
               if (upcase(answer[1]) <> 'Y') then
                   DirectOutput(out);
             end;
           end;
  end; {case}
  rewrite(out);
end; {directoutput}


procedure CheckPath(path : string);
var
  answer : string;

begin
    {$I-}
    ChDir(Path + paramstr(1));
    {$I+}
    if (IOresult <> 0) or (length(paramstr(1)) < 1) then
    repeat
       Writeln('Path missing or incorrect.  Please specify: ');
       write(path);
       readln(answer);
       {$I-}
       ChDir(Path + answer);
       {$I+}
    until (IOResult = 0);
end; {checkpath}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{$F+} PROCEDURE CleanUp; {$F-}
{ restore original directory }
BEGIN
   ChDir(Directory);
   ExitProc := ExitPtr;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

begin {MAIN}
   { Install Termination Code }
   ExitPtr := ExitProc;
   ExitProc := @CleanUp;
   GetDir(0,Directory);  {remember where we started from}
end.

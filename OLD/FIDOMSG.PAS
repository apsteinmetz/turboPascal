{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}

program FidoMsg;

uses Break,
     CRT,      { AssignCRT }
     DOS,      {FindFirst, FindNext, SearchRec}
     Printer,  {PRN}
     StrUtil,  {StringSearch, StartStringSearch, SearchPattern }
     MathLib0, {HighMsgNum}
     FidoUtil;

const
   MaxMsgNum = 500; {Highest Msg. Num. this will search for}
   blocks   = 20;
   buffsize = 128;
   maxsize  = 2560;     {blocks * buffsize}
   ValidChars : set of 0..127 = [32..127];
   Path = 'C:\MSG\';
   EchoIDPrefix  = 'EID:';
   BodyStartByte = 191;
   LinesPerScreen = 24 { Lines per screen * Chars per line };
   LinesPerWindow = 19 { Lines per screen * Chars per line };
   HighArea = 8;
   AreaName : ARRAY[1..HighArea] OF STRING =
                 ('c:\msg\NET ',
                  'c:\msg\AMIGA ',
                  'c:\msg\AMIGLOCA ',
                  'c:\msg\AMIGMUSI ',
                  'c:\msg\AMIGVID ',
                  'c:\msg\AMIGPROG ',
                  'c:\msg\MIDINET ',
                  'c:\msg\HMSL');

type
   str80 = string[80];
   str12 = string[12];
   headers = (From,ToPers,Subj,Date);
   headinforec = record
                   HeadText : str80;
                   StartByte,
                   Length   : integer;
                 end;
   MsgRec   = record
                 orignum : integer;
                 Date    : real;
              end;

{ these type declarations are for QWIKSORT.SUB }
   DataItem  = MsgRec;
   DataArray = array[1..MaxMsgNum] of DataItem;

var
   dest     : char;
   infile   : file;
   out      : text;
   Directory : str80;
   HighMsgNum,           { max used index of MsgName }
   n        : integer;
   Buffer   : array[1..maxsize] of BYTE;
   MsgName  : DataArray;
   header   : headers;
   HeadInfo : array[From..Date] of headinforec;
   ExitPtr  : Pointer;

{ Sorting Routines }
{*****************************************************}

procedure QuickSort(var item : DataArray; count : integer);
     procedure QS(l,r :integer; var it : DataArray);
     var
        i,j : integer;
        x,y : Dataitem;
     begin
           i :=l ; j := r;
           x := it[(l+r) div 2];
           repeat
              while it[i].orignum < x.orignum do i := i + 1;
              while x.orignum < it[j].orignum do j := j - 1;
              if i <= j then
              begin
                 y     := it[i];
                 it[i] := it[j];
                 it[j] := y;
                 i := i+1; j:= j-1;
              end;
           until i > j;
           if l < j then qs(l,j,it);
           if l < r then qs(i,r,it);
        end; {qs}
begin
   qs(1,count,item);
end; {qwiksort}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure ReadDirectory;
const
     dot   = '.';
     space = #32;
var
   Msg,
   code    : WORD;
   DirInfo : SearchRec;
   line    : str80;

begin
   Writeln('Reading Directory - please wait');
   FindFirst('*.MSG',Archive,DirInfo);
   IF DOSError <> 0 THEN BEGIN
      writeln('Directory Error. DOSError: ',DosError:3);
      HALT;
   END;
   n := 0;
   { skip to first desired entry }
   Msg := 0;
   while DOSError = 0 DO BEGIN
      line := DirInfo.Name;
      { first occurance of dot is end of file name number}
      val(copy(line,1,pos(dot,line)-1),Msg,code);

      n := n + 1;
      MsgName[n].orignum := Msg;
      { get next entry }
      FindNext(DirInfo);
   end;
   Writeln('Sorting Entries');
   QuickSort(MsgName,n);
   HighMsgNum := MsgName[n].orignum;
end; {ReadDirectory}

function Exist(NameofFile: str80):Boolean;
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

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Initialize;
begin
  with HeadInfo[From] do
  begin
     HeadText := 'From: ';
     StartByte := 1;
     Length    := 36;
  end;
  with HeadInfo[ToPers] do
  begin
     HeadText := 'To:   ';
     StartByte := 37;
     Length    := 36;
  end;
  with HeadInfo[Subj] do
  begin
     HeadText := 'Subj: ';
     StartByte := 73;
     Length    := 72;
  end;
  with HeadInfo[Date] do
  begin
     HeadText := '';
     StartByte := 145;
     Length    := 20
  end;
end; {initialize}


procedure DirectOutput;

begin
  AssignCRT(out);
  rewrite(out);
end; {directoutput}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure CheckPath;
var
  answer : str80;

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
    until (IOResult = 0) and (length(answer) > 0);
end; {checkpath}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function OpenFile(num : integer; VAR fh : FILE) : boolean;
var
   name,
   MsgNum : str80;

begin
  str(num:1,MsgNum);
  Name := MsgNum + '.msg';
  assign(fh,Name);
    {$I-}
    Reset(Fh);
    {$I+}
    IF IOresult = 0 THEN
      OpenFile := TRUE
    ELSE
      OpenFile := FALSE;
end; {OpenFile}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Pause;
var
   ch : CHAR;

BEGIN
  ch := ReadKey;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure ChangeArea( VAR OldArea : WORD;
                      NewArea : STRING;
                      VAR Msg : WORD);
VAR
  Area,
  err : WORD;

BEGIN
  UpdateLastRead(AreaName[OldArea],Msg);
  delete(NewArea,1,1);
  val(NewArea,Area,err);
  IF (err = 0) AND (Area < HighArea) THEN
  BEGIN
     OldArea := Area;
     ChDir(AreaName[Area]);
     ReadDirectory;
     Msg := FindLastRead(AreaName[Area]);
     IF Msg > HighMsgNum THEN
     BEGIN
         UpdateLastRead(AreaName[Area],HighMsgNum);
         Msg := HighMsgNum;
     END;
     Window(1,1,80,LinesPerScreen);
     ClrScr;
     writeln(out,AreaName[Area],' MSG: ',Msg:1,'/',HighMsgNum:1);
     WriteLn(out,'Last message read was',Msg:5);
  END
  ELSE BEGIN
    ClrScr;
    writeln('Area Not Found!');
  END;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure ProcessMsg(Area, MsgNum : WORD);

var
  i,
  RecsRead,
  LineCount,
  NewChar  : WORD;
  tempstr  : STRING;
  FoundString : BOOLEAN;
  search   : SearchPattern;
  InFile   : FILE;

  procedure LeadOff(Info : HeadInfoRec);
  var
    NewChar,n : integer;
    InHeading : boolean;

  begin
  with Info do
    begin
       n := 0;
       InHeading := TRUE;
       write(out,HeadText);
       while (n < StartByte + Length) and InHeading do
       begin
          NewChar := Buffer[StartByte+n];
          if NewChar in ValidChars then write(out,chr(NewChar))
              else InHeading := FALSE;
          n := n + 1;
       end;
       writeln(out);
    end; {with}
  end; {leadoff}

begin {processsmsg}
IF OpenFile(MsgNum,InFile) then
BEGIN
  Window(1,1,80,LinesPerScreen);
  ClrScr;
  writeln(out,AreaName[Area],'MSG: ',MsgNum:1,'/',HighMsgNum:1);
  FoundString := FALSE;
  StartStringSearch('SEEN-BY',search);
  while NOT (EOF(InFile) OR FoundString) do
  begin
    BlockRead(InFile,Buffer,blocks,RecsRead);
  { Note that the variable i is used in two different contexts }
    for i := 0 to 3 do LeadOff(HeadInfo[headers(i)]);
    writeln(out);
    Window(1,WhereY,80,LinesPerScreen);
    LineCount := 4;
    i := BodyStartByte;

    { test for echo ID label }
    tempstr := CHAR(Buffer[i+1]) + CHAR(Buffer[i+2]) +
                  CHAR(BUFFER[i+3]) + CHAR(BUFFER[i+4]);
    tempstr[0] := CHAR(4);
    IF tempstr = EchoIDPrefix THEN
        i := BodyStartByte + 18;

    while (i < BuffSize * RecsRead) AND NOT FoundString DO
    begin
        NewChar := Buffer[i];
        IF (NewChar = 10) OR (NewChar = 161) THEN
           Writeln(out)
        ELSE BEGIN
           FoundString := StringSearch(chr(NewChar),search);
           IF NOT FoundString THEN
              IF NewChar in ValidChars then write(out,chr(NewChar));
        END;
        INC(i);
        IF WhereX = 1 THEN INC(LineCount); { New Line if Cursor is at 1st col }
        IF  (LineCount > LinesPerWindow) THEN
        BEGIN
           Pause;
           LineCount := 2;
        END;
    end; {for i}
end; {while not EOF}
Close(InFile)
END;
end; {ProcessMsg}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{$F+} PROCEDURE CleanUp; {$F-}
BEGIN
   ChDir(Directory);
   ExitProc := ExitPtr;
END;


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE ProcessArea;
VAR
  err,
  OldArea,
  Num,
  MsgNum : WORD;
  Response : STRING;

BEGIN
   ChDir(AreaName[1]);
   MsgNum := FindLastRead(AreaName[1]);
   OldArea := 1;
   ChangeArea(OldArea,'A1',MsgNum);
   REPEAT
      GotoXY(1,23);
      Write('"<Ret>" Next Msg, "-" Last Msg, "+" Next Msg "A"# Change Area >');
      Response[1] := #0;
      Readln(Response);
      val(Response,Num,err);
      if err = 0 THEN BEGIN
         MsgNum  := Num;
         ProcessMsg(OldArea,MsgNum);
      END
      ELSE
      CASE upcase(Response[1]) OF
         'A' : ChangeArea(OldArea,Response, MsgNum);
         '-' : BEGIN
                 dec(MsgNum);
                 MsgNum := max(MsgNum,0);
                 ProcessMsg(OldArea,MsgNum);
               END;
         '+',#0 : BEGIN
                 INC(MsgNum);
                 MsgNum := min(MsgNum,HighMsgNum);
                 ProcessMsg(OldArea,MsgNum);
               END;
      END; {case}
   UNTIL upcase(Response[1]) = 'G'; {Goodbye }
   UpdateLastRead(AreaName[OldArea],MsgNum);

END; { processarea }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
begin {MAIN}
   { Install Termination Code }
   ExitPtr := ExitProc;
   ExitProc := @CleanUp;

   GetDir(0,Directory);  {remember where we started from}
   Initialize;
   DirectOutput;
   ProcessArea;
   CleanUp; { go back to where we started from }
end.

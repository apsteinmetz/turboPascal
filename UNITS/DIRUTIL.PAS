UNIT DirUtil;
{ some directory utilities }

interface

procedure Dir(Path : string);
{ Gets a list of names }

function NextName : String;
{get next (or first) name found.  '' (null string) after last.}

implementation

USES DOS;

TYPE
 NameListPtr = ^NameList;
 NameList    = Record
      FullName : string; { name including path }
      Next     : NameListPtr;
 END;

VAR
  MatchingNames : NameListPtr;
  CurrentName  : NameListPtr;
  OldExit      : POINTER;

procedure Dir(Path : string);
{ returns a pointer to a linked List of names matching SPEC }

var
  I,J: Integer;
  Attr: Word;
  S: PathStr;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  F: File;
  SR : SearchRec;
  OldNode,
  Node : NameListPtr;
begin

  { properly qualify path name }
  Path := FExpand(Path);
  if Path[Length(Path)] <> '\' then
  begin
    Assign(F, Path);
    GetFAttr(F, Attr);
    if (DosError = 0) and (Attr and Directory <> 0) then
      Path := Path + '\';
  end;
  FSplit(Path, D, N, E);
  if N = '' then N := '*';
  if E = '' then E := '.*';
  Path := D + N + E;

  OldNode := NIL;
  FindFirst(Path, ReadOnly + Archive, SR);
  while (DosError = 0) do
  begin
    New(Node);
    Node^.FullName := D + SR.Name;
    Node^.Next := OldNode;
    OldNode := Node;
    FindNext(SR);
  end;
  MatchingNames := OldNode;
  CurrentName := MatchingNames;
end;

function NextName : String;
BEGIN
  IF CurrentName <> NIL THEN
  BEGIN
    NextName := CurrentName^.FullName;
    CurrentName := CurrentName^.Next;
  END
  ELSE
    NextName := '';
END;



{ -------------------------------------------------------------------- }
{$F+}
procedure FreeList;
VAR
  Node : NameListPtr;

BEGIN
  ExitProc := OldExit;
  WHILE MatchingNames <> NIL DO
  BEGIN
       Node := MatchingNames;
       MatchingNames := MatchingNames^.Next;
       Dispose(Node);
  END;
END;
{$F-}

begin
  OldExit := ExitProc;
  ExitProc := @FreeList;
end.

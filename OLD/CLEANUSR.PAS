PROGRAM CLEANUSR;
USES
  FileOps;

CONST
  errorlogfile = 'IDERR.LOG';

TYPE
  UserIDString = String[10];

  UserIDNodePtr = ^UserIDNode;
  UserIDNode = RECORD
    UserIDNum : UserIDString;
    Next     : UserIDNodePtr;
  END;
  SecArray = ARRAY[0..99] OF UserIDNodePtr;

VAR
  UserID      : UserIDString;
  Instr      : String;
  UserIDList  : SecArray;
  ExitSave,
  heap      : POINTER;
  IDFile,
  IDFile2,
  errlog    : text;

  { input parameters }
  PriceStart,
  PriceLength,
  FactorStart,
  FactorLength,
  UserIDStart,
  UserIDLength  : WORD;
  ReadFile     : String;


(* ---------------------------------------------- *)
PROCEDURE Help;
BEGIN
  Writeln('usage: CLEANUSR FileName');
  Writeln('Error report will be in ',errorlogfile);
  HALT;
END;

(* ---------------------------------------------- *)
PROCEDURE Setup;
VAR
  err : INTEGER;

BEGIN
   ReadFile := Paramstr(1);
   IF (paramcount = 0) OR (ReadFile[1] = '?') THEN
     Help;

   { prepare error log}
   assign(errlog,errorlogfile);
   rewrite(errlog);
   writeln(errlog,'DUPLICATE ID NUMBERS KILLED');
   writeln(errlog);

   IF NOT exist(ReadFile) THEN
   BEGIN
      Writeln(ReadFile,' not found!');
      Help;
   END;
   assign(IdFile,ReadFile);
   reset(IDFile);
   assign(IdFile2,'temp.txt');
   rewrite(IDFile2);
END;

(* ---------------------------------------------- *)
PROCEDURE InitNodes;
VAR
  n : BYTE;
BEGIN
  Mark(heap);
  FOR n := 0 TO 99 DO
    UserIDList[n] := NIL;
END;

(* ---------------------------------------------- *)
FUNCTION UserIDWasDone(UserIDStr : UserIDString) : BOOLEAN;
{ build a linked list of UserIDs found }
{ scan linked list to see if UserID is present,
{ add if not, return FALSE. Return TRUE if it is }

{ also return TRUE on Error - assume error has }
{ already been done so no action will be taken }

VAR

err,
nodecount,
index : INTEGER;
UserIDNode,
Node     : UserIDNodePtr;
Done,
FoundUserID : BOOLEAN;

BEGIN
  FoundUserID := FALSE;
  Done := FALSE;
  nodecount := 0;
  err := 0;

  val(copy(UserIDStr,1,2),index,err);
  IF err > 0 THEN
    UserIDWasDone := TRUE
  ELSE
  BEGIN
    Node := UserIDList[index];
    IF NOT (Node = NIL) THEN
    { array index points to something }
    REPEAT
      inc(NodeCount);
      IF (Node^.UserIDNum = UserIDStr) THEN
      BEGIN
         FoundUserID := TRUE;
         Done       := TRUE;
      END
      ELSE
         IF Node^.Next = NIL THEN
            Done := TRUE
         ELSE
            Node := Node^.Next;
    UNTIL Done;
    IF NOT FoundUserID THEN
    BEGIN
       New(UserIDNode);
       UserIDNode^.UserIDNum := UserIDStr;
       UserIDNode^.Next := NIL;
       IF (Node = NIL) THEN  {first item in list}
           UserIDList[index] := UserIDNode
        ELSE                 { somewhere down the list }
           Node^.Next := UserIDNode;
    END;
    UserIDWasDone := FoundUserID;
  END {if err <> 0};
END;

(* ---------------------------------------------- *)
FUNCTION ExtractIDString(instr : STRING) : UserIDString;
{ user id string is 5 numbers followed by ',' followed by }
{ 1 to 4 numbers followed by a space                      }

CONST
  Id1Len = 5;

VAR
 i,
 err,
 testnum,
 strstop   : INTEGER;
 FoundID  : BOOLEAN;
 Id1, Id2 : STRING[5];


BEGIN
   strstop := length(instr)-Id1Len;
   i := 1;
   FoundID := FALSE;
   REPEAT
      ID1 := copy(instr,i,Id1Len);
      val(ID1,testnum,err);
      IF (err = 0) THEN
      BEGIN
         IF (copy(instr,i+Id1Len,1) = ',') THEN
         BEGIN
           ID2 := copy(instr,i+6,5);
           ID2 := copy(ID2,1,pos(' ',ID2)-1);
           val(ID2,testnum,err);
           IF (err = 0) THEN
              FoundID := TRUE;
         END;
      END;
      INC(i);
   UNTIL FoundID or (i > strstop);

   IF FoundID THEN
      ExtractIDString := ID1 + ID2
   ELSE
       ExtractIDString := '00'+ copy(instr,1,8);

END {ExtractIDString};

(* ---------------------------------------------- *)
PROCEDURE KillDupes;
VAR
  IdStr,
  instr : STRING;

BEGIN
  WHILE NOT eof(IDFile) DO
  BEGIN
     readln(IdFile,instr);
     IdStr := ExtractIDString(instr);
     IF NOT UserIDWasDone(IdStr) THEN
        Writeln(IDFile2,instr)
     ELSE
         Writeln('duplicate ',instr);
  END {DO};
END;

(* ---------------------------------------------- *)
(* ---------------------------------------------- *)
PROCEDURE Finish;
BEGIN
  Release(Heap);
  Close(errlog);
  Close(IDFile);
END;
(* ---------------------------------------------- *)
BEGIN
  Setup;
  InitNodes;
  KillDupes;
  Finish;
END.
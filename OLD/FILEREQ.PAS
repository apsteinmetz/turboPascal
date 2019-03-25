program FileReq;
uses DOS, { FindFirst, FindNext, SearchRec, DirStr, NameStr, ExtStr }
     StrUtil {RepeatStr},
     BTREE {STree, CompProc, TreePtr},
     CRT
     ;
{$F+}

CONST
  WildSpec = '*.*';
  DirAtr    = '<DIR>';

TYPE
  NameStr = String[12];
  NameStrPtr = ^NameStr;
  FNameRecPtr = ^FNameRec;
  FNameRec  = RECORD
            Name : NameStr;
            Atr  : DirStr;
            Last,
            Next : FNameRecPtr;
        END;

  DirRec = RECORD
            Root     : TreePtr;
            Path     : PathStr;
        END;

VAR
  memflag : ^BYTE;
  CurrDir : DirRec;

(* +++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
FUNCTION CompareFunc(item1,item2 : POINTER) : BOOLEAN;
VAR
  Name1,
  Name2 : NameStr;

BEGIN
  Name1 := FNameRecPtr(item1)^.name;
  Name2 := FNameRecPtr(item2)^.name;
  IF Name1 < Name2 THEN CompareFunc := TRUE
     ELSE CompareFunc := FALSE;
END {CompareFunc};

(* +++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
PROCEDURE MakeDirList(Path : PathStr; VAR Dir : DirRec);
{ Create a doubly linked list of directory entries }
VAR
  dummy             : TreePtr;
  Atr               : DirStr;
  FNMask            : PathStr;
  DirInfo           : SearchRec;
  LastPtr,
  FName             : FNameRecPtr;

BEGIN
   Dir.Path := Path;
   FNMask := Path + WildSpec;
   FindFirst(FNMask,Directory,DirInfo);
   IF DOSError = 0 THEN
   { initial dir tree creation }
   BEGIN
     Dir.root := NIL;
     new(FName);
     AddData(Dir.root,POINTER(FName));
   END;
   WHILE DOSError = 0 DO
   BEGIN
      CASE DirInfo.Attr OF
          Hidden    : Atr := ' *Hidden*';
          Directory :
                  Atr := DirAtr;

          ReadOnly  : Atr := ' *Read Only*';
      ELSE
        Atr := '';
      END;
      FName^.Name := DirInfo.Name;
      FName^.Atr  := Atr;
      AddData(Dir.root,POINTER(FName));
      FindNext(DirInfo);
      IF DosError = 0 THEN
      BEGIN
          new(FName);
      END
   END;
END {MakeDirList};

{ Procedure parameters for dynamic sort }
(* +++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

PROCEDURE DisplayDirList(Dir : DirRec);
VAR
   Entry : FNameRecPtr;

   PROCEDURE InOrder(rt : TreePtr);
   BEGIN
     WHILE rt <> NIL DO
     BEGIN
       InOrder(rt^.left);
       Entry := FNameRecPtr(rt^.dataptr);
       Write(Entry^.name);
       Write(Entry^.atr);
       Writeln;
       delay(100);
       InOrder(rt^.right);
     END;
  END {InOrder};

BEGIN
  WriteLn(Dir.Path);
  InOrder(Dir.root);
END {DisplayDirList};

BEGIN
  LessThan := CompareFunc;
  Mark(memflag);
  MakeDirList('C:\tp\',CurrDir);
  DisplayDirList(CurrDir);
  Release(memflag);
END.




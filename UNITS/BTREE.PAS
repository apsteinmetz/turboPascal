unit BTREE;

INTERFACE
TYPE
  TreePtr  = ^Tree;
  Tree     = RECORD
               DataPtr : POINTER;
               left,
               right   : TreePtr;
             END;


  CompProc = FUNCTION(ptr1,ptr2 : POINTER) : BOOLEAN;
  { Return TRUE if first item is less than second }

VAR
  LessThan : CompProc;

PROCEDURE AddData(VAR BaseRoot : TreePtr; Data : POINTER);
{ root should be NIL first time AddData is called }

FUNCTION DummyCompProc( ptr1,ptr2 : POINTER) : BOOLEAN;

IMPLEMENTATION

FUNCTION DummyCompProc( ptr1,ptr2 : POINTER) : BOOLEAN;
BEGIN
  Writeln('You must initialize the LessThan process! to use STree!');
  HALT;
END;


FUNCTION STree(root, r : TreePtr;
               Data : POINTER) : TreePtr;

BEGIN
  IF r = NIL THEN
  BEGIN
    New(r);
    r^.left    := NIL;
    r^.right   := NIL;
    r^.dataptr := Data;
    IF LessThan(Data,root^.dataptr) THEN
        root^.left := r
    ELSE
        root^.right := r;
    STree := r;
  END ELSE
       IF LessThan(Data,root^.dataptr) THEN
           STree := STree(r,r^.left,Data)
       ELSE
           Stree := STree(r,r^.right,Data);
END {STree};

PROCEDURE AddData(VAR BaseRoot : TreePtr; Data : POINTER);
VAR
  dummy : TreePtr;

BEGIN
  IF BaseRoot = NIL THEN
       BaseRoot := STree(BaseRoot,BaseRoot,Data)
{
       BEGIN
        New(BaseRoot);
        WITH BaseRoot^ DO
        BEGIN
          left    := NIL;
          right   := NIL;
          dataptr := Data;
        END;
     END
}
  ELSE
       dummy := STree(BaseRoot,BaseRoot,Data);
END {AddData};

BEGIN
  LessThan := DummyCompProc;
END.
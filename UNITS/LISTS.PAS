UNIT Lists;
interface

CONST
  MaxItems = 10;

TYPE
  Item = ARRAY[1..MaxItems] OF REAL;

  NodeRecPtr = ^NodeRec;
  NodeRec  = RECORD
     Data : Item;
     Next : NodeRecPtr;
  END;

  List = OBJECT
     Node,
     CurrNode,
     TailNode : NodeRecPtr;
     constructor Init;
     destructor Done;
     procedure AddItem(Data : Item);
     procedure ChangeCurrItem(Data : Item);
     function GetNext(VAR Data : Item) : BOOLEAN;
     {return false at end of list }
     function SearchList(VAR Data : Item) : BOOLEAN;
     {return TRUE IF FOUND }
  END;


implementation

{ =============================================== }
constructor List.Init;
BEGIN
  Node := NIL;
  TailNode := NIL;
  CurrNode := NIL;
END;

{ =============================================== }
destructor List.Done;

BEGIN
  WHILE Node <> NIL DO
  BEGIN
    CurrNode := Node^.next;
    Dispose(Node);
    Node := CurrNode;
  END;
  TailNode := NIL;
END {Done};
{ =============================================== }
procedure List.AddItem(Data : Item);
{ Push items on a FIFO Stack }

VAR
  n : NodeRecPtr;

BEGIN
  New(n);
  {clear memory}
  FillChar(n^.Data,SizeOf(n^.Data),#0);
  IF Node = NIL THEN
    Node := n
  ELSE
    TailNode^.next := n; {chain forward }

  n^.Data  := Data;
  n^.Next  := NIL;
  TailNode := n;
END {AddItem};

{ =============================================== }
procedure List.ChangeCurrItem(Data : Item);
BEGIN
  CurrNode^.Data := Data;
END {ChangeCurrItem};

{ =============================================== }
function List.GetNext(VAR Data : Item) : BOOLEAN;
{return false at end of list }

BEGIN
  {Check if initial access or at end of list }
  IF (CurrNode = NIL) THEN
      CurrNode := Node
  ELSE
      CurrNode := CurrNode^.next;

  IF (CurrNode = NIL) THEN {At end of list}
     GetNext := FALSE
  ELSE BEGIN
     Data := CurrNode^.Data;
     GetNext := TRUE;
  END;
END {GetNext};

function SearchList(VAR Data : Item) : BOOLEAN;
     {return TRUE IF FOUND }

END.
UNIT XYSTACK;

TYPE
  nodetype = RECORD
           a,b : WORD;
           lastnode : POINTER;
         END;

VAR
  noderec : nodetype;
  nodeptr : ^noderec;


{ ---------------------------------------------------------------}
PROCEDURE Push(VAR stack : POINTER; x,y : WORD);

BEGIN
  new(node);
  node^.a := x;
  node^.b := y
  node^.lastnode := stack;
  stack := node;
END;

UNIT Memory;

interface

{ use this unit and New() and GetMem() will return NIL if they fail }
{ instead of a run time error }
{ no fuction call required, just a USES statement }

implementation

{$F+}
FUNCTION HeapFunc(Size : WORD) : INTEGER; {$F-}

BEGIN
  HeapFunc := 1;
END;


BEGIN
  HeapError := @HeapFunc;
END.
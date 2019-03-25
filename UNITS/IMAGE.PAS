UNIT Image;

interface

USES Graph; {ImageSize, GetImage PutImage}

FUNCTION SaveImage(x1,y1,x2,y2 : INTEGER) : POINTER;
{ NIL if image is too big }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

implementation

FUNCTION SaveImage(x1,y1,x2,y2 : INTEGER) : POINTER;
{ NIL if image is too big }

VAR
  size

BEGIN
  size := ImageSize(x1,y1,x2,y2)
  IF size > $FFFF {64 k} THEN
     SaveImage := NIL
  ELSE
     GetImage(x1,y1,x2,y2,BitMap);
  SaveImage := BitMap;
END; {SaveImage}

BEGIN
END.
(*  ideas for open array module
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}

FUNCTION MakeSurface(VAR srf : SurfaceRec; HowBig : WORD) : BOOLEAN;
BEGIN
  srf.size := HowBig;
  GetMem(srf.surfptr,sqr(size));
  IF srf.surfptr = NIL THEN
     MakeSurface := FALSE
  ELSE BEGIN
     MakeSurface := TRUE;
  END;
END;
*)
(*
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE AssignArray(VAR srf : SurfaceRec; ary : Pointer);
CONST
  LongSize = 4; {bytes}

VAR
  r, c, offset : LONGINT;
  address1, address2 : POINTER;

BEGIN
  FOR c := 0 TO srf.size-1 DO
     FOR r := 0 TO srf.size-1 DO BEGIN
         offset    := LongSize * r * size + c;
         address1  := POINTER(LONGINT(ary) + offset);
         address2  := POINTER(LONGINT(srf.surfptr) + offset);
         Move(address1,address2,LongSize);
     END;
END;

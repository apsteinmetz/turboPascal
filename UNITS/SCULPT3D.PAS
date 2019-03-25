UNIT Sculpt3D;

interface

{$I FLOAT.INC}


TYPE
   FaceProperty      = WORD;

   VertexPtr   = ^VertexRec;
   EdgeListPtr = ^EdgeListRec;
   EdgePtr     = ^EdgeRec;
   FacePtr     = ^FaceRec;
   ObjectPtr   = ^ObjectRec;

   VertexRec = RECORD
          next : VertexPtr;
          pos  : ARRAY[0..2] OF SINGLE;
          edgelist : EdgeListPtr;
          index    : WORD;
    END;

   EdgeListRec = RECORD
          next : EdgeListPtr;
          edge : EdgePtr;
    END;

   EdgeRec = RECORD
          next   : EdgePtr;
          vertices : ARRAY[0..1] OF VertexPtr;
    END;

   FaceRec = RECORD
          next   : FacePtr;
          vertices : ARRAY[0..2] OF VertexPtr;
          properties : FaceProperty;
    END;

   ObjectRec = RECORD
          vertices : VertexPtr;
          edges   : EdgePtr;
          faces   : FacePtr;
    END;

PROCEDURE WriteCoord(v : VertexPtr);

FUNCTION NewVertex(x,y,z : SINGLE; NextV : VertexPtr) : VertexPtr;

FUNCTION NewEdgeList( NewEdge : EdgePtr;
                      NextEL : EdgeListPtr) : EdgeListPtr;

FUNCTION NewEdge(v1,v2 : VertexPtr; NextE : EdgePtr) : EdgePtr;

FUNCTION NewFace( v1,v2, v3 : VertexPtr;
                  properties : WORD;
                  NextF : FacePtr) : FacePtr;

PROCEDURE NewObject(VAR obj : ObjectRec);

Function GetEulerNum : LONGINT;

PROCEDURE Link( object : ObjectPtr;
                v1, v2 : VertexPtr;
                properties : WORD);

implementation
CONST
  Debug = TRUE;

VAR
  EdgeCount, FaceCount,
  VertexCount,
  EulerNumber : LONGINT;
  p,
  ExitPtr : POINTER (* Termination Code *);

PROCEDURE MemErr(msg : String);
BEGIN
  Writeln('Ran out of Memory making a new ',msg);
  HALT;
END;


PROCEDURE WriteCoord(v : VertexPtr);
BEGIN
   Write(v^.pos[0]:3:0,',');
   Write(v^.pos[1]:3:0,',');
   Write(v^.pos[2]:3:0);
END;

FUNCTION NewVertex(x, y, z : SINGLE; NextV : VertexPtr) : VertexPtr;
VAR
  v : VertexPtr;

BEGIN
  GetMem(v,SizeOf(VertexRec));
  IF v = NIL THEN MemErr('Vertex');
  v^.pos[0] := x;
  v^.pos[1] := y;
  v^.pos[2] := z;
  v^.edgelist := NIL;
  v^.next     := NextV;
  INC(VertexCount);
  NewVertex := v;
END;

FUNCTION NewEdgeList( NewEdge : EdgePtr;
                      NextEL : EdgeListPtr) : EdgeListPtr;
VAR
  EL : EdgeListPtr;

BEGIN
  GetMem(EL,SizeOf(EdgeListRec));
  IF EL = NIL THEN MemErr('EdgeList');
  EL^.edge  := NewEdge;
  EL^.next  := NextEL;
  NewEdgeList := EL;
END;

FUNCTION NewEdge(v1,v2 : VertexPtr; NextE : EdgePtr) : EdgePtr;
VAR
  E : EdgePtr;

BEGIN
  GetMem(E,SizeOf(EdgeRec));
  IF E = NIL THEN MemErr('Edge');
  E^.vertices[0] := v1;
  E^.vertices[1] := v2;
  E^.next  := NextE;
  INC(EdgeCount);
  NewEdge := E;
END;

FUNCTION NewFace( v1,v2, v3 : VertexPtr;
                  properties : WORD;
                  NextF : FacePtr) : FacePtr;
VAR
  F : FacePtr;

BEGIN
  GetMem(F,SizeOf(FaceRec));
  IF F = NIL THEN MemErr('Face');
  F^.vertices[0] := v1;
  F^.vertices[1] := v2;
  F^.vertices[2] := v3;
  F^.next  := NextF;
  INC(FaceCount);
  NewFace := F;
END;

PROCEDURE NewObject(VAR obj : ObjectRec);

BEGIN
  EulerNumber := 0;
  EdgeCount   := 0;
  FaceCount   := 0;
  VertexCount := 0;
  obj.vertices := NIL;
  obj.edges := NIL;
  obj.faces := NIL;
END;

Function GetEulerNum : LONGINT;
BEGIN
  GetEulerNum := FaceCount + VertexCount - EdgeCount;
END;

FUNCTION OtherEnd(VAR e : EdgePtr; VAR v : VertexPtr) : VertexPtr;
(* called by Link *)
BEGIN
   IF e^.vertices[0] <> v THEN
       OtherEnd := e^.vertices[0]
   ELSE
       OtherEnd := e^.vertices[1]
END;

PROCEDURE Link( object : ObjectPtr;
                v1, v2 : VertexPtr;
                properties : WORD);
VAR
  Edge1      : EdgePtr;
  EList1,
  EList2     : EdgeListPtr;
  v3         : VertexPtr;
  Face1      : FacePtr;
  LinkExists : BOOLEAN;

BEGIN
   LinkExists := FALSE;
   EList1 := v1^.edgelist;
   WHILE (EList1 <> NIL) AND NOT LinkExists DO
   BEGIN
     LinkExists := (OtherEnd(EList1^.edge,v1) = v2);
     EList1 := EList1^.next;
   END;

   IF Debug THEN
   BEGIN
     WriteCoord(v1);
     Write(' <--> ');
     WriteCoord(v2);
     IF LinkExists THEN
       Write(' Already linked.')
     ELSE
       Write(' Linking.');
   END;

   IF NOT LinkExists THEN (* make the link *)
   BEGIN
     object^.edges := NewEdge(v1, v2, object^.edges);
     Edge1 := object^.edges;
     v1^.edgelist := NewEdgeList(Edge1, v1^.edgelist);
     v2^.edgelist := NewEdgeList(Edge1, v2^.edgelist);

     { check for face completion }
     EList1 := v1^.edgelist;
     WHILE EList1 <> NIL DO
     BEGIN
       v3 := OtherEnd(EList1^.edge, v1);
       IF v3 <> v2 THEN
       BEGIN
          EList2 := v3^.edgelist;
          WHILE EList2 <> NIL DO
          BEGIN
            IF OtherEnd(Elist2^.edge,v3) = v2 THEN
            BEGIN
              IF Debug THEN
              BEGIN
                WriteCoord(v3);
                Write('Face!');
              END;
              object^.faces :=
                   newface(v1, v2, v3, properties, object^.faces);
            END;
            EList2 := EList2^.next;
          END;
       END;
       EList1 := EList1^.next;
     END;
   END;
   WriteLn;
END {Link};

(* ------------------------------------------------------- *)
{$F+}
PROCEDURE CleanUp;
BEGIN
  ExitProc := ExitPtr;
  Release(p);
END;
{$F-}

BEGIN
   ExitPtr  := ExitProc;
   ExitProc := @CleanUp;
   Mark(p);
   EulerNumber := 0;
END { Sculpt3D }.
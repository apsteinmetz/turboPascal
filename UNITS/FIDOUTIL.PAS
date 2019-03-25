UNIT FidoUtil;

interface

USES FileUtil; {exists}

CONST
  LastReadFileName = 'LASTREAD.';

TYPE
   pathstr =  STRING[79];

PROCEDURE UpDateLastRead( path : PathStr; MsgNum : WORD);

FUNCTION FindLastRead( path : PathStr) : WORD;

(*********************************************************)
implementation

PROCEDURE UpDateLastRead( path : PathStr; MsgNum : WORD);
VAR
  outfile : FILE OF WORD;

BEGIN
  { fix backslash if necessary }
  if NOT (path[length(path)] = '\') THEN
       path := path + '\';
  path := path + LastReadFileName;
  Assign(outfile,path);
  Rewrite(outfile);
  Write(outfile,MsgNum);
  Close(outfile);
END; {  UpDateLastRead }

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION FindLastRead( path : PathStr) : WORD;

VAR
  MsgNum  : WORD;
  outfile : FILE OF WORD;

BEGIN
  { fix backslash if necessary }
  if NOT (path[length(path)] = '\') THEN
       path := path + '\';
  path := path + LastReadFileName;
  IF exists(path) THEN
  BEGIN
     Assign(outfile,path);
     Reset(outfile);
     Read(outfile,MsgNum);
     Close(outfile);
     FindLastRead := MsgNum;
  END
  ELSE FindLastRead := 1;
END; {  UpDateLastRead }

BEGIN
END. {FidoUtil}
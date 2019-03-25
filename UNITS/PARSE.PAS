UNIT PARSE;
(* parse a string *)

interface

CONST
   (* Most args that will be parsed *)
   MaxArg = 50;

PROCEDURE ParseString( VAR strc : WORD;
                       instr    : STRING;
                       delim    : CHAR);
(* the number of args in instr is returned in strc *)
(* delim is the argument delimiter, normally ' ' *)


FUNCTION argstr(argindex : WORD) : STRING;
(* extract string argindex from parsestring.  Returns null *)
(* string if none to retrieve *)


(****************************************************************)
implementation

TYPE
  args = ARRAY[1..MaxArg] OF ^STRING;

VAR
  OrigExit : POINTER;
  arg      : ^args;
  argcount : WORD;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE AddArg(VAR pstr : STRING);
BEGIN
   IF NOT (argcount + 1 > MaxArg) THEN
   BEGIN
      inc(argcount);  { increment internal counter }
      new(arg^[argcount]);   { make new string pointer }
      arg^[argcount]^ := pstr;
      pstr := '';
   END;
END;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROCEDURE ParseString( VAR strc : WORD;
                       instr    : STRING;
                       delim    : CHAR);
(* argc is the number of args, argv is a pointer to an array of string *)
(* pointers argv^[1]^ is a string *)

VAR
   len,
   i      : WORD;
   pstr    : STRING;

BEGIN
  IF (arg <> NIL) AND (argcount > 0) THEN
  BEGIN
     FOR i := 1 to argcount DO Dispose(arg^[i]);
     argcount := 0;
  END;

  pstr := '';
  len := length(instr);
  i := 1;
  REPEAT
    IF (instr[i] = delim) AND (length(pstr) > 0) THEN
       AddArg(pstr);
    WHILE instr[i] = delim DO inc(i);
    IF (i < len + 1) THEN pstr := pstr + instr[i];
    inc(i);
  UNTIL i > len;
  (* add final string, if any *)
  IF (length(pstr) > 0) THEN
       AddArg(pstr);
  argc    := argcount;
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
FUNCTION argstr(argindex : WORD) : STRING;
BEGIN
  IF argindex > argcount THEN
     argstr := ''
  ELSE
     argstr := arg^[argindex]^
END;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{$F+} PROCEDURE ClearParse; {$F-}
VAR
   i : WORD;


BEGIN
  IF (argcount > 0) THEN
  BEGIN
     FOR i := 1 to argcount DO Dispose(arg^[i]);
     argcount := 0;
  END;
  Dispose(arg);
  ExitProc := OrigExit;
END;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

BEGIN
  OrigExit := ExitProc;
  ExitProc := @ClearParse;
  argcount := 0;
  new(arg);  { make new array of pointers }
END.


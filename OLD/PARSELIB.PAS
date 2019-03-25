PROGRAM ParseLib;

uses PARSE, fileutil, DOS;

CONST
  outfileName = 'c:\sym\comod\cislib.txt';
  LibPrompt = 'DL';
  MaxDescrLines = 10;

VAR
  argc,
  n : WORD;
  instr : STRING;
  InText : BOOLEAN;
  Descr  : ARRAY[1..MaxDescrLines] OF STRING;
  outfile,
  infile : TEXT;


PROCEDURE SkipToChange(VAR InText : BOOLEAN);
(* InText := FALSE will jump to blank line *)
(* InText := TRUE will jump to line with text *)

BEGIN
   REPEAT
      readln(infile,instr);
      ParseString(argc,instr,' ');
   UNTIL ((argc > 0) = InText);
   InText := NOT InText;
END;

VAR
  DownLoads,
  Lib, User, Name, Size, UpDate, FileType : STRING;
  Forum : NameStr;
  { throwaways for FSplit }
  infilename : PathStr;  Dir : DirStr;  Ext : ExtStr;

BEGIN
  infilename := paramstr(1);
  if exists(infilename) THEN
  BEGIN
     assign(infile,inFileName);
     reset(infile);
  END ELSE HALT;
  FSplit(infilename,Dir,Forum,Ext);
  if exists(outfilename) THEN
  BEGIN
     assign(outfile,outFileName);
     append(outfile);
  END
  ELSE
  BEGIN
     assign(outfile,outFileName);
     rewrite(outfile);
  END;
  WHILE NOT eof(infile) DO
  BEGIN
    readln(infile,instr);
    ParseString(argc,instr,' ');
    (* test for lib change *)
    IF (argc = 2) AND (argstr(1) = LibPrompt) THEN
      Lib := argstr(2);
    (* Find usernumber. The '[' is the main flag! *)
    IF instr[1] = '[' THEN
    BEGIN
      ParseString(argc,instr,']');
      user := copy(argstr(1),2,length(argstr(1)));
      { get file data }
      readln(infile,instr);
      writeln(instr);
      ParseString(argc,instr,' ');
      UpDate := argstr(2);
      Size := argstr(3);
      Downloads := argstr(4);
      { separate filename from type }
      ParseString(argc,argstr(1),'/');
      Name := argstr(1);
      FileType := argstr(2);

      InText := TRUE; { find next line with text }
      { skip to keywords }
      SkipToChange(InText);
      { skip past keywords }
      SkipToChange(InText);
      { find description }
      SkipToChange(InText);

      { read description }
      n := 0;
      REPEAT
        inc(n);
        Descr[n] := instr;
        ParseString(argc,instr,' ');
      UNTIL (argc = 0) OR (n = MaxDescrLines);

     { now lets dump this info }
      write(outfile,'"',Name,'" ');
      write(outfile,Size,' ');
      write(outfile,'"',UpDate,'" ');
      write(outfile,'"',User,'" ');
      write(outfile,Downloads,' ');
      write(outfile,'"',Forum,'" ');
      write(outfile,Lib,' ');
      writeln(outfile);
    END; { if '[' }

  END; { while not eof }
  close(infile);
  close(outfile);
END.
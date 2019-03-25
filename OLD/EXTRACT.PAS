{route certain lines from a file to a new file}
PROGRAM extract;
{ usage: EXTRACT InFileName OutFileName }

uses FileOps; {directOutput, Exist}


CONST
  tag = '#';

VAR
  outname,
  Name    : string;
  infile,
  outfile : TEXT;
  WriteDate, Skip : BOOLEAN;


PROCEDURE ProcessText;
CONST
  CutOff = 16;
VAR
  line, header, date : STRING;
  SkipCount,
  day, err : INTEGER;

BEGIN
  SkipCount := 0;
  WHILE NOT eof(infile) DO
  BEGIN
    readln(infile,line);
    IF pos(tag,line) = 1 THEN
    BEGIN
      { start of msg }
      readln(infile,date);
      val(copy(date,5,2),day,err);
      IF day < CutOff THEN
      BEGIN
        Skip := TRUE;
        inc(SkipCount);
      END
      ELSE
      BEGIN
        Skip := FALSE;
        WriteDate := TRUE;
      END;
    END;
    {write out each line}
    IF NOT Skip THEN
      writeln(outfile,line);
    IF WriteDate THEN
    BEGIN
      writeln(outfile,date);
      WriteDate := FALSE;
    END;
  END;
  Writeln(SkipCount,' Messages Skipped.');
END;


PROCEDURE DoFile;

BEGIN
  Skip := FALSE;
  WriteDate := FALSE;
  Name := paramstr(1);
  outname := paramstr(2);
  IF (Name = '') or not Exist(Name) THEN
  BEGIN
    writeln(Name,' not found. Quitting.');
    EXIT;
  END;
  assign(infile,Name);
  reset(infile);
  IF outname = '' THEN
    DirectOutput(outfile)
  ELSE
  BEGIN
     assign(outfile,outName);
     rewrite(outfile);
  END;
  ProcessText;
  close(infile);
  close(outfile);
END {Main};

BEGIN
  DoFile;
END.
uses Break;


CONST
  CR = #13;
  LF = #10;
  EF = #26;
  FilSize = 196747;

VAR
  prefile : file;
  infile,outfile : text;
  ch : CHAR;
  i,n,
  size : LONGINT;
  Finished : BOOLEAN;

BEGIN
   Assign(prefile,'f:\word\atech.msg');
   reset(prefile);
   size := filesize(prefile);
   close(prefile);
   writeln('size ',size:10);
   Assign(infile,'f:\word\atech.msg');
   reset(infile);
   Assign(outfile,'f:\word\atech2.msg');
   rewrite(outfile);
   Finished := FALSE;
   i :=0;
   REPEAT
      Read(infile,ch);
      IF ch = EF THEN
      BEGIN
          ch := #7; { ring the bell }
          writeln('EOF found at position ',i:10);
      END;
      IF ch = LF THEN write(outfile,CR);
      write(outfile,ch);
      INC(i);
      IF i mod 1024 = 0 then writeln('Chars Read ',i:10);
   UNTIL i = FilSize-1;
   write(outfile,EF);
   Close(infile);
   Close(outfile);
END.


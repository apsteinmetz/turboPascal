program readcis;

FUNCTION GetValidAreas(Forum : String) : String;

CONST
  Path = 'c:\tapcis\';
  ext  = '.SEC';
  LibFlag = 'Data Libraries Available';

VAR
  SecFile : text;
  InStr,
  NumStr,
  Areas   : String;
  Num, err : INTEGER;

BEGIN
   Areas := '';
   assign(SecFile, Path + Forum + '.SEC');
   reset(SecFile);
   WHILE NOT eof(SecFile) DO
   BEGIN
     readln(SecFile,InStr);
     IF pos(LibFlag,InStr) > 0 THEN
        WHILE NOT eof(SecFile) DO
        BEGIN
          readln(SecFile,InStr);
          IF NOT eof(SecFile) THEN
          BEGIN
            IF InStr[1] = ' ' THEN (* take care of leading blank *)
                NumStr := copy(InStr,2,1)
            ELSE
                NumStr := copy(InStr,1,2);
            val(NumStr,Num,err);
            IF err = 0 THEN
               Areas := Areas + NumStr + ' ';
          END;
        END;
   END;
   close(SecFile);
   GetValidAreas := Areas;

END {GetValidAreas};

BEGIN
  Writeln(GetValidAreas('AMIGAT'));
END.
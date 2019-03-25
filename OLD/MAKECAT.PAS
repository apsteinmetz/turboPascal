PROGRAM MAKECAT;
(* Automatically make catalog .DOW files for TAPCIS *)

uses
   FileUtil,     { exists }
   DOS,          { DateTime, UnpackTime, GetFTime }
   Calendar;     { Today, date }

CONST
  HighForum      = 20;
  DowFileExt     = '.DOW';
  CatFileExt     = '.CAT';
  DestDir        = 'C:\MSG\CIS';
  AreaSelectStr  = 'XA';
  ScanCommandStr = 'SCA/DES/AGE:';
  MaxDays        = 60;

TYPE
 ForumRec = RECORD
            Name, Areas : STRING;
            EraseOld    : BOOLEAN;
          END;

 Forums  = ARRAY[1..HighForum] OF ForumRec;

VAR
   Forum : Forums;

(*
((Name: 'AMIGAT'; Areas:'1 2 3 4 6 7 8 9 10 11 12 13 14 15 16';EraseOld:TRUE),
 (Name: 'AMIGAV'; Areas:'1 2 3 4 5 7 8 9 10 11 12 13 14';EraseOld:TRUE),
 (Name: 'AMIGAA'; Areas:'1 2 3 4 5 6 7 8 10 11 14 15';EraseOld:TRUE),
 (Name: 'BPROGA'; Areas:'1 2 3 4 5 6 9 16';EraseOld:FALSE));
 *)

(* ----------------------------------------------------- *)
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
   InStr := Path + Forum + '.SEC';
   IF NOT exists(InStr) THEN
      Areas := 'NoFile'
   ELSE
   BEGIN
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
   END;

END {GetValidAreas};

(* ----------------------------------------------------- *)
PROCEDURE CheckLastUpdate(Frm:ForumRec; VAR DaysStr : STRING);
VAR
  BakName,
  filename : STRING;
  oldfile,
  infile   : FILE;
  FileDate : LONGINT;
  DaysNum  : LONGINT;
  err      : INTEGER;
  DT       : DateTime; { from DOS unit }

  result   : boolean;

BEGIN
    val(paramstr(1),DaysNum,err);
    (* days to capture on command line overrides last updates *)
    if err > 0 THEN
    BEGIN
       filename := Frm.name + CatFileExt;
       DaysNum  := 0;
       IF Exists(filename) THEN
       BEGIN
          Assign(infile,filename);
          Reset(infile);
          GetFTime(infile,FileDate);
          Close(infile);
          UnpackTime(FileDate,DT);
          DaysNum := Today - Date(DT.Month,DT.Day,DT.Year);
          { Should we make a BAK file instead of appending }
          IF Frm.EraseOld THEN
          BEGIN
            Writeln('Erasing old ',filename);
            BakName := Frm.name + '.BAK';
            IF Exists(BakName) THEN
            BEGIN
                Assign(oldfile,BakName);
                Erase(oldfile);
            END;
            Rename(infile,BakName);
          END;
       END;
       IF (DaysNum < 1) OR (DaysNum > MaxDays) THEN
          DaysNum := MaxDays;
    END; {if err}
    str(DaysNum:1,DaysStr);
END;

(* ----------------------------------------------------- *)
PROCEDURE CheckHelp;
BEGIN
   IF (paramcount = 0) OR (paramstr(1) = '?') THEN
   BEGIN
     writeln('MAKECAT <days back to scan or "X"> <FORUM1> <FORUM2> ...');
     halt;
   END;
END;
(* ----------------------------------------------------- *)
PROCEDURE InitForums;
VAR
  i : WORD;

BEGIN
FOR i := 1 TO paramcount-1 DO
BEGIN
  Forum[i].Name := paramstr(i+1);
  Forum[i].Areas := GetValidAreas(Forum[i].Name);
  Forum[i].EraseOld := FALSE;
END;

(*
  Forum[1].Name := 'AMIGAT';
  Forum[1].Areas := GetValidAreas(Forum[1].Name);
  Forum[1].EraseOld := TRUE;

  Forum[2].Name := 'AMIGAV';
  Forum[2].Areas := GetValidAreas(Forum[2].Name);
  Forum[2].EraseOld := TRUE;

  Forum[3].Name := 'AMIGAA';
  Forum[3].Areas := GetValidAreas(Forum[3].Name);
  Forum[3].EraseOld := TRUE;

  Forum[4].Name := 'BPROGB';
  Forum[4].Areas := GetValidAreas(Forum[4].Name);
  Forum[4].EraseOld := FALSE;
*)
END {InitForums};
(* ----------------------------------------------------- *)
PROCEDURE MakeCatFiles;

VAR
  Days,
  FileName,
  FirstLine,
  SecondLine,
  OrigDir : STRING;
  i       : WORD;
  outfile : TEXT;

BEGIN
   GetDir(0,OrigDir);
   ChDir(DestDir);
   FOR i := 1 TO paramcount-1 DO
   BEGIN
      CheckLastUpdate(Forum[i],Days);
      IF NOT (Forum[i].Name = 'NoFile') THEN
      BEGIN
         filename   := Forum[i].Name + DowFileExt;
         firstline  := AreaSelectStr + Forum[i].Areas;
         secondline := ScanCommandStr + Days;
         IF exists(filename) THEN { append existing file }
         BEGIN
            Assign(outfile,filename);
            Append(outfile);
         END
         ELSE BEGIN
            Assign(outfile,filename);
            rewrite(outfile);
         END;

         writeln(outfile,firstline);
         writeln(outfile,secondline);
         close(outfile);
         Writeln('Will scan ',Forum[i].name,
                 ' for files going back',Days:3,' days');
      END;
   END;
   ChDir(OrigDir);
END; {MakeCatFiles}

(* ----------------------------------------------------- *)

BEGIN
  CheckHelp;
  InitForums;
  MakeCatFiles;
END. {MAKECAT}
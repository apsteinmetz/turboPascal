program PARSTRAD;
(* Parse afs:TRADE holdings report into lotus Readable file *)
{$M 20000, 0, 655360}
uses DOS, Calendar;

const
  extension = '.prn' (* output file extenstion *);

VAR
   Fields : ARRAY[0..50] OF INTEGER;

(* =================================================== *)
FUNCTION StripCommas(SuspectStr: STRING) : String;
VAR
  len, i     : INTEGER;
  CleanedStr : String;
  NewChr    :  String;

BEGIN
 len := length(SuspectStr);
 CleanedStr := '';
 i := 1;
 REPEAT
   NewChr := copy(SuspectStr,i,1);
   IF NewChr <> ',' THEN
     CleanedStr := CleanedStr + NewChr;
   INC(i)
 UNTIL i > len;
 StripCommas := CleanedStr;
END (* StripCommas *);

(* =================================================== *)
FUNCTION Trim(SuspectStr: STRING) : String;
VAR
  len, i,j     : INTEGER;
  NewChr    :  String;

BEGIN
 len := length(SuspectStr);
 i := 1;  j := len;
 REPEAT
   NewChr := copy(SuspectStr,i,1);
   IF NewChr = ' ' THEN
       INC(i)
 UNTIL (NewChr <> ' ') OR (i > len);
 REPEAT
   NewChr := copy(SuspectStr,j,1);
   IF NewChr = ' ' THEN
       DEC(j)
 UNTIL (NewChr <> ' ') OR (j = 0);
 Trim := copy(SuspectStr,i,j);
END (* StripCommas *);

(* =================================================== *)

PROCEDURE ParseFile;
CONST
  RecSize = 1;
VAR
  infile, outfile1     : TEXT;
  Name, Name1, TextLine  : String;

FUNCTION TestLine(line : STRING) : BOOLEAN;
(*
Test of text qualifies as the first line of a holdings
description.
*)

VAR
  amt     : LONGINT;
  ErrCode : INTEGER;
  temp : string;

BEGIN
  temp := StripCommas(copy(line,1,7));
  Val(StripCommas(Copy(line,1,7)),amt,ErrCode);
  TestLine := (ErrCode = 0);  (* TRUE if first 7 chars is a number *)
END (* TestLine *);

(* =================================================== *)
PROCEDURE Parse(VAR infile : text; VAR line : String);

TYPE
  TokenType = (NumTok, StrTok, DatTok);
VAR
  TokenIndex, i : INTEGER;
  line2 : String;
  TokenArray : ARRAY[0..50] OF STRING;

   (* =================================================== *)
   PROCEDURE Token(TokType : TokenType; Start,Stop : INTEGER);

   VAR
     Tok : STRING;
     a,b,temp : LONGINT;

   BEGIN
      Tok := copy(line,Start,Stop-Start+1);
      INC(TokenIndex);
      CASE TokType OF
        NumTok : Tok := StripCommas(Tok) + ',';
        StrTok : Tok := '"' + Trim(Tok) + '"' + ',';
        DatTok : BEGIN
                   a := ParseDateStr(Tok);
                   b := today;
                   IF ParseDateStr(Tok) < Today THEN
                     Tok := '"",'
                   ELSE BEGIN
                      temp := ParseDateStr(Tok);
                      temp := date(12,31,1899);
                      str(ParseDateStr(Tok) - date(12,30,1899),Tok);
                      Tok := Tok + ',';
                    END;
                END;
      END (* CASE *);
      TokenArray[TokenIndex] := Tok;
   END (* MakeToken *);
   (* =================================================== *)


BEGIN
  TokenIndex := 0;
  (* start building Token Array *);
  Token(NumTok,1,7);   { par }
  Token(StrTok,10,38); { description }
  Token(NumTok,40,46); { coupon   }
  Token(DatTok,49,56); { mat date }
  Token(StrTok,59,62); { moody    }
  Token(StrTok,64,67); { s&p      }
  Token(DatTok,70,77); { next call}
  Token(DatTok,80,87); { par call}
  Token(DatTok,90,97); { put feat}
  Token(NumTok,102,108); { avg cost}
  Token(NumTok,110,116); { cost yield}
  Token(NumTok,119,124); { curr yield}
  Token(NumTok,127,132); { %TTL }

  (* get next line *)
  Readln(infile,line);

  Token(StrTok,12,20); { cusip }
  Token(DatTok,23,30); { dtd date }
  Token(StrTok,31,36); { state   }
  Token(StrTok,37,38); { sector1  }
  Token(StrTok,40,41); { sector2  }
  Token(NumTok,71,77); { next call px}
  Token(NumTok,81,87); { par call px}
  Token(NumTok,91,97); { put feat px}
  Token(NumTok,102,108); { mkt px  }
  Token(NumTok,110,116); { mkt  yield}
  Token(NumTok,119,124); { duration  }
  Token(StrTok,125,132); { yld basis }

  (* build string with desired fields *)
  line2 := '';
  i := 0;
  IF Fields[0] = 0 THEN  (* use all fields *)
    FOR i := 0 TO TokenIndex DO
       line2 := line2 + TokenArray[i]
  ELSE
     WHILE Fields[i] > 0 DO
     BEGIN
       line2 := line2 + TokenArray[Fields[i]];
       INC(i)
     END;

  (* terminate by stripping final comma *)
  delete(line2,length(line2),1);

  line := line2;
END (* Parse *);

(* =================================================== *)
PROCEDURE ParseName(VAR FromName, To1 : String);
VAR
  err, i,
  ErrCount  : INTEGER;
  path : PathStr;
  dir  : DirStr;
  name : NameStr;
  ext  : ExtStr;

BEGIN
  IF (ParamCount < 1) or (ParamStr(1) = '?') THEN
  BEGIN
    WriteLn('usage: PARSTRAD FileName [FieldNum [FieldNum...]]');
    WriteLn('Where FileName is a text file containing an afs:TRADE');
    WriteLn('portfolio holdings report and FieldNums are optional');
    WriteLn('ordinal positions of report fields you wish to include.');
    WriteLn('If no field nubmers are indicated all will be included.');
    HALT;
  END;
  path := ParamStr(1);
  FSplit(path,dir,name,ext);
  FromName := path;
  To1 := name + extension;

  (* Get Field Numbers To include *)
  ErrCount := 0;
  i := 0;
  Fields[i] := 0;
  IF ParamCount > 1 THEN
  BEGIN
     FOR i := 2 TO ParamCount DO
     BEGIN
       val(ParamStr(i),Fields[i-2-errcount],err);
       IF err > 0 THEN
         INC(ErrCount)
     END;
     (* 0 indicates end of field list *)
     Fields[i-1-errcount] := 0;
  END;

END (* ParseName *);


(* =================================================== *)
BEGIN
  ParseName(Name, Name1);
  Assign(infile, Name);
  Reset(infile);
  Assign(outfile1, Name1);
  Rewrite(outfile1);
  WriteLn('Parsing file ' ,Name);
  REPEAT
      ReadLn(infile,TextLine);
      IF TestLine(TextLine) THEN
      BEGIN
           Parse(infile, TextLine);
           WriteLn(outfile1,TextLine);
      END;
  UNTIL EOF(infile);
  Close(infile);
  Close(outfile1);
  WriteLn('Wrote ',Name1);

END (* ParseFile *);

(* =================================================== *)
BEGIN
  ParseFile;
END (*ParsTRAD*).
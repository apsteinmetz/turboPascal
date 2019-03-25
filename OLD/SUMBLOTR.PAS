PROGRAM sumblotr;

{no DEFINE BLOTTER} {or HISTORY}

USES StrUtil;

CONST
{$IFDEF BLOTTER}
  parstart = 46;
  pxstart  = 88;
{$ELSE}
  parstart = 41;
  pxstart  = 84;
{$ENDIF}

  parlen   = 10;
  pxlen    =  7;
  yearstart = 18;
  yearlen   = 2;
  tickstart = 6;
  ticklen   = 4;


VAR
  blotter : TEXT;

PROCEDURE GetFile(VAR f : TEXT);
begin
  IF paramcount > 0 THEN
  BEGIN
     assign(f,paramstr(1));
     reset(f);
  END
  ELSE
    HALT;
END;

function GetMV(instr : string) : REAL;
VAR
  err     : integer;
  par, px : real;
  parstr  : STRING;

BEGIN
  parstr := (copy(instr,parstart,parlen));
  parstr := Compress(Compress(parstr,','),' ');
  val(parstr,par,err);
  IF err > 0 THEN
  BEGIN
    writeln('Par conversion error');
    px := 0;
  END
  ELSE
  BEGIN
    val(copy(instr,pxstart,pxlen),px,err);
    IF err > 0 THEN
       writeln('Price conversion error');
  END;
  GetMV := par * px / 100;
END;

PROCEDURE ParseFile(VAR f: text);
VAR
  err     : integer;
  tradeYear,
  tickno  : WORD;
  mvaccum : ARRAY[89..90] OF REAL;
  instr   : string;

BEGIN
  mvaccum[89] := 0.0;
  mvaccum[90] := 0.0;
  WHILE NOT eof(f) DO
  BEGIN
    readln(f,instr);
    val(copy(instr,yearstart,yearlen),tradeYear,err);
    val(copy(instr,tickstart,ticklen),tickno,err);
    IF (err=0) THEN
    BEGIN
{      write(tickno); }
      mvaccum[tradeyear] := mvaccum[tradeyear] + getmv(instr)
    END;
  END;
  WRITELN('Market Value of 1989 trades for ',paramstr(1),mvaccum[89]:10:0);
  WRITELN('Market Value of 1990 trades for ',paramstr(1),mvaccum[90]:10:0);
END;

BEGIN
  GetFile(blotter);
  ParseFile(blotter);
END.

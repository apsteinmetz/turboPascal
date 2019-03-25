PROGRAM Frontier;

USES
  CRT {ClrScr},
  FileOps,
  Lists;

CONST
  fname = 'fx.prn';
  delims = ' ,';      {space, comma}
  AssetCount = 4; {At most one less than Max Assets to allow for portfolio }
  Annualize = 7.21102551; { sqrt(52) - weekly data}
  Precision = 10; { possible allocation shifts }

  USYld = 9.00;



VAR
  iter : integer;
  heap        : POINTER;
  YldSeries,
  WgtSeries,
  TimeSeries  : List;
  avg,
  vol,
  wgt,
  std      : Item;
  OptVol   : REAL;
  out      : TEXT;


(* ---------------------------------------------------- *)
PROCEDURE WriteHeader;
BEGIN
  GotoXY(1,3);
  writeln('             Asset Weights');
  writeln('Term        1         2         3        4      slope    yield  vol.');
  writeln('-----------------------------------------------------------------------');
END;

(* ---------------------------------------------------- *)
PROCEDURE SetUpAccumulators;

VAR
  n  : INTEGER;

BEGIN
  iter := 0;
  FOR n := 1 TO MaxItems DO
  BEGIN
     Avg[n] := 0;
     Std[n] := 0;
     Wgt[n] := 0;
     Vol[n] := 0;
  END;
END;

(* ---------------------------------------------------- *)
PROCEDURE PeriodReturn(VAR list : Item; Before, Now : Item);
VAR
  n  : INTEGER;

BEGIN
  FOR n := 1 TO AssetCount DO
     list[n] := ln(Now[n]/Before[n]);
END;

(* ---------------------------------------------------- *)
FUNCTION SumWgts(wgts : Item) : REAL;
VAR
  n     : INTEGER;
  total : REAL;

BEGIN
  total := 0;
  FOR n := 1 TO AssetCount DO
    total := total + wgts[n];
  SumWgts := total;
END {SumWgts};

(* ---------------------------------------------------- *)
PROCEDURE ShowNums(nums : Item);
VAR
  n     : INTEGER;
  total : REAL;

BEGIN

  FOR n := 1 TO AssetCount + 1 DO
    Write(out,nums[n]:10:5);

END {ShowNums};
(* ---------------------------------------------------- *)
PROCEDURE AvgOneSeries(VAR a : Item;
                       VAR Series : List;
                       Asset : INTEGER);

VAR
  count : INTEGER;
  Data : Item;

BEGIN
  a[Asset] := 0;
  count := 0;
  WHILE Series.GetNext(Data) DO
  BEGIN
    a[Asset] := a[Asset] + Data[Asset];
    inc(count);
  END;
  a[Asset] := a[Asset] / count;
END;

(* ---------------------------------------------------- *)
PROCEDURE StdOneSeries(VAR s, a : Item;
                       VAR Series : List;
                     Asset : INTEGER);


VAR
  count : INTEGER;
  Data : Item;

BEGIN
  s[Asset] := 0;
  count := 0;
  WHILE Series.GetNext(Data) DO
  BEGIN
    s[Asset] := s[Asset] + sqr(Data[Asset] - a[Asset]);
    inc(count);
  END;
  s[Asset] := sqrt(s[Asset] / (count{-1}) );
END;

(* ---------------------------------------------------- *)
PROCEDURE VolOneSeries(VAR v, s : Item; Asset : INTEGER);

BEGIN
    v[Asset] := s[Asset] * annualize;
END;
(* ---------------------------------------------------- *)
PROCEDURE PortVol(VAR Series : List; wgt : Item);

VAR
  Data  : Item;
  i, Port : INTEGER;
  count   : INTEGER;

BEGIN
  Port := AssetCount + 1;
  WHILE Series.GetNext(Data) DO
  BEGIN
    Data[Port] := 0;
    FOR i := 1 TO AssetCount DO
       { compute portfolio return }
       Data[Port] := Data[Port] + wgt[i] * Data[i];
    Series.ChangeCurrItem(Data);
  END;
  AvgOneSeries(avg,Series,Port);
  StdOneSeries(std,avg,Series,Port);
  VolOneSeries(vol,std, Port);

END;

(* =============================================== *)
FUNCTION PortYld(VAR Yield, wgt : Item) : REAL;

VAR
  i, Port : INTEGER;

BEGIN
  Port := AssetCount + 1;
  Yield[Port] := 0;
  FOR i := 1 TO AssetCount DO
  BEGIN
      { compute portfolio yield }
      Yield[Port] := Yield[Port] + wgt[i] * Yield[i];
  END;
  PortYld := Yield[Port];
END;

(* =============================================== *)
PROCEDURE TestFrontier(wgt : Item);
{ note: weight[AssetCount + 1] carries slope info }
CONST
  PrintLine = 5;

VAR
  count : INTEGER;
  slope : REAL;
  weight,
  yield : Item;

{$B+} { Force complete BOOLEAN evaluation }
BEGIN
count := 0;
WHILE YldSeries.GetNext(yield) AND
          WgtSeries.GetNext(weight) DO
  BEGIN
  inc(count);
    slope := (PortYld(yield,wgt) - USYld) / Vol[AssetCount+ 1];
    IF slope > weight[AssetCount+ 1] THEN
    BEGIN
       wgt[AssetCount + 1] := slope;
       WgtSeries.ChangeCurrItem(wgt);
       OptVol := Vol[AssetCount+ 1];
       { display progress }
       IF count > 0  THEN { one year term}
       BEGIN
         GotoXY(1,PrintLine+Count);
         write(out, 'Term ',count);
         ShowNums(wgt);
         write(out,Portyld(yield,wgt):8:3);
         writeln(out,OptVol*100:5:2);
       END;
    END;
  END;
END;
{$B-} { turn off complete BOOLEAN evaluation }
(* ---------------------------------------------------- *)
PROCEDURE Permute( VAR Series : LIST;
                   VAR wgt : Item;
                   Asset : INTEGER);
VAR
  i      : INTEGER;
BEGIN

  FOR i := 0 to Precision DO
  BEGIN
     wgt[Asset] := i / Precision;
     IF Asset = AssetCount THEN BEGIN
       IF abs(SumWgts(wgt) - 1) < 0.00001 THEN BEGIN
         iter := iter + 1;
         IF (iter MOD 25 = 0) THEN BEGIN
           GotoXY(1,2); Write(iter,' Permutations');
         END;
         PortVol(Series,wgt);
{        ShowNums(wgt); writeln(out,Vol[AssetCount+ 1]*100:7:3); }
         { keep track of lowest vol }
         TestFrontier(wgt);
       END;
     END
     ELSE
       Permute(Series,wgt,Asset+1)
  END;
END {Permute};
(* ---------------------------------------------------- *)
PROCEDURE AvgSeries(VAR a : Item; VAR Series : List);

VAR
  i, count : INTEGER;
  Data : Item;

BEGIN
    FOR i := 1 TO AssetCount DO
      a[i] := 0;
  count := 0;
  WHILE Series.GetNext(Data) DO
  BEGIN
    FOR i := 1 TO AssetCount DO
      a[i] := a[i] + Data[i];
    inc(count);
  END;
  FOR i := 1 TO AssetCount DO
    a[i] := a[i] / count;
END;

(* --------------------------------------------------- *)
PROCEDURE StdSeries(VAR s, a : Item; VAR Series : List);

VAR
  i, count : INTEGER;
  Data     : Item;

BEGIN
  count := 0;
    FOR i := 1 TO AssetCount DO
      s[i] := 0;
  WHILE Series.GetNext(Data) DO
  BEGIN
    FOR i := 1 TO AssetCount DO
      s[i] := s[i] + sqr(Data[i] - a[i]);
    inc(count);
  END;
  FOR i := 1 TO AssetCount DO
    std[i] := sqrt(s[i] / (count{-1}) );
END;

(* ---------------------------------------------------- *)
PROCEDURE VolSeries(VAR v, s : Item);

VAR
  i  : INTEGER;

BEGIN
    FOR i := 1 TO AssetCount DO
      v[i] := s[i] * annualize;
END;
(* ---------------------------------------------------- *)

PROCEDURE ShowSeries(Series : List);
VAR
  i  : INTEGER;
  Data : Item;

BEGIN
  WHILE Series.GetNext(Data) DO
  BEGIN
    FOR i := 1 TO AssetCount DO
       write(out,Data[i]:10:6);
    writeln(out);
  END;
END;
(* ---------------------------------------------------- *)
FUNCTION ParseNums( VAR list : Item;
                     line : STRING; NumsToGet : INTEGER) : INTEGER;
(* returns number of numbers parsed *)

VAR
  i, start, stop,
  Got, err       : INTEGER;
  numstr         : STRING;
  num            : Real;

BEGIN
  i := 1;
  Got := 0;
  REPEAT
    WHILE (pos(line[i],delims) > 0) AND (i < length(line)) DO
        inc(i);
    IF i < length(line) THEN
    BEGIN
       Start := i;
       WHILE (pos(line[i],delims) = 0) AND (i < length(line)+1) DO
         inc(i);
       Stop := i;
       val(copy(line,start,stop-start),num,err);
       IF err = 0 THEN
       BEGIN
         inc(Got);
         list[Got] := num;
       END;
    END;
  UNTIL (i > length(line)) OR (Got = NumsToGet);
  ParseNums := Got;
END;

(* ---------------------------------------------------- *)
PROCEDURE GetData;

VAR
  infile  : text;
  line    : string;
  Data    : Item;
  OldList,
  list    : Item;
  First   : BOOLEAN;

  (* ---------------------------------------------------- *)
  FUNCTION OpenFile : BOOLEAN;
  BEGIN
   IF Exist(fname) THEN
   BEGIN
      assign(infile,fname);
      reset(infile);
      OpenFile := TRUE;
    END
    ELSE
      OpenFile := FALSE;
  END {OpenFile};
  (* ---------------------------------------------------- *)
  PROCEDURE GetYields;
  {expects a series of national yields, US last }
  VAR
    ylds : Item;

  BEGIN
    REPEAT
      readln(infile,line);
      IF (line[1] = ';') AND (pos('yield',line)>0) THEN
      BEGIN
        GotoXY(1,2); writeln(line);
        readln(infile,line);
        IF ParseNums(ylds, line, AssetCount+1) = AssetCount + 1 THEN
        BEGIN
           YldSeries.AddItem(ylds);
           WgtSeries.AddItem(ylds); {dummy data}
        END;
      END;
    UNTIL (pos('fx',line) > 0) OR eof(infile);
  END;
  (* ---------------------------------------------------- *)

BEGIN
  First := TRUE;
  TimeSeries.Init;
  YldSeries.Init;
  WgtSeries.Init;
  IF OpenFile THEN
  BEGIN
    GetYields;
    WHILE NOT eof(infile) DO
    BEGIN
      readln(infile,line);
      IF (line[1] = ';') THEN { it's a comment }
        writeln(line)
      ELSE
      BEGIN
         IF ParseNums(list, line, AssetCount) = AssetCount THEN
           IF First THEN BEGIN
             First := FALSE;
             OldList := list;
           END
           ELSE BEGIN
             PeriodReturn(Data,OldList,List);
             TimeSeries.AddItem(Data);
             OldList := List;
           END;
      END;
    END;
  END;
END {GetData};
(* ------------------------------------------------------------- *)
BEGIN
    DirectOutput(out); ClrScr;
    WriteHeader;
    SetupAccumulators;
    GotoXY(1,1); Writeln('Getting data');
    GetData;

{    ShowSeries(TimeSeries); }
 (*
    AvgSeries(avg,TimeSeries);
    StdSeries(std,avg,TimeSeries);
    VolSeries(vol, std);
    ShowNums(vol); writeln(out);
    ShowNums(avg); writeln(out);
*)
    GotoXY(1,1);Writeln('Testing Combos');
    Permute(TimeSeries,wgt,1);
    GotoXY(1,2); writeln(iter,' Permutations');
    GotoXY(1,1); ClrEOL; writeln('Done');

    TimeSeries.Done;
    YldSeries.Done;
    WgtSeries.Done;
    close(out);
END.

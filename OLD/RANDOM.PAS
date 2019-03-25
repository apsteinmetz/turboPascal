{$R-}    {Range checking off}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}
{$N+,E+}
program MultiRandom;


Uses
  Crt,
  Dos,
  Graph,
  GrafText,  { WriteString, WriteLine, WriteInt, WriteReal }
  MaxRes,    { InitEGAMax }
  Break,
  mathlib0,
  StatLib0;

const
(********************** constants for LOTTO ************************)
  GraphOn = TRUE;             { GraphOn = FALSE }
  Trials  = 1000   ;             { TRIALS = 6 }
  WithReplacement = TRUE;     { WithReplacement = FALSE }
(****   Otherwise the above can be whatever  ***********************)

  Generators = 1;                 { e.g. number of dice }
  OneLowNum  = 1;  LowNum  = 1;   {OneLowNum * Generators}
  OneHighNum = 100; HighNum = 100;  {OneHighNum * Generators}
  XHigh = 570; XLow = 40;       { Pixels. May not exceed screen resolution }
  YLow = 340; YHigh = 200;      { Pixels. May not exceed screen resolution }
  DefaultYScale = 3;
  SummaryStats = TRUE;
  WatchProgress = TRUE;       { TRUE and GraphOn  will be slow }
  NewAlgorithm = FALSE;
  Prime1 = 17417;
  Prime2 = 17417;

type
   FreqTable = array[LowNum..HighNum] of integer;
   GraphPart = (BORDER, BODY, BOTH);
var
    y, x,
    n,
    OneResult,
    Result,
    safety,
    a1,a2 : integer;
    f, r : real;
    scaleY,
    scaleX : real;
    freq,tempfreq : FreqTable;
    oldran,
    PrimeFact : longint;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function Seed: longint;

var
  recpack:                registers;           {record for MsDos call}
  min,sec,
  dx,cx,hr:               longint;

begin
  with recpack do
  begin
    ax := $2c shl 8;
  end;
  MsDos(recpack);                        { call function }
  with recpack do
  begin
       min := cx mod 256;
       hr  := cx shr 8;
       sec := dx shr 8;
  end;
  seed := (hr + min) * sec;
end; {SEED}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function ChiSquare(values: FreqTable) : real;
var
  i       : integer;
  ExpFreq : real;

begin
   ExpFreq := Trials/(HighNum - LowNum + 1);
   for i := LowNum to HighNum do
     ChiSquare := Sqr(values[i]-ExpFreq)/ExpFreq;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Sort(VAR values : FreqTable);
{insertion sort}
type
  itemrec = record
               value,
               frequency : integer;
            end;
  items = array[LowNum..HighNum] of itemrec;

var
  i,j  : integer;
  x    : itemrec;
  item : items;

begin
   for i := LowNum to HighNum do
      begin
         item[i].value := i;
         item[i].frequency := values[i];
      end;
   for i := LowNum+1 to HighNum do
   begin
      x:= item[i];
      j:= i-1;
      while (x.frequency<item[j].frequency) and (j>LowNum-1) do
      begin
         item[j+1] := item[j];
         j := j-1;
      end;
      item[j+1]:= x;
   end;
   for i := LowNum to HighNum do
     values[i] := item[i].frequency;
end; {Sort}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE PrintFreqTable;
CONST
  ItemsPerLine = 8;
VAR
  i : INTEGER;

begin
   WriteString('Value: Occurences in ');
   WriteInt(trials,1);
   WriteString(' trials. Sorted by Freq.');
   WriteLine;
   for i := LowNum to HighNum do
      begin
        WriteInt(i,3);
        WriteString(':');
        WriteInt(freq[i],1);
        if i mod ItemsPerLine = 0 then WriteLine;
      end;
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Ran1: real;
var
  t: real;

begin
   t    := (a1 * 32749 +3) mod 32749;
   a1   := trunc(t);
   Ran1 := abs(t/32749);
end; {ran1}

function Ran2: real;
var
  t: real;

begin
   t    := (a2 * 10001+3) mod 17417;
   a2   := trunc(t);
   Ran2 := abs(t/17417);
end; {ran2}

function CombRandom:real;
var
   f : real;

begin
   f:= Ran2;
   if f>0.5 then CombRandom := Random
   else CombRandom := Ran1;
end; {CombRandom}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function PrimeRandom(VAR Base : LONGINT) : real;

begin
  Base := sqr(Base) mod primefact;
  PrimeRandom := abs(Base/primefact);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

procedure display(GP : GraphPart; Low, High : INTEGER);
var
  XCoOrd, t,
  vert, horiz : integer;

begin
   SetColor(Blue);
   for t:= Low to High do
   begin
     XCoOrd := Xlow + trunc(scaleX * (t-1));
     horiz := XCoOrd+trunc(scaleX);
     vert  := YLow - trunc(freq[t] * scaleY);
     CASE GP OF
       BODY   : Bar(XCoOrd,YLow,horiz,vert);
       BORDER : Rectangle(XCoOrd,YLow,horiz,vert);
       BOTH   : BEGIN
                  Bar(XCoOrd,YLow,horiz,vert);
                  Rectangle(XCoOrd,YLow,horiz,vert);
                END;
     END;
   end;
end; {Display}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function finished : boolean;
var
  ch  : char;

begin
   WriteString('Do another? ');
   ch := ReadKey;
   if upcase(ch) <> 'Y' then finished := TRUE
    else finished := FALSE;
end; {finished}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Ranger(ZeroToOne : Real; Upper,Lower : LongInt) : LongInt;
begin
  Ranger :=
       trunc((ZeroToOne * (Upper-Lower + 1)) + Lower);
end; {ranger}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function ScreenScale(HiPxl, LowPxl, HiVal, LowVal : Integer) : Real;
begin
  ScreenScale := (HiPxl - LowPxl)/(HiVal - LowVal + 1);
end; {ScreenScale}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE MakeFrequencyTable2;
{ range of values will be -5 to 5 scaled to be within 0 to 100}
VAR
   Deviation : FLOAT;

BEGIN
     Deviation := GetNormalValue;
     Deviation := (Deviation + 5) * 10;
     IF Deviation > 100 THEN
        Deviation := 100
     ELSE
         IF Deviation < 1 THEN
            Deviation := 1;
     Result := trunc(Deviation + 0.5);
     INC(freq[Result])
END {MakeFrequencyTable2};

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE MakeFrequencyTable;
BEGIN
      safety := safety + 1; {make sure trials w/o replace !> HighNum }
      {here's the beef}
      Result := 0;
      FOR x := 1 TO Generators DO
      BEGIN
        IF NewAlgorithm = TRUE THEN
          OneResult := Ranger(PrimeRandom(OldRan),OneHighNum,OneLowNum)
        ELSE
          OneResult := Ranger(CombRandom,OneHighNum,OneLowNum);
        Result := Result + OneResult;
      END;

      freq[Result] := freq[Result]+1;

END {MakeFrequencyTable};
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
begin {main}

f := 0;
a1 := seed; a2 := seed * 3;
PrimeFact := Prime1 * Prime2;
If GraphOn THEN
  if not InitNormGraph then HALT; (* HiRes EGA *)
repeat
  ClearViewPort;
  OldRan := seed +PrimeFact;
  if GraphOn then
  begin
  SetBaseLine(3);
  SetBkColor(White);
  SetColor(DarkGray);
  scaleX := ScreenScale(XHigh,XLow,HighNum,LowNum);
  IF WatchProgress THEN
  BEGIN
    ScaleY := DefaultYScale;
    SetFillStyle(SlashFill,Blue);
  END;
  Rectangle(XLow,YHigh,XHigh,YLow);
  GotoXY(6,24);

  for n:= LowNum to HighNum do if n mod 5 = 0 then write(n:7);
end;

   n := 0; safety := 0;
   for x := LowNum to HighNum do freq[x] := 0;
   if not GraphOn then gotoXY(1,3);
   repeat
      MakeFrequencyTable2;
      if WithReplacement then {don't care if result has been pulled before}
         begin
            if WatchProgress then
              if GraphOn then Display(BOTH,Result,Result)
                else write(Result:3);
            f := f + Result;
            n := n + 1;
         end
      else if freq[Result] = 1 then  {Result has not been pulled before}
         begin
            if not GraphOn then write(Result:3);
            n := n + 1;
         end;
   until (n = Trials) or (not WithReplacement and (safety > HighNum));
   if SummaryStats then
   begin
      f := f/trials;
{     tempfreq := freq; }
{     sort(freq);       }
      PrintFreqTable;
{     freq := tempfreq; }
      WriteLine;
      WriteString('Avg:');
      WriteReal(f,10,5);
      WriteString('  ChiSquare:');
      WriteReal(ChiSquare(freq),10,5);
      WriteLine;
   end;
   if GraphOn then
   begin
      If NOT WatchProgress THEN
      BEGIN
         tempfreq := freq;
         sort(tempfreq);
         ScaleY := ScreenScale(YLow,YHigh,tempfreq[HighNum],0);
         SetFillStyle(SlashFill,Blue);
         Display(BOTH,LowNum,HighNum);
      END
   end;
until finished;
if GraphOn then CloseGraph;
end.

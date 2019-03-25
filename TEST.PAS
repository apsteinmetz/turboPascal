program TEST;
{$N+,E+}
uses MathLib0;

CONST
   NumBands = 100;  {this determines how close an estimator this table is}
   tolerance = 0.000005;

VAR
   NormTable : ARRAY[0..NumBands] OF myFloat;
   { NormTable is an array containing fractions of positive Std. Deviations }
   { from a mean which are evenly spaced in terms of probability in a       }
   { normal distribution                                                    }

procedure IterateNormal;

VAR
   n : Cardinal;


BEGIN
     for n := 0 to 30 do
         writeln(n/10:3:1,Normal(n/10):10:5);
END;

{------------------------------------------------------------}
procedure CreateNormalTable;
{
To pull out a Std. Dev. from a normal distribution:
  1. Create this table.
  2. Select a random integer, n | 0 < n <= NumBands.
  3. Select a random real, d |  NormTable[n-1] <= d <= NormTable[n].
  4. Select a random integer, s | s=-1, s= 1.
  5. s*d is a deviation from the mean which is randomly distributed.
}

VAR
   n : Cardinal;
   LowDev,
   HiDev,
   LowProb,
   HiProb  : myFLOAT;
   ProbIncr: myFLOAT;  {find std devs. every ProbIncr pct. probability}

BEGIN
     LowDev  := 0.0; { 0.0 deviation from mean of distribution }
     HiDev := 0.01; {starting guess}
     LowProb := Normal(LowDev);
     ProbIncr := 0.5 / NumBands; { we're using 50% of the distribution}
     NormTable[0] := LowDev;
     for n := 1 to NumBands do
     BEGIN
         HiProb := LowProb + ProbIncr;
         SeekGoal(HiProb,tolerance,HiDev,Normal);
         NormTable[n]  := HiDev;
         LowProb := HiProb;
     END;
END;

{------------------------------------------------------------}
BEGIN {MAIN}
      Writeln;
      CreateNormalTable;
END.

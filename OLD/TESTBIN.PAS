PROGRAM TestBin;

{$I FLOAT.INC}

 {$DEFINE DEBUG}

uses MathLib0;

CONST
   OutToDisk = FALSE;
   initial_default = 0.1;
   v_default = 0.2;

VAR
   out       : text;
   steps     : WORD;
   initial,    { starting value }
   v,          { volatility in percent per period }
   Result      : Float;



{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE GetParams;
VAR
   err : INTEGER;

BEGIN
   val(paramstr(1),v,err);
   IF err > 0 THEN v := v_default;
   val(paramstr(2),initial,err);
   IF err > 0 THEN initial := initial_default;
END;



{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
FUNCTION ExpectedValue ( Steps  : WORD;  { periods }
                         intial,  { one period rate }
                         Vol     : Float ) : Float;

CONST
  MaxSteps   = 100;
  MaxStepsx2 = 201;

VAR
  BondPrices  : ARRAY[1..MaxSteps]   OF FLOAT;
  EndRate  : ARRAY[1..MaxStepsx2] OF FLOAT;

  p, pComp  : FLOAT;   { prob. of an up move and it's complement }
  UP, DN,
  DiscRate,
  move  : FLOAT;
  StepsPlus1,
  j, k, i : WORD;

BEGIN
  If Steps > MaxSteps THEN Steps := MaxSteps;
  StepsPlus1 := Steps + 1;
  { adjust inputs for time and precompute some constants   }
  UP := 1 + Vol;
  DN := 1/UP;
  IF Vol = 0.0 THEN
      p := 0.5
  ELSE
      p     := (1-dn)/(Up-Dn);  { will be close to 0.5 }
  pComp := 1 - p;

  { make arrays of ending values and intrinsic values }
  EndRate[StepsPlus1] := 1+Initial;
  move := 1;
  FOR i := 1 to Steps DO BEGIN
      move := move * up;       { equiv to (1+up) raised to the i }
      j := StepsPlus1 + i;
      k := StepsPlus1 - i;
      EndRate[j] := 1 + (Initial * move);
      EndRate[k] := 1 + (Initial / move);
  END; {FOR}

  { assign ending rates as terminal bond prices }
  FOR i := 1 to StepsPlus1 DO BEGIN
     BondPrices[i] := 1 / EndRate[2*i-1];
  END;


  { Works backward down the binomial tree }
  FOR i := Steps DOWNTO 1 DO BEGIN
     FOR j := 1 to i DO BEGIN
         k := Steps - i + 2*j;
         DiscRate := EndRate[k];
         { expected values discounted one period }
         BondPrices[j] := ( p* BondPrices[j+1] +
                              pComp * BondPrices[j] ) / DiscRate;

     END;
  END;
  ExpectedValue := BondPrices[1];
END; { Expected Value }
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

BEGIN
   GetParams;
   IF OutToDisk THEN BEGIN
     Assign(out,'f:\art\test2.prn');
     Rewrite(out);
   END;

   FOR steps := 1 TO 5 DO BEGIN
      Result := ExpectedValue(steps,initial,v);

      IF OutToDisk THEN
         Writeln(out,'Steps ',steps:2,' Result ',Result:8:3)
      ELSE
         Writeln('Steps ',steps:2,' Result ',power(1/Result,1/(Steps+1))-1:8:3);

   END;
   IF OutToDisk THEN Close(out);
END.
PROGRAM Stochast;
{$N+,E+}
{ Stochastic valuation of debt securites }
uses MathLib0, StatLib0;

const
  Periods = 360;  { max periods of any security }

TYPE
  RatePath = ARRAY[0..Periods] OF FLOAT;
VAR
  MonthlyRates : RatePath;

PROCEDURE GenPath;
{ generate a rate path without mean reversion }
VAR
  rate, volatility : FLOAT;
  n                : Cardinal;
BEGIN
   Rate := 6.0;
   Volatility := 0.035; {monthly, 12.1% annl}
   MonthlyRates[0] := Rate;
   for n := 1 to Periods do
   BEGIN
       Rate := Rate + GetNormalValue * Volatility;
       MonthlyRates[n] := Rate;
   END;
END;

BEGIN
  GenPath;
END.

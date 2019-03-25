program AVAIL;
{ show remaining system memory }

CONST
  I_USE = 20560;

BEGIN
   Writeln(MemAvail + I_USE:10,' Total Bytes Available');
END.
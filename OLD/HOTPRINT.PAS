{$R-}    {Range checking off}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

Uses
  Dos,
  DUMPPRN;

begin
  DumpToPrinter;
end.

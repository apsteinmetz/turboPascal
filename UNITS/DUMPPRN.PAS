{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}

Unit DumpPrn;

Interface

Uses
  Dos;


PROCEDURE DumpToPrinter;
{ DUMPS WORKSTATION PRINT QUEUE  TO PRINTER }

{===========================================================================}

Implementation

PROCEDURE DumpToPrinter;
{ DUMPS WORKSTATION PRINT QUEUE  TO PRINTER }

 var
   reg : registers;

begin
    reg.ah:=$DF;
    reg.dl:=1;
    intr ($21,reg);
end; {DumpToPrinter}


End.

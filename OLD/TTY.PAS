{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}


uses CRT, DOS;
var
  ch : char;
  regs : registers;
  AUX  : Text;

function ComAvail : BOOLEAN;
var
  regs: Registers;

begin
  regs.ah := $03;
  regs.dx := 0;
  intr($14,Registers(regs));
  ComAvail := ((regs.ah AND 1) = 1)
end {ComAvail};

{main}
begin
  Assign(AUX,'COM1');
  rewrite(aux);
  Regs.ax := $5A;
  regs.dx := 0;
  Intr($14,Dos.Registers(regs));
  REPEAT
    IF ComAvail THEN
    BEGIN
      Read(AUX,ch);
      IF ch <> #0 THEN Write(ch);
      ch := #0;
    END
    ELSE IF KeyPressed THEN
    BEGIN
      ch := ReadKey;
      Write(AUX,ch);
      IF ch = ^M THEN writeln;
    END;
  UNTIL ch = #27;
  close(AUX);
END.


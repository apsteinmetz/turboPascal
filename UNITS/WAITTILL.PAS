{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program WAITTILL;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++
Suspends operation of a batch file
until time specified in command line
ex: WAITTILL 17.30
waits until 5:30 pm to do anything else
not allowed: time < 0
             time > 24
WAITTILL 17.80 <=> WAITTILL 18.00
+++++++++++++++++++++++++++++++++++++++++++++++++++++}


Uses
  Dos, CRT;

var
  StartDay  : WORD;
  Start     : real;
  err       : integer;

procedure nothing;
   begin
     CheckBreak := TRUE;
     GotoXY(1,2); Write('.');
   end;

function Time: real;

var
  H,M,S,S100 :  WORD;

begin
  GetTime(H,M,S,S100);
  time := H + M/100;
end; {TIME}

function Today : WORD;

var
  Y,M,D,DOW :  WORD;

begin
  GetDate(Y,M,D,DOW);
  Today := D;
end; {Day}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
BEGIN
  ClrScr;
  val(paramstr(1),Start,err);
  if (err = 0) and (start > 0) and (start < 24.00) then
    begin
      StartDay := Today;
      { wait until 2morrow if start has already passed today }
      if time > start then
      begin
        writeln('Waiting until Tomorrow at',paramstr(1),' to do anything else.');
        while Today = StartDay do nothing;
      end;
      writeln('Waiting until Today at',paramstr(1),' to do anything else.');
      while time < Start do nothing;  { infinite loop }
      writeln(time:5:2);
    end
    else writeln('INVALID TIME TO START! - ABORTING.');
END.

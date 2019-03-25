{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program HexDump;

Uses
  Crt;

const
   blocks   = 10;
   buffsize = 128;

type
   str80 = string[80];

var
   infile : file;
   Buffer : array[1..blocks,1..buffsize] of BYTE;

function HexConv(num : integer) : str80;
const
  base = 16;
  Hex  : string[16] = '0123456789ABCEDF';

var
  temp : str80;
  n,
  check,
  digit : integer;

    function pwrint(num,raise : integer) : integer;
    var
      i, temp : integer;

    begin
      temp := 1;
      if raise > 0 then
      for i := 1 to raise do temp := temp * num
      else temp := 1;
      pwrint := temp;
    end;

begin {HexConv}
  n := 0;
  temp := '';
  if num > 4095 then writeln('ERROR! in hex conversion')
  else
  repeat
    n := n + 1;
    check := pwrint(base,n);
    digit := trunc(num/pwrint(base,n-1)) mod base;
    temp := Hex[digit+1] + temp;
  until check > num;
  if length(temp) < 2 then temp := '0'+temp;
  HexConv := temp;
end; {HexConv}

procedure OpenFile;
var
   name : str80;

  function Exist(NameofFile: str80):Boolean;
  var
    Fil: file;
  begin
    Assign(Fil,NameOfFile);
    {$I-}
    Reset(Fil);
    if IOresult <> 0 then
    begin
     Exist := False;
     writeln('File ',NameOfFile,' does not exist here.');ClrEol;
     writeln('Choose again or <Ctrl><Break> to exit.');ClrEol;
    end
    else begin
      Exist := True;
      close(Fil);
    end;
    {$I+}
  end;

begin
  repeat
     write('File to display: ');
     readln(Name);
  until exist(Name);
  assign(infile,Name);
  reset(infile);
end; {OpenFile}

procedure ProcessFile;
const
  ChrsOnLine = 16;
var
  i,j,k,
  RecsRead,
  BlockCount,
  temp     : integer;

begin
  BlockCount := 0;
  while not EOF(infile) do
  begin
    BlockCount := BlockCount + 1;
    BlockRead(infile,Buffer,blocks,RecsRead);
    for i := 1 to RecsRead do
    begin
       j := 0;
       while j < buffsize do
       begin
         write(HexConv(BlockCount*i*buffsize - buffsize + j):5,':  ');
         for k := 1 to ChrsOnLine do
           write(HexConv(Buffer[i,j+k]),' ');
         write('     ');
         for k := 1 to ChrsOnLine do
         begin
           temp := Buffer[i,j+k];
           if (temp > 31) and (temp < 128) then
              write(chr(temp))
           else write('.');
         end;
         writeln;
         j := j + ChrsOnLine;
       end; {for j}
    end; {for i}
  end; {while not EOF}
end; {ProcessFile}

begin {MAIN}
   OpenFile;
   ProcessFile;
   Close(InFile);
end.

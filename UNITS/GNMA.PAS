{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program WORSTYLD;

Uses
  Crt,
  Dos,
  Graph3,
  Calendar;

const maxflow = 400;  {360 should be the most encountered}
      freq    = 12;   {payments per year}
      debug   = FALSE;
      hi      = 2; {for beep  procedure}
      lo      = 1;
      space   = ' ';

type
     anystr     = string[80];
     PmtStream  = array[0..maxflow] of real;
     typeOfBond = (TSY,GNMA,FHLMC,FNMA,FHLB);
     index      = 0..maxflow;

{Variables marked ** are input via the RECSCRN procedure}

var MBS        : PmtStream;
    PmtDelay   : 1..125;   {real payment delay, not stated}
                           {delay is a function of the MBS type}
    SvcFee,                {whole basis points}
    price,
    yield,
    CPR,             { unsched % principal paid per month e.g. 1.5}
    Coupon,
    settle,
    AvgLife,
    mat        :real;
    age,         {**}
    numflows   : integer;
    out        : Text;
    BondType   : typeOfbond;
    DoYield    : Boolean;   {**}


function computeMat(age : integer):real;
{computes approx maturity date given age of mortgage}

const length = 360;  {30 year mortgage}

var years,months  : integer;
    now           : real;

begin
     now    := Today;
     years      := trunc((length - age)/12) + year(now);
     months := ((length - age) mod 12) + month(now);
     if months > 12 then
        begin
          months := months - 12;
          years  := years + 1;
        end;
     computeMat := date(months,1,years);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FlowCount(Settle,Mat : real) : integer;
{compute the number of cash flows to any security}

begin
   Settle := Date(month(Settle),day(Mat),year(Settle));
   FlowCount := round((Mat - Settle)/(365/freq)); {freq = 12 for monthly}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function FirstPay(Settle : real) : real;
{date of first MBS cashflow}
var m,d,y : integer;

begin
         d := 1;          {first day..}
         m := month(Settle) + 1;     {.. of the month after settle date}
         if m > 12 then   {adjust for year rollover mm # 13}
           begin
             m := m - 12;
             y := year(Settle) + 1;
           end
         else y := year(Settle);

     FirstPay := date(m,d,y) + PmtDelay;  {add delay to 1st of MM}
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Accrued(settle,coupon : real; Btype : TypeOfBond) : real;

begin
   if Btype = GNMA then
        Accrued := (day(settle) - 1) * (coupon/36000.0)
     else
     begin
        writeln('BOND TYPE NOT IMPLEMENTED');HALT
     end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Power(base,raise : real) : real;

begin
   Power  := exp(ln(base) * raise)
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Makebond;  {loads an array with the mbs cash flows.
                      the 0th element is the purchase price + accrued}
var   n  : integer;
      T,
      RemainBal,
      MonthlyInt,
      PrinPay,
      lnMoPay,
      Interest,
      SchedPay,
      SumFlows,
      PrePay       : real;
      CoupDate     :daterec;

begin
     numflows   := flowcount(settle,mat);
     svcFee     := svcFee/1200;       {convert annual to monthly}
     CPR        := CPR/100.0;
     MonthlyInt := Coupon/1200 + svcFee; {total monthly int. on mtg}
     lnMoPay    := ln(1+MonthlyInt);
     MBS[0]     := (price/100 + accrued(settle,Coupon,bondType));
     RemainBal  := 1;
     SumFlows   := 0;
     AvgLife    := 0;
     for n := 1 to numflows do
       begin
          {An intermediate result, optimized for speed}
          {actually T = MonthlyInt ^(numflows-n+1) }
          T         := exp(lnMoPay * (numFlows - n + 1));
          {Level payment to self amortizing loan}
          SchedPay  := MonthlyInt * T/(T-1) * RemainBal;
          {percent of remain. bal. prepaid in any month (unsched) }
          PrePay    := RemainBal * CPR;
          {interest accrual}
          Interest  := RemainBal * MonthlyInt;
          { cash flow to investor }
          PrinPay   := SchedPay + PrePay - Interest;
          MBS[n]    := SchedPay - (svcFee*remainBal) + PrePay;
          SumFlows  := SumFlows + PrinPay;
          AvgLife   := AvgLife + (PrinPay * n);
          { What's left for next time around }
          RemainBal := RemainBal - PrinPay;
       end;
     AvgLife := AvgLife / SumFlows;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function priceMBS(Pmt : PmtStream; yield : real): real;
{discount all cash flows to a monthly paying instrument to compute a
 present value}

var  DiscSum  :  real;
     i        :  index;

  begin
    yield    := (power(yield/200+1,1/6) -1) * 1200;  {CBE to monthly}
    yield    := ln(1 + yield/1200); {intermediate result, saves time}
    DiscSum  := pmt[1];
    for i    := 2 to numFlows do
        begin
          DiscSum := DiscSum + pmt[i] / exp(yield*(i-1));
        end;
    DiscSum  := DiscSum / exp(yield*((firstpay(settle) - settle)/30));
    priceMBS := DiscSum;   {this includes accrued interest}
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function DurationMBS(Pmt : PmtStream; yield : real): real;
{discount all cash flows to a monthly paying instrument to compute a
 modified MacCauly Duration value}

var  DiscSum,
     Dur, PV  :  real;
     i        :  index;

  begin
    yield    := (power(yield/200+1,1/6) -1) * 1200;  {CBE to monthly}
    yield    := ln(1 + yield/1200); {intermediate result, saves time}
    DiscSum  := pmt[1];
    Dur      := pmt[1];
    for i    := 2 to numFlows do
        begin
          PV      := pmt[i] / exp(yield*(i-1));
          DiscSum := DiscSum + PV;
          Dur     := Dur + (PV * i);
        end;
    DiscSum  := DiscSum / exp(yield*((firstpay(settle) - settle)/30));
    DurationMBS := Dur/(DiscSum * 12 * exp(yield));
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function YieldMBS(Pmts :PmtStream) :real;
  {iteration routine to find yield - quite slow}

const maxiter   = 25;
      tolerance = 0.0003;

var   low,high,incr,
      upper,lower,
      Ayield,
      pricecalc  :  real;
      n          :  integer;
      done       :  boolean;

begin
  low       := 1;
  n         := 0;
  high      := Coupon/mbs[0] + 1.0;
  incr      := (high - low)/2;
  upper     := pmts[0] + tolerance;
  lower     := pmts[0] - tolerance;
  done      := false;
    repeat   {goal seeking}
       n := n + 1;
       if debug then
        begin
          gotoXY(18,13);write(n:3)
        end;
       Ayield    := low + incr;
       pricecalc := priceMBS(pmts,Ayield);
       if pricecalc < lower then incr := incr/2
         else if pricecalc > upper then low := low + incr
             else done := true;
       if n = maxiter then done := true;
    until done;  {goal seeking}
yieldMBS := Ayield;
if debug then gotoXY(18,13);write('   ');
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure InputScreen;

const
     MaxField  = 10;
     HalfField = 5;
     NullStr   = '';
     space     = ' ';

type
  PossTypes = (RealNum,Frac32,IntNum,AString,ADate,YesOrNo);
  Characters = set of char;
  Months    = 1..12;
  Days      = 1..31;
  Years     = 0..2500;



 OneField = Record
              Name         : String;
              Contents     : String ;
              ValidChars   : Characters;
              ypos,
              xpos,
              width        : Integer;
              case ContentsType : PossTypes of
                RealNum: (RValue    : real);
                Frac32 : (FValue    : real);
                IntNum : (IValue    : integer);
                ADate  : (DValue    : real);
                YesOrNo: (BValue    : boolean;
                          TrueCase  : Characters);
            end; {RECORD}

Library = Array[1..MaxField] of OneField;

var
   I,OldField,
   NewField     : Integer;
   ch           : char;
   temp: String;
   Field        : library;
   PrintChars,
   RealChars,
   IntChars     : Characters;
   AnnlSpd      : boolean;


procedure Beep(factor : integer);
   begin
     Sound(1000 * factor); delay(trunc(200 * 1/factor));NoSound;
   end;

procedure InitFields;

begin
   with Field[1] do
      begin
        Name         := 'Coupon';
        Contents     := NullStr;
        ContentsType := RealNum;
        ValidChars   := ['0'..'9','.'];
        RValue        := 0.0;
        xpos         := 3;
        ypos         := 3;
        width        := 6;
       end;

   with Field[2] do
      begin
        Name         := 'Price';
        Contents     := NullStr;
        ContentsType := Frac32;
        ValidChars   := ['0'..'9','.',':','-']; {: and - are 32nd flags};
        FValue        := 0.0;
        xpos         := 21;
        ypos         := 3;
        width        := 7;
       end;

   with Field[3] do
      begin
        Name         := 'Yield';
        Contents     := NullStr;
        ContentsType := RealNum;
        ValidChars   := ['0'..'9','.'];
        RValue       := 0.0;
        xpos         := 38;
        ypos         := 3;
        width        := 7;
       end;

   with Field[5] do
      begin
        Name         := 'CMP/CPR';
        Contents     := NullStr;
        ContentsType := RealNum;
        ValidChars   := ['0'..'9','.'];
        RValue       := 0.0;
        xpos         := 44;
        ypos         := 10;
        width        := 6;
       end;

   with Field[4] do
      begin
        Name         := '(M)onthly or (A)nnual Speed';
        Contents     := 'M';
        ContentsType := YesOrNo;
        ValidChars   := ['a','m','A','M'];
        BValue       := false;   {compute monthly CPR by default}
        TrueCase     := ['a','A'];
        xpos         := 2;
        ypos         := 10;
        width        := 1;
       end;

   with Field[6] do
      begin
        Name         := 'Age (months)';
        Contents     := '0';
        ContentsType := IntNum;
        ValidChars   := ['0'..'9'];
        IValue        := 0;
        xpos         := 10;
        ypos         := 12;
        width        := 3;
       end;

   with Field[7] do
      begin
        Name         := 'SettleDate (MM/DD/YY)';
        Contents     := TodayString;
        ContentsType := ADate;
        ValidChars   := ['0'..'9','/'];
        DValue       := Today;
        xpos         := 40;
        ypos         := 12;
        width        := 10;
       end;

   with Field[8] do
      begin
        Name         := 'Compute (P)rice or (Y)ield';
        Contents     := 'P';
        ContentsType := YesOrNo;
        ValidChars   := ['p','y','P','Y'];
        BValue       := false;   {compute price given yield by default}
        TrueCase     := ['y','Y'];
        xpos         := 25;
        ypos         := 15;
        width        := 1;
       end;

   with Field[9] do
      begin
        Name         := 'Service Fee (pct)';
        Contents     := '0.50';
        ContentsType := RealNum;
        ValidChars   := ['0'..'9','.'];;
        RValue       := 0.5;
        xpos         := 5;
        ypos         := 18;
        width        := 4;
       end;

   with Field[10] do
      begin
        Name         := 'Real Delay (days)';
        Contents     := '15';
        ContentsType := IntNum;
        ValidChars   := ['0'..'9'];
        IValue       := 15;
        xpos         := 36;
        ypos         := 18;
        width        := 2;
       end;

end;

procedure TransferValues;  {assign Field.Contents to global variables}
var n : integer;

begin
     for n := 1 to MaxField do
       with Field[n] do
          case n of
            1: Coupon  := RValue;
            2: Price   := RValue;
            3: Yield   := RValue;
            4: AnnlSpd := BValue;
            6: Age     := IValue;
            7: Settle  := DValue;
            8: DoYield := BValue;
            9: svcFee  := RValue;
            10: PmtDelay := IValue;
            5: if AnnlSpd then
                  begin
                   CPR := 100*(1-power((1-RValue/100),(1/12)));
                  end  {begin/end should be superfluous, but isn't }
                 else CPR := RValue;
          end; {CASE}
end;


procedure Colors(Scheme:Integer);
var
   Back,Txt :Integer;

  procedure ColorSet(txt,back : integer);
    begin
      textcolor(txt);
      textbackground(back);
    end; {COLORSET}

   procedure rvson;
     begin
       textcolor(0);
       textbackground(7);
      end;  {RVSON}

    procedure rvsoff;
      begin
        textcolor(7);
        textbackground(0);
      end;  {RVSOFF}

begin
{ FOR MONO MONITORS }
   case Scheme of
   1: rvsoff;
   2: rvson;
   3: rvson;
   4: colorSet(Black + Blink,LightGray);
   end;

(*
{ FOR COLOR MONITORS }
   case Scheme of
   1: colorSet(LightGray,Blue);
   2: colorSet(Black,Cyan);
   3: colorSet(Black,Brown);
   4: colorSet(Black + blink,Red);
   end;
*)
end; {COLORS}


function Time: String;
type  regpack = registers;

var
  recpack:                regpack;           {record for MsDos call}
  hour,minute,second:     string[2];
  part:                   string[4];
  dx,cx,hr:               integer;

begin
  with recpack do
  begin
    ax := $2c shl 8;
  end;
  MsDos(recpack);                        { call function }
  with recpack do
  begin
       str(cx mod 256,minute); if length(minute)=1 then
               minute := '0'+minute;
       hr := cx shr 8;
       if hr > 11 then part := 'p.m.' else part := 'a.m.';
       if hr >12 then hr := hr - 12;
       str(hr,hour);
       if length(hour)=1 then hour := ' '+hour;
       str(dx shr 8,second);
       if length(second)=1 then second := '0'+second;
  end;
  time := hour+':'+minute+':'+second+' '+part;
end; {TIME}


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

procedure Restore;
var T : anystr;

begin
  T:=time;
  colors(2);
  gotoXY(1,24);
  write(TodayString);
  colors(1);
end;

procedure Refresh;
  begin
    gotoXY(26,24);
    colors(2);
    write(time);
    colors(1);
  end;

function RepeatStr(fill:anystr; times:integer) : anystr;
var temp : anystr;
    i    : integer;

begin
   temp := nullstr;
   for i := 1 to times do temp := temp + fill;
   RepeatStr := temp;
end; {REPEATSTR}

procedure InitScreen;
const Title = 'MBS YIELD TO MATURITY CALCULATOR';
var   pad : anystr;

  begin
     GraphBackground(1);
     Colors(1);
     ClrScr;
     Colors(2);
     GotoXY(2,1);
     pad := RepeatStr(space,trunc((79-length(Title))/2));
     Write(pad,title,pad);
     GotoXY(2,22);
     Colors(1);
     Write('ENTER DATA,  <F10> to Calculate, "Q" TO END');
  end;

procedure DrawBox(x,y,wide : integer);
begin
      gotoXY(x-1,y);
      write(char(179));
      gotoXY(x-1,y+1);
      write(char(192),RepeatStr(char(196),wide),char(217));
      gotoXY(x+wide,y);
      write(char(179));
      gotoXY(x-1,y-1);
      write(char(218),RepeatStr(char(196),wide),char(191));
end; {drawbox}

procedure RePaint;
var startX : integer;

begin {repaint}
    with Field[OldField] do
    begin
      startX := xpos + length(Name)+2;
      gotoXY(xpos,ypos);
      write(Name);
      DrawBox(startX,ypos,width);
      gotoXY(startX,ypos);
      highvideo;
{! 5. ^The effects of HighVideo,LowVideo,NormVideo are different in Turbo 4.0.}
      write(Contents + RepeatStr(space, width - length(Contents)));
      lowvideo;
{! 6. ^The effects of HighVideo,LowVideo,NormVideo are different in Turbo 4.0.}
    end;

    with Field[NewField] do
    begin
      gotoXY(xpos,ypos);
      write(Name);
      gotoXY(xpos + length(Name)+2,ypos);
      colors(3);
      if ch=#13 then colors(4);
      write(Contents + RepeatStr(space, width - length(Contents)));
      colors(1);
    end;
end; {REPAINT}

procedure MoveRight;
begin
     OldField := NewField;
     NewField := NewField + 1;
     if NewField > MaxField then NewField := NewField mod MaxField;
     RePaint;
end;

procedure MoveLeft;
begin
     OldField := NewField;
     NewField := NewField - 1;
     if NewField < 1 then NewField := NewField mod MaxField + MaxField;
     RePaint;
end;

function ReadStr(temp       :anystr;
                  x,y,
                  MaxWidth  :integer;
                  ValidChars:Characters):anystr;
var
    ch   : char;

    procedure backspace;
         begin
            if length(temp)>0 then
              begin
                colors(3);
                temp := Copy(temp,1,Length(temp)-1);
                GotoXY(WhereX-1,WhereY);
                Write(' ');
                write(ch);
                colors(1);
              end
            else beep(hi);
         end;

begin
    gotoXY(x,y);
    if temp[1] in ValidChars then write(temp) else temp := nullstr;
    repeat
      if Keypressed then
       begin
         ch := ReadKey;
{! 7. USE TURB^O3 unit for access to KBD, or instead USE CRT and ReadKey.}
         if ch in ValidChars then temp := temp + ch
           else if ch = #8 then backspace
              else if ch <> #13 then beep(hi);
         if ch in ValidChars then write(ch);
       end
    until (ch=#13) or (length(temp)=MaxWidth);
    ch := chr(0);
    ReadStr := temp;
end; {READSTR}

function CheckTypeOK(var FieldStuff : OneField) : boolean;

var i, err : integer;

 function Frac2Dec(StringPart : String) : real;
 var IntPart, FracPart, loc : Integer;
     Value : real;

 begin
   loc := pos('-',StringPart);
   if loc = 0 then loc := pos(':',StringPart);
   if loc = 0 then Val(StringPart,Value,Err)
   else
     begin
        Val(Copy(StringPart,1,loc-1),IntPart,err);
        Val(Copy(StringPart,loc+1,length(StringPart)-loc),FracPart,err);
        Value := IntPart + FracPart/32;
     end;
  Frac2Dec := Value;
  end; {Frac2Dec}

begin  {CheckTypeOK}
     err := 0;
{
     for i := 1 to MaxField do
       begin
}
         with FieldStuff do
           begin
             while Contents[1] = space do Delete(Contents,1,1);
             case ContentsType of
               RealNum  :  Val(Contents,RValue,Err);
               Frac32   :  FValue := Frac2Dec(Contents);
               IntNum   :  Val(Contents,IValue,Err);
               ADate    :  DValue := ParseDateStr(Contents);
               YesOrNo  :  if Contents[1] in TrueCase then
                              BValue := True
                           else BValue := False;
             end; {case}
           end; {with}
(*
     end; {for}
*)
     if err = 0 then
       begin
         CheckTypeOK := true;
         if debug then begin gotoXY(10,21);write('OK') end;
       end
       else
         begin
          CheckTypeOK := False;
          if debug then begin gotoXY(10,21);write('BAD') end;
          beep(hi); beep(hi);
         end;
end;  {CheckType}

procedure WriteAvgLife;
begin
     gotoXY(35,6); Write('Avg.Life');
     DrawBox(45,6,5);
     gotoXY(45,6); Write(AvgLife/12:4:1);
end; { writeavglife }

procedure WriteDuration;
begin
     gotoXY(5,6); Write('Mod. Duration');
     DrawBox(20,6,6);
     gotoXY(20,6); Write(DurationMBS(MBS,yield):4:1);
end; { WriteDuration }

procedure Recalculate;
var  GoodData : boolean;
     n        : INTEGER {0..maxfield};
begin
n := 0;
repeat
      n := n + 1;
      GoodData := CheckTypeOK(Field[n]);
      if (n = 2) and (not DoYield) then GoodData := True;
      if (n = 3) and DoYield       then GoodData := True;
until (not GoodData) or (n = MaxField);
if GoodData then
  begin
     OldField := NewField;
     TransferValues;
     mat := computeMat(age);
     makeBond;
     if DoYield then
         begin
          yield := yieldMBS(MBS);
          str(yield:7:3,Field[3].Contents);
          NewField := 3;
         end
      else
        begin
          Price := (priceMBS(MBS,yield)-accrued(settle,coupon,bondtype))*100;
          str(Price:7:3, Field[2].Contents);
          NewField := 2;
        end;
     Repaint;
     WriteAvgLife;
     WriteDuration;
     beep(lo);
  end
  else
  if debug then
    begin
      beep(hi);
      write('xx ',n:3);
     end;  {end if GoodData}
end; {recalculate}

{************************************************}
procedure CursorKeyPress;
var
   mover:char;

begin
     if KeyPressed then
        begin
          Mover := ReadKey;
{! 8. USE TURBO^3 unit for access to KBD, or instead USE CRT and ReadKey.}
          {HalfField constant has no effect here , could replace +/- 1
           for cursor right/left}
          case Mover of
          'P':MoveRight;         {cursor down}
          'H':MoveLeft;          {cursor up}
          'M':MoveRight;         {cursor right}
          'K':MoveLeft;          {cursor left}
          #68:Recalculate;        {F10 function key}
          end {CASE}
        end; {IF}
     ch := #0;
end; {cursorkeypress}


{ *****   MAIN BODY ******}

begin
  IntChars     := ['0'..'9','-'];
  RealChars    := IntChars + ['.'];
  PrintChars   := RealChars + ['A'..'P','a'..'p','R'..'Z','r'..'z'];
  InitScreen;
  InitFields;
  NewField := 1;
  while OldField <> 2 do MoveLeft;
  Restore;
  repeat
        While not KeyPressed do Refresh;
        if KeyPressed then ch := ReadKey;
{! 9. USE TURBO3 unit for access^ to KBD, or instead USE CRT and ReadKey.}
        if ch = #27 then CursorKeyPress;     {checks for cursor key}
        if ch = #13 then MoveRight;
        if ch in PrintChars then
           begin
              with Field[NewField] do
                begin
                  if ch in ValidChars then
                     repeat
                        Contents :=
                           ReadStr(ch,xpos+length(Name)+2,ypos,
                                   width,
                                   ValidChars);
                        ch := #0;
                      until CheckTypeOK(Field[NewField])
                   else beep(hi);
                   RePaint;
                end; {WITH}
              MoveRight;
           end;
  until (ch = #3) or (ch = 'q') or (ch = 'Q');  {Control-C to end}
  beep(hi);
end; {INPUTSCREEN}
{-------------------------------------------------------------}

{MAIN PROGRAM}
begin
    {INITIALIZE}
    BondType := GNMA;
    InputScreen;
    ClrScr;
end.

unit HPDATE;
{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

{CALENDAR FUNCTION SUBROUTINES
Provides conversion of mm,dd,yy numbers into serial numbers
     which can be used in math operations and then converted
     back.
{++++++++++++++++++++++++++++++++++++++++++++++++++++++}
interface

Uses
  Dos;

const
     weekDay : array[1..7] of string[5] = ('Mon','Tues','Weds',
                            'Thurs', 'Fri','Sat','Sun');

     mo      : array[1..12] of string[3] = ('Jan','Feb','Mar',
                            'Apr','May', 'Jun','Jul','Aug','Sep',
                            'Oct','Nov','Dec');
     ShortForm = 1;
     LongForm  = 2;

type
     Months    = 1..12;
     Days      = 1..31;
     Years     = 0..2500;
     DateFormat = 1..2;
     daterec   = record
                    mm   : Months;
                    dd   : Days;
                    yy   : Years;
                    DOW  : byte;
                 end;

     function date (m,d,y:integer) : longint;
     function month(serial : longint) : integer;
     function day  (serial : longint) : integer;
     function year (serial : longint) : integer;
     function DayString  (serial : longint): string;
     function MonthString(serial : longint): string;
     function Today: longint;
     function DateString(serial :longint; format :DateFormat): string;
     function TodayString : string;
     function ParseDateStr(VAR datestr : string) :longint;

{++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
  function DateNum(date : daterec): longint;
  {Converts mm,dd,yy numbers into serial number using HP 12C algorithm ***}

  var z,x  : longint;
    begin
      with date do
        begin
             z := yy - ord(mm<3) ;
             x := (40000 * mm + 230000) div 100000 * ord(mm>2) ;
          datenum := trunc(365.0) * yy + 31 * (mm-1) + dd + trunc(z / 4) - x;
        end;
   end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function date (m,d,y:integer) : longint;

var dates : daterec;

begin
     with dates do
     begin
       mm := m;
       dd := d;
       yy := y
     end;
     date := dateNum(dates);
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure DateConv(var date : daterec; serial : longint);
{converts serial to mm,dd,yy. result in DATE}

begin
     date.yy := trunc(serial/365.25+1);
     date.mm := 1;
     date.dd := 1;
     while dateNum(date) > serial do
           date.yy := date.yy-1;
     date.mm := trunc((serial - dateNum(date)) / 28.0 + 1);
     while dateNum(date) > serial do
           date.mm := date.mm-1;
     date.dd := trunc(serial - dateNum(date)) + 1;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function month(serial : longint) : integer;
var date : daterec;

begin
     dateconv(date,serial);
     month := date.mm
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function day(serial : longint) : integer;
var date : daterec;

begin
     dateconv(date,serial);
     day := date.dd
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function year(serial : longint) : integer;
var date : daterec;

begin
     dateconv(date,serial);
     year := date.yy
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Today: longint;
{uses ms-dos function call to get system date}

var
  recpack:       registers;                {record for MsDos call}

begin
  with recpack do
  begin
    ax := $2a shl 8;
  end;
  MsDos(recpack);                        { call function }
  with recpack do Today := date(dx shr 8,dx mod 256,cx);
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function MonthString  (serial : longint): string;

begin
   MonthString := mo[month(serial)];
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function DayString  (serial : longint): string;

begin
  DayString := weekday[(serial - 719540) mod 7 + 1];
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function DateString(serial : longint; format : DateFormat) : string;
{format = 1 : mm/dd/yy; format = 2 : Weekday, Month,day, year }

var  year, month, day,
     suffix           : string;
     temp             : daterec;

begin
  if format > 2 then format := 2;
  if format < 1 then format := 1;
  DateConv(temp, serial);
  with temp do
  begin
    str(yy:4,year);                  {convert to string}
    str(dd:2,day);
    case format of
       1 : begin
             str(mm:2,month);
             DateString := month+'/'+day+'/'+year;
           end; {case 1}
       2 : begin
             case (dd mod 10) of
                0 : suffix := 'th';
                1 : suffix := 'st';
                2 : suffix := 'nd';
                3 : suffix := 'rd';
             4..9 : suffix := 'th';
             end;  {case dd}
             case dd of
               11..13 : suffix := 'th';
             end; {case dd - exception}
             DateString := DayString(Today)+', ' + MonthString(Today)
                   +' '+ day + suffix + ', '+ year;
           end; {case 2}
    end; {case format}
  end; {with temp do }
end; {DateString}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function TodayString : string;
begin
   TodayString := datestring(today,1);
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function ParseDateStr(VAR datestr : string) : longint;

{ this makes an educated guess about the century if it only gets the
  last two digits of a year: more than 50 years less than the current
  year will be interpeted as the next century.  This is useful
  for financial applications.  Override this by simply expressing
  the year with four digits (i.e. in 1986, '16' is 2016 but
   '1916' is 1916.
  Valid years are 100-2500 A.D. }

CONST slash =   #47;
      dash  =   #45;
      nullstr = '';

TYPE
    StateType = (GetMonth, GetDay, GetYear);

var num,yy,mm,dd,
    doneOK, i          : integer;
    monthstr,daystr,
    yearstr, tempstr : string;
    State            : StateType;

BEGIN
    tempstr := nullstr;
    doneOK    := 0;
    State   := GetMonth;
    i := 1;  (* change to zero for Modula *)
    WHILE i < LENGTH(datestr) + 2 (* - 1 for Modula *) DO
    BEGIN
        IF ((datestr[i] = slash) OR
            (datestr[i] = dash)  OR
            (i = LENGTH(datestr) + 1)) THEN
        BEGIN
            CASE State OF
               GetMonth : monthstr := tempstr;
               GetDay   : daystr   := tempstr;
               GetYear  : yearstr  := tempstr;
            END;
            State := SUCC(State);
            tempstr := nullstr;
        END
        ELSE
            tempstr := Concat(tempstr,datestr[i]);
        i := SUCC(i);
    END; (* WHILE *)

         {year is not given, assume this year}
    IF State = GetYear THEN yy := year(Today)
    ELSE
      BEGIN
         val(yearstr,yy,doneOK);
         IF doneOK = 0 THEN
             (* this allows you to abbreviate years.  A consequence is
                this routine does not handle any years before 99 AD    *)
             IF (yy +1900) < (year(today) - 50) THEN yy := yy + 2000
             ELSE IF  yy < 100 THEN yy := yy + 1900;
    END; (* year *)
    IF doneOK = 0 THEN val(daystr,dd,doneOK);
    IF doneOK = 0 THEN val(monthstr,mm,doneOK);
    IF doneOK = 0 THEN
    BEGIN
       IF (yy >0) AND (yy <2500) AND
         (mm IN [1..12]) AND
         (dd IN [1..31])
       THEN  {if parse successful change to serial #}
          ParseDateStr := Date(mm,dd,yy)
     END
     ELSE ParseDateStr := 0;
END;  (* ParseDateStr *)
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

{END OF CALENDAR FUNCTIONS}
end.
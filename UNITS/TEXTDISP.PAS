Unit TextDisp;


interface

{$I TEXTMODE.INC}

uses CRT, Graph, Windows, Memory;


type
   MessageRec     = RECORD
                   BitMap   : POINTER;
                   OldColor,
                   OldBkColor,
                   ClipSize : WORD;
                   x, y      : INTEGER;
                 END;

procedure Beep;

procedure CursorConvert(X,Y : INTEGER; VAR gX, gY : INTEGER);
{ convert 80x24 line position to graphics pixels }

PROCEDURE MyGotoXY(X,Y: WORD);
{ replaces Turbo GotoXY in graphics mode}

PROCEDURE WriteT(X,Y: WORD; stg : String);
{ subsitute for GotoXY();Write() with graphic screens }

PROCEDURE WriteInt(X,Y: WORD; intnum : INTEGER);
{ subsitute for GotoXY();Write() with graphic screens }

PROCEDURE Message(VAR mp : MessageRec; msg : string);

PROCEDURE ClearMsg(mp : MessageRec);
{ call to clear message }

function ErrorMsg(msg : string) : BOOLEAN;
{ beeps, displays the msg, waits a sec, then returns false }

procedure DrawBox(x,y,wide,high : integer);

{ ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure Beep;
BEGIN
  Sound(500);
  Delay(500);
  NoSound;
END;

function RepeatStr(fill:string; times:integer) : string;
var temp : string;
    i    : integer;

begin
   temp := '';
   for i := 1 to times do temp := temp + fill;
   RepeatStr := temp;
end; {REPEATSTR}

{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE FillRect( x1,y1,x2,y2 : WORD);
VAR
  v : ARRAY[0..3] OF PointType;

BEGIN
   v[0].x := x1; v[0].y := y1;
   v[1].x := x2; v[1].y := y1;
   v[2].x := x2; v[2].y := y2;
   v[3].x := x1; v[3].y := y2;
   FillPoly(4,v);

END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure CursorConvert(X,Y : INTEGER; VAR gX, gY : INTEGER);
{ convert 80x25 line position to graphics pixels for 8 pixel font}

CONST
  FontWidth = 8;
  FontHeight = 8;


BEGIN
  gX := trunc(GetMaxX / 80 * X) - FontWidth;
  IF gX < 0 THEN gX := 0;
  IF gX > GetMaxX THEN gX := GetMaxX;

  gy := trunc(GetMaxY / 24 * Y) - FontHeight;
  IF gY < 0 THEN gY := 0;

END; {CursorConvert}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE MyGotoXY(X,Y: WORD);
{ replaces Turbo GotoXY in graphics mode}

VAR
  gx,gy : INTEGER;

BEGIN
{$IFDEF TextMode }
  GotoXY(X,Y);
{$ELSE }
  CursorConvert(X,Y,gx,gy);
  MoveTo(gx,gy);
{$ENDIF }
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE WriteT(X,Y: WORD; stg : String);

VAR
  gx,gy : INTEGER;

begin
{$IFDEF TextMode }
  GotoXY(X,Y);
  Write(stg);
{$ELSE }
  CursorConvert(X,Y,gx,gy);
  OutTextXY(gx,gy,repeatstr(' ',length(stg)));
  OutTextXY(gx,gy,stg);
{$ENDIF }
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE WriteInt(X,Y: WORD; intnum : INTEGER);
VAR
  stg   : String;
  gx,gy : INTEGER;

begin
{$IFDEF TextMode }
  GotoXY(X,Y);
  Write(intnum:0);
{$ELSE }
  CursorConvert(X,Y,gx,gy);
  str(intnum:0,stg);
  OutTextXY(gx,gy,stg);
{$ENDIF }
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE Message(VAR mp : MessageRec; msg : string);
CONST
  HalfCols  = 40;
  top       = 12;
  bottom    = 14;

VAR
  Spaces,i,
  left, right,
  x1,y1,x2,y2,
  len      : INTEGER;
  Error    : BYTE;

begin
  len := length(msg);
  right := HalfCols + len + 2;
  left  := HalfCols - len + 2;

  IF left < 1 THEN
  BEGIN
      left  := 1;
      right := HalfCols * 2 - 1;
  END;


{$IFDEF TextMode }
  OpenWindow(left,top,right,bottom,Black,red,error);
  WriteT(left+2,top-1,msg);
{$ELSE }
  CursorConvert(left,top,x1,y1);
  CursorConvert(right,bottom,x2,y2);
  mp.ClipSize := ImageSize(x1,y1,x2,y2);
  GetMem(mp.BitMap,mp.ClipSize);
  IF mp.BitMap <> NIL THEN
  BEGIN
     GetImage(x1,y1,x2,y2,mp.BitMap^);
     mp.OldColor   := GetColor;
     mp.OldBkColor := GetBkColor;
     SetColor(Black);
     SetFillStyle(SolidFill,Red);
     SetColor(Yellow);
     FillRect(x1,y1,x2,y2);
     WriteT(left+2,top+1,msg);
     mp.x := x1; mp.y := y1;
  END;
{$ENDIF}
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
PROCEDURE ClearMsg(mp : MessageRec);
BEGIN
{$IFDEF TextMode }
     CloseWindow;
{$ELSE }
     PutImage(mp.x,mp.y,mp.BitMap^,NormalPut);
     FreeMem(mp.BitMap,mp.ClipSize);
     SetColor(mp.OldColor);
     SetBkColor(mp.OldBkColor);
{$ENDIF}
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function ErrorMsg(msg : string) : BOOLEAN;

VAR
  Error    : BOOLEAN;
  mp      : MessageRec;


BEGIN
  Beep;
  Message(mp,msg);
  Delay(1000);
  ClearMsg(mp);
  ErrorMsg := FALSE;
END;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure DrawBox(x,y,wide, high : integer);
{ x,y is character position WITHIN box at upper left. }

var
  i : integer;
begin
   for i := 0 to high DO
   BEGIN
      WriteT(x-1,y+i,char(179));
      WriteT(x+wide,y+i,char(179));
   END;
   WriteT(x-1,y+high,char(192)+RepeatStr(char(196),wide)+char(217));
   WriteT(x-1,y-1,char(218)+RepeatStr(char(196),wide)+char(191));
end; {drawbox}


begin
end.

Unit GetField;

Interface

uses Crt, KeyCodes;

CONST
   IgnoreStr  = 0;
   BlankStr   = 1;
   TrimStr    = 2;
   BlankNTrim = 3;
   NoStr      = '';

type
   BoxToggle   = (NOBOX, BOX);
   Alignment   = (LEFT,TOP);


procedure AddExitKey(NewKey : Integer);
{ The pre-existing default is ESC }


(* automatically called

procedure ForgetExitKeys;
{ You must call this upon exit even if you did not add any beyond
  the default }
*)

procedure DrawBox(x,y,wide,high : integer);

procedure Field_Str( Xpos, Ypos,
                     Len, Opts : Byte;
                     Lab   : String;
                     Var UserStr : String;
                     Format : Char;
                     DoBox : BoxToggle;
                     RelPos : Alignment);

procedure SetUp_Field(ActiveFColor,InactiveFColor : Byte;
                      ActiveBColor,InactiveBColor : Byte;
                      ClearChar : Char);

procedure Release_Fields;

procedure CleanString(var S : String);

procedure GetString(Ypos,Xpos,Attr,Len,Opts : Byte;
                    Var UserStr : String;
                    Legal : Char;
                    Var Keyval : Integer);

procedure Do_Fields(Var KeyVal : Integer);
{  KeyVal is key code of last key pressed }

function Get_Key : Integer;

{ ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

Type
  Field_IO = Record
               Xpos,Ypos,Len,Exit,Opts : Byte;
               Format : Char;
               UserStr : ^String;
             end;

  KeyPtr = ^Node;
  Node   = Record
            Key : integer;
            Next : KeyPtr;
           END;

Var
  Field_Array : Array[1..256] of ^Field_IO;
  Max_Field : Byte;
  Active_Fcolor : Byte;
  Inactive_Fcolor : Byte;
  Active_Bcolor : Byte;
  Inactive_Bcolor : Byte;
  Clear_Char : Char;
  KeyList,
  LastNode,
  KeyNode : KeyPtr;
  ExitSave : POINTER;

procedure AddExitKey(NewKey : Integer);
{ dynamically allocate a linked list of keys that trigger loop exit }
begin
   new(KeyNode);
   IF KeyList <> NIL THEN
     LastNode^.Next := KeyNode
   ELSE
     KeyList := KeyNode;
   KeyNode^.Key  := NewKey;
   KeyNode^.Next := NIL;
   LastNode := KeyNode;
end;

function ExitKey(KeyVal : integer) : BOOLEAN;
{ check if KeyVal matches any exit keys }

VAR
  position : KeyPtr;

begin
  position := KeyList;
  ExitKey  := FALSE;
  WHILE (position <> NIL) AND (position^.Key <> KeyVal) DO
      position := position^.Next;
  IF position <> NIL then ExitKey := TRUE;
end; {ExitKey}

procedure ForgetExitKeys;
{ release memory used by KeyList }

VAR
  position : KeyPtr;

begin
  WHILE (KeyList <> NIL) DO
  BEGIN
    position := KeyList;
    KeyList := KeyList^.next;
    Dispose(position);
  END;
end; {ForgetExitKeys}

function RepeatStr(fill:string; times:integer) : string;
var temp : string;
    i    : integer;

begin
   temp := '';
   for i := 1 to times do temp := temp + fill;
   RepeatStr := temp;
end; {REPEATSTR}

procedure DrawBox(x,y,wide, high : integer);
{ x,y is character position WITHIN box at upper left. }

var
  i : integer;
begin
   for i := 0 to high DO
   BEGIN
      gotoXY(x-1,y+i);
      write(char(179));
      gotoXY(x+wide,y+i);
      write(char(179));
   END;
   gotoXY(x-1,y+high);
   write(char(192),RepeatStr(char(196),wide),char(217));
   gotoXY(x-1,y-1);
   write(char(218),RepeatStr(char(196),wide),char(191));
end; {drawbox}

procedure Field_Str;
VAR
  StartLabel : INTEGER;

  begin
    inc(Max_Field,1);
    New(Field_Array[Max_Field]);
    Field_Array[Max_Field]^.Xpos := Xpos;
    Field_Array[Max_Field]^.Ypos := Ypos;
    Field_Array[Max_Field]^.Len := Len;
    Field_Array[Max_Field]^.Opts := Opts;
    If Opts > 2 then UserStr := '';
    Field_Array[Max_Field]^.UserStr := @UserStr;
    Field_Array[Max_Field]^.Format := Format;
    IF NOT (Lab = NoStr) THEN
      IF RelPos = LEFT THEN
      begin
         StartLabel := Xpos - Length(Lab) - 1;
         IF StartLabel > 0 THEN
         begin
            GotoXY(StartLabel,YPos);
            Write(Lab);
         end;
      end
      else
      begin
         StartLabel := trunc(XPos + Len/2 - Length(Lab)/2);
         IF StartLabel < 1 THEN StartLabel := 1;
         GotoXY(StartLabel,YPos-1-ORD(DoBox));
         Write(Lab);
      end;
    IF DoBox = BOX THEN DrawBox(Xpos,Ypos,Len,1);


  end;

procedure SetUp_Field;
  begin
    Active_FColor := ActiveFColor;
    Inactive_Fcolor := InactiveFColor;
    Active_BColor := ActiveBColor;
    Inactive_Bcolor := InactiveBColor;
    Clear_Char := ClearChar;
    Max_Field := 0;
  end;

procedure Release_Fields;
  Var
    X : Byte;
  begin
    For X := 1 to Max_Field do
      Release(Field_Array[Max_Field]);
    Max_Field := 0;
  end;


procedure CleanString;
  Var X : Byte;
  Begin
    If Length(S) > 0 then
      begin
        X := 1;
        While (s[x] = ' ') and (Length(s) > 0) do
          Delete(S,x,1);
        X := Length(S);
        While (s[x] = ' ') and (x > 0) do
          dec(x);
        S[0] := Char(x);
      end;
  end;

function Get_Key : Integer;
  Var CH : Char;
      Int : Integer;
  begin
    CH := ReadKey;
    If CH = #0 then
      begin
        CH := ReadKey;
        int := Ord(CH);
        inc(int,256);
      end else Int := Ord(CH);
    Get_Key := Int;
  end;

procedure GetString(Ypos,Xpos,Attr,Len,Opts : Byte;
                    Var UserStr : String;
                    Legal : Char;
                    Var Keyval : Integer);

Var
  Position : Byte;
  Ins,Exit : Boolean;
  Str255 : String;

  procedure WriteString;
    Var X : Byte;
    begin
      GotoXY(Xpos,Ypos);
      If Length(Str255) > Len then
        Str255[0] := Char(Len);
      Write(Str255);
      If Length(Str255) < Len then
        For X := Length(Str255) to Len-1 do
          Write(Clear_Char);
    end;

  procedure BackSpaceChar;
    Begin
      delete(Str255,Position-1,1);
      dec(Position);
      WriteString;
    end;

  procedure DeleteChar;
    Begin
      inc(Position);
      BackSpaceChar;
    end;

  procedure WriteChar;
    Var
      DoWrite : Boolean;
    Begin
      If Position <= Len then
        begin
          DoWrite := True;
          case Legal of
            'U' : Char(KeyVal) := UpCase(Chr(KeyVal));
            'L' : DoWrite := True;
            'N' : If Pos(Char(KeyVal),'1234567890.-') = 0 then
                    DoWrite := False;
            else DoWrite := False;
          end;
          If DoWrite then
          begin
            If Ins then
              Insert(Char(Keyval),Str255,Position)
            else Str255[Position] := Char(KeyVal);
            if Position > Length(Str255) then
              Str255[0] := Char(Position);
            WriteString;
            Inc(Position);
            GotoXY(Xpos+Position-1,Ypos);
          end;
        end;
    End;

  procedure EditString;
    Begin
      KeyVal := Get_Key;
      Case KeyVal of
{Back}    8 : If Position > 1 then BackSpaceChar;
{Return} 13 : Exit := True;
{Home}  327 : Position := 1;
{Up}    328 : Exit := True;
{PgUp}  329 : Exit := True;
{Left}  331 : If Position > 1 then
                dec(Position);
{Right} 333 : If Position < Len then
                inc(Position);
{End}   335 : Position := Length(Str255)+1;
{Down}  336 : Exit := True;
{PgDn}  337 : Exit := True;
{Ins}   338 : If Ins then Ins := False else Ins := True;
{Del}   339 : DeleteChar;
      end;
      IF ExitKey(KeyVal) THEN
        Exit := TRUE;
      If (KeyVal < 256) and (Keyval > 27) then
        WriteChar
      else GotoXY(Xpos+Position-1,Ypos);
    end;

begin
  Exit := false;
  Ins := False;
  TextAttr := Attr;
  Position := 1;
  FillChar(Str255,SizeOf(Str255),Clear_Char);
  Insert(UserStr,Str255,1);
  Str255[0] := Char(Length(UserStr));
  WriteString;
  GotoXY(Xpos+Position-1,Ypos);
  repeat EditString until Exit;
  TextAttr := Inactive_FColor + Inactive_BColor * 16;
  If Opts > 1 then
    CleanString(Str255);
  WriteString;
  UserStr := Str255;
end;

procedure Do_Fields;
  Var
    Exit : Boolean;
    Field_Id : Byte;
  begin
    Field_Id := 1;
    Repeat
      With Field_Array[Field_Id]^ do
        GetString(Ypos,Xpos,
                  Active_Fcolor + Active_Bcolor * 16,
                  Len,Opts,UserStr^,Format,KeyVal);
      If ExitKey(KeyVal) THEN Exit := True
        ELSE  Exit := False;
      Case KeyVal of
        CR,DownArrow : If Field_Id = Max_Field then
                   Field_Id := 1 else inc(Field_Id);
        UpArrow: If Field_Id = 1 then
                Field_Id := Max_Field
              else dec(Field_Id,1);
      end;
    Until Exit;
  end;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{$F+} procedure TerminateClean; {$F-}
{ This should automatically get called no matter how we exit }

BEGIN
  IF Max_Field > 0 Then Release_Fields;
  IF KeyList <> NIL THEN ForgetExitKeys;
  ExitProc := ExitSave;
END; {TerminateClean}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}

begin
  SetUp_Field($70,$07,$00,$00,' ');
  KeyList := NIL;
  AddExitKey(ESC);
  ExitSave := ExitProc;
  ExitProc := @TerminateClean;
end.

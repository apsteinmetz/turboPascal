UNIT windows;

INTERFACE
USES Dos,Crt;

PROCEDURE OpenWindow(x1,y1,x2,y2: byte;
                   Fgnd,Bkgnd: byte;
                   VAR Error : ShortInt );
(* Creates a blank Window with the given coordinates, and saves the contents *)
(* of the underlying region on the heap. If an Error occurs in attempting to *)
(* open the Window, Error is set to TRUE; otherwise, FALSE is returned.      *)


  procedure CloseWindow;

IMPLEMENTATION

CONST MaxWindows = 10;        (* maximum # on-screen windows *)
      FrameFgnd = red;        (* frame colors *)
      FrameBkgnd = lightgray;

      { error conditions }
      NoError        = 0;
      TooManyWindows = 1;
      OutOfHeap      = 2;
      BadDimensions  = 3;

TYPE IntPtr = ^integer;
     WindowType =
       record
     xL,yL,xR,yR : integer;     (* coordinates of corners     *)
     BufrPtr : IntPtr;         (* pointer to buffer location *)
     CursorX,CursorY : integer; (* cursor position before opening *)
     ScreenAttr : byte;         (* text attributes before opening *)
       end;

VAR WindowStack : array [0..MaxWindows] of WindowType;
    MaxCols,MaxRows : byte; (* # rows & columns for initial video mode *)
    NumWindows : 0..MaxWindows;  (* # windows currently open  *)
    VidStart : word;             (* location for video memory *)
    Regs : registers;
    ExitSave : POINTER;

PROCEDURE Beep;
(* This procedure is called if the request to open a window causes an error *)
begin
  Sound(200); Delay(100);
  Sound(350); Delay(100);
  Sound(100); Delay(100);
  Nosound
end (* procedure Beep *);

PROCEDURE DrawFrame (x1,y1,x2,y2: byte);
(* Draws a rectangular frame on the screen with upper left hand corner      *)
(*                at x1,y1, lower right hand corner at x2,y2.               *)
VAR k : integer;
    CurrentAttr : byte;
begin (* DrawFrame *)
  CurrentAttr := TextAttr;  (* save the current text attributes *)
  TextAttr := FrameFgnd + 16*FrameBkgnd; (* change attributes for frame *)
  GotoXY(x1,y1);
  Write(chr(201));
  for k := (x1 + 1) to (x2 - 1) do
    Write(chr(205));
  Write(chr(187));
  for k := (y1 + 1) to (y2 - 1) do
  begin
    GotoXY(x1,k);  Write(chr(186));
    GotoXY(x2,k);  Write(chr(186));
  end;
  GotoXY(x1,y2);
  Write(chr(200));
  for k := (x1 + 1) to (x2 - 1) do
    Write(chr(205));
  Write(chr(188));
  TextAttr := CurrentAttr   (* restore previous text attributes *)
end (* DrawFrame *);

PROCEDURE SaveRegion (x1,y1,x2,y2 : byte;
                      VAR StartAddr : IntPtr   );
(* Saves the contents of the screen rectangle with coordinates x1,y1,x2,y2  *)
(*             on the heap starting at address StartAddr.                   *)
VAR TempPtr,LinePtr : IntPtr;
    k,LineLength : integer;
begin
  LineLength := (x2 - x1 + 1) * 2; (* # bytes per line in rectangle *)
  (* allocate space on heap *)
  GetMem (StartAddr,LineLength * (y2 - y1 + 1));
  TempPtr := StartAddr; (* TempPtr points to copy destination on heap *)
  for k := y1 to y2 do begin
    (* Make LinePtr point to screen position x=x1, y=k *)
    LinePtr := Ptr(VidStart, (k-1)*MaxCols*2 + (x1-1)*2);
    (* Move the line from screen to heap *)
    Move (LinePtr^,TempPtr^,LineLength);
    (* Increment the screen IntPtr *)
    TempPtr := Ptr(seg(TempPtr^),ofs(TempPtr^) + LineLength);
  end
end (* procedure SaveRegion *);

PROCEDURE RecallRegion (x1,y1,x2,y2 : integer;
              HpPtr : IntPtr);
(* Moves the contents of a previously saved region from the heap back *)
(*                       to the screen.                               *)
VAR TempPtr,LinePtr : IntPtr;
    k,LineLength : integer;
begin
  LineLength := (x2 - x1 + 1) * 2; (* # bytes per line in rectangle *)
  TempPtr := HpPtr;   (* TempPtr gives the source location for copy *)
  for k := y1 to y2 do
    begin
      (* Make LinePtr point to screen position x=x1, y=k *)
      LinePtr := Ptr(VidStart, (k-1)*MaxCols*2 + (x1-1)*2);
      move (TempPtr^,LinePtr^,LineLength);
      TempPtr := Ptr(seg(TempPtr^),ofs(TempPtr^) + LineLength);
    end;
end (* procedure RecallRegion *);

PROCEDURE OpenWindow(x1,y1,x2,y2: byte;
                   Fgnd,Bkgnd: byte;
                   VAR Error : ShortInt );
(* Creates a blank Window with the given coordinates, and saves the contents *)
(* of the underlying region on the heap. If an Error occurs in attempting to *)
(* open the Window, Error is set to TRUE; otherwise, FALSE is returned.      *)
VAR Pntr : IntPtr;
begin
  if (NumWindows = 0) then begin  (* determine current screen parameters *)
    MaxCols := Lo(WindMax) + 1; (* add 1, since numbering begins with 0  *)
    MaxRows := Hi(WindMax) + 1;
    with WindowStack[0] do  (* WindowStack[0] is the entire screen *)
      begin
        xL := 0; yL := 0;
        xR := MaxCols + 1; yR := MaxRows + 1
      end
  end;

  (* check for possible error conditions *)
  Error := 0;
  IF (NumWindows = MaxWindows)  THEN (* too many windows? *)
      Error := 1;

  (* out of heap? *)
  IF (MaxAvail < longint((x2 - x1 + 1)*(y2 - y1 + 1)*2)) THEN
     Error := 2;

  (* wrong dimensions? *)
  IF NOT ( (x1 in [1..MaxCols-2]) and (x2 in [3..MaxCols]) and (x2-x1>1)
          and (y1 in [1..MaxRows-2]) and (y2 in [3..MaxRows])
          and (y2-y1>1) )  THEN Error := 3;
  IF Error > 0 THEN
     Beep
  ELSE BEGIN  (* successful request *)
    SaveRegion (x1,y1,x2,y2,Pntr);
    Error := 0;
    NumWindows := NumWindows + 1;
    with WindowStack[NumWindows] do begin
      xL := x1; yL := y1;
      xR := x2; yR := y2;
      BufrPtr := Pntr;
      CursorX := WhereX;
      CursorY := Wherey;
      ScreenAttr := TextAttr
    end;
    Window (1,1,MaxCols,MaxRows);  (* make the whole screen a window *)
    DrawFrame (x1,y1,x2,y2);
    Window (x1+1,y1+1,x2-1,y2-1);  (* create the requested window    *)
    TextColor(Fgnd);
    TextBackground(Bkgnd);
    ClrScr
  end  (* else clause *)
end (* procedure OpenWindow  *);

PROCEDURE CloseWindow;
VAR x,y : integer;
begin
  if NumWindows > 0 then begin
    with WindowStack[NumWindows] do begin
      RecallRegion (xL,yL,xR,yR,BufrPtr); (* restore underlying text      *)
      FreeMem (BufrPtr,(xR - xL + 1)*(yR - yL + 1)*2); (* free heap space *)
      x := CursorX; y := CursorY;  (* prepare to restore cursor position  *)
      TextAttr := ScreenAttr       (* restore screen attributes           *)
    end;
    (* activate the underlying Window *)
    NumWindows := NumWindows - 1;
    with WindowStack[NumWindows] do
      Window (xL+1,yL+1,xR-1,yR-1);
    GotoXY (x,y)  (* restore the cursor position *)
  end  (* if NumWindows > 0 *)
end (* procedure CloseWindow  *);

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{$F+} procedure TerminateClean; {$F-}
{ This should automatically get called no matter how we exit }
{ I added this - Art }

BEGIN
  WHILE NumWindows > 0 DO CloseWindow;
  ExitProc := ExitSave;
END; {TerminateClean}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++}


begin  (* Windows initialization *)
  NumWindows := 0;
  Regs.AH := 15;   (* prepare for DOS interrupt    *)
  Intr($10,Regs);  (* determine current video mode *)
  case Regs.AL of
    0..3 : VidStart := $B800;  (* start of video memory *)
       7 : VidStart := $B000;
  end; (* case statement *)
  ExitSave := ExitProc;
  ExitProc := @TerminateClean;
end (* Windows initialization *).

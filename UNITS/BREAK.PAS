{$R-,S-,I-}

unit Break;

{ A unit to allow Control-Break to interrupt program execution.

  Version 1.00 -  1/02/1987 - First general release

  Scott Bussinger
  Professional Practice Systems
  110 South 131st Street
  Tacoma, WA  98444
  (206)531-8944
  Compuserve 72247,2671 }


interface

uses Dos;


implementation

const ControlBreakFlag: boolean = false;

var ExitSave: pointer;
    SaveInt8: pointer;
    SaveInt1B: pointer;

procedure JmpOldISR(OldISR: pointer);
  { Chain to previous interrupt handler }
  inline($5B/                   {  pop bx             ;BX = Ofs(OldIsr)}
         $58/                   {  pop ax             ;AX = Seg(OldIsr)}
         $87/$5E/$0E/           {  xchg bx,[bp+14]    ;Switch old BX and Ofs(OldIsr)}
         $87/$46/$10/           {  xchg ax,[bp+16]    ;Switch old AX and Seg(OldIsr)}
         $89/$EC/               {  mov sp,bp          ;Restore SP}
         $5D/                   {  pop bp             ;Restore BP}
         $07/                   {  pop es             ;Restore ES}
         $1F/                   {  pop ds             ;Restore DS}
         $5F/                   {  pop di             ;Restore DI}
         $5E/                   {  pop si             ;Restore SI}
         $5A/                   {  pop dx             ;Restore DX}
         $59/                   {  pop cx             ;Restore CX}
         $CB);                  {  retf               ;Chain to OldIsr, leaving CS and IP params on the stack}

procedure HaltProgram;
  { Simple routine to halt the program }
  begin
  halt(255)                                      { 255 is the standard error code for ^Break }
  end;

{$F+}
procedure ControlBreakHandler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP: Word); interrupt;
  { Set a flag on seeing a ^Break }
  begin
  ControlBreakFlag := true
  end;

procedure TimerHandler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP: Word); interrupt;
  { Check to see that things are safe and then halt program if ^Break flag is set }
  begin
  if ControlBreakFlag and                        { Wait for ^Break to be hit }
     (CS>=PrefixSeg) and (CS<DSeg) then          { Make sure we're in our program (and not in DOS, etc.) }
    begin
    CS := seg(HaltProgram);                      { Return to the halt routine }
    IP := ofs(HaltProgram)
    end;
  JmpOldISR(SaveInt8)                            { Chain to other timer interrupts }
  end;

procedure ExitHandler;
  { Cleanup after ourselves }
  begin
  ExitProc := ExitSave;
  SetIntVec($08,SaveInt8);
  SetIntVec($1B,SaveInt1B)
  end;
{$F-}

begin
ExitSave := ExitProc;
ExitProc := @ExitHandler;
GetIntVec($08,SaveInt8);
GetIntVec($1B,SaveInt1B);
SetIntVec($1B,@ControlBreakHandler);
SetIntVec($08,@TimerHandler)
end.

{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

  (*
  PRNDRV.PAS

 PROCEDURE AttachPrinter(Printer : Printers);
      {-define the Lst device to print to the specified printer}

  PROCEDURE ReleasePrinter;
      {-deassign the Lst device and restore the printer timeout}

  printer driver to provide clean error handling
  modification of Kim Kokkonen's TUFPRT, to include his later
  changes, some corrections to error handling, & restore of display
  after error message
  *)

  
Uses
  Dos;

TYPE
    Printers = (LPT1, LPT2, LPT3, LPT4, NoPrinter);
  CONST
    ActivePrinter : Printers = NoPrinter;
  VAR
    SavePrintTimeOut : Byte;
    {
    the following bytes normally equal $14, providing 20 retries on printer
    busy calls. Set to 1 for a single retry (timeout takes about 2 seconds).
    Do not set to 0 or system will retry forever.
    }
    PrintTimeOut : ARRAY[Printers] OF Byte ABSOLUTE $40 : $78;

  PROCEDURE PrintChar(ch : Char);
      {-print the character ch, handle errors & loop when busy }
      {
      **********************************************************************
      CANNOT USE TURBO I/O FUNCTIONS INSIDE HERE DUE TO RE-ENTRANCY PROBLEMS
      **********************************************************************
      }

    TYPE
      PrintErrors =
      (TimeOut, unused1, unused2, IOerror, Selected,
      OutOfPaper, Acknowledge, Busy, NoError);

      DisplayString = STRING[80];

      registers =
      RECORD
        CASE Integer OF
          1 : (ax, bx, cx, dx, bp, si, di, ds, es, flags : Integer);
{! 1. Instead use the Registers type from the Turbo 4.0 DOS unit. ^ }
          2 : (al, ah, bl, bh, cl, ch, dl, dh : Byte);
      END;

    CONST
      PrintErrorMsg : ARRAY[PrintErrors] OF DisplayString =
      ('Printer Timeout Error', '', '', 'Printer Not Selected',
      'Printer Not Selected', 'Printer Out of Paper',
      'Printer Acknowledge Error', 'Printer Busy', '');

      EndStr : DisplayString = #13#10#36;

      {maximum number of replies with busy before calling it a timeout error.
      may need to be adjusted empirically to avoid false timeouts}
      BusyMax = 100;

    VAR
      reg : registers;
      Error : PrintErrors;
      BusyCount : Integer;
    VAR err : Byte;


    PROCEDURE writestring(s : DisplayString);
        {-write string to standard output}
      VAR
        reg : registers;
      BEGIN
        reg.ah := 9;
        reg.ds := Seg(s);
        reg.dx := Ofs(s[1]);
        MsDos(Dos.Registers(reg));
{! 2. Paramete^r to MsDos must be of the type Registers defined in DOS unit.}
      END;                    {displaystring}

    PROCEDURE getchar(VAR response : Char);
        {-get a character from the keyboard}
      VAR
        reg : registers;
      BEGIN
        reg.ah := 0;
        Intr($16, Dos.Registers(reg));
        response := Chr(reg.al);
      END;                    {getchar}


    PROCEDURE HandleError(Error : PrintErrors);
        {-handle user-oriented error conditions}
      TYPE
        ScreenContents = ARRAY[1..4000] OF Byte;
      VAR
        CrtMode : Byte ABSOLUTE $0040 : $0049;
        MonoBuffer : ScreenContents ABSOLUTE $B000 : $0000;
        ColorBuffer : ScreenContents ABSOLUTE $B800 : $0000;
        savescreen : ScreenContents;
        response : Char;
      BEGIN
        IF CrtMode = 7 THEN
          savescreen := MonoBuffer
        ELSE
          savescreen := ColorBuffer; { save screen contents }
        writestring(PrintErrorMsg[Error]+EndStr);
        writestring('Correct condition and then press <ENTER> '+#36);
        REPEAT getchar(response) UNTIL (response IN [#13, #3]);
        writestring(EndStr);
        IF response = #3 THEN Halt; {Ctrl-C}
        BusyCount := 0;
        IF CrtMode = 7 THEN
          MonoBuffer := savescreen
        ELSE
          ColorBuffer := savescreen; { restore screen contents }
      END;                    {handleerror}

    PROCEDURE int17(Printer : Printers; func : Byte;
                    CharToPrint : Byte; VAR err : Byte);
        {-call the printer interrupt and return error information}
        {-func =0 to print, =2 to just check status}
      BEGIN
        INLINE(
{! 3. Ne^w stack conventions require that many Inlines be rewritten.}
          $8B/$56/$0C/        {MOV    DX,[BP+0C] - get printer number}
          $8A/$66/$0A/        {MOV    AH,[BP+0A] - get printer function}
          $8A/$46/$08/        {MOV    AL,[BP+08] - get character to print}
          $CD/$17/            {INT    17}
          $C4/$7E/$04/        {LES    DI,[BP+04] - get address of error}
          $26/$88/$25);       {MOV    ES:[DI],AH - return error if any}
      END;                    {int17}


    BEGIN                     { PrintChar }
      IF ActivePrinter = NoPrinter THEN BEGIN
        writestring('program error: no printer is selected'+EndStr);
        Exit;
      END;
      reg.dx := Ord(ActivePrinter); {equals 0..3}
      BusyCount := 0;

      REPEAT
        {print the character}
        int17(ActivePrinter, 0, Ord(ch), err);
        {check for errors}
        IF (err AND 128) <> 0 THEN BEGIN
          {printer busy}
          BusyCount := Succ(BusyCount);
          IF BusyCount < BusyMax THEN
            Error := Busy
          ELSE BEGIN
            {busy too long, call it a timeout}
            HandleError(TimeOut);
            Error := TimeOut;
          END;
        END ELSE IF (err AND 41) <> 0 THEN BEGIN
          {a "hard" error}
          IF (err AND 32) <> 0 THEN
            HandleError(OutOfPaper)
          ELSE IF (err AND 8) <> 0 THEN
            HandleError(IOerror)
          ELSE HandleError(TimeOut);
          Error := IOerror;
        END ELSE
          Error := NoError;
      UNTIL Error = NoError;
    END;                      {printchar}


  PROCEDURE AttachPrinter(Printer : Printers);
      {-define the Lst device to print to the specified printer}
    BEGIN
      IF ActivePrinter = NoPrinter THEN BEGIN
        ActivePrinter := Printer;
        LstOutPtr := Ofs(PrintChar);
{! 4. Us^e new textfile device drivers to replace I/O Ptr references.}
        {save current printer timeout}
        SavePrintTimeOut := PrintTimeOut[Printer];
        {set to minimum timeout period}
        PrintTimeOut[Printer] := 1;
      END ELSE
        WriteLn(Con,
{! 5. Special de^vices Con, Trm, Aux, Usr are not supported in Turbo 4.0.}
        'program error: only one printer can be protected at a time');
    END;                      {protectprinter}

  PROCEDURE ReleasePrinter;
      {-deassign the Lst device and restore the printer timeout}
    BEGIN
      IF ActivePrinter <> NoPrinter THEN BEGIN
        PrintTimeOut[ActivePrinter] := SavePrintTimeOut;
        ActivePrinter := NoPrinter;
      END;
    END;                      {restoreprinter}

    {end of include portion
    ***********************************************************************}
(*
    {demonstration follows}
  VAR
    i : Integer;
    prn : text;
  BEGIN
    assign(prn,'LST:');
    WriteLn(prn, 'using TURBO list device'); {this doesn't print}

    WriteLn(Lst, 'using DOS list device');  { this does not }

    AttachPrinter(LPT1);
    WriteLn(Lst, 'using PRNDRV.PAS device');   { this prints }
    ReleasePrinter;

    { this generates the 'printer not selected' error }
    { I figured ReleasePrinter was supposed to give it back }
    WriteLn(Lst, 'using DOS list device');
  END.
  *)

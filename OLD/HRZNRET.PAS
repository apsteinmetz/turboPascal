program HrznRet;
{ test yield calcs}

{$IFDEF CPU87}
  {$N+}
{$ELSE}
  {N-}
{$ENDIF}

uses Break, CRT, GetField, Calendar, Bondage, KeyCodes, Windows;

CONST
  MaxMoves          = 5;
  MaxHorizons       = 4;
  ExitKeyVal        = F10;
  CalcKeyString     = 'F9';
  ExitKeyString     = 'F10';

TYPE
   WindowColors = RECORD
                ActiveFgd,
                InActiveFgd,
                ActiveBgd,
                InActiveBgd,
                Background,
                WindowText   : INTEGER;
             END;

VAR
   Done,
   Annual    : BOOLEAN;
{ i, }
   KeyVal,
   Horizons,
   Moves        : INTEGER;
   settle, sell : LONGINT;  (* Serial dates *)
   BuyYld,
   ReinvRate,
   coupon      : REAL;
   Bond        : BondRec;
   MainWin,
   HelpWin,
   ErrorWin    : WindowColors;
   CoupStr,
   DateStr,
   CPStr,
   AnnStr,
   YieldStr    : String;
   YldChStr    : ARRAY[0..4] of String;
   HorizonStr  : ARRAY[0..3] of String;
   YldCh       : ARRAY[0..4] of Real;
   Horizon     : ARRAY[0..3] of Integer;



procedure Beep;
BEGIN
  Sound(500);
  Delay(500);
  NoSound;
END;

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
  procedure ColorsOn(UseColor : BOOLEAN);

  BEGIN
    IF UseColor THEN
    BEGIN
       With MainWin DO
       BEGIN
         ActiveFgd   := Red;        (* Active text color *)
         InActiveFgd := Black;      (* Inactive text color *)
         ActiveBgd   := Green;      (* Active text background color *)
         InActiveBgd := LightGray;  (* Inactive text background color *)
         Background  := LightGray;
         WindowText  := Blue;
       END;
       With HelpWin DO
       BEGIN
         Background  := Blue;
         WindowText  := White;
       END;
       With ErrorWin DO
       BEGIN
         Background := Magenta;
         WindowText := White;
       END;
     END
     ELSE
     BEGIN
       With MainWin DO
       BEGIN
         ActiveFgd   := White;        (* Active text color *)
         InActiveFgd := LightGray;      (* Inactive text color *)
         ActiveBgd   := Black;      (* Active text background color *)
         InActiveBgd := Black;  (* Inactive text background color *)
         Background  := Black;
         WindowText  := LightGray;
       END;
       With HelpWin DO
       BEGIN
         Background  := Black;
         WindowText  := LightGray;
       END;
       With ErrorWin DO
       BEGIN
         Background  := LightGray;
         WindowText  := Black;
       END;
     END;
   END; { ColorsOn }

  {+++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure Help;
VAR
  Error : SHORTINT;

begin
   With HelpWin DO
      OpenWindow(10,2,70,23,WindowText,Background,Error);
   writeln('                     HELP!');
   writeln;
   writeln('* Use Up/Down arrow keys or <Enter> to scroll around.');
   writeln('* Enter data for bond coupon, maturity, and yield.');
   writeln('* Enter the 30 day CP Rate, or any rate you want');
   writeln('   to use as the reinvestment rate.');
   writeln('* Y to Annualize or N for simple return');
   writeln('* Enter one or more rate changes to use.  Express');
   writeln('    values in basis points.');
   writeln('* Enter one or more time horizons (in months). Do');
   writeln('    not enter zero.');
   writeln;
   writeln('* Press <F9> to recalculate, <F10> to quit.');
   writeln;
   writeln('NOTE: If you have a monochrome screen start this program');
   writeln('      by typing HRZNRET MONO.  If you have an ATT mono');
   writeln('      screen type HRZNRET ATT');
   writeln;
   writeln('            Press any key to return.');
   Error := GetKey;  {nothing statement}
   CLoseWindow;
end;

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure Abort(errmsg : string);
CONST
  left =  10;
  right = 60 ;

VAR
  Spaces,i : INTEGER;
  Error    : ShortInt;

begin
  With ErrorWin DO
       OpenWindow(left,12,right,14,WindowText,Background,Error);
  IF Error = 0 THEN
  begin
     {do text centering}
     spaces := ( right-left-2-length(errmsg) ) div 2;
     if spaces > 0 then for i := 1 to spaces do write(' ');
     Write(errmsg);
     Beep;
     Delay(500);
     CloseWindow;
     Done := FALSE;
  end;
end;

{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure Initialize;

VAR
  Error : ShortInt;
  i, j, VOfs, GrDriver, GrMode : INTEGER;


BEGIN

{++++ Exit Keys ++++++++++++++++++++++}
AddExitKey(ExitKeyVal);  {This one Quits Prog.  Others just force recalc }
AddExitKey(F9);          { Force Recalc }
AddExitKey(F1);          { Help }

{++++++++++++++++++++++++++}
  TextMode(CO80);
  ColorsOn(TRUE);
  IF (paramstr(1) = 'MONO') OR (paramstr(1) = 'mono') THEN
  BEGIN
    TextMode(Mono);
    ColorsOn(FALSE);
  END
  ELSE IF (paramstr(1) = 'ATT') OR (paramstr(1) = 'att') THEN
  BEGIN
    ColorsOn(FALSE);
  END;

  ClrScr;
  With MainWin DO OpenWindow(1,1,79,25,WindowText,Background,Error);
  if Error = 0 then begin
    Write('       Horizon Total Rate of Return Calculator');
    GotoXY(12,20); Write('Press ',CalcKeyString,' to Calculate');
    GotoXY(12,21); Write('Press ',ExitKeyString,' to Quit');
    GotoXY(12,22); Write('Press F1 for Help');
  end;


  With MainWin DO SetUp_Field( ActiveFgd, InActiveFgd,
                               ActiveBgd, InActiveBgd,
                               ' ' (* Fill String *)  );

{++++++++++++ SET UP FIELDS +++++++++++++++}

{ +++++ Bond Spec Block +++++++}
Field_Str(5,5,6,3,'Coupon',CoupStr,'N',nobox,top);
Field_Str(15,5,12,3,'Mat Date',DateStr,'L',nobox,top);
Field_Str(30,5,6,3,'Yield',YieldStr,'N',nobox,top);
Field_Str(40,5,6,3,'30 Day CP Rate',CPStr,'N',nobox,top);
Field_Str(60,5,1,3,'Annualize [Y]/N',AnnStr,'L',nobox,top);

{++++++++++  Rate Change Block +++++++++++++++}
VOfs := 8;
GotoXY(15,VOfs-1);
Write('Rate Movements (Basis Points)');
DrawBox(10,VOfs+2,MaxMoves*8,1);
FOR i := 0 to MaxMoves-1 DO
  Field_Str(13 + (8 * i),VOfs+2,4,3,nostr,YldChStr[i],'N',nobox,top);

{++++++++++  Hozizon Block +++++++++++++++}
GotoXY(5,VOfs+4); Write('Horizon');
GotoXY(5,VOfs+5); Write('(Months)');
DrawBox(6,VOfs+7,3,MaxHorizons);
FOR i := 0 to MaxHorizons-1 DO
  Field_Str(6,VOfs+7+i,3,3,nostr,HorizonStr[i],'N',nobox,top);

END; {Initialize}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure ProcessInput;

VAR
  mat : LONGINT;
  err,
  i, VOfs : INTEGER;

BEGIN
   Done := TRUE;
   Mat := ParseDateStr(DateStr);
   if Mat = 0 then Abort('Maturity Date is Unreadable.');
   Val(CoupStr,Coupon,err);
   if err > 0 then Abort('Coupon is not a valid number.');
   Val(YieldStr,BuyYld,err);
   if err > 0 then Abort('Yield is not a valid number');
   Val(CPStr,ReinvRate,err);
   if err > 0 then Abort('CP Rate is not a valid number');
   IF upcase(AnnStr[1]) = 'N' Then Annual := FALSE
        ELSE Annual := TRUE;

{++++++++ Scan the Rate changes +++++++++++}
   i := 0; err := 0;
   IF Done THEN
      WHILE (i < MaxMoves) AND (err = 0) DO
      BEGIN
          Val(YldChStr[i],YldCh[i],err);
         if (err <> 0) THEN
           BEGIN
              IF i = 0 THEN Abort('Enter a valid Yield Change')
           END
         ELSE
           BEGIN
              YldCh[i] := YldCh[i]/100;
              { Write absolute yields }
              gotoXY(11+(8*i),8);
              write(BuyYld + YldCh[i]:5:2);
           END;
        IF err = 0 then Moves := i;
        inc(i);
      end;

{++++++++ Scan the Time horizons +++++++++++}
   i   := 0; err := 0;
   IF Done THEN
      WHILE (i < MaxHorizons) AND (err = 0) DO
      begin
         Val(HorizonStr[i],Horizon[i],err);
         IF  (i = 0) AND  (err <> 0) then
             Abort('Enter time horizon(s)');
         IF (Horizon[i] = 0) AND (err = 0) then
             Abort('Zero Horizon not Allowed');
         IF Err = 0 then Horizons := i;
         inc(i);
      end;
   IF Done THEN
   BEGIN
      Settle := today;
      sell   := settle;
      Makebond(settle,mat,coupon,Bond);
   END;
end; {ProcessInput}

{++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure DisplayResults;
CONST
  XShift = 8; {display arrangement constants }
  YShift = 1;

VAR
  i, j,
  YOfs, XOfs : INTEGER;
  Return     : Real;

BEGIN
   { row header }
(*
   GotoXY(1,10);
   write('  Spread to ',BaseRateString,(BuyYld-ReinvRate)*100:5:0,' BP');
   writeln; writeln;
*)

{++++++++++++++++++++++++++}
YOfs := 15; XOfs := 10;
   for i := 0 to MaxHorizons-1 DO
   begin
      Sell := Settle;
      IncMonth(Sell,Horizon[i]);
      for j := 0 to MaxMoves-1 do
      BEGIN
        GotoXY(XOfs + (j*XShift),YOfs + (i * YShift));
        IF (i > Horizons) OR (J > Moves) THEN
           Write('   n/a  ')
        ELSE
        BEGIN
           Return := TotalReturn(Bond,
                              Settle, Sell, (* Start, End dates *)
                              BuyYld, BuyYld+YldCh[j], ReinvRate);
           {adjust for semiannual compounding }
           Return := Compound(Return, 2 { per year });
           {now annualize the return}
           IF Annual THEN
               Return := Annualize(Return,Settle,Sell);
           Write(Return*100:6:2);
        END;
     end; {for j}
   end; {for i}
END; {DisplayResults}

{MAIN}
BEGIN

Initialize;
REPEAT
   Do_Fields(KeyVal);
   IF KeyVal = F1 then HELP
   ELSE
    IF KeyVal <> ExitKeyVal THEN
    BEGIN
      ProcessInput;
      IF Done THEN  DisplayResults;
    END;
UNTIL KeyVal = ExitKeyVal;
Release_Fields;
CloseWindow;
END.

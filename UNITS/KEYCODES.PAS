unit KeyCodes;
(* copyright 1991 by Art Steinmetz *)


interface

uses CRT;

CONST
{ These are valid ASCII codes }
   ESC = 27;
   BS  = 8;
   SP  = 32;
   LF  = 10;
   FF  = 12;
   CR  = 13;
   Break = 3;

{ These are only valid if you use the GetKey procedure below }
     F1 = 315;
     F2 = 316;
     F3 = 317;
     F4 = 318;
     F5 = 319;
     F6 = 320;
     F7 = 321;
     F8 = 322;
     F9 = 323;
    F10 = 324;
    F11 = 389;
    F12 = 390;

    SF1 = 340;
    SF2 = 341;
    SF3 = 342;
    SF4 = 343;
    SF5 = 344;
    SF6 = 345;
    SF7 = 346;
    SF8 = 347;
    SF9 = 348;
   SF10 = 349;
   SF11 = 391;
   SF12 = 392;

   Home = 327;
   UpArrow   = 328;
   PgUp = 329;
   LeftArrow = 331;
   RightArrow = 333;
   EndKey = 335;
   DownArrow = 336;
   PgDn  = 337;
   Ins  = 338;
   Del   = 339;

function GetKey : Integer;
{ This uses Turbo's ReadKey procedure and interpets extended key codes
  according to the constants defined above }

implementation

function GetKey : Integer;
  Var CH : Char;
      Int : Integer;
  begin
    CH := ReadKey;
    If CH = #0 then
      begin
        CH := ReadKey;
        int := Ord(CH);
        inc(int,256); {add 256 to the extended code to avoid ascii conflict}
      end else Int := Ord(CH);
    GetKey := Int;
  end;

BEGIN
END. {KeyCodes}

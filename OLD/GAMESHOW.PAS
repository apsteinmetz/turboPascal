program GameShow;

CONST
   Trials = 10000;
   Switch = TRUE {switch picked door when offered? };
   DoorCount = 3;

TYPE
   DoorSet = Set Of 0..DoorCount;

VAR
  DoorWithPrize,
  DoorPicked,
  NewDoorPicked,
  i,j, WinCount      : WORD;
  DoorsLeft : DoorSet;
  Done      : BOOLEAN;

BEGIN
  Randomize;
  WinCount := 0;
  FOR i := 1 to Trials DO
  BEGIN
    { what doors can be chosen ? }
    DoorsLeft := [1,2,3];

    { hide the prize behind a door }
    DoorWithPrize := Random(DoorCount)+1;

    { contestant picks a door }
    DoorPicked := Random(DoorCount)+1;
    DoorsLeft   := DoorsLeft - [DoorPicked];

    IF Switch THEN
    BEGIN
    { host opens door without prize and not picked}
    Done := FALSE;
    j := 0;
    REPEAT
      inc(j);
      IF NOT (j= DoorPicked) AND NOT (j = DoorWithPrize) THEN
      BEGIN
        DoorsLeft   := DoorsLeft - [j];
        Done := TRUE;
      END;
    UNTIL Done;

    { host lets contestant switch }
    DoorPicked := 1;
    WHILE NOT (DoorPicked IN DoorsLeft) DO
          INC(DoorPicked);

    END {SWITCH};

    { Does contestant win? }
    IF DoorPicked = DoorWithPrize THEN
      INC(WinCount);
  END {trial};
  Writeln(WinCount:5);

END.
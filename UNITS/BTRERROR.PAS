unit btrerror;
{text strings of BTrieve Errors }

interface

FUNCTION BtrStatus(StatusNum : INTEGER) : String;
{ Get string describing errors }

FUNCTION BtrOp(OpNum : INTEGER) : String;
{ Get string describing operation.  Account for extended ops }

FUNCTION BtrErrReport(OpNum, ErrNum : INTEGER) : String;
{ both functions above in more verbose result }

implementation

CONST

    {array index corresponds to error number }
    BTRErrors : ARRAY[0..99] OF String[35] = (
    { 0} ' 0: Success',
    { 1} ' 1: Invalid Operation',
    { 2} ' 2: I/O Error',
    { 3} ' 3: File Not Open',
    { 4} ' 4: Key Value Not Found',
    { 5} ' 5: Duplicate Key Value',
    { 6} ' 6: Invalid Key Number',
    { 7} ' 7: Different Key Number',
    { 8} ' 8: Invalid Positioning',
    { 9} ' 9: End Of File',
    {10} '10: Modifiable Key Value Error',
    {11} '11: Invalid File Name',
    {12} '12: File Not Found',
    {13} '13: Exetended File Error',
    {14} '14: Pre-Image Open Error',
    {15} '15: Pre-Image I/O Error',
    {16} '16: Expansion Error',
    {17} '17: Close Error',
    {18} '18: Disk Full',
    {19} '19: Unrecoverable Error',
    {20} '20: Record Manager Inactive',
    {21} '21: Key Buffer Too Short',
    {22} '22: Short Data Buffer Length',
    {23} '23: Wrong Position Block Length',
    {24} '24: Page Size Error',
    {25} '25: Create I/O Error',
    {26} '26: Wrong Number Of Keys',
    {27} '27: Invalid Key Position',
    {28} '28: Invalid Record Length',
    {29} '29: Invalid Key Length',
    {30} '30: Not A Btrieve File',
    {31} '31: File Already Extended',
    {32} '32: Extend I/O Error',
    {33} '33: Undefined Error',
    {34} '34: Invalid Extension Name',
    {35} '35: Directory Error',
    {36} '36: Transaction Error',
    {37} '37: Transaction Is Active',
    {38} '38: Trans. Control File I/O Error',
    {39} '39: End/Abort Transaction Error',
    {40} '40: Transaction Max Files',
    {41} '41: Operation Not Allowed',
    {42} '42: Incomplete Accelerated Access',
    {43} '43: Invalid Record Access',
    {44} '44: Null Key Path',
    {45} '45: Inconsistant Key Flags',
    {46} '46: Access To File Denied',
    {47} '47: Maximum Open Files',
    {48} '48: Invalid Alt. Sequence Def.',
    {49} '49: Key Type Error',
    {50} '50: Owner Already Set',
    {51} '51: Invalid Owner',
    {52} '52: Error Writing Cache',
    {53} '53: Invalid Interface',
    {54} '54: Variable Page Error',
    {55} '55: Autoincrement Error',
    {56} '56: Incomplete Index',
    {57} '57: Undefined Error',
    {58} '58: Compression Buffer Too Short',
    {59} '59: File Already Exists',
    {60} '60: Undefined Error',
    {61} '61: Undefined Error',
    {62} '62: Undefined Error',
    {63} '63: Undefined Error',
    {64} '64: Undefined Error',
    {65} '65: Undefined Error',
    {66} '66: Undefined Error',
    {67} '67: Undefined Error',
    {68} '68: Undefined Error',
    {69} '69: Undefined Error',
    {70} '70: Undefined Error',
    {71} '71: Undefined Error',
    {72} '72: Undefined Error',
    {73} '73: Undefined Error',
    {74} '74: Undefined Error',
    {75} '75: Undefined Error',
    {76} '76: Undefined Error',
    {77} '77: Undefined Error',
    {78} '78: Undefined Error',
    {79} '79: Undefined Error',
    {80} '80: Conflict On Update Or Delete',
    {81} '81: Lock Error',
    {82} '82: Lost Position',
    {83} '83: Read Outside Transaction',
    {84} '84: Record In Use',
    {85} '85: File In Use',
    {86} '86: File Table Full',
    {87} '87: Handle Table Full',
    {88} '88: Incompatible Mode Error',
    {89} '89: Undefined Error',
    {90} '90: Redirected Device Table Full',
    {91} '91: Server Error',
    {92} '92: Transaction Table Full',
    {93} '93: Incompatible File Lock Type',
    {94} '94: Permission Error',
    {95} '95: Session No Longer Valid',
    {96} '96: Communications Environment Err.',
    {97} '97: Data Message To Small',
    {98} '98: Internal Transaction Error',
    {99} '99: Undefined Error'

    );

{ Btrieve Operation Codes }
    BtrOperation : ARRAY[0..40] of String[25] = (
    '0: BTR Open',
    '1: BTR Close',
    '2: BTR Insert',
    '3: UpDate',
    '4: BTR Delete',
    '5: GetEqual',
    '6: GetNext',
    '7: GetPrevious',
    '8: GetGreater',
    '9: GetGreaterOrEqual',
    '10: GetLessThan',
    '11: GetLessThanOrEqual',
    '12: GetFirst',
    '13: GetLast',
    '14: Create',
    '15: Stat',
    '16: Extend',
    '17: SetDirectory',
    '18: GetDirectory',
    '19: BeginTrans',
    '20: EndTrans',
    '21: AbortTrans',
    '22: GetPos',
    '23: GetDirect',
    '24: StepNext',
    '25: Stop',
    '26: Version',
    '27: UnLock',
    '28: BTRReset',
    '29: SetOwner',
    '30: ClearOwner',
    '31: CreateIndex',
    '32: DropIndex',
    '33: StepFirst',
    '34: StepLast',
    '35: StepPrevious',
    '36: Undefined',
    '37: Undefined',
    '38: Undefined',
    '39: Undefined',
    '40: Undefined'
    );



{------------------------------------------------------------}
FUNCTION BtrStatus(StatusNum : INTEGER) : String;
{ Get string describing errors }

BEGIN
  BtrStatus := BtrErrors[StatusNum];
END {BtrStatus};

{------------------------------------------------------------}
FUNCTION BtrOp(OpNum : INTEGER) : String;
{ Get string describing operation.  Account for extended ops }

VAR
 extend : WORD;
 extendedOp : String;

BEGIN
  IF OpNum > 50 THEN
  BEGIN
    extend := OpNum div 50;
    CASE extend OF
       1 : ExtendedOp := ' Extended: Get Key';
       2 : ExtendedOp := ' Extended: Lock Single Wait';
       4 : ExtendedOp := ' Extended: Lock Single No Wait';
       6 : ExtendedOp := ' Extended: Lock Multi Wait';
       8 : ExtendedOp := ' Extended: Lock Multi No Wait';
       ELSE
           ExtendedOp := ' Extended: Invalid Extension';
    END;
    BTROp := BtrOperation[OpNum mod 50] + ExtendedOp;
  END
  ELSE
    BTROp := BtrOperation[OpNum mod 50];
END {BtrOp};

FUNCTION BtrErrReport(OpNum, ErrNum : INTEGER) : String;
BEGIN
  BtrErrReport := 'Error '+ BtrErrors[ErrNum] + ' during Op '+ BtrOp(OpNum);
END;

END.
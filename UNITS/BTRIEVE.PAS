{$V-}
{$R-}    {Range checking off}
{$S+}    {Stack checking on}

{									      }
{  Module Name: BTRIEVE.PAS						      }
{									      }
{  Description: This is the Btrieve interface for Turbo Pascal (MS-DOS).      }
{		This routine sets up the parameter block expected by	      }
{		Btrieve, and issues interrupt 7B.  It should be compiled      }
{		with the $V- switch so that runtime checks will not be	      }
{		performed on the variable parameters.			      }
{									      }
{  Synopsis:	STAT := BTRV (OpCode, POS.START, DataBuf.START, BufLen,	      }
{				 KeyBuf.START, Key);			      }
{			      where					      }
{			OpCode is an integer,				      }
{			POS is a 128 byte array,			      }
{			DataBuf is an untyped parameter for the data buffer,     }
{			BufLen is the integer length of the data buffer,     }
{			KeyBuf is the untyped parameter for the key buffer,     }
{		    and Key is an integer.				      }
{									      }
{  Returns:	Btrieve status code (see Appendix B of the Btrieve Manual).   }
{									      }
{  Note:	The Btrieve manual states that the 2nd, 3rd, and 5th	      }
{		parameters be declared as variant records, with an integer    }
{		type as one of the variants (used only for Btrieve calls),    }
{		as is shown in the example below.  This is supported, but     }
{		the restriction is no longer necessary.  In other words, any  }
{		variable can be sent in those spots as long as the variable   }
{		uses the correct amount of memory so Btrieve does not	      }
{		overwrite other variables.				      }
{									      }
{		   var DataBuf = record case boolean of			      }
{		      FALSE: ( START: integer );			      }
{		      TRUE:  ( EMPLOYEE_ID: 0..99999;			      }
{			       EMPLOYEE_NAME: packed array[1..50] of char;    }
{			       SALARY: real;				      }
{			       DATA_OF_HIRE: DATE_TYPE );		      }
{		      end;						      }
{									      }
{		There should NEVER be any string variables declared in the    }
{		data or key records, because strings store an extra byte for  }
{		the length, which affects the total size of the record.       }
{									      }
{									      }
UNIT BTRIEVE;

interface

Uses
     Dos;

CONST
  KeyLength = 255;

 { file open modes }
  Normal      =  0;
  Accelerated = -1;
  ReadOnly    = -2;
  Verify      = -3;
  Exclusive   = -4;


  { Btrieve Operation Codes }

  AbortTrans         = 21;
  BeginTrans         = 19;
  ClearOwner         = 30;
  BTRClose           =  1;
  Create             = 14;
  CreateIndex        = 31;
  BTRDelete          =  4;
  DropIndex          = 32;
  EndTrans           = 20;
  Extend             = 16;
  GetDirect          = 23;
  GetDirectory       = 18;
  GetEqual           =  5;
  GetFirst           = 12;
  GetGreater         =  8;
  GetGreaterOrEqual  =  9;
  GetLast            = 13;
  GetLessThan        = 10;
  GetLessThanOrEqual = 11;
  GetNext            =  6;
  GetPos             = 22;
  GetPrevious        =  7;
  BTRInsert          =  2;
  BTROpen            = 0;
  BTRReset           = 28;
  SetDirectory       = 17;
  SetOwner           = 29;
  Stat               = 15;
  StepFirst          = 33;
  StepLast           = 34;
  StepNext           = 24;
  StepPrevious       = 36;
  Stop               = 25;
  UnLock             = 27;
  UpDate             =  3;
  Version            = 26;

  { Additive operation modifiers }

  { Add to a get }
  GetKey             = 50;

  { Add locks to Get, Step, Open, or Begin }
  LockSingleWait     = 100;
  LockSingleNoWait   = 200;
  LockMultiWait      = 300;
  LockMultiNoWait    = 400;

  { BTRIEVE Status Return Codes }
   Sucess = 0;
   InvalidOperation = 1;
   IoError = 2;
   FileNotOpen = 3;
   KeyNotFound = 4;
   DuplicateKey = 5;
   InvalidKey = 6;
   DifferentKey = 7;
   InvalidPos = 8;
   EndOfFile = 9;
   NonModifiableKey = 10;
   InvalidFileName = 11;
   FileNotFound = 12;
   ExtendedFileError = 13;
   PreImageOpenError = 14;
   PreImageIoError = 15;
   ExpansionError = 16;
   CloseError = 17;
   DiskFull = 18;
   UnrecoverableErr = 19;
   BTRNotLoaded = 20;
   Conflict     = 80;

TYPE
   PosBlock =  ARRAY[1..128] OF BYTE;
   KeyBufType = ARRAY[1..KeyLength] OF CHAR;

(* ---------------------------------------------- *)
PROCEDURE BTRString(var Dest;len : BYTE; Source : string);
{ Converts Turbo strings to ARRAY OF CHAR without length byte   }
{ Dest will be filled up to LEN, excess is lost, surplus padded }
{ with #0.                                                      }

(* ---------------------------------------------- *)
PROCEDURE TurboString(VAR Dest : String; len : BYTE; VAR Source);
{ Converts ARRAY OF CHAR without length byte to Turbo String  }
{ Dest will be filled up to LEN, excess is lost, surplus padded }
{ with #0.                                                      }

(* ---------------------------------------------- *)
PROCEDURE AssignKey(var Dest : KeyBufType; Source : string);
{ Converts Turbo strings to valid BTRIEVE key buffer }

(* ---------------------------------------------- *)
function BTRV (OpCode : integer; var POS, DataBuf; var BufLen: integer;
	       var KeyBuf : KeyBufType; Key: integer): integer;

{======================================================================}
implementation

(* ---------------------------------------------- *)
PROCEDURE TurboString(VAR Dest : String; len : BYTE; VAR Source);

BEGIN

   { copy string bytes from first data byte }
   IF len > 255 THEN
      len := 255;

   Move(Source,Dest[1],len);
   Dest[0] := chr(len);

END (* TurboString *);


(* ---------------------------------------------- *)
PROCEDURE BTRString(var Dest;len : BYTE; Source : string);
{ Converts Turbo strings to ARRAY OF CHAR without length byte   }
{ Dest will be filled up to LEN, excess is lost, surplus padded }
{ with #0.                                                      }

CONST
  PadChar = #0;

VAR
  n, stop : INTEGER;

BEGIN
   { pad with null char }
   FillChar(Dest,len,PadChar);

   { copy string bytes from first data byte }
   IF ORD(Source[0]) > len THEN
      n := len
   ELSE
      n := ORD(Source[0]);

   Move(Source[1],Dest,n);

   (*
   n := 1;
   stop := ord(Source[0])+1;  { length of Source + 1 }
   WHILE n <  stop DO
   BEGIN
     Dest[n] := Source[n];
     inc(n);
   END;
*)
END (* BTRString *);

(* ---------------------------------------------- *)
PROCEDURE AssignKey(var Dest : KeyBufType; Source : string);
{ Converts Turbo strings to valid BTRIEVE key buffer }

BEGIN
   BTRString(Dest,SIZEOF(KeyBufType),Source);
END (* AssignKey *);
(* ---------------------------------------------- *)

function BTRV (OpCode : integer; var POS, DataBuf; var BufLen: integer;
	       var KeyBuf : KeyBufType; Key: integer): integer;

const
     VAR_ID		= $6176;	{id for variable length records - 'va'}
     BTR_INT		= $7B;
     BTR2_INT		= $2F;
     BTR_OFFSET 	= $0033;
     MULTI_FUNCTION	= $AB;

{  ProcId is used for communicating with the Multi Tasking Version of	      }
{  Btrieve. It contains the process id returned from BMulti and should	      }
{  not be changed once it has been set. 				      }
{									      }
     ProcId: integer = 0;			{ initialize to no process id }
     MULTI: boolean = false;		    { set to true if BMulti is loaded }
     VSet: boolean = false;	  { set to true if we have checked for BMulti }

type
     ADDR32 = record					       {32 bit address}
	OFFSET: integer;
	SEGMENT: integer;
     end;

     BTR_PARMS = record
	USER_BUF_ADDR: ADDR32;				  {data buffer address}
	USER_BUF_LEN: integer;				   {data buffer length}
	USER_CUR_ADDR: ADDR32;			       {currency block address}
	USER_FCB_ADDR: ADDR32;			   {file control block address}
	USER_FUNCTION: integer; 			    {Btrieve operation}
	USER_KEY_ADDR: ADDR32;				   {key buffer address}
	USER_KEY_LENGTH: BYTE;				    {key buffer length}
	USER_KEY_NUMBER: BYTE;					   {key number}
	USER_STAT_ADDR: ADDR32; 			{return status address}
	XFACE_ID: integer;				{language interface id}
     end;

var
     STAT: integer;					 {Btrieve status code}
     XDATA: BTR_PARMS;				     {Btrieve parameter block}
     REGS: Dos.Registers;	  {register structure used on interrrupt call}
     DONE: boolean;

begin
     REGS.AX := $3500 + BTR_INT;
     INTR ($21, REGS);
     if (REGS.BX <> BTR_OFFSET) then	      {make sure Btrieve is installed}
	STAT := 20
     else
	begin
	   if (not VSet) then	{if we haven't checked for Multi-User version}
	      begin
		 REGS.AX := $3000;
		 INTR ($21, REGS);
		 if ((REGS.AX AND $00FF) >= 3) then
		    begin
		       VSet := true;
		       REGS.AX := MULTI_FUNCTION * 256;
		       INTR (BTR2_INT, REGS);
		       MULTI := ((REGS.AX AND $00FF) = $004D);
		    end
		 else
		    MULTI := false;
	      end;
						    {make normal btrieve call}
	   with XDATA do
	      begin
		 USER_BUF_ADDR.SEGMENT := SEG (DataBuf);
		 USER_BUF_ADDR.OFFSET := OFS (DataBuf); {set data buffer address}
		 USER_BUF_LEN := BufLen;
		 USER_FCB_ADDR.SEGMENT := SEG (POS);
		 USER_FCB_ADDR.OFFSET := OFS (POS);	     {set FCB address}
		 USER_CUR_ADDR.SEGMENT := USER_FCB_ADDR.SEGMENT; {set cur seg}
		 USER_CUR_ADDR.OFFSET := USER_FCB_ADDR.OFFSET+38;{set cur ofs}
		 USER_FUNCTION := OpCode;		  {set Btrieve operation code}
		 USER_KEY_ADDR.SEGMENT := SEG (KeyBuf);
		 USER_KEY_ADDR.OFFSET := OFS (KeyBuf);  {set key buffer address}
		 USER_KEY_LENGTH := KeyLength;	     {assume its large enough}
		 USER_KEY_NUMBER := Key;		      {set key number}
		 USER_STAT_ADDR.SEGMENT := SEG (STAT);
		 USER_STAT_ADDR.OFFSET := OFS (STAT);	  {set status address}
		 XFACE_ID := VAR_ID;			     {set lamguage id}
	      end;

	   REGS.DX := OFS (XDATA);
	   REGS.DS := SEG (XDATA);

	   if (NOT MULTI) then		     {MultiUser version not installed}
	      INTR (BTR_INT, REGS)
	   else
	      begin
		 DONE := FALSE;
		 repeat
		    REGS.BX := ProcId;
		    REGS.AX := 1;
		    if (REGS.BX <> 0) then
		       REGS.AX := 2;
		    REGS.AX := REGS.AX + (MULTI_FUNCTION * 256);
		    INTR (BTR2_INT, REGS);
		    if ((REGS.AX AND $00FF) = 0) then
		       DONE := TRUE
		    else begin
		       REGS.AX := $0200;
		       INTR ($7F, REGS);
		       DONE := FALSE;
		    end;
		 until (DONE);
		 if (ProcId = 0) then
		    ProcId := REGS.BX;
	      end;
	   BufLen := XDATA.USER_BUF_LEN;
	end;
     BTRV := STAT;
end {BTRV};
{ --------------------------------------------------------------------}

END {BRTIEVE}.

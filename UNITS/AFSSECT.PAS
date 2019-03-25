UNIT afsSect;

INTERFACE


function GetSector( secfield, secnum : BYTE;
                     short : BOOLEAN) : STRING;

procedure RemapSect(VAR sec1 : BYTE; VAR sec2 : BYTE;VAR sec3 : BYTE);

implementation

TYPE
  Codes = ARRAY[0..1] OF CHAR;

CONST
  Sec1Array : ARRAY[0..8] OF STRING[30] = (
'NA NOT SPECIFIED',
'HY',
'US',
'MU',
'CB',
'AG',
'MB',
'FO',
'HD'
);

  Sec2Array : ARRAY[0..112] OF STRING[30] = (
'NA NOT SPECIFIED',
' 1',
' 2',
' 3',
' 4',
' 5',
' 6',
' 7',
' 8',
' 9',
'10',
'11',
'12',
'13',
'14',
'15',
'16',
'17',
'18',
'19',
'20',
'21',
'22',
'23',
'24',
'25',
'26',
'27',
'28',
'29',
'30',
'31',
'32',
'33',
'34',
'35',
'36',
'37',
'38',
'39',
'40',
'41',
'42',
'43',
'44',
'45',
'46',
'47',
'48',
'49',
'50',
'51',
'52',
'53',
'54',
'55',
'56',
'57',
'58',
'59',
'60',
'61',
'62',
'63',
'64',
'65',
'66',
'67',
'68',
'69',
'70',
'71',
'72',
'73',
'74',
'75',
'76',
'77',
'78',
'79',
'80',
'81',
'82',
'83',
'84',
'85',
'86',
'87',
'88',
'89',
'90',
'91',
'92',
'93',
'94',
'95',
'96',
'97',
'98',
'99',
'GN',
'G2',
'FN',
'FH',
'BD',
'NT',
'OP',
'FU',
'AU',
'CN',
'UK',
'IT',
'US'
);

Sec1New : ARRAY[0..8] OF BYTE = ( 0,11,10,9,11,10,12,13,14);

Sec2New : ARRAY[0..44] OF BYTE = (
{  0 }   0 { NOT SPECIFIED},
{  1 }   1 { AEROSPACE/DEFENSE},
{  2 }   2 { AIR TRANSPORTATION},
{  3 }   3 { AUTO/VEHICLE},
{  4 }   4 { BANKS/SAVINGS & LOANS},
{  5 }   6 { BUILDING MATERIALS},
{  6 }   5 { CABLE/BROADCASTING},
{  7 }   7 { CHEMICALS/PLASTICS},
{  8 }   8 { CONSUMER PRODUCTS},
{  9 }   9 { CONTAINERS},
{ 10 }  16 { DATA PROCESSING/ELECTRONICS},
{ 11 }  18 { DIVERSE MANUFACTURING},
{ 12 }  35 { DIVERSIFIED},
{ 13 }  17 { FILMED ENTERTAINMENT},
{ 14 }  12 { FOOD/BEVERAGE},
{ 15 }  13 { GAMING},
{ 16 }  14 { HEALTHCARE FAC./SUPPLIES},
{ 17 }  15 { HOMEBUILDERS},
{ 18 }  11 { INSURANCE FINANCIAL},
{ 19 }  17 { LEISURE/AMUSEMENT},
{ 20 }  13 { LODGING},
{ 21 }  18 { MACHINERY},
{ 22 }  20 { OFFICE EQUIPMENT},
{ 23 }  21 { OIL & GAS: FIELD SERVICES},
{ 24 }  22 { OIL & GAS: INTEGRATED},
{ 25 }  23 { OIL & GAS: PRODUCTION},
{ 26 }  24 { OIL & GAS: REFINING},
{ 27 }  10 { PAPER},
{ 28 }  25 { PUBLISHING},
{ 29 }  26 { RAILROADS/EQUIPMENT},
{ 30 }  15 { REAL ESTATE/DEVELOPMENT},
{ 31 }  12 { RESTAURANTS},
{ 32 }  29 { RETAIL: BUILDING SUPPLIES},
{ 33 }  27 { RETAIL: FOOD AND DRUG},
{ 34 }  28 { RETAIL: GENERAL},
{ 35 }  29 { RETAIL: SPECIALTY},
{ 36 }  30 { SERVICES},
{ 37 }  33 { SHIPPING/TRANSPORTATION},
{ 38 }  19 { STEEL/MINING},
{ 39 }  31 { TELECOMMUNICATIONS},
{ 40 }  32 { TEXTILE/APPAREL},
{ 41 }  34 { UTILITIES},
{ 42 }  35 { OTHER CORPORATE},
{ 43 }   1 { Foreign Govt.},
{ 44 }   1 { US Treasury}
);

CountryCode : ARRAY[0..36] OF Codes = (

'US' {  0  US/DOLLAR},
'AD' {  1  AUSTRALIA/$},
'AS' {  2  AUSTRIA/SCHILLING},
'BD' {  3  BAHRAIN/DINAR},
'BF' {  4  BELGIUM/FRANC},
'BK' {  5  BURMA/KYAT},
'CD' {  6  CANADA/DOLLAR},
'DK' {  7  DENMARK/KRONER},
'DM' {  8  GERMANY/MARK},
'EC' {  9  EURO CURR UNIT},
'FF' { 10  FRANCE/FRANC},
'FM' { 11  FINLAND/MARKKA},
'GD' { 12  GREECE/DRACHMA},
'HK' { 13  HONG KONG/$},
'IL' { 14  ITALY/LIRA},
'IP' { 15  IRELAND/PUNT},
'IR' { 16  INDIA/RUPEE},
'JY' { 17  JAPAN/YEN},
'KD' { 18  KUWAIT/DINAR},
'MR' { 19  MALAYSIA/RINGGIT},
'MX' { 36  Multi-Currency},
'NG' { 20  NETH/GUILDER},
'NK' { 21  NORWAY/KRONER},
'NZ' { 22  NEW ZEALAND/$},
'PE' { 23  PORTUGAL/ESCUDO},
'PK' { 24  PAKISTAN/RUPEE},
'SA' { 25  SAUDI/RIYAL},
'SD' { 26  SINGAPORE/$},
'SF' { 27  SWITZ/FRANC},
'SK' { 28  SWEDEN/KRONER},
'SL' { 29  SRI LANKA/RUPEE},
'SO' { 30  S AFRICA/RAND},
'SP' { 31  SPAIN/PESATA},
'TB' { 32  THAILAND/BHAT},
'UD' { 33  UAE/DIRHAM},
'UG' { 34  UGANDA/SCHILLING},
'UK' { 35  BRITAIN/POUND}
);


function GetSector( secfield, secnum : BYTE;
                     short : BOOLEAN) : STRING;
VAR
 tempstr : string;
BEGIN
  CASE secfield OF
    1: tempstr := Sec1Array[secnum];
    2: tempstr := Sec2Array[secnum];
  END;

  IF Short THEN
    GetSector := copy(tempstr,1,2)
  ELSE
    GetSector := tempstr;
END;

procedure RemapSect(VAR sec1 : BYTE; VAR sec2 : BYTE;VAR sec3 : BYTE);
BEGIN
  IF sec2 > 44 THEN
  BEGIN
     CASE sec2 OF
       108                 : sec3 := 1;
       109                 : sec3 := 6;
       110                 : sec3 := 35;
       111                 : sec3 := 14;
       112                 : sec3 := 36;
       113                 : sec3 := 22;
       114                 : sec3 := 10;
       115                 : sec3 := 7;
       116                 : sec3 := 28;
     END;

     CASE sec2 OF
       100,101,104,105,106 : sec2 := 1;
       102,103,107         : sec2 := 2;
     ELSE
       sec2 := 0;
     END
  END
  ELSE
      sec2 := sec2New[sec2];

  CASE sec1 OF
     2 : sec2 := 1;
     5 : sec2 := 3;
  END;
  sec1 := sec1new[sec1];

END {RemapSect};

END.

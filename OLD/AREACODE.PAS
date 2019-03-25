PROGRAM AreaCode;

TYPE
  ACArray = ARRAY[0..999] OF String[50];

VAR
   AC : ACArray;


PROCEDURE AssignACs;

VAR
  n : WORD;

BEGIN
    FOR n := 0 TO 999 DO
       AC[n] := 'NV';
    AC [205] := 'Alabama';
    AC [907] := 'Alaska';
    AC [602] := 'Arizona';
    AC [501] := 'Arkansas';
    AC [213] := 'Los Angeles CA';
    AC [209] := 'central California';
    AC [415] := 'California - greater San Francisco area';
    AC [408] := 'California - south of San Franscisco';
    AC [707] := 'northwestern California';
    AC [714] := 'California - south of Los Angeles';
    AC [805] := 'California - north of Los Angeles';
    AC [818] := 'California - greater Los Angeles area';
    AC [916] := 'northeastern California';
    AC [619] := 'southern and eastern California';
    AC [303] := 'northern Colorado';
    AC [719] := 'southern Colorado';
    AC [203] := 'Connecticut';
    AC [302] := 'Delaware';
    AC [202] := 'Washington DC';
    AC [305] := 'southern Florida Atlantic coast';
    AC [813] := 'southern Florida Gulf coast';
    AC [904] := 'northern Florida both coast';
    AC [404] := 'northern Georgia';
    AC [912] := 'south Georgia';
    AC [808] := 'Hawaii';
    AC [208] := 'Idaho';
    AC [217] := 'central Illinois';
    AC [309] := 'west central Illinois';
    AC [312] := 'northeast Illinois';
    AC [618] := 'southern Illinois';
    AC [219] := 'northern Indiana';
    AC [317] := 'central Indiana';
    AC [812] := 'southern Indiana';
    AC [319] := 'eastern Iowa';
    AC [515] := 'central Iowa';
    AC [712] := 'western Iowa';
    AC [316] := 'southern Kansas';
    AC [913] := 'northern Kansas';
    AC [502] := 'western Kentucky';
    AC [606] := 'eastern Kentucky';
    AC [318] := 'southeastern Louisiana';
    AC [504] := 'western Louisiana';
    AC [207] := 'Maine';
    AC [301] := 'Maryland';
    AC [413] := 'western Massachusetts';
    AC [617] := 'eastern Massachusetts';
    AC [313] := 'east Michigan';
    AC [517] := 'east central Michigan';
    AC [616] := 'west central Michigan';
    AC [906] := 'western Michigan';
    AC [507] := 'southern Minnesota';
    AC [612] := 'south central Minnesota';
    AC [218] := 'northern Minnesota';
    AC [601] := 'Mississippi';
    AC [314] := 'southeastern Missouri';
    AC [417] := 'southwestern Missouri';
    AC [816] := 'northern Missouri';
    AC [406] := 'Montana';
    AC [308] := 'western Nebraska';
    AC [402] := 'eastern Nebraska';
    AC [702] := 'Nevada';
    AC [603] := 'New Hampshire';
    AC [201] := 'northern New Jersey';
    AC [908] := 'central New Jersey';
    AC [609] := 'southern New Jersey';
    AC [505] := 'New Mexico';
    AC [212] := 'New York City - Manhattan / Bronx';
    AC [315] := 'north central New York';
    AC [516] := 'Long Island NY';
    AC [518] := 'northeastern New York';
    AC [607] := 'south central New York';
    AC [716] := 'western New York';
    AC [718] := 'New York City - Brooklyn/Queens/Staten Isle';
    AC [914] := 'southern New York';
    AC [704] := 'western North Carolina';
    AC [919] := 'eastern North Carolina';
    AC [701] := 'North Dakota';
    AC [216] := 'northeastern Ohio';
    AC [419] := 'northwestern Ohio';
    AC [513] := 'southwestern Ohio';
    AC [614] := 'southeastern Ohio';
    AC [405] := 'west and southeast Oklahoma';
    AC [918] := 'northeastern Oklahoma';
    AC [503] := 'Oregon';
    AC [215] := 'southeastern Pennsylvania';
    AC [412] := 'southwestern Pennsylvania';
    AC [717] := 'east central Pennsylvania';
    AC [814] := 'west central Pennsylvania';
    AC [401] := 'Rhode Island';
    AC [803] := 'South Carolina';
    AC [605] := 'South Dakota';
    AC [615] := 'central and east Tennessee';
    AC [901] := 'western Tennessee';
    AC [214] := 'northeastern Texas';
    AC [512] := 'south Texas';
    AC [713] := 'Texas - greater Houston area';
    AC [903] := 'Texas - greater Dallas area';
    AC [806] := 'northern Texas panhandle area';
    AC [817] := 'north central Texas';
    AC [915] := 'southwestern Texas';
    AC [801] := 'Utah';
    AC [802] := 'Vermont';
    AC [703] := 'northern and western Virginia';
    AC [804] := 'southeastern Virginia';
    AC [206] := 'western Washington';
    AC [509] := 'eastern Washington';
    AC [304] := 'West Virginia';
    AC [414] := 'east Wisconsin';
    AC [608] := 'southwestern Wisconsin';
    AC [715] := 'northern Wisconsin';
    AC [307] := 'Wyoming';
    AC [809] := 'US Territories - Virgin Isles/Bahamas/PR';
    AC [403] := 'Alberta Canada';
    AC [604] := 'British Columbia Canada';
    AC [204] := 'Manitoba Canada';
    AC [506] := 'New Brunswick Canada';
    AC [709] := 'Newfoundland Canada';
    AC [902] := 'Nova Scotia and Pr. Edward Isl. Canada';
    AC [807] := 'Fort William - Ontario Canada';
    AC [519] := 'London - Ontario Canada';
    AC [705] := 'North Bay - Ontario Canada';
    AC [613] := 'Ottawa - Ontario Canada';
    AC [807] := 'Thunder Bay - Ontario Canda';
    AC [416] := 'Toronto - Ontario Canada';
    AC [514] := 'Montreal - Quebec Canada';
    AC [418] := 'Quebec - Quebec Canada';
    AC [819] := 'Sherbrooke - Quebec Canada';
    AC [306] := 'Saskatchewan Canada';
    AC [684] := 'American Samoa';
    AC [54 ] := 'Argentina';
    AC [61 ] := 'Australia';
    AC [43 ] := 'Austria';
    AC [973] := 'Bahrain';
    AC [32 ] := 'Belgium';
    AC [591] := 'Bolivia';
    AC [55 ] := 'Brazil';
    AC [237] := 'Cameroon';
    AC [56 ] := 'Chile';
    AC [57 ] := 'Columbia';
    AC [357] := 'Cyprus';
    AC [42 ] := 'Czechoslovakia';
    AC [45 ] := 'Denmark';
    AC [593] := 'Ecuador';
    AC [20 ] := 'Egypt';
    AC [251] := 'Ethiopia';
    AC [679] := 'Fiji';
    AC [358] := 'Finland';
    AC [33 ] := 'France';
    AC [596] := 'French Antilles';
    AC [689] := 'French Polynesia';
    AC [241] := 'Gabon';
    AC [37 ] := 'German Democratic Republic';
    AC [49 ] := 'Federal Republic of Germany';
    AC [30 ] := 'Greece';
    AC [671] := 'Guam';
    AC [53 ] := 'Guantanamo Bay';
    AC [592] := 'Guyana';
    AC [852] := 'Hong Kong';
    AC [36 ] := 'Hungary';
    AC [354] := 'Iceland';
    AC [91 ] := 'India';
    AC [62 ] := 'Indonesia';
    AC [98 ] := 'Iran';
    AC [964] := 'Iraq';
    AC [353] := 'Ireland';
    AC [972] := 'Israel';
    AC [39 ] := 'Italy';
    AC [225] := 'Ivory Coast';
    AC [81 ] := 'Japan';
    AC [962] := 'Jordon';
    AC [254] := 'Kenya';
    AC [82 ] := 'Republic of Korea';
    AC [965] := 'Kuwait';
    AC [231] := 'Liberia';
    AC [352] := 'Luxembourg';
    AC [265] := 'Malawi';
    AC [60 ] := 'Malaysia';
    AC [52 ] := 'Mexico';
    AC [264] := 'Namibia';
    AC [31 ] := 'Netherlands';
    AC [599] := 'Nethrlands Antilles';
    AC [687] := 'New Caledonia';
    AC [64 ] := 'New Zealand';
    AC [234] := 'Nigeria';
    AC [47 ] := 'Norway';
    AC [968] := 'Oman';
    AC [92 ] := 'Pakistan';
    AC [675] := 'Papua New Guinea';
    AC [595] := 'Paraquay';
    AC [51 ] := 'Peru';
    AC [63 ] := 'Philippines';
    AC [48 ] := 'Poland';
    AC [351] := 'Portugal';
    AC [974] := 'Qatar';
    AC [40 ] := 'Romania';
    AC [670] := 'Saipan';
    AC [966] := 'Saudia Arabia';
    AC [221] := 'Senegal';
    AC [65 ] := 'Singapore';
    AC [27 ] := 'South Africa';
    AC [34 ] := 'Spain';
    AC [94 ] := 'Sri Lanka';
    AC [597] := 'Suriname';
    AC [46 ] := 'Sweden';
    AC [41 ] := 'Switzerland';
    AC [886] := 'Taiwan';
    AC [66 ] := 'Thailand';
    AC [90 ] := 'Turkey';
    AC [971] := 'United Arab Emirates';
    AC [44 ] := 'United Kingdom';
    AC [598] := 'Uruguay';
    AC [58 ] := 'Venezuela';
    AC [967] := 'Yemen Arab Republic';
    AC [38 ] := 'Yugoslavia';
END;

PROCEDURE ShowHelp;
BEGIN
  writeln('Displays location of Area Code or Area Code for location');
  writeln('usage: AREACODE <number or location>');
END;

PROCEDURE SearchByAreaCode(ACNum : WORD);

BEGIN
      IF ACNum > 999 THEN
         Writeln('You must a number less than 999')
      ELSE
      BEGIN
        AssignACs;
        IF AC[ACNum] = 'NV' THEN
            Writeln(ACNum, ' is not an actual Area Code')
         ELSE
           Writeln(ACNum,' is in ',AC[ACNum]);
      END;
END {SearchByAreaCode};

PROCEDURE SearchByLocation(lstr : STRING);
VAR
  found : BOOLEAN;
  i, n : WORD;

BEGIN
    AssignACs;
    found := FALSE;
{
    FOR i := 1 to Length(lstr) DO
      lstr[i] := UpCase(lstr[i]);
}
    lstr[1] := upcase(lstr[1]);

    FOR n := 0 TO 999 DO
       IF NOT (AC[n] = 'NV') AND (pos(lstr,AC[n]) > 0) THEN
       BEGIN
          writeln(AC[n],' is',n:4);
          found := TRUE;
       END;
    IF not found THEN
       writeln('No match found for ',lstr);
END {SearchByLocation};

VAR
  err : INTEGER;
  ACNum : WORD;

BEGIN
  IF paramcount = 0 THEN
  BEGIN
    ShowHelp;
    HALT;
  END;

  val(paramstr(1),ACNum,err);
  IF err > 0 THEN
      SearchByLocation(paramstr(1))
  ELSE
      SearchByAreaCode(ACNum);
END.
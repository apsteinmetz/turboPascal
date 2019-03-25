{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program Anagram;

{Copyright 1985 by Bob Keefer}

{Anagram.Pas takes a word of up to 10 letters from
the keyboard and rearranges the letters into every
possible permutation, or anagram, of the word.}

{It then evaluates the likelihood that each anagram
is an English word by looking up every trigram in
the word in a probability table, which is stored in
a separate file PROB.DAT and is read into the array
Probability[X,Y,Z]. Finally, it records the top
scoring anagrams in Scoreboard and prints them to
the screen.}

{The program must be compiled with the Turbo
 "c" compiler option to a *.COM file.}

(*
{ $A-} {compiler directive for recursion}
!{!^ 1. Directives A,B,C,D,F,G,P,U,W,X are obsolete or changed in meaning}
{ $C-} {.... ignore ^C and ^S breaks}
!{!^ 2. Directives A,B,C,D,F,G,P,U,W,X are obsolete or changed in meaning}
*)

{$I-} {.... no i/o checking}
{$V-} {.... no string checking}




Uses
  Crt;

const
     MaxLength = 13;   {biggest word + 3}
     MaxScores = 200 ;  {how many winners to store}
     LinesPerPage = 20;

type
    ScoreLine = record {One line of the Scoreboard}
              Winner : string[MaxLength] ;
              Points : WORD ;
              end;

var
   AWord        : array [1..Maxlength] of char;  {Word to permute}
   Wordlength  : WORD; {Length of Word}
   Probability : array [0..26,0..26,0..26] of WORD;
   ScoreBoard  : array [1..MaxScores] of ScoreLine;
   WordToScore : string[Maxlength]; {anagram}
   DataFile    : file of WORD; {probability table}
   TheWord     : String[Maxlength]; {Word as string}
   I           : WORD; {counter}

   OutFile     : text;

procedure Score;

var
   X,Y,Z        : INTEGER;
   I,J          : WORD ;
   Total        : WORD ;
   Unlikelihood : WORD;


   procedure KeepScore;

    var
       N : WORD;

       procedure ChalkItUp;
           var
                TempScore, I : WORD;
                TempName : String[MaxLength];

       begin  {ChalkItUp}
           for I := N to MaxScores do
           begin
                with ScoreBoard[I] do   {If an anagram}
                if Total>Points then    {scores better,}
                begin                   {then record it...}
                     begin
                          TempScore := Points;
                          TempName := Winner;
                          Points := Total;
                          Winner := WordToScore
                     end;
                     if I<>MaxScores then

                     begin {..bump the rest down}
                          with ScoreBoard[I+1] do
                          begin
                               WordToScore := TempName;
                               Total := TempScore;
                          end;
                     end;
                end;
           end;
       end;   {ChalkItUp}


begin {KeepScore}
      for N := 1 to MaxScores do
      begin
           if WordToScore = ScoreBoard[N].Winner
              then Total := 0; {eliminate duplicates}
           if (Total > ScoreBoard[N].Points)
               then ChalkItUp;
           {record good-scoring words}
      end;
end;  {KeepScore}


begin {procedure Score}
     WordToScore := ' ' + WordToScore + ' ';
     Total := 0;
     Unlikelihood := 0;
     for I := 1 to length(WordToScore) -2 do
     begin
          X := ord(WordToScore[I])-64;
          Y := ord(WordToScore[I+1])-64;
          Z := ord(WordToScore[I+3])-64;
          if X<0 then X:=0;
          if Y<0 then Y:=0;
          if Z<0 then Z:=0;

          Total := Total + Probability[X,Y,Z];
          if Probability[X,Y,Z]=0 then Unlikelihood := succ(Unlikelihood);
     end;
     for J := 1 to Unlikelihood do Total := Total div 2;
     KeepScore;
end;  {procedure Score}



procedure Permute (CurrentLength : WORD);

var
   i : WORD;

   procedure Switch;
   var
      Temp : char;
   begin
        Temp := AWord[CurrentLength];
        AWord[CurrentLength] := AWord[I];
        AWord[I] := Temp;
   end; {Switch}


   procedure Outword;
   VAR
      j : WORD;

      begin
         WordToScore:='';
         FOR j := 1 to Wordlength do
         WordToScore := WordToScore + AWord[j];
      end; {Outword}

begin {Permute body}
      if CurrentLength = 1
      then begin
                Outword;
                Score;
           end
      else for i := 1 to CurrentLength do
          begin
               Switch;
               Permute(CurrentLength - 1);
               Switch;
          end;
end; {Permute}


procedure GetInput;

var
  I : WORD;

begin
     write('Enter word: ');
     readln(TheWord);
     WordLength := length(TheWord);
     for I := 1 to WordLength do
     begin
          AWord[I] := upcase(TheWord[I]);
     end;
     TheWord := '';
     for I := 1 to WordLength do
         TheWord := TheWord + AWord[I];

end; {procedure GetInput}

procedure ZeroScore;
var I : WORD;

begin
     for I:= 1 to MaxScores do
     begin
          with ScoreBoard[I] do
          begin
               Points := 0;
               Winner := '';
          end;
     end; {with}
end; {ZeroScore}


procedure PostScore;

var
   I,j   : WORD;
   GotIt : boolean;

begin
     GotIt:=false;
     j := 0;
     for I := 1 to MaxScores do
     begin
          with ScoreBoard[I] do
          begin
               if Points>0 then
               begin
                 j := j + 1;
                 writeln(I:2, ' ',Winner, '  ', Points);
                 writeln(OutFile,I:2, ' ',Winner, '  ', Points);
               end; {if Points}
          end; {with}
     end; {for loop}
end; {procedure PostScore}

procedure ReadProb;

var X,Y,Z : WORD;

begin
     assign(Datafile,'PROB.DAT');
     reset(DataFile);
     for X := 0 to 26 do begin
         write('*');
         for Y := 0 to 26 do begin
             for Z := 0 to 26 do begin
                  read(Datafile,Probability[X,Y,Z]);
             end;
         end;
     end;
     close(Datafile);
     writeln;
end;  {procedure ReadProb}


procedure SignOn;
begin
     clrscr;
     writeln('Anagram.Pas');
     writeln('By Bob Keefer');
     writeln('Copyright 1985');
     writeln;
     writeln;
     writeln('To halt program, enter "*"');
     writeln;
     writeln;
     writeln;
     writeln('Reading Probability Table...');
end; {procedure Signon}


begin {Anagram program}
      SignOn;      {Display signon message}
      ReadProb;    {Read probability table}
      clrscr;
      assign(OutFile,'ANAGRAM.TXT');
      rewrite(OutFile);
      repeat
            GetInput;               {Get word}
            ZeroScore;              {clear Scoreboard}
            Permute (Wordlength);   {Evaluate words}
            writeln;
            PostScore;              {Print results}
            writeln;
            writeln;
      until AWord[1]='*';
      close(outfile);
end.

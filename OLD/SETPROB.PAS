{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program SetProb;

    {Copyright 1985 by Bob Keefer}

    {SetProb.Pas creates a 3-dimensional byte
    array, Probability[X,Y,Z], in which are stored
    the relative probability of each 3-letter
    trigram found in an input text.

    Once the table is completed, it is stored in
    the disc file PROB.DAT.}

    {To use this program to add more data to an
    existing version of PROB.DAT, modify procedure
    ZeroProb so that it reads Probability[X,Y,Z]
    from PROB.DAT instead of zeroing the array.
    This can be done by commenting out the lines
    marked with a single * and restoring the lines
    marked with a double **.}



Uses
  Crt;

var
   Ch1, Ch2, Ch3 : char;
   X, Y, Z : integer;
   Filename : string[15];
   TheFile : text;
   Datafile : file of integer;
   Probability : array [0..26,0..26,0..26] of integer;

procedure ZeroProb;

var
   X,Y,Z : integer;
begin
     {assign (Datafile,'Prob.dat');} {**}
     {reset(Datafile);}   {**}
     for X:=0 to 26 do begin
         for Y:=0 to 26 do begin
             for Z:= 0 to 26 do begin
                 {*} Probability[X,Y,Z] := 0;
                 {**} {read(Datafile,Probability[X,Y,Z]);}
             end;
         end;
     end;
     {close (Datafile);} {**}
end; {ZeroProb}


procedure ScaleProb;

var
   X,Y,Z : integer;

begin
     for X:=0 to 26 do begin
         for Y:=0 to 26 do begin
             for Z:= 0 to 26 do begin
                 Probability[X,Y,Z] :=
                    (Probability[X,Y,Z] + 1)
                      div 2;
             end;
         end;
     end;
end; {ScaleProb}


procedure StartUp;

begin
   clrscr;
   writeln('SetProb.Pas');
   writeln('Copyright 1985 by Bob Keefer');
   writeln;
   write ('Enter filename: ');
   readln (Filename);
   assign (TheFile, Filename);
   reset (TheFile);
end;

function Cleanup ( A : integer ) : integer;

begin
     if (A>64) and (A<91) then Cleanup := A-64
        else Cleanup := 0;
end; {function Cleanup}


procedure Countem;

begin
     Ch1 := #32;
     Ch2 := #32;
     while not EOF (TheFile) do
     begin
          read(TheFile,Ch3);
          X := Cleanup(ord(upcase(Ch1)));
          Y := Cleanup(ord(upcase(Ch2)));
          Z := Cleanup(ord(upcase(Ch3)));

          if not (((X=0) and (Y=0)) or
                  ((Y=0) and (Z=0)))
                  then Probability[X,Y,Z] :=
                  Probability[X,Y,Z] + 1;
          if Probability[X,Y,Z] >32000 then ScaleProb;
          Ch1:=Ch2;
          Ch2:=Ch3;
      end;
end;  {Countem}

procedure WriteData;
var X,Y,Z : integer;
begin
     for X := 0 to 26 do begin
         for Y := 0 to 26 do begin
             for Z := 0 to 26 do begin
                 write(Datafile,Probability[X,Y,Z]);
             end;
         end;
     end;
end; {procedure WriteData}


begin {program SetProb}
      ZeroProb;
      Startup;
      Countem;
      assign(Datafile,'Prob.dat');
      rewrite(Datafile);
      WriteData;
      close(DataFile);
      close(TheFile);
      write(#7);
end.

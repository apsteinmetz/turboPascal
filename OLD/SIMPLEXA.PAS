{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

Uses
  Crt;

procedure DirectOutput;
begin
   writeln('Direct output to Printer or Screen? ');
   readln(answer);
   if upcase(Copy(answer,1,1)) = 'P' then assign(OutFile,'LST:')
{! 1. Special filename LST: is not supported now. USE PRI^NTER Lst file.}
      else assign(OutFile,'CON:');
{! 2. Special filenames CO^N:, TRM:, AUX:, USR: are not supported in Turbo 4.0.}
   Reset(OutFile);
   writeln('Display iteration results? ');
   readln(answer);
   answer := UpCase(Copy(answer,1,1));
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure FIRST;
     begin
       writeln(OutFile,'Starting Simplex');
       for j := 1 to n do               {vertices}
         begin
           write(OutFile,'simplex[',j:1,']');
           for i := 1 to n do          {dimensions}
             begin
               if (i mod lw) = 0 then writeln(OutFile);
               write(OutFile,simp[j,i]:10:7)
             end;                       {dimensions}
           writeln(OutFile);
         end;                           {vertices}
     writeln(OutFile);
end;                                    {FIRST}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

procedure NewVertex;               {next in place of worst vertex}
     begin
         if Answer = 'Y' then write(OutFile,' --- ',NIter:4)
            else
                begin
                  GotoXY(70,2);
                  write(NIter:4)
                end;
         for i := 1 to n do
           begin
             simp[h[n],i] := next[i];
             if Answer = 'Y' then write(OutFile,next[i]);
           end;
       if Answer = 'Y' then writeln(OutFile);
     end;                          {NewVertex}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

procedure Order;         {gives hi/low in each parameter}
                         {caution: not initialized}
     var i, j    : index;

     begin
       for j := 1 to n do               {all dimensions}
         begin
           for i := 1 to n do           {of all vertices}
             begin
               if simp[i,j] < simp[L[j],j] then L[j] := i;
               if simp[i,j] > simp[H[j],j] then H[j] := i;
             end                        {i loop}
         end                            {j loop}
     end;                               {ORDER}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

{MAIN PROGRAM}
begin
     ChooseFile('.DAT');
     DirectOutput;
     Enter;
     TimeIn := Time;
     { INITIALIZE SIMPLEX 5/10/88 }
     for i := 1 to n do
          for j := 1 to n do
              simp[i,j] := 0;
     {}

     SumOfResiduals(simp[1]);           {first vertex}

     for i := 1 to m do                 {compute offset or vertices}
       begin                            {of the starting simplex}
         p[i] := step[i] * (sqrt(n) + m - 1) / (m * root2);
         q[i] := step[i] * (sqrt(n) - 1) / (m * root2)
       end;

     for i := 2 to n do                 {all vertices of the}
       begin                            {starting simplex}
         for j := 1 to m do simp[i,j] := simp[1,j] + q[j];
         simp[i,i - 1] := simp[1,i - 1] + p[i - 1];
         SumOfResiduals(simp[i]);
       end;

     for i := 1 to n do
       begin                            {preset}
         L[i] := 1; h[i] := 1
       end;                             {before calling}
     Order;

     First;

     NIter := 0;

     if Answer = 'N' then
       begin
          OldX := WhereX; OldY := WhereY;
          TextColor(Red + Blink);
          GotoXY(55,2);
          write('Iteration Count: ');
          TextColor(Red);
       end;

repeat
     done  := true;
     NIter := succ(NIter);

     for i := 1 to n do center[i] := 0.0;
     for i := 1 to n do                      {compute centroid}
       if i <> h[n] then                     {excluding the worst}
         for j := 1 to m do
           center[j] := center[j] + simp[i,j];

     for i := 1 to n do                      {attempt to reflect}
       begin
         center[i] := center[i] / m;
         next[i] := (1.0 + alfa) * center[i] - alfa * simp[h[n],i]
           {next vertex is specular reflection of the worst}
       end;
     SumOfResiduals(next);


     if next[n] <= simp[L[n],n] then
       begin                                 {better than the best ?}
         NewVertex;                          {accepted}
         for i := 1 to m do                  {and expanded}
           next[i] :=
             gamma * simp[h[n],i] + (1.0 - gamma) * center[i];
           SumOfResiduals(next);
           if next[n] <= simp[L[n],n] then NewVertex
       end                                   {expansion accepted}

     else
       begin
         if next[n] <= simp[h[n],n] then
             NewVertex                     {better than worst}
         else                              {worse than worst}
           begin
             for i := 1 to m do                  {and expanded}
             next[i] :=
             beta * simp[h[n],i] + (1.0 - beta) * center[i];
           SumOfResiduals(next);
           if next[n] <= simp[h[n],n] then NewVertex
           else                               {contraction accepted}
             begin                            {if still bad}
               for i := 1 to n do             {shrink all vertices}
                 begin
                   for j := 1 to m do
                     simp[i,j] :=
                           (simp[i,j] + simp[L[n],j]) * beta;
                   SumOfResiduals(simp[i])
                 end                          {i loop}
           end                                {else}
         end                                  {else}
     end;                                     {else}

     Order;
     for j := 1 to n do                      {check for convergence}
       begin
         error[j] :=
           (simp[h[j],j] - simp[L[j],j]) / simp[h[j],j];
         if done then
           if error[j] > maxerr[j] then
             done := false
       end

until (done or (NIter = MaxIter));

     for i := 1 to n do                      {average each parameter}
       begin
         mean[i] := 0.0;
         for j := 1 to n do
           mean[i] := mean[i] + simp[j,i];
           mean[i] := mean[i] / n;
       end;
     if Answer = 'N' then
       begin
         GotoXY(OldX,OldY);
         TextColor(Yellow)
       end;
     report;

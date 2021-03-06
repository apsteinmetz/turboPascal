Program Life;

USES CRT, DOS, Graph;

  Const
    Blank    = ' ';
    Aster    = '*';
    Dead     = 0;
    Alive    = 1;
    Hashsize = 9461;
    Hashmax  = 9460;

  Type
    Status = 0..1;
    Count  = 0..8;
    PCell  = ^Cell;
    PNode  = ^Node;
    Cell   = Record
               State    : Status;
               Numnbrs  : Count;
               Col      : Integer;
               Row      : Integer;
               NextCell : PCell
             End;
    Node   = Record
               Entry    : PCell;
               NextNode : PNode
             End;

  Var
    hashtable : array [0..hashmax] of pcell;
    live      : PNode;
    die       : PNode;
    nextlive  : PNode;
    nextdie   : PNode;
    availcell : pcell;
    availnode : pnode;
    initarray : array [1..80, 1..24] of status;
    gencount  : integer;
    OrigMode  : integer;

{ ----------------------------------------------------------------------}
  procedure newcell (var p : pcell);

    begin
      if availcell = nil then
        new (p)
      else
        begin
          p := availcell;
          availcell := p^.nextcell;
          p^.nextcell := nil
        end
    end; {newcell}

{ ----------------------------------------------------------------------}
  procedure freecell (p : pcell);

    begin
      p^.nextcell := availcell;
      availcell := p
    end; {freecell}

{ ----------------------------------------------------------------------}
  procedure newnode (var p : pnode);

    begin
      if availnode = nil then
        new (p)
      else
        begin
          p := availnode;
          availnode := p^.nextnode;
          p^.nextnode := nil;
          p^.entry:=nil
        end
    end; {newnode}

{ ----------------------------------------------------------------------}
  procedure freenode (p : pnode);

    begin
      p^.nextnode := availnode;
      p^.entry := nil;
      availnode := p
    end; {freenode}

{ ----------------------------------------------------------------------}
  procedure insert (var L : pnode;
                        x : pcell);
    var
      p : pnode;

    begin
      newnode (p);
      p^.nextnode := L;
      L := p;
      p^.entry := x
    end; {insert}

{ ----------------------------------------------------------------------}
  function hash (i, j : integer): integer;

    const
      factor = 101;

    begin
      hash := Abs (j + factor*i) mod hashsize
    end; {hash}

{ ----------------------------------------------------------------------}
  function getcell (i, j : integer): pcell;

    var
      p   : pcell;
      loc : integer;

    begin
      loc := hash (i, j);
      p := hashtable [loc];
      if p <> nil then
        begin
          while ((p^.row <> j) or (p^.col <> i)) and (p^.nextcell <> nil) do
            p := p^.nextcell;
          if (p^.row <> j) or (p^.col <> i) then
            p := nil
        end;
      if p <> nil then
        getcell := p
      else
        begin
          newcell (p);
          with p^ do
            begin
              row := j;
              col := i;
              state := dead;
              numnbrs := 0;
              nextcell := hashtable [loc];
              hashtable [loc] := p
            end;
          getcell := p
        end
    end; {getcell}

{ ----------------------------------------------------------------------}
  procedure removecell (i, j : integer);

    var
      loc  : integer;
      p, q : pcell;

    begin
      loc := hash (i, j);
      p := hashtable [loc];
      q := nil;
      while ((p^.row <> j) or (p^.col <> i)) and (p^.nextcell <> nil) do
        begin
          q := p;
          p := p^.nextcell
        end;
      if (p^.row <> j) or (p^.col <> i) then
        writeln ('Error!')
      else if q = nil then
        if p^.nextcell = nil then
          begin
            hashtable [loc] := nil;
            freecell (p)
          end
        else
          begin
            hashtable [loc] := p^.nextcell;
            freecell (p)
          end
       else
         begin
           q^.nextcell := p^.nextcell;
           freecell (p)
         end
    end; {removecell}

{ ----------------------------------------------------------------------}
  procedure neighboradj (i, j, k : integer);

    var
      cellptr : pcell;
      i0, j0  : integer;

    begin
      for i0 := i-1 to i+1 do
        for j0 := j-1 to j+1 do
          begin
            cellptr := getcell (i0, j0);
            with cellptr^ do
              begin
                if (i <> i0) or (j <> j0) then
                  numnbrs := numnbrs + k;
                if (state = dead) and (numnbrs = 3) then
                  insert (live, cellptr);
                if (state = alive) and ((numnbrs < 2) or (numnbrs > 3)) then
                  insert (die, cellptr)
              end
          end
    end; {neighboradj}

{ ----------------------------------------------------------------------}
  procedure setup;

    var
      params  : registers;
      done    : boolean;
      scan,
      char,
      i, j    : integer;
      cellptr : pcell;
      grDriver : Integer;
      grMode   : Integer;

    begin {setup}
      for i := 0 to hashmax do
        hashtable [i] := nil;
      for i := 1 to 80 do
        for j := 1 to 24 do
          initarray [i, j] := 0;
      live := nil;
      die := nil;
      nextlive := nil;
      nextdie := nil;
      availcell := nil;
      availnode := nil;
      clrscr;
      gotoxy (40, 12);
      done := false;
      while not done do
        begin
          params.AX := 0;
          intr (22, params);
          scan := hi (params.AX);
          char := lo (params.AX);
          if (scan = 75) and (char = 52) then
            if wherex > 1 then
              gotoxy (wherex-1, wherey);
          if (scan = 77) and (char = 54) then
            if wherex < 80 then
              gotoxy (wherex+1, wherey);
          if (scan = 72) and (char = 56) then
            if wherey > 1 then
              gotoxy (wherex, wherey-1);
          if (scan = 80) and (char = 50) then
            if wherey < 24 then
              gotoxy (wherex, wherey+1);
          if (scan = 76) and (char = 53) then
            begin
              cellptr := getcell (wherex+280, wherey+88);
              with cellptr^ do
                begin
                  if state = dead then
                    begin
                      state := alive;
                      neighboradj (wherex+280, wherey+88, 1);
                      initarray [wherex, wherey] := 1;
                      write (aster)
                    end
                  else
                    begin
                      state := dead;
                      neighboradj (wherex+280, wherey+88, -1);
                      initarray [wherex, wherey] := 0;
                      write (blank)
                    end
                end
            end;
          if (scan = 28) and (char = 13) then
            done := true
        end;

    { initialize graphics}
    grDriver := Detect;
    InitGraph(grDriver,grMode,'');

      for i := 1 to 80 do
        for j := 1 to 24 do
          putpixel (i+280, j+88, initarray [i, j])
    end; {setup}

{ ----------------------------------------------------------------------}
  procedure vivify;

    var
      p : pnode;

    begin
      p := live;
      while p <> nil do
        with p^ do
          begin
            with entry^ do
              if (state = dead) and (numnbrs = 3) then
                begin
                  state := alive;
                  putpixel (col, row, alive)
                end
              else
                entry := nil;
            p := nextnode
          end
    end; {vivify}

{ ----------------------------------------------------------------------}
  procedure kill;

    var
      p : pnode;

    begin
      p := die;
      while p <> nil do
        with p^ do
          begin
            with entry^ do
              if (state = alive) and ((numnbrs < 2) or (numnbrs > 3)) then
                begin
                  state := dead;
                  putpixel (col, row, dead)
                end
              else
                entry := nil;
            p := nextnode
          end
    end; {kill}

{ ----------------------------------------------------------------------}
  procedure addneighbors;

    var
      i, j     : integer;
      p, q     : pnode;
      neighbor : pcell;

    begin
      p := live;
      while p <> nil do
        with p^ do
          begin
            if entry <> nil then
              with entry^ do
                for j := row-1 to row+1 do
                  for i := col-1 to col+1 do
                    if (j <> row) or (i <> col) then
                      begin
                        neighbor := getcell (i, j);
                        with neighbor^ do
                          begin
                            numnbrs := numnbrs + 1;
                            if numnbrs = 3 then
                              if state = dead then
                                insert (nextlive, neighbor);
                            if numnbrs = 4 then
                              if state = alive then
                                insert (nextdie, neighbor)
                          end
                      end;
            q := p;
            p := nextnode;
            freenode (q)
          end
    end; {addneighbors}

{ ----------------------------------------------------------------------}
  procedure subtractneighbors;

    var
      i, j     : integer;
      p, q     : pnode;
      neighbor : pcell;

    begin
      p := die;
      while p <> nil do
        with p^ do
          begin
            if entry <> nil then
              with entry^ do
                for j := row-1 to row+1 do
                  for i := col-1 to col+1 do
                    if (j <> row) or (i <> col) then
                      begin
                        neighbor := getcell (i, j);
                        with neighbor^ do
                          begin
                            numnbrs := numnbrs - 1;
                            if numnbrs = 3 then
                              if state = dead then
                                insert (nextlive, neighbor);
                            if numnbrs = 1 then
                              if state = alive then
                                insert (nextdie, neighbor);
                            if numnbrs = 0 then
                              if state = dead then
                                removecell (i, j)
                          end
                      end;
            q := p;
            p := nextnode;
            freenode (q)
          end
    end; {subtractneighbors}

{ ----------------------------------------------------------------------}
  procedure copylive;

    begin
      live := nextlive;
      nextlive := nil
    end; {copylive}

{ ----------------------------------------------------------------------}
  procedure copydie;

    begin
      die := nextdie;
      nextdie := nil
    end; {copydie}

{ ----------------------------------------------------------------------}
{ ----------------------------------------------------------------------}
  begin {main}
    setup;
    gencount := 1;
    while (not keypressed) do
      begin
        gotoxy (1, 1);
        write ('Gen:', gencount);
        vivify;
        kill;
        addneighbors;
        subtractneighbors;
        copylive;
        copydie;
        gencount := gencount + 1
      end;
    textmode (OrigMode)
  end. {main}
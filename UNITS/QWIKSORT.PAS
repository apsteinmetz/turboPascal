UNIT QWIKSORT;

interface
{*****************************************************}
{ You must pass parameters to this procedure of type  }
{ DataArray; an array with comparable elements        }
{ for example }
type
  dataitem = integer;
  dataarray = array[1..10] of dataitem;

procedure QuickSort(var item : DataArray; count : integer);

(* dynamic sort of opaque type linked list *)
TYPE
  LastProc = FUNCTION (RecordPtr :POINTER) : POINTER;
  NextProc = FUNCTION (RecordPtr :POINTER) : POINTER;
  GetItemProc = FUNCTION (RecordPtr :POINTER) : POINTER;
  SetItemProc = PROCEDURE (VAR RecordPtr :POINTER;ItemPtr : POINTER);

procedure DynaSort( list : POINTER;
                         Next : NextProc;
                         GetItem : GetItemProc;
                         SetItem : SetItemProc;
                         ItemSize : WORD);


implementation

procedure QuickSort(var item : DataArray; count : integer);
     procedure QS(l,r :integer; var it : DataArray);
     var
        i,j : integer;
        x,y : Dataitem;
     begin
         i :=l ; j := r;
         x := it[(l+r) div 2];
         repeat
            while it[i] < x do i := i + 1;
            while x < it[j] do j := j - 1;
            if i <= j then
            begin
               y     := it[i];
               it[i] := it[j];
               it[j] := y;
               i := i+1; j:= j-1;
            end;
         until i > j;
         if l < j then qs(l,j,it);
         if l < r then qs(i,r,it);
     end; {qs}
begin
   qs(1,count,item);
end {qwiksort};

(* +++++++++++++++++++++++++++++++++++++++++++ *)

procedure DynaSort( list : POINTER;
                         Next : NextProc;
                         GetItem : GetItemProc;
                         SetItem : SetItemProc;
                         ItemSize : WORD);
TYPE
  (* not necessarily a string *)
  DataItem = string[255];

VAR
  ptr1, ptr2, ptr3 : POINTER;
  item1, item2, item3 : ^DataItem;

BEGIN
   ptr1 := list;
   WHILE Next(ptr1) <> NIL DO
   BEGIN
      ptr2 := Next(ptr1);
      ptr3 := ptr1;
      REPEAT
      BEGIN
         item2 := GetItem(ptr2);
         item3 := GetItem(ptr3);
         If item2^ < item3^ THEN
            ptr3 := ptr2;
         ptr2 := Next(ptr2);
      END
      UNTIL ptr2 = NIL;
      IF ptr3 <> ptr1 THEN
      BEGIN
         item1 := GetItem(ptr1);
         SetItem(ptr1,GetItem(ptr3));
         SetItem(ptr3,item1);
      END;
      ptr1 := Next(ptr1);
   END;
END {DynaQuickSort};

BEGIN
END {QWIKSORT}.

unit Unit1; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids;

type

  { TForm1 }

  TForm1 = class(TForm)
   Licz: TButton;
   Dialog: TOpenDialog;
   Memo1: TMemo;
   StringGrid1: TStringGrid;
   procedure LiczClick(Sender: TObject);
  private
    { private declarations }
  public
    procedure DisplayMatrix;
  end; 

var
  Form1: TForm1;
  macierz: array of array of Boolean;

  trans: array of Integer;   { tablica taka ze indeks to pozycja w macierzy, a
                               wartosc to to jakiej liczby sie ten wpis tyczy }

  dfs: array of Integer;       { tablica tymczasowa do algorytmu DFS }

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.DisplayMatrix;
var
  x, y: Integer;
begin
 for x := 0 to Length(trans)-1 do
     StringGrid1.Cells[x, 0] := IntToStr(trans[x]);

 for y := 0 to Length(macierz)-1 do
      for x := 0 to Length(trans)-1 do
          if macierz[y][x] then
                    StringGrid1.cells[x, y+1] := '1'
          else
                    StringGrid1.cells[x, y+1] := '0';

 StringGrid1.AutoAdjustColumns;
end;

function is_in(a: Integer; b: array of Integer): Integer;
         { sprawdza czy a jest w b.
           jesli tak, zwraca jej indeks
           inaczej zwraca -1
           }
var
  i: Integer;
begin
     result := -1;
     for i := 0 to Length(b)-1 do
     if a = b[i] then
        begin
          result := i;
          Exit;
        end;
end;

procedure TForm1.LiczClick(Sender: TObject);
label
  powtarza_sie;
var
   liczba_zbiorow: Integer;
   liczba_el_zbioru: Integer;

   i, j, k, l: Integer;

   s: String;

   plik: system.Text; { jest roznica miedzy system.Text a TextFile w czytaniu liczb i nowymi liniami }
begin
 if not Dialog.Execute then Exit;   {  jesli user dialog, to nic nie robimy }

 Memo1.Clear;          { czysc memo }


 { pierwszy przelot nad plikiem ma na celu ustalenie rozmiaru macierzy }
 AssignFile(plik, Dialog.FileName);
 Reset(plik);

 { bedziemy operowac na macierzy AxB, gdzie A to liczba podzbiorow a B to liczba unikatowych
   elementow gdyby "splaszczyc" zbiory.

   Wyznaczymy teraz tabele "trans"}

 Read(plik, liczba_zbiorow);

 for i := 0 to liczba_zbiorow-1 do
 begin
      Read(plik, liczba_el_zbioru);

      for j := 0 to liczba_el_zbioru-1 do
      begin
           Read(plik, k);
           if is_in(k, trans) = -1 then  { jesli k nie ma jeszcze w trans..}
           begin
                { .. to dopisz, bo trans ma byc lista unikatowych wszystkich elementow !}
                l := Length(trans);
                SetLength(trans, l+1);
                trans[l] := k;
           end;
      end;
 end;

 CloseFile(plik);

 { ok, przygotujmy teraz "macierz" zeby miala liczba_zbiorow wierszy i Length(trans) kolumn, wsio 0 }

 SetLength(macierz, liczba_zbiorow);
 for i := 0 to liczba_zbiorow-1 do
 begin
      macierz[i] := nil;        { zeby sobie alokator czego durnego nie pomyslal }
      SetLength(macierz[i],Length(trans));
      for j := 0 to Length(trans)-1 do
           macierz[i][j] := False;
 end;


 if Length(macierz) > Length(trans) then
 begin
      Memo1.Lines.Append('Nie istnieje SDR');
      Exit;
 end;

 // DEBUG
 StringGrid1.RowCount := liczba_zbiorow+1;
 StringGrid1.ColCount := Length(trans);
 // DEBUG

 { Mamy fajna wyzerowana macierz. Teraz drugi przelot pliku wypelni nam macierz... }

 Reset(plik);

 Read(plik, liczba_zbiorow);
 for i := 0 to liczba_zbiorow-1 do
 begin
      Read(plik, liczba_el_zbioru);
      for j := 0 to liczba_el_zbioru-1 do
      begin
            Read(plik, k);
                          { wpisz ze to nalezy do i-tego zbioru na odpowiedniej pozycji }
            macierz[i][is_in(k, trans)] := True;
      end;
 end;

 CloseFile(plik);

 Form1.DisplayMatrix;
 { Plik nie jest nam juz potrzebny, mamy za to macierz }

 { przygotuj tablice DFS }
 SetLength(dfs, Length(macierz));
 for i := 0 to length(macierz)-1 do dfs[i] := -1;

 i := 0;                         { indeks aktualnie robionego zbioru }
 while True do
 begin
   Inc(dfs[i]); { wezmy nastepna liczbe }


   if dfs[i] = length(trans) then       { no, tylu liczb to juz nie ma :D }
   begin
              { skonczyly sie nam opcje. Sprawdzmy czy mozemy sie wrocic ... }
       if i = 0 then
       begin
             Memo1.Lines.Append('Koniec przeszukiwania');
           Exit;
       end;

       Dec(i);  { tak, mozemy }
       dfs[i+1] := -1; { wracajac sie, nie zapominamy zerowac po sobie }
       continue;
   end;

   if macierz[i][dfs[i]] then    { jesli jest to liczba ktora nalezy do naszego zbioru }
   begin
        for j := 0 to i-1 do     { sprawdzamy czy juz wykorzystalismy ja kiedys }
          if dfs[i] = dfs[j] then goto powtarza_sie;

        // to jest dobra liczba
        inc(i);                    { lec do nastepnego zbioru}

        if i = length(macierz) then
        begin
             { SDR znaleziony, zapisz i szukaj dalej }
             s := '';

             for k := 0 to length(dfs)-1 do
               s := s + inttostr(trans[dfs[k]])+' '; { wygeneruj linie tekstu }

             Memo1.Lines.Append(s);               { dopisz do mema }
             dec(i);           { cofnij o 1 pozycje do tylu aby zapobiec zwiekszeniu i ponad dopuszczalna wartosc }
        end;
        continue;
   end;

   powtarza_sie:
 end;

     // dobry programista jest jak dobry platny morderca - zawsze po sobie sprzata
  SetLength(trans, 0);
  SetLength(dfs, 0);
  for i := 0 to Length(macierz)-1 do
      SetLength(macierz[i], 0);
  SetLength(macierz, 0);
end;
end.


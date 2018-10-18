program Demo3;
{$APPTYPE CONSOLE}
var
  i: Integer;
begin
  i := 0;
  while i < 10 do
  begin
    WriteLn('Hello ', i);
    Inc(i);
  end;
end.
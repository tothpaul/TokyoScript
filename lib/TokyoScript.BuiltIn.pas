unit TokyoScript.BuiltIn;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}

interface

uses
  System.SysUtils;

type
  TBuiltIn = (
    bi_None,
    biWrite,
    biWriteLn,
    biInc
  );

const
  BUILTINS : array[TBuiltIn] of string = (
    '',
    'WRITE',
    'WRITELN',
    'INC'
  );

function GetBuiltIn(Str: string): TBuiltIn;

implementation

function GetBuiltIn(Str: string): TBuiltIn;
begin
  Str := UpperCase(Str);
  Result := High(TBuiltIn);
  while Result > bi_None do
  begin
    if BUILTINS[Result] = Str then
      Exit;
    Dec(Result);
  end;
end;

end.

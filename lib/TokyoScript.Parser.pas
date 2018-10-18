unit TokyoScript.Parser;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}
interface

uses
  System.SysUtils,
  TokyoScript.Chars,
  TokyoScript.Keywords;

type
  TDefine = class
    Value: string;
    Next : TDefine;
  end;

  TAppType = (
    APPTYPE_GUI,    // default
    APPTYPE_CONSOLE
  );

  ESourceError = class(Exception)
    Row: Integer;
    Col: Integer;
    constructor Create(const Msg: string; ARow, ACol: Integer);
  end;

  TParser = record
  private
    FDefines: TDefine;
    FSource : string;
    FIndex  : Integer;
    FRow    : Integer;
    FLine   : Integer;
    FStart  : Integer;
    FAppType: TAppType;
    FLiteral: string;
    function GetCol: Integer;
    procedure Blanks;
    function NextChar: Char;
    function ReadChar: Char;
    function GetString(var At: Integer): string;
    procedure Comment1;
    function Comment2: Boolean;
    function LineComment: Boolean;
    procedure Directive(Start: Integer);
    function IsDirective(Start: Integer; const AName: string): Boolean;
    function GetAppType(Start: Integer): TAppType;
    function AddChar(AChar: Char): Boolean;
    procedure AddChars(CharTypes: TCharTypes);
    function Match(AChar: Char; AType: TCharType): Boolean;
    procedure ParseIdent;
    procedure ParseNumber;
    function GetChar(Start, Base: Integer): Char;
    procedure ParseChar;
    procedure ParseHexa;
    procedure ParseString;
  public
    CharType: TCharType;
    Keyword: TKeyword;
    function Token: string;
    procedure Init(const Str: string);
    procedure Error(const Msg: string);
    procedure Next();
    procedure Define(const Value: string);
    procedure Undef(const Value: string);
    function IsDef(const Value: string): Boolean;
    function SkipChar(AChar: Char): Boolean;
    procedure DropChar(AChar: Char);
    procedure DropCharType(ACharType: TCharType);
    function SkipKeyword(AKeyword: TKeyword): Boolean;
    procedure DropKeyword(AKeyword: TKeyword);
    function SkipKeywords(AKeywords: TKeywords): TKeyword;
    function GetIdent: string;
    procedure SemiColon; inline;
    procedure Clear;
    property Position: Integer read FStart;
    property Row: Integer read FRow;
    property Col: Integer read GetCol;
    property Literal: string read FLiteral;
    property AppType: TAppType read FAppType;
  end;

implementation

{ TParser }

procedure TParser.Clear;
var
  Define: TDefine;
begin
  if FSource = '' then
  begin
    FDefines := nil;
  end else begin
    FSource := '';
    while FDefines <> nil do
    begin
      Define := FDefines;
      FDefines := Define.Next;
      Define.Free;
    end;
  end;
end;

procedure TParser.Comment1;
var
  Start: Integer;
begin
  Inc(FIndex);
  Start := FIndex;
  repeat
  until ReadChar = '}';
  if FSource[Start] = '$' then
    Directive(Start);
end;

function TParser.Comment2: Boolean;
var
  Start: Integer;
begin
  Result := FSource[FIndex + 1] = '*';
  if Result then
  begin
    Inc(FIndex, 2);
    Start := FIndex;
    repeat
    until (ReadChar = '*') and (NextChar = ')');
    if FSource[Start] = '$' then
      Directive(Start);
    Inc(FIndex);
  end;
end;

procedure TParser.Define(const Value: string);
var
  Def: TDefine;
begin
  if not IsDef(Value) then
  begin
    Def := TDefine.Create;
    Def.Value := Value;
    Def.Next := FDefines;
    FDefines := Def;
  end;
end;

procedure TParser.Directive(Start: Integer);
begin
  if IsDirective(Start, 'APPTYPE') then
    FAppType := GetAppType(Start)
  else
    Error('Todo ' + Copy(FSource, Start, FIndex - Start - 1));
end;

function TParser.IsDirective(Start: Integer; const AName: string): Boolean;
var
  Index: Integer;
begin
  Result := False;
  for Index := 1 to Length(AName) do
  begin
    Inc(Start);
    if FSource[Start] <> AName[Index] then
      Exit;
  end;
  Result := FSource[Start + 1] = ' ';
end;

function TParser.GetAppType(Start: Integer): TAppType;
var
  Str: string;
  Up : string;
begin
  Inc(Start, 8); // 'APPTYPE '
  Str := GetString(Start);
  Up := UpperCase(Str);
  if Up = 'GUI' then
    Exit(APPTYPE_GUI);
  if Up = 'CONSOLE' then
    Exit(APPTYPE_CONSOLE);
  Error('Unknown APPTYPE "' + Str + '"');
end;

function TParser.GetChar(Start, Base: Integer): Char;
var
  Digit: Integer;
  Value: Integer;
begin
  Value := 0;
  while Start < FIndex do
  begin
    Digit := Ord(FSource[Start]);
    Inc(Start);
    case Chr(Digit) of
      '0'..'9': Dec(Digit, Ord('0'));
      'a'..'f': Dec(Digit, Ord('a'));
      'A'..'F': Dec(Digit, Ord('A'));
    end;
    Value := Base * Value + Digit;
    if Value > $FFFF then
      Error('Char overflow');
  end;
  Result := Char(Value);
end;

function TParser.GetCol: Integer;
begin
  Result := FStart - FLine + 1;
end;

function TParser.SkipChar(AChar: Char): Boolean;
begin
  Result := (FSource[FStart] = AChar) and (FIndex = FStart + 1);
  if Result then
    Next();
end;

procedure TParser.DropChar(AChar: Char);
begin
  if not SkipChar(AChar) then
    Error('Expected "' + AChar + '", found, "' + Token +'"');
end;

procedure TParser.DropCharType(ACharType: TCharType);
begin
  if CharType <> ACharType then
    Error('Unexpacted token "' + Token + '"');
  Next();
end;

function TParser.SkipKeyword(AKeyword: TKeyword): Boolean;
begin
  Result := Keyword = AKeyword;
  if Result then
    Next();
end;

procedure TParser.DropKeyword(AKeyword: TKeyword);
begin
  if not SkipKeyword(AKeyword) then
    Error('Keyword expected "' + KEYWORDS[AKeyword] + '", found "' + Token + '"');
end;

procedure TParser.Error(const Msg: string);
begin
  raise ESourceError.Create(Msg, FRow, Col);
end;

function TParser.GetIdent: string;
begin
  Result := Token;
  if CharType <> ctIdent then
    Error('Ident expected, found "' + Result + '"');
  Next();
end;

procedure TParser.Init(const Str: string);
begin
  Clear;
  FSource := Str;
  FIndex := 1;
  FRow := 1;
  FLine := 0;
  Next();
end;

function TParser.IsDef(const Value: string): Boolean;
var
  Def: TDefine;
begin
  Def := FDefines;
  while Def <> nil do
  begin
    if Def.Value = Value then
      Exit(True);
    Def := Def.Next;
  end;
  Result := False;
end;

function TParser.LineComment: Boolean;
begin
  Result := FSource[FIndex + 1] = '/';
  if Result then
  begin
    Inc(FIndex, 2);
    repeat
    until GetCharType(ReadChar) in [ctLineFeed, ctReturn];
  end;
end;

function TParser.Match(AChar: Char; AType: TCharType): Boolean;
begin
  Result := AddChar(AChar);
  if Result then
    CharType := AType;
end;

function TParser.AddChar(AChar: Char): Boolean;
begin
  Result := NextChar = AChar;
  if Result then
    Inc(FIndex);
end;

procedure TParser.AddChars(CharTypes: TCharTypes);
var
  C: Char;
begin
  C := NextChar;
  while GetCharType(C) in CharTypes do
  begin
    Inc(FIndex);
    C := NextChar;
  end;
end;

procedure TParser.Blanks;
begin
  repeat
    case GetCharType(NextChar) of
      ctPadding  : Inc(FIndex);
      ctLineFeed : // LF
      begin
        Inc(FRow);
        Inc(FIndex);
        FLine := FIndex;
      end;
      ctReturn: // CR/LF
      begin
        Inc(FRow);
        Inc(FIndex);
        if NextChar = #10 then
          Inc(FIndex);
        FLine := FIndex;
      end;
      ctLBrace : Comment1;    // {
      ctLParent: if not Comment2 then Exit;    // (*
      ctSlash  : if not LineComment then Exit; // //
    else
      Exit;
    end;
  until False;
end;

procedure TParser.Next;
begin
  FLiteral := '';
  Blanks; // <SPACE> <TAB> <CR> <LF> { comment1 } (* comment 2 *) // line comment
  FStart := FIndex;
  CharType := GetCharType(ReadChar);
  Keyword := kw_None;
  case CharType of
    ctAlpha      : ParseIdent;
    ctDigit      : ParseNumber;
    ctColon      : Match('=', ctAssign);
    ctGT         : Match('=', ctGE);
    ctLT         : if not Match('=', ctLE) then Match('>', ctNE);
    ctDot        : Match('.', ctRange);
    ctSharp      : ParseChar;
    ctDollar     : ParseHexa;
    ctSimpleQuote: ParseString;
  end;
end;

function TParser.NextChar: Char;
begin
  if FIndex <= Length(FSource) then
    Result := FSource[FIndex]
  else
    Result := #0;
end;

procedure TParser.ParseChar;
var
  Start: Integer;
begin
  if NextChar = '$' then
  begin
    Inc(FIndex);
    Start := FIndex;
    ParseHexa;
    if FIndex = Start then
      Error('Expected hexadecimal value');
    FLiteral := FLiteral + GetChar(Start, 16);
  end else begin
    Start := FIndex;
    AddChars([ctDigit]);
    if FIndex = Start then
      Error('Expected number');
    FLiteral := FLiteral + GetChar(Start, 10);
  end;
  if NextChar = '''' then
  begin
    Inc(FIndex);
    ParseString;
  end else begin
    CharType := ctChar;
  end;
end;

procedure TParser.ParseHexa;
begin
  while NextChar in ['0'..'9', 'a'..'f', 'A'..'F'] do
    Inc(FIndex);
  CharType := ctHexa;
end;

procedure TParser.ParseIdent;
begin
  AddChars([ctAlpha, ctDigit]);
  CharType := ctIdent;
  Keyword := GetKeyword(Token);
  if Keyword <> kw_None then
    CharType := ctKeyword;
end;

procedure TParser.ParseNumber;
begin
  AddChars([ctDigit]);            // 123
  CharType := ctNumber;
  if NextChar = '.' then          // 123.4
  begin
    CharType := ctReal;
    Inc(FIndex);
    AddChars([ctDigit]);
  end;
  if NextChar in ['e', 'E'] then  // 123e10, 123.4e10
  begin
    CharType := ctReal;
    Inc(FIndex);
    if NextChar in ['+', '-'] then  // 123e+10
      Inc(FIndex);
    AddChars([ctDigit]);
  end;
end;

procedure TParser.ParseString;
var
  Start: Integer;
begin
  Start := FIndex;
  while True do
  begin
    while NextChar <> '''' do
    begin
      Inc(FIndex);
    end;
    Inc(FIndex);
    if NextChar = '''' then
    begin
      FLiteral := FLiteral + Copy(FSource, Start, FIndex - Start);
      Inc(FIndex);
      Start := FIndex;
    end else begin
      Break;
    end;
  end;
  FLiteral := FLiteral + Copy(FSource, Start, FIndex - Start - 1);
  if NextChar = '#' then
  begin
    Inc(FIndex);
    ParseChar;
  end;
  CharType := ctString;
end;

function TParser.ReadChar: Char;
begin
  Result := NextChar;
  if Result = #0 then
    raise Exception.Create('End of File');
  Inc(FIndex);
end;

function TParser.GetString(var At: Integer): string;
var
  Start: Integer;
begin
  while (At < FIndex) and (GetCharType(FSource[At]) = ctPadding) do
    Inc(At);
  Start := At;
  while (At < FIndex) and (GetCharType(FSource[At]) in [ctAlpha, ctDigit]) do
    Inc(At);
  Result := Copy(FSource, Start, At - Start);
end;

procedure TParser.SemiColon;
begin
  DropChar(';');
end;

function TParser.SkipKeywords(AKeywords: TKeywords): TKeyword;
begin
  if Keyword in AKeywords then
  begin
    Result := Keyword;
    Next();
  end else begin
    Result := kw_None;
  end;
end;

function TParser.Token: string;
begin
  SetString(Result, PChar(@FSource[FStart]), FIndex - FStart);
end;

procedure TParser.Undef(const Value: string);
var
  Def: TDefine;
  Tmp: TDefine;
begin
  if FDefines = nil then
    Exit;
  Def := FDefines;
  if Def.Value = Value then
  begin
    FDefines := Def.Next;
    Def.Free;
  end else begin
    Tmp := Def.Next;
    while Tmp <> nil do
    begin
      if Tmp.Value = Value then
      begin
        Def.Next := Tmp.Next;
        Tmp.Free;
        Exit;
      end;
      Def := Tmp;
      Tmp := Def.Next;
    end;
  end;
end;

{ ESourceError }

constructor ESourceError.Create(const Msg: string; ARow, ACol: Integer);
begin
  inherited Create(Msg + ' at [' + IntToStr(ACol) + ',' + IntToStr(ARow) + ']');
  Row := ARow;
  Col := ACol;
end;

end.

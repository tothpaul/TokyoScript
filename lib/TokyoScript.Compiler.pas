unit TokyoScript.Compiler;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}

interface

uses
  System.Classes,
  System.SysUtils,
  TokyoScript.Runtime,
  TokyoScript.Chars,
  TokyoScript.Parser,
  TokyoScript.Keywords,
  TokyoScript.BuiltIn;

type
  TSymbolKind = (
  // const
    skString,
    skNumber,
  // ident
    skProgramName,
    skVariableName,
    skTypeName
  );

  TSystemType = (
    stInteger,
    stString
  );

  TSymbol = class;

  TTypeDef = class
    Base: TSystemType;
  end;

  TTypeRef = class
    Symbol : TSymbol; // can be null
    TypeDef: TTypeDef;
  end;

  TSymbol = class
    Name    : string;
    Kind    : TSymbolKind;
    TypeRef : TTypeRef; // TypeRef.Symbol = Self
  end;

  TStatementKind = (
    skNop,
    skLoadInt,
    skLoadStr,
    skLabel,
    skGoto,
    skJumpiEQ,
    skJumpTrue,
    skAssign,
    skiIncr,
    skIMul,
    skiLT,
    skConcat,
    skWriteInt,
    skWriteStr
  );

  TRegister = class
    Symbol   : TSymbol;
    TypeDef  : TTypeDef;
  end;

  TStatement = class
    Kind  : TStatementKind;
    Param1: TRegister;
    Param2: TRegister;
    Param3: TRegister;
    Addr  : TStatement;
    Ofs   : Integer;
    Symbol: TSymbol;
  end;

  TCodeSection = class
  // parent/child for Scope resolution
    Parent    : TCodeSection;
    Childs    : TList;
  // local symbols
    Symbols   : TList;
  // required symbols
    Needs     : TList;
  // params & vars
    Registers : TList;
  // code
    Labels    : TList;
    CodeSize  : Integer;
    Statements: TList;
    constructor Create(AParent: TCodeSection);
    destructor Destroy; override;
    function NewSymbol: TSymbol;
    function NewRegister: TRegister;
    function NewStatement(Size: Integer): TStatement;
    function LoadSymbol(Symbol: TSymbol): TRegister;
    procedure LoadRegSymbol(Load: TStatementKind; Reg: TRegister);
    function GetLabel: TStatement;
    procedure IncReg(Reg: TRegister);
    procedure Clear;
  end;

  TLogEvent = procedure(Sender: TObject; const Msg: string) of object;

  TOperation = function(Reg1, Reg2: TRegister): TRegister of object;

  TCompiler = class
  private
    FOnLog   : TLogEvent;
    FParser  : TParser;
    FMain    : TCodeSection;
    FCode    : TCodeSection;
    FInteger : TSymbol;
    FString  : TSymbol;
    FValues  : TList;
  // Gabarge Collector
    FGarbage : TList;
  // todo
    FByteCode: TByteCode;
    procedure Log(const Msg: string);
    function Expression: TRegister;
    function Expression1: TRegister;
    function Expression2: TRegister;
    function Expression3: TRegister;
    function IdentExpression: TRegister;
    function GetLiteral: TSymbol;
    function GetString(const Value: string): TSymbol;
    function GetNumber: TSymbol;
    function OpAdd(R1, R2: TRegister): TRegister;
    function OpMult(R1, R2: TRegister): TRegister;
    function OpLT(R1, R2: TRegister): TRegister;
    procedure SetReg(Target, Value: TRegister);
    procedure FreeReg(R: TRegister);
    function GoLabel(L: TStatement): TStatement;
    function WriteStr(R: TRegister): TStatement;
    function WriteInt(R: TRegister): TStatement;
    function GetJumpiEQ(R1, R2: TRegister): TStatement;
    function GetJumpTrue(R: TRegister): TStatement;
    function AddSymbol(const AName: string): TSymbol;
    function AddTypeDef(BaseType: TSystemType): TTypeDef;
    function AddTypeRef(TypeDef: TTypeDef): TTypeRef;
    function SystemType(const AName: string; BaseType: TSystemType): TSymbol;
    procedure Variables;
    function Variable: TSymbol;
    function GetSymbol: TSymbol;
    function GetLocalVar: TSymbol;
    function GetLocalVarReg: TRegister;
    function GetTypeRef: TTypeRef;
    procedure WriteStatement(Ln: Boolean);
    procedure IncStatement();
    procedure Statement;
    procedure Statements;
    procedure IdentStatement;
    procedure VariableStatement(Variable: TSymbol);
    procedure KeywordStatement;
    procedure ForStatement;
    procedure WhileStatement;
    procedure Clear;
    procedure WriteCodeB(var Ofs: Integer; Value: Byte);
    procedure WriteCodeW(var Ofs: Integer; Value: Word);
    procedure WriteCodeL(var Ofs: Integer; Value: Integer);
    procedure WriteCodeV(var Ofs: Integer; Value: Integer);
    procedure WriteCodeR(var Ofs: Integer; Reg: TRegister);
    procedure WriteCodeOpV(var Ofs: Integer; OpCode: TOpCode; Value: Integer);
    procedure WriteCodeOpR(var Ofs: Integer; OpCode: TOpCode; Reg: TRegister);
    procedure WriteCodeOpRV(var Ofs: Integer; OpCode: TOpCode; Reg: TRegister; Value: Integer);
    procedure WriteCodeOpRR(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2: TRegister);
    procedure WriteCodeOpRRV(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2: TRegister; Value: Integer);
    procedure WriteCodeOpRRR(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2, Reg3: TRegister);
    procedure GenCode(Code: TCodeSection);
    procedure GenByteCode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Compile(Lines: TStrings);
    property ByteCode: TByteCode read FByteCode;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

procedure ClearList(List: TList);
var
  Index: Integer;
begin
  for Index := 0 to List.Count - 1 do
    TObject(List[Index]).Free;
  List.Clear;
end;

const
  OP_R   = 1 + 4;
  OP_V   = 1 + 4;
  OP_RR  = 1 + 4 + 4;
  OP_RV  = 1 + 4 + 4;
  OP_RRV = 1 + 4 + 4 + 4;
  OP_RRR = 1 + 4 + 4 + 4;

{ TCodeSection }

constructor TCodeSection.Create(AParent: TCodeSection);
begin
  inherited Create;
  Parent := AParent;
  Childs := TList.Create;
  Symbols := TList.Create;
  Needs := TList.Create;
  Labels := TList.Create;
  Statements := TList.Create;
  Registers := TList.Create;
  if Parent <> nil then
    Parent.Childs.Add(Self);
end;

destructor TCodeSection.Destroy;
begin
  Clear;
  Labels.Free;
  Registers.Free;
  Statements.Free;
  Needs.Free;
  Childs.Free;
  Symbols.Free;
  inherited;
end;

function TCodeSection.GetLabel: TStatement;
begin
  Result := NewStatement(0);
  Result.Kind := skLabel;
  Labels.Add(Result);
end;

procedure TCodeSection.IncReg(Reg: TRegister);
var
  S: TStatement;
begin
  S := NewStatement(OP_R);
  S.Kind := skiIncr;
  S.Param1 := Reg;
end;

function TCodeSection.LoadSymbol(Symbol: TSymbol): TRegister;
var
  Index: Integer;
begin
  for Index := 0 to Registers.Count - 1 do
  begin
    Result := Registers[Index];
    if Result.Symbol = Symbol then
      Exit;
  end;
  Result := NewRegister;
  Result.Symbol := Symbol;
  Result.TypeDef := Symbol.TypeRef.TypeDef;
end;

procedure TCodeSection.LoadRegSymbol(Load: TStatementKind; Reg: TRegister);
var
  S: TStatement;
begin
  S := NewStatement(OP_RV);
  S.Kind := Load;
  S.Param1 := Reg;
  S.Symbol := Reg.Symbol;
end;

function TCodeSection.NewRegister: TRegister;
begin
  Result := TRegister.Create;
  Registers.Add(Result);
end;

function TCodeSection.NewStatement(Size: Integer): TStatement;
begin
  Result := TStatement.Create;
  Result.Ofs := CodeSize;
  Inc(CodeSize, Size);
  Statements.Add(Result);
end;

function TCodeSection.NewSymbol: TSymbol;
begin
  Result := TSymbol.Create;
  Symbols.Add(Result);
end;

procedure TCodeSection.Clear;
begin
  ClearList(Childs);
  ClearList(Statements);
  ClearList(Symbols);
  ClearList(Registers);
  Labels.Clear;
end;

{ TCompiler }

constructor TCompiler.Create;
begin
  inherited;
  FByteCode := TByteCode.Create;
  FValues := TList.Create;
  FMain := TCodeSection.Create(nil);
  FGarbage := TList.Create;
end;

destructor TCompiler.Destroy;
begin
  Clear;
  FMain.Free;
  FValues.Free;
  FByteCode.Free;
  FGarbage.Free;
  inherited;
end;

function TCompiler.Expression: TRegister;
var
  op: TOperation;
begin
  Result := Expression1;
  case FParser.CharType of
    ctLT: op := OpLT;
//    ctEQ: ;
//    ctGT: ;
//    ctGE: ;
//    ctLE: ;
//    ctNE: ;
  else
    Exit;
  end;
  FParser.Next();
  Result := op(Result, Expression1);
end;

function TCompiler.Expression1: TRegister;
var
  op: TOperation;
begin
  Result := Expression2;
  case FParser.CharType of
    ctStar : op := OpMult;
  else
    Exit;
  end;
  FParser.Next();
  Result := op(Result, Expression2);
end;

function TCompiler.Expression2: TRegister;
var
  op: TOperation;
begin
  Result := Expression3;
  case FParser.CharType of
    ctPlus: op := OpAdd;
  else
    Exit;
  end;
  FParser.Next();
  Result := op(Result, Expression3);
end;

function TCompiler.Expression3: TRegister;
begin
  case FParser.CharType of
    ctString:
    begin
      Result := FCode.LoadSymbol(GetLiteral);
      FCode.LoadRegSymbol(skLoadStr, Result);
    end;
    ctNumber:
    begin
      Result := FCode.NewRegister;
      Result.Symbol := GetNumber;
      Result.TypeDef := Result.Symbol.TypeRef.TypeDef;
      FCode.LoadRegSymbol(skLoadInt, Result);
    end;
    ctIdent: Result := IdentExpression;
  else
    Result := nil;
    FParser.Error('Unknown expression');
  end;
end;

function TCompiler.IdentExpression: TRegister;
var
  Symbol: TSymbol;
begin
  Symbol := GetSymbol;
  case Symbol.Kind of
//    skString: ;
//    skNumber: ;
//    skProgramName: ;
    skVariableName: Result := FCode.LoadSymbol(Symbol);
//    skTypeName: ;
  else
    Result := nil;
    FParser.Error('Unexpected symbol');
  end;
end;

function TCompiler.GetLiteral: TSymbol;
begin
  Result := GetString(FParser.Literal);
  FParser.Next();
end;

function TCompiler.GetString(const Value: string): TSymbol;
var
  Index: Integer;
begin
  for Index := 0 to FValues.Count - 1 do
  begin
    Result := FValues[Index];
    if (Result.Kind = skString) and (Result.Name = Value) then
      Exit;
  end;
  Result := TSymbol.Create;
  FValues.Add(Result);
  Result.Name := Value;
  Result.Kind := skString;
  Result.TypeRef := FString.TypeRef;
end;

function TCompiler.GetSymbol: TSymbol;
var
  Name  : string;
  Code  : TCodeSection;
  Index : Integer;
begin
  Name := FParser.Token;
  Code := FCode;
  for Index := Code.Symbols.Count - 1 downto 0 do
  begin
    Result := Code.Symbols[Index];
    if SameText(Result.Name, Name) then
    begin
      FParser.Next();
      Exit;
    end;
  end;
  Result := nil;
  FParser.Error('Unknown ident "' + Name + '"');
end;

function TCompiler.GetNumber: TSymbol;
var
  Value: string;
  Index: Integer;
begin
  Value := FParser.Token;
  FParser.Next();
  for Index := 0 to FValues.Count - 1 do
  begin
    Result := FValues[Index];
    if (Result.Kind = skNumber) and (Result.Name = Value) then
      Exit;
  end;
  Result := TSymbol.Create;
  FValues.Add(Result);
  Result.Name := Value;
  Result.Kind := skNumber;
  Result.TypeRef := FInteger.TypeRef;
end;

procedure TCompiler.ForStatement;
var
  R : TRegister;
  T : TRegister;
  J : TStatement;
  L : TStatement;
begin
  R := GetLocalVarReg;
  Log('for ' + R.Symbol.Name);
  FParser.DropCharType(ctAssign);
  SetReg(R, Expression);
  FParser.DropKeyword(kwTo);
  T := Expression;
  FParser.DropKeyword(kwDo);
  L := FCode.GetLabel;
  J := GetJumpiEQ(R, T);
  Statement;
  FCode.IncReg(R);
  GoLabel(L);
  J.Addr := FCode.GetLabel;
  FreeReg(T);
  FreeReg(R);
end;

procedure TCompiler.WhileStatement;
var
  L: TStatement;
  J: TStatement;
  E: TStatement;
begin
  L := FCode.GetLabel;
  J := GetJumpTrue(Expression);
  E := GoLabel(nil);
  J.Addr := FCode.GetLabel;
  FParser.DropKeyword(kwDo);
  Statement;
  GoLabel(L);
  E.Addr := FCode.GetLabel;
end;

procedure TCompiler.FreeReg(R: TRegister);
begin
// todo
end;

procedure TCompiler.GenByteCode;
var
  Index : Integer;
  Count : Integer;
  Symbol: TSymbol;
begin
// Strings
  Count := 0;
  for Index := 0 to FValues.Count - 1 do
  begin
    Symbol := FValues[Index];
    if Symbol.TypeRef = FString.TypeRef then
    begin
      if Index > Count then
      begin
        FValues[Index] := FValues[Count];
        FValues[Count] := Symbol;
      end;
      Inc(Count);
    end;
  end;
  if FParser.AppType = APPTYPE_CONSOLE then
    FByteCode.Flags := FLAG_CONSOLE;
  SetLength(FByteCode.Strings, Count);
  for Index := 0 to Count - 1 do
  begin
    Symbol := FValues[Index];
    FByteCode.Strings[Index] := Symbol.Name;
  end;
  SetLength(FByteCode.Values, FValues.Count - Count);
  for Index := Count to FValues.Count - 1 do
  begin
    Symbol := FValues[Index];
    FByteCode.Values[Index - Count] := StrToInt(Symbol.Name);
  end;
// Code
  GenCode(FMain);
end;

procedure TCompiler.WriteCodeB(var Ofs: Integer; Value: Byte);
begin
  Move(Value, FByteCode.Code[Ofs], 1);
  Inc(Ofs, 1);
end;

procedure TCompiler.WriteCodeW(var Ofs: Integer; Value: Word);
begin
  Move(Value, FByteCode.Code[Ofs], 2);
  Inc(Ofs, 2);
end;

procedure TCompiler.WriteCodeL(var Ofs: Integer; Value: Integer);
begin
  Move(Value, FByteCode.Code[Ofs], 4);
  Inc(Ofs, 4);
end;

procedure TCompiler.WriteCodeR(var Ofs: Integer; Reg: TRegister);
begin
  WriteCodeV(Ofs, FCode.Registers.IndexOf(Reg));
end;

procedure TCompiler.WriteCodeV(var Ofs: Integer; Value: Integer);
begin
  Assert(Value >= 0);
  if Value < 254 then
    WriteCodeB(Ofs, Value)
  else
  if Value <= $FFFF then
  begin
    WriteCodeB(Ofs, 254);
    WriteCodeW(Ofs, Value);
  end else begin
    WriteCodeB(Ofs, 255);
    WriteCodeL(Ofs, Value);
  end;
end;

procedure TCompiler.WriteCodeOpV(var Ofs: Integer; OpCode: TOpCode; Value: Integer);
begin
  WriteCodeB(Ofs, Ord(OpCode));
  WriteCodeV(Ofs, Value);
end;

procedure TCompiler.WriteCodeOpR(var Ofs: Integer; OpCode: TOpCode; Reg: TRegister);
begin
  WriteCodeB(Ofs, Ord(OpCode));
  WriteCodeR(Ofs, Reg);
end;

procedure TCompiler.WriteCodeOpRV(var Ofs: Integer; OpCode: TOpCode; Reg: TRegister; Value: Integer);
begin
  WriteCodeOpR(Ofs, OpCode, Reg);
  WriteCodeV(Ofs, Value);
end;

procedure TCompiler.WriteCodeOpRR(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2: TRegister);
begin
  WriteCodeOpR(Ofs, OpCode, Reg1);
  WriteCodeR(Ofs, Reg2);
end;

procedure TCompiler.WriteCodeOpRRV(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2: TRegister; Value: Integer);
begin
  WriteCodeOpRR(Ofs, OpCode, Reg1, Reg2);
  WriteCodeV(Ofs, Value);
end;

procedure TCompiler.WriteCodeOpRRR(var Ofs: Integer; OpCode: TOpCode; Reg1, Reg2, Reg3: TRegister);
begin
  WriteCodeOpRR(Ofs, OpCode, Reg1, Reg2);
  WriteCodeR(Ofs, Reg3);
end;

procedure TCompiler.GenCode(Code: TCodeSection);
var
  Index: Integer;
  CodeLen: Integer;
  CodePos: Integer;
  SizePos: Integer;
  Statement: TStatement;
begin
  for Index := 0 to Code.Childs.Count - 1 do
    GenCode(TCodeSection(Code.Childs[Index]));

  CodePos := Length(FByteCode.Code);

  if Code = FMain then
    FByteCode.Start := CodePos;

  CodeLen := 1 // Code Format
           + 4 // RegCount
           + 4 // LabelCount
           + 4 // CodeLen
           + Code.CodeSize
           + 1 // opReturn
           + Code.Labels.Count * 4;

  SetLength(FByteCode.Code, CodePos + CodeLen);

// CodeFormat
  WriteCodeB(CodePos, 1);

// RegCount
  WriteCodeV(CodePos, Code.Registers.Count);

// Labels
  WriteCodeV(CodePos, Code.Labels.Count);

// Code
  SizePos := CodePos;
  WriteCodeL(CodePos, Code.CodeSize + 1); // + opReturn

  FCode := Code;
  CodeLen := CodePos;
  for Index := 0 to Code.Statements.Count - 1 do
  begin
    Statement := Code.Statements[Index];
    Assert(CodePos <= Statement.Ofs + CodeLen);
    Statement.Ofs := CodePos;
    case Statement.Kind of
      skNop     : ;
      skLoadInt : WriteCodeOpRV(CodePos, opLoadInt, Statement.Param1, FValues.IndexOf(Statement.Symbol) - Length(FByteCode.Strings));
      skLoadStr : WriteCodeOpRV(CodePos, opLoadStr, Statement.Param1, FValues.IndexOf(Statement.Symbol));
      skLabel   : ;
      skGoto    : WriteCodeOpV(CodePos, opGotoLabel, Code.Labels.IndexOf(Statement.Addr));
      skJumpiEQ : WriteCodeOpRRV(CodePos, opJumpiEQ, Statement.Param1, Statement.Param2, Code.Labels.IndexOf(Statement.Addr));
      skJumpTrue: WriteCodeOpRV(CodePos, opJumpTrue, Statement.Param1, Code.Labels.IndexOf(Statement.Addr));
      skAssign  : WriteCodeOpRR(CodePos, opAssign, Statement.Param1, Statement.Param2);
      skiIncr   : WriteCodeOpR(CodePos, opiIncr, Statement.Param1);
      skiLT     : WriteCodeOpRRR(CodePos, opiLT, Statement.Param1, Statement.Param2, Statement.Param3);
      skIMul    : WriteCodeOpRR(CodePos, opIMul, Statement.Param1, Statement.Param2);
      skConcat  : WriteCodeOpRR(CodePos, opConcat, Statement.Param1, Statement.Param2);
      skWriteInt: WriteCodeOpV(CodePos, opWriteInt, Code.Registers.IndexOf(Statement.Param1));
      skWriteStr: WriteCodeOpV(CodePos, opWriteStr, Code.Registers.IndexOf(Statement.Param1));
    else
      raise Exception.Create('Unsupported statement');
    end;
  end;
  WriteCodeB(CodePos, Ord(opReturn));

  WriteCodeL(SizePos, CodePos);
  for Index := 0 to Code.Labels.Count - 1 do
  begin
    WriteCodeV(CodePos, TStatement(Code.Labels[Index]).Ofs);
  end;

  SetLength(FByteCode.Code, CodePos);
end;

function TCompiler.GetJumpiEQ(R1, R2: TRegister): TStatement;
begin
  Result := FCode.NewStatement(OP_RRV);
  Result.Kind := skJumpiEQ;
  Result.Param1 := R1;
  Result.Param2 := R2;
end;

function TCompiler.GetJumpTrue(R: TRegister): TStatement;
begin
  Result := FCode.NewStatement(OP_RV);
  Result.Kind := skJumpTrue;
  Result.Param1 := R;
end;

function TCompiler.GetLocalVar: TSymbol;
var
  Name  : string;
  Index : Integer;
  Symbol: TSymbol;
begin
  Name := FParser.GetIdent;
  for Index := FCode.Symbols.Count - 1 downto 0 do
  begin
    Symbol := FCode.Symbols[Index];
    if SameText(Symbol.Name, Name)  then
    begin
      if Symbol.Kind <> TSymbolKind.skVariableName then
        Break;
      FCode.Needs.Add(Symbol);
      Exit(Symbol);
    end;
  end;
  Result := nil;
  FParser.Error('Not a local variable');
end;

function TCompiler.GetLocalVarReg: TRegister;
var
  V: TSymbol;
  I: Integer;
begin
  V := GetLocalVar;
  for I := 0 to FCode.Registers.Count - 1 do
  begin
    Result := FCode.Registers[I];
    if Result.Symbol = V then
      Exit;
  end;
  Result := FCode.NewRegister;
  Result.Symbol := V;
  Result.TypeDef := V.TypeRef.TypeDef;
end;

function TCompiler.GetTypeRef: TTypeRef;
var
  Symbol: TSymbol;
begin
  Symbol := GetSymbol;
  if Symbol.Kind <> TSymbolKind.skTypeName then
    FParser.Error('Not a type name');
  Result := Symbol.TypeRef;
end;

function TCompiler.GoLabel(L: TStatement): TStatement;
begin
  Result := FCode.NewStatement(OP_V);
  Result.Kind := skGoto;
  Result.Addr := L;
end;

procedure TCompiler.IdentStatement;
var
  Symbol: TSymbol;
begin
  case GetBuiltIn(FParser.Token) of
    biWrite  : WriteStatement(False);
    biWriteLn: WriteStatement(True);
    biInc    : IncStatement();
  else
    Symbol := GetSymbol;
    case Symbol.Kind of
      skString      : FParser.Error('Unexpected string');
      skNumber      : FParser.Error('Unexpected number');
      skProgramName : FParser.Error('Unsupported syntax');
      skVariableName: VariableStatement(Symbol);
      skTypeName    : FParser.Error('Unsupported syntax');
    end;
  end;
end;

procedure TCompiler.IncStatement;
begin
  FParser.Next();
  FParser.DropChar('(');
  FCode.IncReg(Expression);
  FParser.DropChar(')');
end;

procedure TCompiler.Statements;
begin
  while not FParser.SkipKeyword(kwEnd) do
  begin
    Statement;
    if FParser.Keyword <> kwEnd then
      FParser.SemiColon;
  end;
end;

procedure TCompiler.KeywordStatement;
begin
  case FParser.SkipKeywords([kwBegin, kwFor, kwWhile]) of
    kwBegin: Statements;
    kwFor  : ForStatement;
    kwWhile: WhileStatement;
  else
    FParser.Error('Unexpected keyword "' + FParser.Token + '"');
  end;
end;

procedure TCompiler.Log(const Msg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, Msg);
end;

function TCompiler.OpAdd(R1, R2: TRegister): TRegister;
var
  S: TStatement;
begin
  S := FCode.NewStatement(OP_RR);
  S.Kind := skConcat;
  S.Param1 := R1;
  S.Param2 := R2;
  Result := R1;
end;

function TCompiler.OpMult(R1, R2: TRegister): TRegister;
var
  S: TStatement;
begin
  S := FCode.NewStatement(OP_RR);
  S.Kind := skIMul;
  S.Param1 := R1;
  S.Param2 := R2;
  Result := R1;
end;

function TCompiler.OpLT(R1, R2: TRegister): TRegister;
var
  S: TStatement;
begin
  Result := FCode.NewRegister;
  S := FCode.NewStatement(OP_RRR);
  S.Kind := skiLT;
  S.Param1 := R1;
  S.Param2 := R2;
  S.Param3 := Result;
end;

procedure TCompiler.SetReg(Target, Value: TRegister);
var
  S: TStatement;
begin
  S := FCode.NewStatement(OP_RR);
  S.Kind := skAssign;
  S.Param1 := Target;
  S.Param2 := Value;
end;

procedure TCompiler.Statement;
begin
  case FParser.CharType of
    ctIdent  : IdentStatement;
    ctKeyword: KeywordStatement;
  else
    FParser.Error('Unknow statement');
  end;
end;

function TCompiler.SystemType(const AName: string; BaseType: TSystemType): TSymbol;
begin
  Result := AddSymbol(AName);
  Result.Kind := skTypeName;
  Result.TypeRef := AddTypeRef(AddTypeDef(BaseType));
  Result.TypeRef.Symbol := Result;
end;

function TCompiler.Variable: TSymbol;
var
  Next : TSymbol;
begin
  Result := AddSymbol(FParser.GetIdent);
  Log('var ' + Result.Name);
  Result.Kind := TSymbolKind.skVariableName;
  if FParser.SkipChar(',') then
  begin
    Next := Variable();
    Result.TypeRef := Next.TypeRef;
  end else begin
    FParser.DropChar(':');
    Result.TypeRef := GetTypeRef;
  end;
end;

procedure TCompiler.Variables;
begin
  repeat
    Variable();
  until FParser.CharType <> ctIdent;
  FParser.SemiColon;
end;

procedure TCompiler.VariableStatement(Variable: TSymbol);
var
  V: TRegister;
begin
  FParser.DropCharType(ctAssign);
  V := FCode.LoadSymbol(Variable);
  SetReg(V, Expression);
end;

procedure TCompiler.WriteStatement(Ln: Boolean);
var
  e: TRegister;
begin
  FParser.Next();
  if FParser.SkipChar('(') then
  begin
    while not FParser.SkipChar(')') do
    begin
      e := Expression;
      if e.TypeDef = FString.TypeRef.TypeDef then
         WriteStr(e)
      else
      if e.TypeDef = FInteger.TypeRef.TypeDef then
         WriteInt(e)
      else
        FParser.Error('Can''t write this expression');
      if FParser.CharType <> ctRParent then
        FParser.DropChar(',');
    end;
  end;
  if Ln then
  begin
    e := FCode.LoadSymbol(GetString(#13#10));
    FCode.LoadRegSymbol(skLoadStr, e);
    WriteStr(e);
  end;
end;

function TCompiler.WriteStr(R: TRegister): TStatement;
begin
  Result := FCode.NewStatement(OP_R);
  Result.Kind := skWriteStr;
  Result.Param1 := R;
end;

function TCompiler.WriteInt(R: TRegister): TStatement;
begin
  Result := FCode.NewStatement(OP_R);
  Result.Kind := skWriteInt;
  Result.Param1 := R;
end;

function TCompiler.AddSymbol(const AName: string): TSymbol;
begin
  Result := TSymbol.Create;
  Result.Name := AName;
  FCode.Symbols.Add(Result);
end;

function TCompiler.AddTypeDef(BaseType: TSystemType): TTypeDef;
begin
  Result := TTypeDef.Create;
  Result.Base := BaseType;
  FGarbage.Add(Result);
end;

function TCompiler.AddTypeRef(TypeDef: TTypeDef): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.TypeDef := TypeDef;
  FGarbage.Add(Result);
end;

procedure TCompiler.Clear;
begin
  FByteCode.Clear;
  FMain.Clear;
  ClearList(FValues);
  ClearList(FGarbage);
end;

procedure TCompiler.Compile(Lines: TStrings);
begin
  Log('Start');
  Clear;
  FParser.Init(Lines.Text);
// Code
  FCode := FMain;
  FInteger := SystemType('Integer', stInteger);
  FString := SystemType('String', stString);
// program <ident>;
  FParser.DropKeyword(kwProgram);
  Log('Program ' + FParser.Token);
  AddSymbol(FParser.GetIdent);
  FParser.DropChar(';');
  while not FParser.SkipKeyword(kwBegin) do
  begin
    case FParser.SkipKeywords([kwVar]) of
      kwVar: Variables();
    else
      FParser.Error('Unexpected token');
    end;
  end;
// begin
  Statements;
// end.
  if FParser.Token <> '.' then
    raise Exception.Create('Final dot expected');
// ByteCode
  GenByteCode;
end;

end.

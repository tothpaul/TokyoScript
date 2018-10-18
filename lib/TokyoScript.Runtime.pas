unit TokyoScript.Runtime;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}
interface

uses
  System.Classes,
  System.SysUtils;

const
  FLAG_CONSOLE = 1;

type
  TOpCode = (
    opReturn,    // empty
    opGotoLabel, // goto vLabel
    opJumpiEQ,   // if vReg1 = vReg2 then goto vLabel
    opJumpTrue,  // if vReg then goto vLabel
    opAssign,    // vReg1 := vReg2
    opiIncr,     // Inc(vReg1)
    opIMul,      // vReg1 *= VReg2
    opiLT,       // vReg3 := vReg1 < vReg2
    opConcat,    // vReg1 += vReg2
    opLoadInt,   // vReg1 := vValue
    opLoadStr,   // vReg1 := vString
    opWriteInt,  // Write(vReg1)
    opWriteStr   // Write(vReg1)
  );

  TByteCode = class
    Version: Word;
    Flags  : Word;
    Strings: TArray<string>;
    Values : TArray<Integer>;
    Start  : Integer;
    Code   : TArray<Byte>;
    procedure Clear;
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(AStream: TStream);
  end;

  TWriteStrEvent = procedure(Sender: TObject; const Value: string) of object;

  TRuntime = class
  private
    FOnWriteStr: TWriteStrEvent;
  public
    procedure Execute(ByteCode: TByteCode);
    procedure WriteStr(const Str: string); virtual;
    property OnWriteStr: TWriteStrEvent read FOnWriteStr write FOnWriteStr;
  end;

implementation

const
  SIGN   : array[0..3] of AnsiChar = 'TKS1';
  VER    = 1;

{ TByteCode }

procedure TByteCode.Clear;
begin
  Version := 0;
  Flags := 0;
  Strings := nil;
  Values := nil;
  Start := 0;
  Code := nil;
end;

procedure TByteCode.LoadFromFile(const AFileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TByteCode.LoadFromStream(AStream: TStream);
var
  Count: Integer;
  Index: Integer;
  Len  : Integer;
begin
  Clear;
  try
    AStream.ReadBuffer(Count, SizeOf(Count));
    if Count <> Integer(SIGN) then
      raise Exception.Create('Not a TokyoScript file');
    AStream.ReadBuffer(Version, SizeOf(Version));
    if Version <> VER then
      raise Exception.Create('Unsupported version');
    AStream.ReadBuffer(Flags, SizeOf(Flags));
    AStream.ReadBuffer(Count, SizeOf(Count));
    SetLength(Strings, Count);
    for Index := 0 to Count - 1 do
    begin
      AStream.ReadBuffer(Len, SizeOf(Len));
      if Len > 0 then
      begin
        SetLength(Strings[Index], Len);
        AStream.Read(Strings[Index][1], Len * SizeOf(Char));
      end;
    end;
    AStream.ReadBuffer(Count, SizeOf(Count));
    if Count > 0 then
    begin
      SetLength(Values, Count);
      AStream.ReadBuffer(Values[0], Count * SizeOf(Integer));
    end;
    AStream.ReadBuffer(Len, SizeOf(Len));
    if Len > 0 then
    begin
      SetLength(Code, Len);
      AStream.Read(Code[0], Len);
    end;
  except
    Clear;
    raise;
  end;
end;

procedure TByteCode.SaveToFile(const AFileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TByteCode.SaveToStream(AStream: TStream);
var
  Count: Integer;
  Index: Integer;
  Len  : Integer;
begin
  AStream.Write(SIGN, SizeOf(SIGN));
  Version := VER;
  AStream.Write(Version, SizeOf(Version));
  AStream.Write(Flags, SizeOf(Flags));
  Count := Length(Strings);
  AStream.Write(Count, SizeOf(Count));
  for Index := 0 to Count - 1 do
  begin
    Len := Length(Strings[Index]);
    AStream.Write(Len, SizeOf(Len));
    if Len > 0 then
      AStream.Write(Strings[Index][1], Len * SizeOf(Char));
  end;
  Count := Length(Values);
  AStream.Write(Count, SizeOf(Count));
  if Count > 0 then
    AStream.Write(Values[0], Count * SizeOf(Integer));
  Len := Length(Code);
  AStream.Write(Len, SizeOf(Len));
  if Len > 0 then
    AStream.Write(Code[0], Len)
end;

{ TContext }

type
  TRegister = record
    AsInteger: Integer;
    AsString : string;
    procedure LoadInt(Value: Integer);
    procedure LoadStr(const Str: string);
    procedure Assign(const Reg: TRegister);
  end;

  TContext = record
    RT  : TRuntime;
    BC  : TByteCode;
    EOC : Integer;
    PC  : Integer;
    Regs: TArray<TRegister>;
    Lbls: TArray<Integer>;
    procedure Get(var Data; Size: Integer);
    function GetByte: Byte; inline;
    function GetWord: Word; inline;
    function GetShort: SmallInt; inline;
    function GetLong: Integer; inline;
    function GetVarLen: Integer;
    function GetValue: Integer;
    function GetString: string;
    function GetReg: Integer;
    function GetLabel: Integer;
    procedure Start;
    procedure Run;
    function Next: TOpCode;
    procedure LoadInt;
    procedure LoadStr;
    procedure WriteInt;
    procedure WriteStr;
    procedure AssignRegs;
    procedure iIncr;
    procedure iLT;
    procedure JumpiEQ;
    procedure JumpTrue;
    procedure GotoLabel;
  end;

{ TRegister }

procedure TRegister.Assign(const Reg: TRegister);
begin
  AsInteger := Reg.AsInteger;
  AsString := Reg.AsString;
end;

procedure TRegister.LoadInt(Value: Integer);
begin
  AsInteger := Value;
end;

procedure TRegister.LoadStr(const Str: string);
begin
  AsString := Str;
end;

{ TContext }

procedure TContext.Get(var Data; Size: Integer);
begin
  if PC + Size > Length(BC.Code) then
    raise Exception.Create('Code overflow');
  Move(BC.Code[PC], Data, Size);
  Inc(PC, Size);
end;

function TContext.GetByte: Byte;
begin
  Get(Result, SizeOf(Result));
end;

function TContext.GetWord: Word;
begin
  Get(Result, SizeOf(Result));
end;

function TContext.GetShort: SmallInt;
begin
  Get(Result, SizeOf(Result));
end;

function TContext.GetLong: Integer;
begin
  Get(Result, SizeOf(Result));
end;

function TContext.GetVarLen: Integer;
begin
  Result := GetByte;
  case Result of
    254: Result := GetWord;
    255: Result := GetLong;
  end;
end;

function TContext.GetString: string;
var
  Index: Integer;
begin
  Index := GetVarLen;
  if Index >= Length(BC.Strings) then
    raise Exception.Create('Strings index overflow');
  Result := BC.Strings[Index];
end;

function TContext.GetValue: Integer;
begin
  Result := GetVarLen;
  if Result >= Length(BC.Values) then
    raise Exception.Create('Values overflow');
  Result := BC.Values[Result];
end;

function TContext.GetLabel: Integer;
begin
  Result := GetVarLen;
  if Result >= Length(Lbls) then
    raise Exception.Create('Labels overflow');
  Result := Lbls[Result];
end;

function TContext.GetReg: Integer;
begin
  Result := GetVarLen;
  if Result >= Length(Regs) then
    raise Exception.Create('Register overflow');
end;

procedure TContext.AssignRegs;
var
  R1, R2: Integer;
begin
  R1 := GetReg;
  R2 := GetReg;
  Regs[R1].Assign(Regs[R2]);
end;

procedure TContext.iIncr;
var
  R: Integer;
begin
  R := GetReg;
  Inc(Regs[R].AsInteger);
end;

procedure TContext.iLT;
var
  R1: Integer;
  R2: Integer;
  R3: Integer;
begin
  R1 := GetReg;
  R2 := GetReg;
  R3 := GetReg;
  Regs[R3].AsInteger := Ord(Regs[R1].AsInteger < Regs[R2].AsInteger);
end;

procedure TContext.GotoLabel;
begin
  PC := GetLabel;
end;

procedure TContext.JumpiEQ;
var
  R1: Integer;
  R2: Integer;
  AD: Integer;
begin
  R1 := GetReg;
  R2 := GetReg;
  AD := GetLabel;
  if Regs[R1].AsInteger = Regs[R2].AsInteger then
    PC := AD;
end;

procedure TContext.JumpTrue;
var
  R: Integer;
  A: Integer;
begin
  R := GetReg;
  A := GetLabel;
  if Regs[R].AsInteger <> 0 then
    PC := A;
end;

procedure TContext.LoadInt;
var
  R: Integer;
begin
  R := GetReg;
  Regs[R].LoadInt(GetValue);
end;

procedure TContext.LoadStr;
var
  R: Integer;
begin
  R := GetReg;
  Regs[R].LoadStr(GetString);
end;

procedure TContext.WriteInt;
var
  R: Integer;
begin
  R := GetReg;
  RT.WriteStr(IntToStr(Regs[R].AsInteger));
end;

procedure TContext.WriteStr;
var
  R: Integer;
begin
  R := GetReg;
  RT.WriteStr(Regs[R].AsString);
end;

procedure TContext.Start;
begin
  PC := BC.Start;
  case GetByte of
    1: Run; // Format 1
  else
    raise Exception.Create('Unsupported code version');
  end;
end;

procedure TContext.Run;
var
  Save : Integer;
  Index: Integer;
begin
// Registers Count
  SetLength(Regs, GetVarLen);
// Labels count
  SetLength(Lbls, GetVarLen);
// End of code Offset
  EOC := GetLong;
  if EOC > Length(BC.Code) then
    raise Exception.Create('Code overflow');
// get Labels offsets
  if Length(Lbls) > 0 then
  begin
    Save := PC;
    PC := EOC;
    for Index := 0 to Length(Lbls) - 1 do
      Lbls[Index] := GetVarLen;
    PC := Save;
  end;
// execute byte code until opReturn
  repeat until Next() = opReturn;
end;

function TContext.Next: TOpCode;
begin
  Result := TOpCode(GetByte);
  case Result of
    opReturn    : { done };
    opLoadInt   : LoadInt;
    opiIncr     : iIncr;
    opLoadStr   : LoadStr;
    opWriteInt  : WriteInt;
    opWriteStr  : WriteStr;
    opJumpiEQ   : JumpiEQ;
    opJumpTrue  : JumpTrue;
    opiLT       : iLT;
    opAssign    : AssignRegs;
    opGotoLabel : GotoLabel;
  else
    raise Exception.Create('Unknow opcode #' + IntToStr(Ord(Result)));
  end;
end;


{ TRuntime }

procedure TRuntime.Execute(ByteCode: TByteCode);
var
  C: TContext;
begin
  if ByteCode.Version <> VER then
    raise Exception.Create('Unsupported version');
  C.RT := Self;
  C.BC := ByteCode;
  C.Start;
end;

procedure TRuntime.WriteStr(const Str: string);
begin
  if Assigned(FOnWriteStr) then
    FOnWriteStr(Self, Str);
end;

end.

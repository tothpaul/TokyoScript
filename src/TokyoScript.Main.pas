unit TokyoScript.Main;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEditHighlighter, SynHighlighterPas,
  SynEdit, Vcl.StdCtrls, Vcl.ExtCtrls,
  TokyoScript.Parser,
  TokyoScript.Compiler,
  TokyoScript.Runtime;


type
  TMain = class(TForm)
    SynEdit: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    Panel1: TPanel;
    btRun: TButton;
    mmLog: TMemo;
    cbSource: TComboBox;
    spLog: TSplitter;
    mmDump: TMemo;
    Splitter1: TSplitter;
    procedure btRunClick(Sender: TObject);
    procedure cbSourceChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
    FConsole: Boolean;
    procedure OnLog(Sender: TObject; const Msg: string);
    procedure OnWriteStr(Sender: TObject; const Msg: string);
    procedure Dump(ByteCode: TByteCode);
  public
    { Déclarations publiques }
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

function GetConsoleWindow: HWnd; stdcall; external 'kernel32.dll';

procedure ClearConsole;
var
  hConsole: THandle;
  Coord: TCoord;
  Info: TConsoleScreenBufferInfo;
  Count: Cardinal;
begin
  hConsole := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(hConsole, Info);
  Coord.X := 0;
  Coord.Y := 0;
  FillConsoleOutputCharacter(hConsole, ' ', Info.dwSize.X * Info.dwSize.Y, Coord, Count);
  SetConsoleCursorPosition(hConsole, Coord);
  BringWindowToTop(GetConsoleWindow);
end;

procedure TMain.btRunClick(Sender: TObject);
var
  Compiler: TCompiler;
  Runtime : TRuntime;
begin
  mmLog.Clear;
  spLog.Hide;
  mmLog.Hide;

  Compiler := TCompiler.Create;
  try
    try
      Compiler.OnLog := OnLog;
      Compiler.Compile(SynEdit.Lines);
      Compiler.ByteCode.SaveToFile('output.tks');
    except
      on e: ESourceError do
      begin
        SynEdit.CaretX := e.Col;
        SynEdit.CaretY := e.Row;
        SynEdit.SetFocus;
        OnLog(Self, e.Message);
        Abort;
      end;
      on e: Exception do
      begin
        OnLog(Self, e.Message);
        Abort;
      end;
    end;

    Dump(Compiler.ByteCode);

    OnLog(Self, 'Start');
    OnLog(Self, '');
    FConsole := (Compiler.ByteCode.Flags and FLAG_CONSOLE) <> 0;
    if FConsole then
    begin
      AllocConsole;
      ClearConsole;
    end;
    Runtime := TRuntime.Create;
    try
      Runtime.OnWriteStr := OnWriteStr;
      try
        Runtime.Execute(Compiler.ByteCode);
      except
        on e: Exception do
          OnLog(Self, e.Message);
      end;
    finally
      Runtime.Free;
    end;
    OnLog(Self, 'Done.');
  finally
    Compiler.Free;
  end;
end;

procedure TMain.cbSourceChange(Sender: TObject);
var
  Index: Integer;
  Stream: TResourceStream;
begin
  Index := cbSource.ItemIndex + 1;
  Stream := TResourceStream.Create(hInstance, 'DEMO' + IntToStr(Index), RT_RCDATA);
  try
    SynEdit.Lines.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TMain.Dump(ByteCode: TByteCode);
var
  St: string;
  PC: Integer;
  Lbl : TArray<Integer>;
  Ends: Integer;
  Next: Integer;

  function GetByte: Byte;
  begin
    Result := ByteCode.Code[PC];
    Inc(PC);
  end;

  function GetWord: Word;
  begin
    Move(ByteCode.Code[PC], Result, SizeOf(Result));
    Inc(PC, SizeOf(Result));
  end;

  function GetLong: Integer;
  begin
    Move(ByteCode.Code[PC], Result, SizeOf(Result));
    Inc(PC, SizeOf(Result));
  end;

  function GetVarLen: Integer;
  begin
    Result := GetByte;
    case Result of
      254: Result := GetWord;
      255: Result := GetLong;
    end;
  end;

  function GetLabels: Integer;
  var
    Save: Integer;
    Index: Integer;
  begin
    Save := PC;
    PC := Ends;
    for Index := 0 to Length(Lbl) - 1 do
      Lbl[Index] := GetVarLen;
    Result := PC;
    PC := Save;
  end;

  procedure Add(const Str: string);
  begin
    mmDump.Lines.Add(St + Str);
  end;

  function Reg: string;
  begin
    Result := 'r' + IntToStr(GetVarLen);
  end;

  function Str: string;
  begin
    Result := ByteCode.Strings[GetVarLen];
    Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  end;

  function Val: string;
  begin
    Result := IntToStr(ByteCode.Values[GetVarLen]);
  end;

  function Adr: string;
  begin
    Result := '@' + IntToHex(Lbl[GetVarLen], 4);
  end;

begin
  mmDump.Clear;
  PC := 0;
  while PC < Length(ByteCode.Code) do
  begin
    St := '';
    Add('// Format: ' + IntToStr(GetByte));
    Add('// Regs  : ' + IntToSTr(GetVarLen));
    SetLength(Lbl, GetVarLen);
    Add('// Labels: ' + IntToSTr(Length(Lbl)));
    Ends := GetLong;
    Add('// Ends  : $' + IntToHex(Ends, 4));
    Next := GetLabels();
    Add('// Next  : $' + IntToHex(Next, 4));
    while PC < Ends do
    begin
      St := IntToHex(PC, 4) + ' ';
      case TOpCode(GetByte) of
        opReturn   : Add('opReturn');
        opGotoLabel: Add('opGoto     ' + Adr);
        opJumpiEQ  : Add('opJumpiEQ  ' + Reg + ', ' + Reg + ', '+ Adr);
        opJumpTrue : Add('opJumpTrue ' + Reg + ', ' + Adr);
        opLoadInt  : Add('opLoadInt  ' + Reg + ', ' + Val);
        opLoadStr  : Add('opLoadStr  ' + Reg + ', ' + Str);
        opWriteInt : Add('opWriteInt ' + Reg);
        opWriteStr : Add('opWriteStr ' + Reg);
        opAssign   : Add('opAssign   ' + Reg + ', ' + Reg);
        opiIncr    : Add('opiIncr    ' + Reg);
        opiLT      : Add('opiLT      ' + Reg + ', ' + Reg + ', ' + Reg);
      else
        Add(IntToStr(ByteCode.Code[PC - 1]) + '?');
        break;
      end;
    end;
    PC := Next;
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Index : Integer;
  Demo  : string;
begin
  Index := 1;
  Demo := 'DEMO1';
  while FindResource(hInstance, PChar(Demo), RT_RCDATA) <> 0 do
  begin
    cbSource.Items.Add('Demo' + IntToStr(Index) + '.pas');
    Inc(Index);
    Demo := 'DEMO' + IntToStr(Index);
  end;
  cbSource.ItemIndex := 0;
  cbSourceChange(Self);
end;

procedure TMain.OnLog(Sender: TObject; const Msg: string);
begin
  mmLog.Lines.Add(Msg);
  mmLog.Show;
  spLog.Show;
end;

procedure TMain.OnWriteStr(Sender: TObject; const Msg: string);
var
  Index: Integer;
begin
  if FConsole then
    Write(Msg)
  else begin
    if Msg = #13#10 then
      mmLog.Lines.Add('')
    else begin
      Index := mmLog.Lines.Count - 1;
      if Index < 0 then
        mmLog.Lines.Add(Msg)
      else
        mmLog.Lines[Index] := mmLog.Lines[Index] + Msg;
    end;
  end;
end;

end.

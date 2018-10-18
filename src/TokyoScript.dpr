program TokyoScript;

{$R 'Demos.res' 'Demos.rc'}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  TokyoScript.Main in 'TokyoScript.Main.pas' {Main},
  TokyoScript.Compiler in '..\lib\TokyoScript.Compiler.pas',
  TokyoScript.Runtime in '..\lib\TokyoScript.Runtime.pas',
  TokyoScript.Chars in '..\lib\TokyoScript.Chars.pas',
  TokyoScript.Keywords in '..\lib\TokyoScript.Keywords.pas',
  TokyoScript.Parser in '..\lib\TokyoScript.Parser.pas',
  TokyoScript.BuiltIn in '..\lib\TokyoScript.BuiltIn.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.

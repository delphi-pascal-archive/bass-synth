program Synth;

uses
  Forms,
  uMain in 'uMain.pas' {MainForm},
  uConstanteBASS in 'uConstanteBASS.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

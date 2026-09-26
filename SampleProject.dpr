program SampleProject;

uses
  Vcl.Forms,
  RaylibSandbox in 'RaylibSandbox.pas',
  JoltPhysics in 'JoltPhysics.pas',
  ModelEngine in 'ModelEngine.pas',
  Unit1 in 'Unit1.pas' {Form1},
  VCL3D in 'VCL3D.pas',
  MPVManager in 'MPVManager.pas',
  MPVEmbedded in 'MPVEmbedded.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

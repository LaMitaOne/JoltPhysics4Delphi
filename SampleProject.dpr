program SampleProject;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  RaylibSandbox in 'RaylibSandbox.pas',
  JoltPhysics in 'JoltPhysics.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RaylibSandbox;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Sandbox: TRaylibSandbox;
begin
  Sandbox := TRaylibSandbox.Create(Self);
  Sandbox.Parent := Self;
  Sandbox.Align := alClient;
  Sandbox.Active := True;
end;

end.

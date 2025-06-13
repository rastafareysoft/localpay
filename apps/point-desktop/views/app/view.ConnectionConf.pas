unit view.ConnectionConf;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.App, FMX.Controls.Presentation,
  FMX.Layouts, FMX.Edit, FMX.ListBox;

type
  TvConnectionConf = class(TvApp)
    Layout1: TLayout;
    Label1: TLabel;
    cbbModelo: TComboBox;
    Layout2: TLayout;
    Label2: TLabel;
    cbbPort: TComboBox;
    Layout3: TLayout;
    Label3: TLabel;
    cbbBauds: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    btnTest: TButton;
    Layout4: TLayout;
    lblMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vConnectionConf: TvConnectionConf;

implementation

{$R *.fmx}

uses types.App, dll.SL500;

procedure TvConnectionConf.btnTestClick(Sender: TObject);
Const
  __COLORS: Array[Boolean] Of TAlphaColor = (TAlphaColorRec.Darkred, TAlphaColorRec.Darkgreen);
begin
  inherited;
  If SL500_OpenPort(cbbPort.ItemIndex+1, TBauds(cbbBauds.ItemIndex)) Then Begin
    SL500_Beep(10);
    lblMessage.TextSettings.FontColor := __COLORS[True];
    lblMessage.Text := 'Conexión existosa.';
    SL500_ClosePort;
  End Else Begin
    lblMessage.TextSettings.FontColor := __COLORS[False];
    lblMessage.Text := 'Conexión fallida.';
  End;
end;

procedure TvConnectionConf.FormCreate(Sender: TObject);
begin
  //inherited; Not Get Position
  IdModule := mdConnectionConf;
end;

procedure TvConnectionConf.FormDestroy(Sender: TObject);
begin
  //inherited; Not Set Position
end;

end.

unit view.DeviceConfiguration;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.Edit;

type
  TvDeviceConfiguration = class(TForm)
    Z: TLayout;
    Layout3: TLayout;
    Label3: TLabel;
    Layout1: TLayout;
    Label4: TLabel;
    Layout4: TLayout;
    Label5: TLabel;
    Layout7: TLayout;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vDeviceConfiguration: TvDeviceConfiguration;

implementation

{$R *.fmx}

procedure TvDeviceConfiguration.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Constraints.MinHeight + 36;
  Constraints.MinWidth := Constraints.MinWidth + 14;
  Left := Trunc((Screen.Width/2) - (Width/2));
  Top := Trunc((Screen.Height/2) - (Height/2));
end;

end.

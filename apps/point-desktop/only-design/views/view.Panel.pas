unit view.Panel;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TvPanel = class(TForm)
    Z: TLayout;
    Layout7: TLayout;
    Button1: TButton;
    Button2: TButton;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vPanel: TvPanel;

implementation

{$R *.fmx}

uses view.DeviceConfiguration, view.PlaceBalance, view.UpdateData;

procedure TvPanel.Button1Click(Sender: TObject);
begin
  With TvUpdateData.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.Button2Click(Sender: TObject);
begin
  With TvPlaceBalance.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.Button4Click(Sender: TObject);
begin
  With TvDeviceConfiguration.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Constraints.MinHeight + 36;
  Constraints.MinWidth := Constraints.MinWidth + 14;
  Left := Trunc((Screen.Width/2) - (Width/2));
  Top := 50;
  //Top := Trunc((Screen.Height/2) - (Height/2));
end;

end.

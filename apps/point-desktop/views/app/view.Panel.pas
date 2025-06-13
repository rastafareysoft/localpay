unit view.Panel;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Graphics, FMX.Controls,
  FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.App, FMX.Layouts, FMX.Controls.Presentation;

type
  TvPanel = class(TvApp)
    tbrTop: TToolBar;
    sbtConfiguration: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure sbtConfigurationClick(Sender: TObject);
  private
  public
  end;

var
  vPanel: TvPanel;

implementation

{$R *.fmx}

uses types.App, view.ConnectionConf, files.Ini, conf.App, constt.App;

procedure TvPanel.FormCreate(Sender: TObject);
begin
  inherited;
  IdModule := mdPanel;
end;

procedure TvPanel.sbtConfigurationClick(Sender: TObject);
begin
  inherited;
  With TvConnectionConf.Create(Self) Do Try
    If ShowModal = mrOk Then
      TIni.Sett(FileConnection, __CONNECTION_SECTION, [__CONNECTION_MODEL, __CONNECTION_PORT, __CONNECTION_BAUDS], [cbbModelo.ItemIndex, cbbPort.ItemIndex+1, cbbBauds.Items[cbbBauds.ItemIndex]]);
  Finally
    Free;
  End;
end;

end.

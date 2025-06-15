unit view.DeviceConfiguration;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Graphics, FMX.Controls,
  FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.AppData, Data.Bind.EngExt, Fmx.Bind.DBEngExt, FMX.ListBox,
  Data.Bind.Components, Data.Bind.DBScope, Data.DB, Datasnap.DBClient, Fmx.Bind.Navigator, System.Actions, FMX.ActnList,
  FMX.Controls.Presentation, FMX.Layouts;

type
  TvDeviceConfiguration = class(TvAppData)
    lytModel: TLayout;
    lblModel: TLabel;
    cmbModel: TComboBox;
    lytPort: TLayout;
    lblPort: TLabel;
    cmbPort: TComboBox;
    lytBauds: TLayout;
    lblBauds: TLabel;
    cmbBauds: TComboBox;
    procedure cmbPortChange(Sender: TObject);
    procedure btnActionModuleClick(Sender: TObject);
    procedure cdsDataAfterPost(DataSet: TDataSet);
  private
  Protected
    Procedure InitializeData; Override;
  public
  end;

var
  vDeviceConfiguration: TvDeviceConfiguration;

implementation

{$R *.fmx}

uses dll.SL500, constt.App, files.Ini, conf.App;

{ TvDeviceConfiguration }

procedure TvDeviceConfiguration.btnActionModuleClick(Sender: TObject);
begin
  If SL500_OpenPort(cmbPort.ItemIndex+1, TBauds(cmbBauds.ItemIndex)) Then Begin
    SL500_Beep(10);
    MessageInfo := 'Verificación exitosa.';
    SL500_ClosePort;
  End Else
    MessageError := 'Verificación fallida.';
end;

procedure TvDeviceConfiguration.cdsDataAfterPost(DataSet: TDataSet);
begin
  inherited;
  If Not FInit Then
    TIni.Sett(FileConnection, __CONNECTION_SECTION, [__CONNECTION_MODEL, __CONNECTION_PORT, __CONNECTION_BAUDS], [cmbModel.ItemIndex, cmbPort.ItemIndex+1, cmbBauds.Items[cmbBauds.ItemIndex]]);
end;

procedure TvDeviceConfiguration.cmbPortChange(Sender: TObject);
Var
  LCmb:  TComboBox;
begin
  inherited;
  If FInit Then
    Exit;
  LCmb := TComboBox(Sender);
  If cdsData.State = dsBrowse Then
    cdsData.Edit;
  cdsData.Fields[LCmb.Tag].AsInteger := LCmb.ItemIndex;
end;

procedure TvDeviceConfiguration.InitializeData;
Var
  LIni: TArray<Variant>;
begin
  LIni := TIni.Gett(FileConnection, __CONNECTION_SECTION, [__CONNECTION_MODEL, __CONNECTION_PORT, __CONNECTION_BAUDS], [0, 0, 115200]);
  inherited;
  cdsData.CreateDataSet;
  cdsData.Insert;
  cdsData.Fields[0].AsInteger := LIni[0];
  cdsData.Fields[1].AsInteger := LIni[1]-1;
  cdsData.Fields[2].AsInteger := IndexOfBauds(LIni[2]);
  //-------------------------------------
  cmbModel.ItemIndex := cdsData.Fields[0].AsInteger;
  cmbPort.ItemIndex := cdsData.Fields[1].AsInteger;
  cmbBauds.ItemIndex := cdsData.Fields[2].AsInteger;
  cdsData.Post;
  FInit := False;
end;

end.

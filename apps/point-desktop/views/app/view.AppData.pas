unit view.AppData;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Graphics, FMX.Controls,
  FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.App, FMX.Layouts, FMX.Controls.Presentation, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, Data.DB, Datasnap.DBClient, Fmx.Bind.Navigator,
  System.Actions, FMX.ActnList;

type
  TMesageType = (msInfo, msError);

  TvAppData = class(TvApp)
    lytButtons: TLayout;
    btnActionModule: TButton;
    btnSaveData: TButton;
    btnExit: TButton;
    btnCancelData: TButton;
    lblMessage: TLabel;
    actData: TActionList;
    actSaved: TFMXBindNavigatePost;
    actCancel: TFMXBindNavigateCancel;
    cdsData: TClientDataSet;
    bnsData: TBindSourceDB;
    bnlData: TBindingsList;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    procedure SetMessageError(const Value: String);
    procedure SetMessageInfo(const Value: String);
    procedure Set__MessageType(const AMesageType: TMesageType; const Value: String);
    Property __MessageType[Const AMesageType: TMesageType]: String write Set__MessageType;
  Protected
    FInit: Boolean;
    Procedure GetIni; Override;
    Procedure InitializeData; Virtual;
  public
    Property MessageError: String write SetMessageError;
    Property MessageInfo: String write SetMessageInfo;
  end;

var
  vAppData: TvAppData;

implementation

{$R *.fmx}

Uses FMX.DialogService.Sync, files.Ini, conf.App, constt.App;

procedure TvAppData.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  inherited;
  If cdsData.State In [dsEdit, dsInsert] Then
    CanClose := TDialogServiceSync.MessageDialog('Hay cambios sin aplicar, ¿está seguro que desea salir sin guardarlos?.', TMsgDlgType.mtConfirmation, mbYesNoCancel, TMsgDlgBtn.mbCancel, 0) = mrYes;
end;

procedure TvAppData.FormCreate(Sender: TObject);
begin
  inherited;
  InitializeData;
end;

procedure TvAppData.GetIni;
Var
  LIni: TArray<Variant>;
begin
  LIni := TIni.Gett(FileConf, __POSITION_SECTION + '.' + Name, [__POSITION_LEFT, __POSITION_TOP, __POSITION_WIDTH, __POSITION_HEIGHT], [Trunc((Screen.Width/2) - (Width/2)), Trunc((Screen.Height/2) - (Height/2)), Width, Height]);
  SetBounds(LIni[0], LIni[1], LIni[2], LIni[3]);
end;

procedure TvAppData.InitializeData;
begin
  FInit := True;
end;

procedure TvAppData.SetMessageError(const Value: String);
begin
  __MessageType[msError] := Value;
end;

procedure TvAppData.SetMessageInfo(const Value: String);
begin
  __MessageType[msInfo] := Value;
end;

procedure TvAppData.Set__MessageType(const AMesageType: TMesageType; const Value: String);
Const
  __MESSAGE_COLOR: Array[TMesageType] Of TAlphaColor = (TAlphaColorRec.Darkgreen, TAlphaColorRec.Darkred);
begin
  lblMessage.Text := Value;
  lblMessage.TextSettings.FontColor := __MESSAGE_COLOR[AMesageType];
end;

end.

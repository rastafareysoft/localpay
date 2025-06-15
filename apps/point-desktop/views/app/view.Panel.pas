unit view.Panel;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Graphics, FMX.Controls,
  FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.App, FMX.Layouts, FMX.Controls.Presentation;

type
  TvPanel = class(TvApp)
    gdlPanel: TGridPanelLayout;
    btnUpdate: TButton;
    btnRecharge: TButton;
    btnRegister: TButton;
    btnConfig: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure btnRechargeClick(Sender: TObject);
  private
  Protected
    Procedure GetIni; Override;
  public
  end;

var
  vPanel: TvPanel;

implementation

{$R *.fmx}

uses types.App, files.Ini, conf.App, constt.App, view.DeviceConfiguration, view.CardRegister, view.CardUpdate,
  view.CardBalanceRecharge;

procedure TvPanel.btnConfigClick(Sender: TObject);
begin
  With TvDeviceConfiguration.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.btnRechargeClick(Sender: TObject);
begin
  With TvCardBalanceRecharge.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End

end;

procedure TvPanel.btnRegisterClick(Sender: TObject);
begin
  With TvCardRegister.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.btnUpdateClick(Sender: TObject);
begin
  With TvCardUpdate.Create(Self) Do Try
    ShowModal;
  Finally
    Free;
  End;
end;

procedure TvPanel.FormCreate(Sender: TObject);
begin
  inherited;
  IdModule := mdPanel;
end;

procedure TvPanel.GetIni;
Var
  LIni: TArray<Variant>;
begin
  LIni := TIni.Gett(FileConf, __POSITION_SECTION + '.' + Name, [__POSITION_LEFT, __POSITION_TOP, __POSITION_WIDTH, __POSITION_HEIGHT], [Trunc((Screen.Width/2) - (Width/2)), 50, Width, Height]);
  SetBounds(LIni[0], LIni[1], LIni[2], LIni[3]);
end;

end.

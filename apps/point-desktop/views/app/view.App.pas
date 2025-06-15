unit view.App;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types,  FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Layouts, types.App;

type
  TvApp = class(TForm)
    lytApp: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FIdModule: TModule;
    procedure SetIdModule(const Value: TModule);
  Protected
    Procedure GetIni; Virtual;
    Procedure SetIni; Virtual;
    Procedure SetConstraints; Virtual;
  public
    Property IdModule: TModule read FIdModule write SetIdModule;
  end;

var
  vApp: TvApp;

implementation

{$R *.fmx}

uses
  files.Ini, conf.App, constt.App;

{ TForm2 }

procedure TvApp.FormCreate(Sender: TObject);
begin
  FIdModule := mdNone;
  SetConstraints;
  GetIni;
end;

procedure TvApp.FormDestroy(Sender: TObject);
begin
  SetIni;
end;

procedure TvApp.GetIni;
Var
  LIni: TArray<Variant>;
begin
  LIni := TIni.Gett(FileConf, __POSITION_SECTION + '.' + Name, [__POSITION_LEFT, __POSITION_TOP, __POSITION_WIDTH, __POSITION_HEIGHT], [Left, Top, Width, Height]);
  SetBounds(LIni[0], LIni[1], LIni[2], LIni[3]);
end;

procedure TvApp.SetConstraints;
Const
  __INC_HEIGHT = 36;
  __INC_WIDTH = 14;
begin
  If Constraints.MinHeight <> 0 Then
    Constraints.MinHeight := Constraints.MinHeight + __INC_HEIGHT;
  If Constraints.MaxHeight <> 0 Then
    Constraints.MaxHeight := Constraints.MaxHeight + __INC_HEIGHT;
  If Constraints.MinWidth <> 0 Then
    Constraints.MinWidth := Constraints.MinWidth + __INC_WIDTH;
  If Constraints.MaxWidth <> 0 Then
    Constraints.MaxWidth := Constraints.MaxWidth + __INC_WIDTH;
end;

procedure TvApp.SetIdModule(const Value: TModule);
begin
  FIdModule := Value;
end;

procedure TvApp.SetIni;
begin
  TIni.Sett(FileConf, __POSITION_SECTION + '.' + Name, [__POSITION_LEFT, __POSITION_TOP, __POSITION_WIDTH, __POSITION_HEIGHT], [Left, Top, Width, Height]);
end;

end.

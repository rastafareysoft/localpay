unit view.CardUpdate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.AppData, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, Data.DB, Datasnap.DBClient, Fmx.Bind.Navigator,
  System.Actions, FMX.ActnList, FMX.Controls.Presentation, FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit;

type
  TvCardUpdate = class(TvAppData)
    Layout2: TLayout;
    Edit1: TEdit;
    Label2: TLabel;
    Layout3: TLayout;
    Edit2: TEdit;
    Label3: TLabel;
    Layout1: TLayout;
    Label4: TLabel;
    Edit4: TEdit;
    Layout4: TLayout;
    Label5: TLabel;
    Edit3: TEdit;
    Layout5: TLayout;
    Label6: TLabel;
    Memo1: TMemo;
    Layout6: TLayout;
    Label7: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vCardUpdate: TvCardUpdate;

implementation

{$R *.fmx}

end.

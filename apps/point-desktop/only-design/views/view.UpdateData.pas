unit view.UpdateData;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Edit, FMX.ListBox, FMX.Objects, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView;

type
  TvUpdateData = class(TForm)
    Z: TLayout;
    Edit1: TEdit;
    Layout2: TLayout;
    Label2: TLabel;
    Layout3: TLayout;
    Edit2: TEdit;
    Label3: TLabel;
    Layout1: TLayout;
    Label4: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit4: TEdit;
    Layout4: TLayout;
    Label5: TLabel;
    Edit3: TEdit;
    Layout5: TLayout;
    Label6: TLabel;
    Memo1: TMemo;
    Layout7: TLayout;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    Layout6: TLayout;
    Label7: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vUpdateData: TvUpdateData;

implementation

{$R *.fmx}

procedure TvUpdateData.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Constraints.MinHeight + 36;
  Constraints.MinWidth := Constraints.MinWidth + 14;
  Left := Trunc((Screen.Width/2) - (Width/2));
  Top := Trunc((Screen.Height/2) - (Height/2));
end;

end.

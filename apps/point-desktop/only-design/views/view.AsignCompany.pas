unit view.AsignCompany;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.Layouts, FMX.StdCtrls, FMX.ScrollBox,
  FMX.Memo, FMX.ListBox, FMX.Controls.Presentation, FMX.Edit;

type
  TvAsignCompany = class(TForm)
    Z: TLayout;
    Layout2: TLayout;
    Edit1: TEdit;
    Label2: TLabel;
    Layout7: TLayout;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    Layout1: TLayout;
    RadioButton1: TRadioButton;
    Layout4: TLayout;
    Label5: TLabel;
    Edit4: TEdit;
    Layout3: TLayout;
    RadioButton2: TRadioButton;
    Layout6: TLayout;
    Label4: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit5: TEdit;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vAsignCompany: TvAsignCompany;

implementation

{$R *.fmx}

procedure TvAsignCompany.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Constraints.MinHeight + 36;
  Constraints.MinWidth := Constraints.MinWidth + 14;
  Left := Trunc((Screen.Width/2) - (Width/2));
  Top := Trunc((Screen.Height/2) - (Height/2));
end;

end.

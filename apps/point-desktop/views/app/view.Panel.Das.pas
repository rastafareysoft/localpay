unit view.Panel.Das;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.App, FMX.Layouts,
  FMX.Controls.Presentation;

type
  TvPanel = class(TvApp)
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  vPanel: TvPanel;

implementation

{$R *.fmx}

uses types.App;

procedure TvPanel.FormCreate(Sender: TObject);
begin
  inherited;
  IdModule := mdPanel;
end;

end.

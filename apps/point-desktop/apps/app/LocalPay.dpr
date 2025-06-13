program LocalPay;

uses
  System.StartUpCopy,
  FMX.Forms,
  view.App in '..\..\views\app\view.App.pas' {vApp},
  constt.App in '..\..\const\app\constt.App.pas',
  conf.App in '..\..\models\app\conf.App.pas',
  view.Panel in '..\..\views\app\view.Panel.pas' {vPanel},
  dll.SL500 in '..\..\models\library\dll.SL500.pas',
  types.App in '..\..\types\app\types.App.pas',
  view.ConnectionConf in '..\..\views\app\view.ConnectionConf.pas' {vConnectionConf},
  constt.Map.Iso14443A in '..\..\const\app\constt.Map.Iso14443A.pas',
  types.Map in '..\..\types\app\types.Map.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TvPanel, vPanel);
  Application.Run;
end.

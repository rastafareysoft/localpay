program OnlyDesign;

uses
  System.StartUpCopy,
  FMX.Forms,
  view.App in '..\views\view.App.pas' {Form2},
  view.UpdateData in '..\views\view.UpdateData.pas' {vUpdateData},
  view.PlaceBalance in '..\views\view.PlaceBalance.pas' {vPlaceBalance},
  view.DeviceConfiguration in '..\views\view.DeviceConfiguration.pas' {vDeviceConfiguration},
  view.Panel in '..\views\view.Panel.pas' {vPanel},
  view.AsignCompany in '..\views\view.AsignCompany.pas' {vAsignCompany};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TvPanel, vPanel);
  Application.Run;
end.

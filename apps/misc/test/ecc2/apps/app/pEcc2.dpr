program pEcc2;

uses
  System.StartUpCopy,
  FMX.Forms,
  view.App in '..\..\views\app\view.App.pas' {vApp},
  view.AppPem in '..\..\views\app\view.AppPem.pas' {vAppPem},
  encryptions.EccPem in '..\..\..\..\..\..\..\libs\src\libs\encryptions.EccPem.pas',
  encryptions.Aes2 in '..\..\..\..\..\..\..\libs\src\libs\encryptions.Aes2.pas',
  view.AppAes in '..\..\views\app\view.AppAes.pas' {vAppAes},
  view.AppPemPrivate in '..\..\views\app\view.AppPemPrivate.pas' {vAppPemPrivate},
  encryptions.Ecc in '..\..\..\..\..\..\..\libs\src\libs\encryptions.Ecc.pas',
  view.AppEcc in '..\..\views\app\view.AppEcc.pas' {vAppEcc};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TvAppEcc, vAppEcc);
  Application.Run;
end.

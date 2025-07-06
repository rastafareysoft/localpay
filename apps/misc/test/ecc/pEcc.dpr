program pEcc;

uses
  System.StartUpCopy,
  FMX.Forms,
  vista.App in 'vista.App.pas' {Form2},
  Crypto.ECC.Native.Utils in 'Crypto.ECC.Native.Utils.pas',
  Crypto.Bridge.Final.Verified in 'Crypto.Bridge.Final.Verified.pas',
  Crypto.Bridge.Final.Verified2 in 'Crypto.Bridge.Final.Verified2.pas',
  vista.App2 in 'vista.App2.pas' {vApp2},
  Crypto.Bridge.Final.Verified3 in 'Crypto.Bridge.Final.Verified3.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TvApp2, vApp2);
  Application.Run;
end.

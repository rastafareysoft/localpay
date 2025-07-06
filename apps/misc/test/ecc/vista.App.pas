unit vista.App;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo;

type
  TForm2 = class(TForm)
    memoLog: TMemo;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
  private
    PublicKey, PrivateKey: String;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

uses Crypto.Bridge.Final.Verified2;

procedure TForm2.Button2Click(Sender: TObject);
var
  // --- Variables que existir�an en el SERVIDOR ---
  StoredPublicKeyX: string;
  StoredPublicKeyY: string;
  NonceSentToServer: string;
  SignatureReceived: TSignatureRec;

  // --- Variables que existir�an en el DISPOSITIVO (ESP32) ---
  DevicePrivateKey: string;
  NonceReceivedFromClient: string;
  SignatureGenerated: TSignatureRec;

  // --- Variables para el resultado ---
  IsSignatureValid: Boolean;
begin
  //TECCFinalUtils.GenerateKeyPairPEM(PublicKey, PrivateKey);

  memoLog.Lines.Clear;
  memoLog.Lines.Add('--- INICIANDO SIMULACI�N DE AUTENTICACI�N DE DISPOSITIVO ---');
  memoLog.Lines.Add('========================================================');

  // =======================================================================
  // PASO 1: APROVISIONAMIENTO (Se hace una sola vez en la vida del dispositivo)
  // =======================================================================
  memoLog.Lines.Add('PASO 1: Aprovisionando un nuevo dispositivo...');

  var PublicKeyPEM: string;
  TECCFinalUtils.GenerateKeyPairPEM(PublicKeyPEM, DevicePrivateKey);

  // En un sistema real, guardar�amos la clave p�blica en la base de datos.
  // Aqu�, la guardamos en variables locales para la simulaci�n.
  // Necesitamos extraer X e Y del PEM para la verificaci�n (un paso que a�n no hemos implementado).
  // Por ahora, vamos a generar las claves y usar los componentes Hex directamente.
  // �CORRECCI�N! Usaremos la versi�n que nos da los componentes directamente.

  //var KeyPair: TECCKeyPair_FromYourLibrary; // Asumiendo el tipo de tu librer�a
  // ... L�gica para generar y obtener los componentes X, Y, y d como Hex ...
  // Para este ejemplo, usaremos los que generaste antes:

  DevicePrivateKey   := '0d91f2aa65fcef744919d3bfac1ac9eb885c50a28cea580ec694e6f876e3dc69';
  StoredPublicKeyX   := 'ab20a5068c3fc4216a509bf0c6f2674086abba63a9be40646d18700ec921724e';
  StoredPublicKeyY   := '81ba04e44cb897478810b713209fb9e3446979371ca14850bdf91a67743547a5';

  memoLog.Lines.Add('  -> Dispositivo ha generado su clave privada (guardada en su flash).');
  memoLog.Lines.Add('  -> Servidor ha almacenado su clave p�blica (X, Y) en la base de datos.');
  memoLog.Lines.Add('========================================================');


  // =======================================================================
  // PASO 2: EL SERVIDOR GENERA UN DESAF�O (NONCE)
  // =======================================================================
  memoLog.Lines.Add('PASO 2: El Servidor genera un desaf�o aleatorio (nonce)...');
  NonceSentToServer := TGuid.NewGuid.ToString; // Un GUID es una excelente fuente de aleatoriedad
  memoLog.Lines.Add('  -> Nonce: ' + NonceSentToServer);
  memoLog.Lines.Add('========================================================');


  // =======================================================================
  // PASO 3: EL DISPOSITIVO FIRMA EL DESAF�O
  // =======================================================================
  memoLog.Lines.Add('PASO 3: El Dispositivo recibe el nonce y lo firma con su clave privada...');
  NonceReceivedFromClient := NonceSentToServer;

  SignatureGenerated := TECCFinalUtils.Sign(DevicePrivateKey, NonceReceivedFromClient);

  memoLog.Lines.Add('  -> Firma generada (R): ' + SignatureGenerated.R_Hex);
  memoLog.Lines.Add('  -> Firma generada (S): ' + SignatureGenerated.S_Hex);
  memoLog.Lines.Add('========================================================');


  // =======================================================================
  // PASO 4: EL SERVIDOR VERIFICA LA FIRMA
  // =======================================================================
  memoLog.Lines.Add('PASO 4: El Servidor recibe la firma y la verifica...');
  SignatureReceived := SignatureGenerated;

  IsSignatureValid := TECCFinalUtils.Verify(
    StoredPublicKeyX,
    StoredPublicKeyY,
    NonceSentToServer,  // Usa el nonce original que envi�
    SignatureReceived
  );

  memoLog.Lines.Add('  -> Verificando firma contra el nonce original y la clave p�blica almacenada...');

  if IsSignatureValid then
  begin
    memoLog.Lines.Add('');
    memoLog.Lines.Add('************************************');
    memoLog.Lines.Add('*  ��XITO! La firma es V�LIDA.     *');
    memoLog.Lines.Add('*  Dispositivo autenticado.       *');
    memoLog.Lines.Add('************************************');
  end
  else
  begin
    memoLog.Lines.Add('');
    memoLog.Lines.Add('************************************');
    memoLog.Lines.Add('*  �FALLO! La firma es INV�LIDA.  *');
    memoLog.Lines.Add('*  Dispositivo RECHAZADO.         *');
    memoLog.Lines.Add('************************************');
  end;
end;

end.

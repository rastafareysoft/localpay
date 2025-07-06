unit view.AppEcc;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TvAppEcc = class(TForm)
    Layout1: TLayout;
    Button3: TButton;
    Memolog: TMemo;
    Button1: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vAppEcc: TvAppEcc;

implementation

{$R *.fmx}

uses encryptions.Ecc, System.NetEncoding;

procedure TvAppEcc.Button1Click(Sender: TObject);
Var
  Pu, Pr: String;
begin
  TEcc.GenerateKeys(Pu, Pr);
  Memolog.Lines.Clear;

  Memolog.Lines.Add(Pr);

  Memolog.Lines.Add('');

  Memolog.Lines.Add(Pu);

end;

procedure TvAppEcc.Button3Click(Sender: TObject);
var
  // Claves de largo plazo para Alice y Bob en formato PEM
  Alice_PublicPEM, Alice_PrivatePEM: string;
  Bob_PublicPEM, Bob_PrivatePEM: string;

  // Variables para la prueba de Firma/Verificación
  OriginalMessageBytes, TamperedMessageBytes: TBytes;
  Signature64: string;
  isVerified: Boolean;

  // Variables para la prueba de Acuerdo de Secreto (Handshake)
  Alice_SessionKey, Bob_SessionKey: TBytes;
  HandshakePacket64: string;
  Alice_KeyHex, Bob_KeyHex: string;

begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST COMPLETO DE LA FACHADA TEcc (API TBytes) ---');

  // --- Parte 1: Generación de Claves ---
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('---[ PARTE 1: GENERACIÓN DE CLAVES ]---');
  try
    TEcc.GenerateKeys(Alice_PublicPEM, Alice_PrivatePEM);
    TEcc.GenerateKeys(Bob_PublicPEM, Bob_PrivatePEM);
    MemoLog.Lines.Add('OK: Se han generado pares de claves PEM para Alice y Bob.');
  except on E: Exception do
    begin
      MemoLog.Lines.Add('FALLO en la generación de claves: ' + E.Message);
      Exit;
    end;
  end;

  // --- Parte 2: Firma y Verificación (ECDSA) con TBytes ---
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('---[ PARTE 2: FIRMA Y VERIFICACIÓN ]---');
  try
    // Convertir el mensaje a TBytes para firmar. ESTE es el dato real.
    OriginalMessageBytes := TEncoding.UTF8.GetBytes('Este es el mensaje original y auténtico.');
    MemoLog.Lines.Add('Alice firma los bytes del mensaje: "' + TEncoding.UTF8.GetString(OriginalMessageBytes) + '"');

    // Alice firma los bytes
    Signature64 := TEcc.Sign(OriginalMessageBytes, Alice_PrivatePEM);
    MemoLog.Lines.Add('OK: Mensaje firmado. Firma (Base64): ' + Copy(Signature64, 1, 40) + '...');

    // Bob verifica los mismos bytes
    isVerified := TEcc.Verify(OriginalMessageBytes, Signature64, Alice_PublicPEM);
    if isVerified then
      MemoLog.Lines.Add('OK: Bob verificó la firma exitosamente.')
    else
      MemoLog.Lines.Add('FALLO: La verificación de la firma del mensaje original falló.');

    // Prueba de fallo: Bob intenta verificar bytes alterados con la firma original
    TamperedMessageBytes := TEncoding.UTF8.GetBytes('Este es un mensaje FALSO.');
    isVerified := TEcc.Verify(TamperedMessageBytes, Signature64, Alice_PublicPEM);
    if not isVerified then
      MemoLog.Lines.Add('OK: La verificación del mensaje alterado falló, como se esperaba.')
    else
      MemoLog.Lines.Add('FALLO: La verificación del mensaje alterado tuvo éxito, ¡esto es un error grave!');

  except on E: Exception do
    begin
      MemoLog.Lines.Add('FALLO en Firma/Verificación: ' + E.Message);
      Exit;
    end;
  end;

  // --- Parte 3: Acuerdo de Clave Segura (ECDHE) ---
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('---[ PARTE 3: ACUERDO DE CLAVE SEGURA (ECDHE) ]---');
  try
    // Lado de Alice (Iniciadora)
    MemoLog.Lines.Add('Alice inicia el handshake para generar una clave de sesión...');
    Alice_SessionKey := TEcc.GenerateInitiatorSharedSecret(Alice_PrivatePEM, Bob_PublicPEM, HandshakePacket64);
    MemoLog.Lines.Add('OK: Alice generó su clave de sesión y un paquete de handshake.');

    // Lado de Bob (Respondedor)
    MemoLog.Lines.Add('Bob recibe el paquete y genera su clave de sesión...');
    Bob_SessionKey := TEcc.GenerateResponderSharedSecret(Bob_PrivatePEM, Alice_PublicPEM, HandshakePacket64);
    MemoLog.Lines.Add('OK: Bob procesó el paquete y generó su clave de sesión.');

    // Verificación final: ¿Ambas claves de sesión son idénticas?
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('Verificando si las claves de sesión de Alice y Bob coinciden...');
    Alice_KeyHex := TNetEncoding.Base64.EncodeBytesToString(Alice_SessionKey);
    Bob_KeyHex := TNetEncoding.Base64.EncodeBytesToString(Bob_SessionKey);

    MemoLog.Lines.Add('Clave de Alice (Base64): ' + Alice_KeyHex);
    MemoLog.Lines.Add('Clave de Bob (Base64):   ' + Bob_KeyHex);

    if (Length(Alice_SessionKey) > 0) and (Alice_KeyHex = Bob_KeyHex) then
    begin
      MemoLog.Lines.Add('');
      MemoLog.Lines.Add('======================================================');
      MemoLog.Lines.Add('| ¡ÉXITO TOTAL! Las claves de sesión son idénticas.  |');
      MemoLog.Lines.Add('| El protocolo de handshake seguro ha funcionado.   |');
      MemoLog.Lines.Add('======================================================');
    end
    else
    begin
      MemoLog.Lines.Add('');
      MemoLog.Lines.Add('------------------------------------------------------');
      MemoLog.Lines.Add('| ¡FALLO! Las claves de sesión NO coinciden.         |');
      MemoLog.Lines.Add('------------------------------------------------------');
    end;

  except on E: Exception do
    begin
      MemoLog.Lines.Add('FALLO en el acuerdo de clave: ' + E.Message);
      Exit;
    end;
  end;

  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('--- FIN DEL TEST ---');
end;

end.

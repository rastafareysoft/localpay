unit vista.App2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, FMX.Layouts;

type
  TvApp2 = class(TForm)
    Layout1: TLayout;
    memoLog: TMemo;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vApp2: TvApp2;

implementation

{$R *.fmx}

uses Crypto.Bridge.Final.Verified3;

procedure TvApp2.Button1Click(Sender: TObject);
var
  // Variables generadas
  Device_PrivKeyHex: string;
  Device_PubKeyX_Hex, Device_PubKeyY_Hex: string;
  Device_PubKeyPEM: string;

  // Flujo
  Nonce: string;
  Signature: TSignatureRec;
  IsVerified: Boolean;
begin
  memoLog.lines.Clear;

  // --- 1. Generar un par de claves para la simulación ---
  TECCFinalUtils.GenerateKeyPair(
    Device_PrivKeyHex,
    Device_PubKeyX_Hex,
    Device_PubKeyY_Hex,
    Device_PubKeyPEM
  );

  // --- 2. Crear un mensaje de desafío ---
  Nonce := 'Este es un mensaje de prueba para firmar';

  // --- 3. Firmar el mensaje ---
  Signature := TECCFinalUtils.Sign(Device_PrivKeyHex, Nonce);

  // --- 4. IMPRIMIR TODO PARA DEPURAR ---
  memoLog.Lines.Add('--- DATOS ENVIADOS A LA FUNCIÓN DE VERIFICACIÓN ---');
  memoLog.Lines.Add('Clave Pública X (Hex): ' + Device_PubKeyX_Hex);
  memoLog.Lines.Add('Clave Pública Y (Hex): ' + Device_PubKeyY_Hex);
  memoLog.Lines.Add('Mensaje (Nonce): ' + Nonce);
  memoLog.Lines.Add('Firma R (Hex): ' + Signature.R_Hex);
  memoLog.Lines.Add('Firma S (Hex): ' + Signature.S_Hex);
  memoLog.Lines.Add('----------------------------------------------------');
  memoLog.Lines.Add('Iniciando verificación...');
  memoLog.Lines.Add('');
  Application.ProcessMessages; // Forzar actualización del TMemo antes de la posible excepción

  // --- 5. Intentar la verificación ---
  try
    {IsVerified := TECCFinalUtils.Verify(
     Device_PrivKeyHex,,
      Device_PubKeyX_Hex,
      Device_PubKeyY_Hex,
      Nonce,
      Signature
    );}

     IsVerified := TECCFinalUtils.Verify(
      Device_PrivKeyHex,      // <--- El nuevo primer parámetro
      Device_PubKeyX_Hex,     // Tu variable original
      Device_PubKeyY_Hex,     // Tu variable original
      Nonce,                  // Tu variable original
      Signature               // Tu variable original
    );



    // --- 6. Mostrar el resultado ---
    if IsVerified then
      memoLog.Lines.Add('RESULTADO: ¡ÉXITO! La firma es VÁLIDA.')
    else
      // Este caso es poco probable si la firma se generó correctamente, pero es bueno tenerlo
      memoLog.Lines.Add('RESULTADO: FALLO. La firma NO es válida.');

  except
    on E: Exception do
      memoLog.Lines.Add('¡EXCEPCIÓN ATRAPADA! Mensaje: ' + E.Message);
  end;
end;

end.

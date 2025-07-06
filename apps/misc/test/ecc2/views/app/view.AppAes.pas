unit view.AppAes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TvAppAes = class(TForm)
    Layout1: TLayout;
    Button3: TButton;
    Memolog: TMemo;
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vAppAes: TvAppAes;

implementation

{$R *.fmx}

uses
  encryptions.Aes2, strs.Hex, System.Hash;

procedure TvAppAes.Button3Click(Sender: TObject);
var
  MasterKey, Salt, IV: TBytes;
  DerivedKey, EncryptedData, DecryptedData, WrongKey: TBytes;
  OriginalMessage: string;
  KeySize: TAESKeySize2;
  TestOK: Boolean;

  procedure RunTest(AKeySize: TAESKeySize2);
  var
    KeySizeStr: string;
  begin
    case AKeySize of
      aes128: KeySizeStr := '128';
      aes192: KeySizeStr := '192';
      aes256: KeySizeStr := '256';
    end;

    MemoLog.Lines.Add(Format('--- INICIANDO TEST CON AES-%s ---', [KeySizeStr]));

    // 1. Derivar la clave de cifrado
    DerivedKey := TAes2Utils.DeriveKey(MasterKey, Salt, AKeySize);
    MemoLog.Lines.Add('   Paso 1: Clave de cifrado derivada.');

    // 2. Cifrar el mensaje
    MemoLog.Lines.Add('   Paso 2: Cifrando el mensaje original...');
    EncryptedData := TAes2.Encrypt(TEncoding.UTF8.GetBytes(OriginalMessage), DerivedKey, IV, AKeySize);
    MemoLog.Lines.Add('   > Mensaje cifrado (Hex): ' + THex.ToHex(EncryptedData) + '...');
    //MemoLog.Lines.Add('   > Mensaje cifrado (Hex): ' +  TBytes.ToHexString(Copy(EncryptedData, 1, 32)) + '...');

    // 3. Descifrar el mensaje
    MemoLog.Lines.Add('   Paso 3: Descifrando los datos...');
    try
      DecryptedData := TAes2.Decrypt(EncryptedData, DerivedKey, IV, AKeySize);

      // 4. Verificar el resultado
      MemoLog.Lines.Add('   Paso 4: Verificando el resultado...');
      if TEncoding.UTF8.GetString(DecryptedData) = OriginalMessage then
      begin
        MemoLog.Lines.Add('      >>> ¡ÉXITO! El mensaje descifrado coincide con el original.');
        TestOK := True;
      end
      else
      begin
        MemoLog.Lines.Add('      >>> ¡FALLO! El mensaje descifrado NO coincide.');
        TestOK := False;
      end;
    except
      on E: Exception do
      begin
        MemoLog.Lines.Add('      >>> ¡FALLO! Ocurrió una excepción durante el descifrado: ' + E.Message);
        TestOK := False;
      end;
    end;
    MemoLog.Lines.Add('----------------------------------------');
    MemoLog.Lines.Add('');
  end;

begin
  // --- PREPARACIÓN DEL TEST ---
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('====== INICIO DEL TEST DE CIFRADO AES ======');
  MemoLog.Lines.Add('');

  // Sembrar el generador de números aleatorios (hacerlo una vez al inicio de la app)
  Randomize;

  OriginalMessage := 'Este es un mensaje secreto que debe ser protegido. AES es el estándar de oro.';

  // Generamos una "contraseña" o clave maestra, y un "salt" para derivar la clave.
  // En un sistema real, la clave maestra estaría protegida y el salt se guardaría junto a los datos cifrados.
  SetLength(MasterKey, 32);
  MasterKey := THashBobJenkins.GetHashBytes('una-clave-maestra-muy-segura');
  SetLength(Salt, 16);
  Salt := THashBobJenkins.GetHashBytes('un-salt-aleatorio');

  // Generamos un Vector de Inicialización (IV) aleatorio.
  // En un sistema real, el IV no necesita ser secreto, pero debe ser único para cada cifrado.
  // Se guarda normalmente junto a los datos cifrados.
  IV := TAes2Utils.GenerateRandomIV;

  MemoLog.Lines.Add('Mensaje Original: "' + OriginalMessage + '"');
  MemoLog.Lines.Add('IV (Hex): ' + THex.ToHex(IV));
  MemoLog.Lines.Add('');

  // --- EJECUCIÓN DE LOS TESTS ---
  // Ejecutamos el ciclo completo para cada tamaño de clave
  RunTest(aes128);
  if not TestOK then Exit; // Si un test falla, no continuamos.

  RunTest(aes192);
  if not TestOK then Exit;

  RunTest(aes256);
  if not TestOK then Exit;

  // --- TEST DE FALLO (CLAVE INCORRECTA) ---
  MemoLog.Lines.Add('--- INICIANDO TEST DE FALLO (CLAVE INCORRECTA) ---');
  DerivedKey := TAes2Utils.DeriveKey(MasterKey, Salt, aes256);
  EncryptedData := TAes2.Encrypt(TEncoding.UTF8.GetBytes(OriginalMessage), DerivedKey, IV, aes256);

  // Creamos una clave incorrecta simplemente modificando la correcta
  WrongKey := DerivedKey;
  WrongKey[0] := WrongKey[0] xor $FF;

  MemoLog.Lines.Add('   Intentando descifrar con una clave incorrecta...');
  try
    DecryptedData := TAes2.Decrypt(EncryptedData, WrongKey, IV, aes256);
    // Si llegamos aquí, podría ser un problema, pero lo más probable es que el resultado sea basura
    // o que el unpadding falle.
    if TEncoding.UTF8.GetString(DecryptedData) <> OriginalMessage then
      MemoLog.Lines.Add('      >>> ¡ÉXITO! El resultado no es el mensaje original (es basura).')
    else
      MemoLog.Lines.Add('      >>> ¡FALLO! El descifrado tuvo éxito con una clave incorrecta.');
  except
    on E: Exception do
      // El resultado esperado es una excepción de padding, porque los datos descifrados son basura.
      MemoLog.Lines.Add('      >>> ¡ÉXITO! El descifrado falló con una excepción como se esperaba: ' + E.Message);
  end;
  MemoLog.Lines.Add('----------------------------------------');
  MemoLog.Lines.Add('');


  MemoLog.Lines.Add('====== FIN DEL TEST DE CIFRADO AES ======');
end;

end.

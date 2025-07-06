unit view.AppPem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TvAppPem = class(TForm)
    Layout1: TLayout;
    Button1: TButton;
    button2: TButton;
    Memolog: TMemo;
    Button3: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vAppPem: TvAppPem;

implementation

{$R *.fmx}

uses
  flcCipherEllipticCurve, flcHugeInt, encryptions.EccPem, encryptions.Aes;

procedure TvAppPem.Button1Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  AliceKeys: TCurveKeys;
  BobsCopyOfAliceKey: TCurveKeys; // Bob solo tendr� la clave p�blica reconstruida
  AlicePublicKeyPEM: string;
  OriginalMessage: RawByteString;
  AliceSignature: TCurvePoint;
  IsSignatureValid: Boolean;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE FIRMA CON INTERCAMBIO PEM ---');
  MemoLog.Lines.Add('');

  // --- Inicializaci�n (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobsCopyOfAliceKey);
  InitCurvePoint(AliceSignature);

  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice genera su par de claves.
    GenerateCurveKeys(CurveParams, AliceKeys);
    MemoLog.Lines.Add('PASO 1: Alice genera su par de claves (privada+p�blica).');
    MemoLog.Lines.Add('');

    // 2. Alice exporta su CLAVE P�BLICA a formato PEM para poder compartirla.
    MemoLog.Lines.Add('PASO 2: Alice exporta su clave p�blica a formato PEM.');
    AlicePublicKeyPEM := TEccPem.ToPEMPublicKey(CurveParams, AliceKeys.H);
    MemoLog.Lines.Add(AlicePublicKeyPEM);
    MemoLog.Lines.Add('');

    // --- INTERCAMBIO DE INFORMACI�N ---
    // Alice env�a su mensaje, su firma y su clave p�blica en PEM a Bob.

    // 3. Bob recibe la clave p�blica PEM de Alice y la importa.
    MemoLog.Lines.Add('PASO 3: Bob recibe la clave PEM de Alice y la importa a su sistema.');
    if not TEccPem.ToPublicKey(AlicePublicKeyPEM, BobsCopyOfAliceKey.H) then
    begin
      MemoLog.Lines.Add('   > �FALLO! Bob no pudo importar la clave PEM de Alice.');
      Exit;
    end;
    MemoLog.Lines.Add('   > ��xito! Bob ahora tiene una copia de la clave p�blica de Alice.');
    MemoLog.Lines.Add('');

    // 4. Alice firma un mensaje con su CLAVE PRIVADA.
    OriginalMessage := 'Bob, los fondos han sido transferidos. Referencia: TX-4815162342';
    MemoLog.Lines.Add('PASO 4: Alice firma un mensaje importante con su clave privada.');
    MemoLog.Lines.Add('   > Mensaje: "' + string(OriginalMessage) + '"');
    CurveSignMessage(CurveParams, AliceKeys, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);
    MemoLog.Lines.Add('');

    // 5. Bob verifica la firma usando la clave que import� del PEM.
    MemoLog.Lines.Add('PASO 5: Bob verifica la firma usando la clave p�blica importada.');
    IsSignatureValid := CurveVerifySignature(CurveParams, BobsCopyOfAliceKey, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);

    if IsSignatureValid then
    begin
      MemoLog.Lines.Add('   ==============================================================');
      MemoLog.Lines.Add('   |   ��XITO! La firma es v�lida. Bob est� seguro de que   |');
      MemoLog.Lines.Add('   |   el mensaje es aut�ntico y proviene de Alice.         |');
      MemoLog.Lines.Add('   ==============================================================');
    end
    else
    begin
      MemoLog.Lines.Add('   --------------------------------------------------------------');
      MemoLog.Lines.Add('   |   �FALLO! La firma no es v�lida. El mensaje es falso.    |');
      MemoLog.Lines.Add('   --------------------------------------------------------------');
    end;

  finally
    // --- Liberaci�n de memoria ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(AliceKeys);
    FinaliseCurveKeys(BobsCopyOfAliceKey);
    FinaliseCurvePoint(AliceSignature);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

procedure TvAppPem.button2Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  AliceKeys, BobKeys: TCurveKeys;
  AlicePublicKeyPEM, BobPublicKeyPEM: string;
  // Estructuras para las claves reconstruidas
  AliceKnowsOfBobKey, BobKnowsOfAliceKey: TCurveKeys;
  // Semillas compartidas
  AliceSharedSeed, BobSharedSeed: TCurvePoint;
  SeedHexAlice, SeedHexBob: string;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE ACUERDO DE CLAVE (ECDH) CON INTERCAMBIO PEM ---');
  MemoLog.Lines.Add('');

  // --- Inicializaci�n (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobKeys);
  InitCurveKeys(AliceKnowsOfBobKey);
  InitCurveKeys(BobKnowsOfAliceKey);
  InitCurvePoint(AliceSharedSeed);
  InitCurvePoint(BobSharedSeed);

  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice y Bob generan sus respectivos pares de claves.
    GenerateCurveKeys(CurveParams, AliceKeys);
    GenerateCurveKeys(CurveParams, BobKeys);
    MemoLog.Lines.Add('PASO 1: Alice y Bob generan sus pares de claves de forma independiente.');
    MemoLog.Lines.Add('');

    // 2. Alice y Bob exportan sus claves p�blicas a formato PEM para compartirlas.
    AlicePublicKeyPEM := TEccPem.ToPEMPublicKey(CurveParams, AliceKeys.H);
    BobPublicKeyPEM := TEccPem.ToPEMPublicKey(CurveParams, BobKeys.H);
    MemoLog.Lines.Add('PASO 2: Ambos exportan sus claves p�blicas a PEM.');
    MemoLog.Lines.Add('   > Clave PEM de Alice: ' + Copy(AlicePublicKeyPEM.Replace(sLineBreak, ' '), 27, 40) + '...');
    MemoLog.Lines.Add('   > Clave PEM de Bob: ' + Copy(BobPublicKeyPEM.Replace(sLineBreak, ' '), 27, 40) + '...');
    MemoLog.Lines.Add('');

    // --- INTERCAMBIO DE CLAVES P�BLICAS (como texto) ---

    // 3. Alice importa la clave PEM de Bob. Bob importa la clave PEM de Alice.
    MemoLog.Lines.Add('PASO 3: Intercambian sus claves PEM y las importan.');
    if not TEccPem.ToPublicKey(BobPublicKeyPEM, AliceKnowsOfBobKey.H) then
    begin
      MemoLog.Lines.Add('   > �FALLO! Alice no pudo importar la clave de Bob.');
      Exit;
    end;
    if not TEccPem.ToPublicKey(AlicePublicKeyPEM, BobKnowsOfAliceKey.H) then
    begin
      MemoLog.Lines.Add('   > �FALLO! Bob no pudo importar la clave de Alice.');
      Exit;
    end;
    MemoLog.Lines.Add('   > ��xito! Ambos tienen ahora la clave p�blica del otro.');
    MemoLog.Lines.Add('');

    // 4. Alice calcula el secreto compartido usando SU clave privada y la p�blica de Bob (importada).
    MemoLog.Lines.Add('PASO 4: Alice calcula el secreto compartido.');
    CalculateECDHSharedSeed(CurveParams, AliceKeys.d, AliceKnowsOfBobKey.H, AliceSharedSeed);
    SeedHexAlice := HugeWordToHex(AliceSharedSeed.X.Value, true);
    MemoLog.Lines.Add('   > Secreto de Alice: ' + SeedHexAlice);
    MemoLog.Lines.Add('');

    // 5. Bob calcula el secreto compartido usando SU clave privada y la p�blica de Alice (importada).
    MemoLog.Lines.Add('PASO 5: Bob calcula el secreto compartido.');
    CalculateECDHSharedSeed(CurveParams, BobKeys.d, BobKnowsOfAliceKey.H, BobSharedSeed);
    SeedHexBob := HugeWordToHex(BobSharedSeed.X.Value, true);
    MemoLog.Lines.Add('   > Secreto de Bob:   ' + SeedHexBob);
    MemoLog.Lines.Add('');

    // 6. Verificaci�n final.
    MemoLog.Lines.Add('PASO 6: Verificando si los secretos coinciden.');
    if AliceSharedSeed.HasValue and (SeedHexAlice = SeedHexBob) then
    begin
      MemoLog.Lines.Add('   ==============================================================');
      MemoLog.Lines.Add('   |   ��XITO TOTAL! Ambos han llegado al mismo secreto.    |');
      MemoLog.Lines.Add('   |   Ahora pueden usarlo para cifrar su comunicaci�n.     |');
      MemoLog.Lines.Add('   ==============================================================');
    end
    else
    begin
      MemoLog.Lines.Add('   --------------------------------------------------------------');
      MemoLog.Lines.Add('   |   �FALLO! Los secretos no coinciden. El canal NO es seguro. |');
      MemoLog.Lines.Add('   --------------------------------------------------------------');
    end;
  finally
    // --- Liberaci�n de memoria ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(AliceKeys);
    FinaliseCurveKeys(BobKeys);
    FinaliseCurveKeys(AliceKnowsOfBobKey);
    FinaliseCurveKeys(BobKnowsOfAliceKey);
    FinaliseCurvePoint(AliceSharedSeed);
    FinaliseCurvePoint(BobSharedSeed);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

procedure TvAppPem.Button3Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  OriginalKeys, ReconstructedKeys: TCurveKeys;
  PEMString: string;
  OriginalHex, ReconstructedHex: string;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE CONVERSI�N A/DESDE PEM ---');
  MemoLog.Lines.Add('');

  // --- Inicializaci�n (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(OriginalKeys);
  InitCurveKeys(ReconstructedKeys); // Estructura para la clave reconstruida

  try
    // Usamos secp256r1 que es la curva que hemos soportado en el c�digo PEM
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Generar un par de claves original
    GenerateCurveKeys(CurveParams, OriginalKeys);

    // Convertimos la clave original a Hex para una comparaci�n f�cil
    OriginalHex := HugeWordToHex(OriginalKeys.H.X.Value, true) + HugeWordToHex(OriginalKeys.H.Y.Value, true);

    MemoLog.Lines.Add('PASO 1: Se ha generado una clave p�blica ECC nativa.');
    MemoLog.Lines.Add('   > Valor (Hex): ' + Copy(OriginalHex, 1, 64) + '...');
    MemoLog.Lines.Add('');

    // 2. Convertir la clave p�blica nativa a formato PEM est�ndar
    MemoLog.Lines.Add('PASO 2: Convirtiendo la clave p�blica nativa a formato PEM...');
    PEMString := TEccPem.ToPEMPublicKey(CurveParams, OriginalKeys.H);

    if PEMString = '' then
    begin
      MemoLog.Lines.Add('   > �FALLO! La conversi�n a PEM devolvi� una cadena vac�a.');
      Exit; // Salimos del test si falla este paso
    end;

    MemoLog.Lines.Add('   > Resultado PEM:');
    MemoLog.Lines.Add(PEMString);
    MemoLog.Lines.Add('');

    // 3. Convertir la cadena PEM de vuelta a una estructura nativa
    MemoLog.Lines.Add('PASO 3: Reconstruyendo la clave nativa desde la cadena PEM...');

    if TEccPem.ToPublicKey(PEMString, ReconstructedKeys.H) then
    begin
      MemoLog.Lines.Add('   > ��xito! La reconstrucci�n desde PEM fue exitosa.');

      // Convertimos la clave reconstruida a Hex para comparar
      ReconstructedHex := HugeWordToHex(ReconstructedKeys.H.X.Value, true) + HugeWordToHex(ReconstructedKeys.H.Y.Value, true);
      MemoLog.Lines.Add('   > Valor reconstruido (Hex): ' + Copy(ReconstructedHex, 1, 64) + '...');
      MemoLog.Lines.Add('');

      // 4. Verificar que la clave original y la reconstruida son id�nticas
      MemoLog.Lines.Add('PASO 4: Verificando la integridad de los datos (round-trip)...');
      if OriginalHex = ReconstructedHex then
      begin
        MemoLog.Lines.Add('   ==================================================');
        MemoLog.Lines.Add('   |   ��XITO TOTAL! La clave es id�ntica.          |');
        MemoLog.Lines.Add('   ==================================================');
      end
      else
      begin
        MemoLog.Lines.Add('   --------------------------------------------------');
        MemoLog.Lines.Add('   |   �FALLO! La clave reconstruida NO coincide.   |');
        MemoLog.Lines.Add('   --------------------------------------------------');
      end;
    end
    else
    begin
      MemoLog.Lines.Add('   > �FALLO! No se pudo reconstruir la clave desde la cadena PEM.');
    end;

  finally
    // --- Liberaci�n de memoria ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(OriginalKeys);
    FinaliseCurveKeys(ReconstructedKeys);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

end.

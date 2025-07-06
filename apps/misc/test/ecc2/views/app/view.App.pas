unit view.App;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TvApp = class(TForm)
    Layout1: TLayout;
    Button1: TButton;
    Memolog: TMemo;
    button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  vApp: TvApp;

implementation

{$R *.fmx}

Uses
  flcCipherEllipticCurve, flcHugeInt;

procedure CurvePointAssign(var A: TCurvePoint; const B: TCurvePoint);
begin
  A.HasValue := B.HasValue;
  HugeIntAssign(A.X, B.X);
  HugeIntAssign(A.Y, B.Y);
end;


procedure TvApp.Button1Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  AliceKeys: TCurveKeys;         // Las claves completas de Alice (privada + pública)
  BobsKnowledgeOfAlice: TCurveKeys; // Lo que Bob sabe de Alice (solo su clave pública)
  OriginalMessage: RawByteString;
  AliceSignature: TCurvePoint;
  IsSignatureValid: Boolean;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE FIRMA DIGITAL (VERSIÓN REALISTA) ---');

  // --- Inicialización (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobsKnowledgeOfAlice); // Bob prepara una estructura para guardar la clave de Alice
  InitCurvePoint(AliceSignature);

  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice genera su par de claves.
    GenerateCurveKeys(CurveParams, AliceKeys);
    MemoLog.Lines.Add('SITUACIÓN: Alice ha generado su par de claves.');

    // 2. Alice comparte SU CLAVE PÚBLICA con Bob.
    //    En el mundo real, esto podría ser a través de un directorio, un email, etc.
    //    Bob la guarda en su estructura `BobsKnowledgeOfAlice`.
    //    IMPORTANTE: solo se copia la parte PÚBLICA (H). La privada (d) no se toca.
    CurvePointAssign(BobsKnowledgeOfAlice.H, AliceKeys.H);
    MemoLog.Lines.Add('SITUACIÓN: Alice ha enviado su CLAVE PÚBLICA a Bob.');
    MemoLog.Lines.Add('');

    // --- Conversación ---

    // 3. Alice escribe un mensaje y lo firma con SU CLAVE PRIVADA.
    OriginalMessage := 'Hola Bob, te envío los planes de la fase 2.';
    MemoLog.Lines.Add('Alice escribe: "' + string(OriginalMessage) + '"');
    CurveSignMessage(CurveParams, AliceKeys, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);
    MemoLog.Lines.Add('Alice: "He firmado el mensaje. Te lo envío."');
    MemoLog.Lines.Add('');

    // 4. Bob recibe el mensaje y la firma. Ahora lo verifica.
    MemoLog.Lines.Add('Bob recibe el mensaje y la firma.');

    // Bob usa SU COPIA de la CLAVE PÚBLICA de Alice para la verificación.
    // Ahora el código refleja la realidad: Bob NO tiene acceso a `AliceKeys`.
    IsSignatureValid := CurveVerifySignature(CurveParams, BobsKnowledgeOfAlice, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);

    if IsSignatureValid then
    begin
      MemoLog.Lines.Add('Bob: "Verificación EXITOSA. La firma es auténtica. Procede de Alice."');
    end
    else
    begin
      MemoLog.Lines.Add('Bob: "¡ALERTA! La firma no es válida."');
    end;

  finally
    // --- Liberación de memoria ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(AliceKeys);
    FinaliseCurveKeys(BobsKnowledgeOfAlice);
    FinaliseCurvePoint(AliceSignature);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

procedure TvApp.button2Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  AliceKeys, BobKeys: TCurveKeys;
  AliceSharedSeed, BobSharedSeed: TCurvePoint;
  SeedHexAlice, SeedHexBob: string;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE ACUERDO DE CLAVE (ECDH) ---');

  // --- Inicialización (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobKeys);
  InitCurvePoint(AliceSharedSeed);
  InitCurvePoint(BobSharedSeed);

  try
    // Se elige la curva estándar para la comunicación
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice y Bob generan sus pares de claves y comparten las públicas.
    GenerateCurveKeys(CurveParams, AliceKeys);
    GenerateCurveKeys(CurveParams, BobKeys);
    MemoLog.Lines.Add('SITUACIÓN: Alice y Bob ya tienen sus claves y conocen la clave PÚBLICA del otro.');
    MemoLog.Lines.Add('');

    // --- Conversación para acordar un secreto ---

    // 2. Alice usa SU CLAVE PRIVADA y la CLAVE PÚBLICA de Bob para calcular el secreto.
    MemoLog.Lines.Add('Alice: "Voy a calcular nuestro secreto compartido..."');
    CalculateECDHSharedSeed(CurveParams, AliceKeys.d, BobKeys.H, AliceSharedSeed);

    // 3. Bob hace lo mismo, pero a la inversa.
    MemoLog.Lines.Add('Bob: "Perfecto, yo haré mi cálculo también..."');
    CalculateECDHSharedSeed(CurveParams, BobKeys.d, AliceKeys.H, BobSharedSeed);
    MemoLog.Lines.Add('');

    // --- VERIFICACIÓN DEL PROTOCOLO ECDH ---
    MemoLog.Lines.Add('--- Resultados del cálculo ---');

    // CORRECCIÓN: Comprobamos si el punto del secreto compartido es válido.
    if AliceSharedSeed.HasValue and BobSharedSeed.HasValue then
    begin
      // Si los puntos son válidos, extraemos la coordenada X como el secreto.
      SeedHexAlice := HugeWordToHex(AliceSharedSeed.X.Value, True);
      SeedHexBob := HugeWordToHex(BobSharedSeed.X.Value, True);

      MemoLog.Lines.Add('Secreto calculado por Alice: ' + SeedHexAlice);
      MemoLog.Lines.Add('Secreto calculado por Bob:   ' + SeedHexBob);
      MemoLog.Lines.Add('');

      // 4. El momento de la verdad: ¿los secretos son idénticos?
      if SeedHexAlice = SeedHexBob then
      begin
          MemoLog.Lines.Add('¡ÉXITO! Alice y Bob han llegado al MISMO secreto.');
          MemoLog.Lines.Add('Ahora pueden usar este valor para derivar una clave de cifrado simétrico.');
      end
      else
      begin
          MemoLog.Lines.Add('¡FALLO CRÍTICO! Sus secretos son diferentes. Hay un problema en la implementación.');
      end;
    end
    else
    begin
      // Si uno de los puntos no tiene valor, el cálculo falló.
      MemoLog.Lines.Add('¡FALLO! El cálculo del secreto compartido no produjo un punto válido en la curva.');
    end;

  finally
    // --- Liberación de memoria (Paso Final) ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(AliceKeys);
    FinaliseCurveKeys(BobKeys);
    FinaliseCurvePoint(AliceSharedSeed);
    FinaliseCurvePoint(BobSharedSeed);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

procedure TvApp.FormCreate(Sender: TObject);
Var
  T: TBytes;
begin
  //
end;

end.
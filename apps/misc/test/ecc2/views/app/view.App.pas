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
  AliceKeys: TCurveKeys;         // Las claves completas de Alice (privada + p�blica)
  BobsKnowledgeOfAlice: TCurveKeys; // Lo que Bob sabe de Alice (solo su clave p�blica)
  OriginalMessage: RawByteString;
  AliceSignature: TCurvePoint;
  IsSignatureValid: Boolean;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE FIRMA DIGITAL (VERSI�N REALISTA) ---');

  // --- Inicializaci�n (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobsKnowledgeOfAlice); // Bob prepara una estructura para guardar la clave de Alice
  InitCurvePoint(AliceSignature);

  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice genera su par de claves.
    GenerateCurveKeys(CurveParams, AliceKeys);
    MemoLog.Lines.Add('SITUACI�N: Alice ha generado su par de claves.');

    // 2. Alice comparte SU CLAVE P�BLICA con Bob.
    //    En el mundo real, esto podr�a ser a trav�s de un directorio, un email, etc.
    //    Bob la guarda en su estructura `BobsKnowledgeOfAlice`.
    //    IMPORTANTE: solo se copia la parte P�BLICA (H). La privada (d) no se toca.
    CurvePointAssign(BobsKnowledgeOfAlice.H, AliceKeys.H);
    MemoLog.Lines.Add('SITUACI�N: Alice ha enviado su CLAVE P�BLICA a Bob.');
    MemoLog.Lines.Add('');

    // --- Conversaci�n ---

    // 3. Alice escribe un mensaje y lo firma con SU CLAVE PRIVADA.
    OriginalMessage := 'Hola Bob, te env�o los planes de la fase 2.';
    MemoLog.Lines.Add('Alice escribe: "' + string(OriginalMessage) + '"');
    CurveSignMessage(CurveParams, AliceKeys, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);
    MemoLog.Lines.Add('Alice: "He firmado el mensaje. Te lo env�o."');
    MemoLog.Lines.Add('');

    // 4. Bob recibe el mensaje y la firma. Ahora lo verifica.
    MemoLog.Lines.Add('Bob recibe el mensaje y la firma.');

    // Bob usa SU COPIA de la CLAVE P�BLICA de Alice para la verificaci�n.
    // Ahora el c�digo refleja la realidad: Bob NO tiene acceso a `AliceKeys`.
    IsSignatureValid := CurveVerifySignature(CurveParams, BobsKnowledgeOfAlice, Pointer(OriginalMessage)^, Length(OriginalMessage), AliceSignature);

    if IsSignatureValid then
    begin
      MemoLog.Lines.Add('Bob: "Verificaci�n EXITOSA. La firma es aut�ntica. Procede de Alice."');
    end
    else
    begin
      MemoLog.Lines.Add('Bob: "�ALERTA! La firma no es v�lida."');
    end;

  finally
    // --- Liberaci�n de memoria ---
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

  // --- Inicializaci�n (Paso 0) ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(AliceKeys);
  InitCurveKeys(BobKeys);
  InitCurvePoint(AliceSharedSeed);
  InitCurvePoint(BobSharedSeed);

  try
    // Se elige la curva est�ndar para la comunicaci�n
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Alice y Bob generan sus pares de claves y comparten las p�blicas.
    GenerateCurveKeys(CurveParams, AliceKeys);
    GenerateCurveKeys(CurveParams, BobKeys);
    MemoLog.Lines.Add('SITUACI�N: Alice y Bob ya tienen sus claves y conocen la clave P�BLICA del otro.');
    MemoLog.Lines.Add('');

    // --- Conversaci�n para acordar un secreto ---

    // 2. Alice usa SU CLAVE PRIVADA y la CLAVE P�BLICA de Bob para calcular el secreto.
    MemoLog.Lines.Add('Alice: "Voy a calcular nuestro secreto compartido..."');
    CalculateECDHSharedSeed(CurveParams, AliceKeys.d, BobKeys.H, AliceSharedSeed);

    // 3. Bob hace lo mismo, pero a la inversa.
    MemoLog.Lines.Add('Bob: "Perfecto, yo har� mi c�lculo tambi�n..."');
    CalculateECDHSharedSeed(CurveParams, BobKeys.d, AliceKeys.H, BobSharedSeed);
    MemoLog.Lines.Add('');

    // --- VERIFICACI�N DEL PROTOCOLO ECDH ---
    MemoLog.Lines.Add('--- Resultados del c�lculo ---');

    // CORRECCI�N: Comprobamos si el punto del secreto compartido es v�lido.
    if AliceSharedSeed.HasValue and BobSharedSeed.HasValue then
    begin
      // Si los puntos son v�lidos, extraemos la coordenada X como el secreto.
      SeedHexAlice := HugeWordToHex(AliceSharedSeed.X.Value, True);
      SeedHexBob := HugeWordToHex(BobSharedSeed.X.Value, True);

      MemoLog.Lines.Add('Secreto calculado por Alice: ' + SeedHexAlice);
      MemoLog.Lines.Add('Secreto calculado por Bob:   ' + SeedHexBob);
      MemoLog.Lines.Add('');

      // 4. El momento de la verdad: �los secretos son id�nticos?
      if SeedHexAlice = SeedHexBob then
      begin
          MemoLog.Lines.Add('��XITO! Alice y Bob han llegado al MISMO secreto.');
          MemoLog.Lines.Add('Ahora pueden usar este valor para derivar una clave de cifrado sim�trico.');
      end
      else
      begin
          MemoLog.Lines.Add('�FALLO CR�TICO! Sus secretos son diferentes. Hay un problema en la implementaci�n.');
      end;
    end
    else
    begin
      // Si uno de los puntos no tiene valor, el c�lculo fall�.
      MemoLog.Lines.Add('�FALLO! El c�lculo del secreto compartido no produjo un punto v�lido en la curva.');
    end;

  finally
    // --- Liberaci�n de memoria (Paso Final) ---
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
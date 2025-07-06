unit view.AppPemPrivate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TvAppPemPrivate = class(TForm)
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
  vAppPemPrivate: TvAppPemPrivate;

implementation

{$R *.fmx}

Uses flcCipherEllipticCurve, flcHugeInt, encryptions.EccPem;

procedure TvAppPemPrivate.Button1Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  OriginalKeys: TCurveKeys;
  ReconstructedPoint: TCurvePoint; // Solo necesitamos un punto para la clave p�blica
  PEMString: string;
  OriginalHex, ReconstructedHex: string;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE REGRESI�N PARA CLAVE P�BLICA PEM ---');
  MemoLog.Lines.Add('');

  // --- Inicializaci�n ---
  InitCurvePameters(CurveParams);
  InitCurveKeys(OriginalKeys);
  InitCurvePoint(ReconstructedPoint); // Inicializamos la estructura de destino

  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Generar un par de claves y extraer la p�blica
    GenerateCurveKeys(CurveParams, OriginalKeys);
    OriginalHex := HugeWordToHex(OriginalKeys.H.X.Value, True) + HugeWordToHex(OriginalKeys.H.Y.Value, True);
    MemoLog.Lines.Add('PASO 1: Generada clave p�blica nativa.');
    MemoLog.Lines.Add('   > Valor (Hex): ' + Copy(OriginalHex, 1, 64) + '...');
    MemoLog.Lines.Add('');

    // 2. Convertir la clave p�blica a formato PEM (X.509)
    MemoLog.Lines.Add('PASO 2: Convirtiendo a formato PEM...');
    PEMString := TEccPem.ToPEMPublicKey(CurveParams, OriginalKeys.H);
    if PEMString = '' then
    begin
      MemoLog.Lines.Add('   > �FALLO! La conversi�n a PEM devolvi� una cadena vac�a.');
      Exit;
    end;
    MemoLog.Lines.Add('   > Resultado PEM:');
    MemoLog.Lines.Add(PEMString);
    MemoLog.Lines.Add('');

    // 3. Reconstruir la clave p�blica desde el PEM
    MemoLog.Lines.Add('PASO 3: Reconstruyendo desde PEM...');
    if TEccPem.ToPublicKey(PEMString, ReconstructedPoint) then
    begin
      MemoLog.Lines.Add('   > ��xito! La reconstrucci�n fue exitosa.');
      ReconstructedHex := HugeWordToHex(ReconstructedPoint.X.Value, True) + HugeWordToHex(ReconstructedPoint.Y.Value, True);
      MemoLog.Lines.Add('');

      // 4. Verificar que la clave original y la reconstruida son id�nticas
      MemoLog.Lines.Add('PASO 4: Verificando integridad (round-trip)...');
      if OriginalHex = ReconstructedHex then
      begin
        MemoLog.Lines.Add('   ==================================================');
        MemoLog.Lines.Add('   |   ��XITO! La clave p�blica es id�ntica.        |');
        MemoLog.Lines.Add('   |   No se han introducido regresiones.           |');
        MemoLog.Lines.Add('   ==================================================');
      end
      else
      begin
        MemoLog.Lines.Add('   --------------------------------------------------');
        MemoLog.Lines.Add('   |   �FALLO DE REGRESI�N! Clave no coincide.      |');
        MemoLog.Lines.Add('   --------------------------------------------------');
      end;
    end
    else
    begin
      MemoLog.Lines.Add('   > �FALLO! No se pudo reconstruir la clave p�blica desde el PEM.');
    end;

  finally
    // --- Liberaci�n de memoria ---
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(OriginalKeys);
    FinaliseCurvePoint(ReconstructedPoint);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

procedure TvAppPemPrivate.Button3Click(Sender: TObject);
var
  CurveParams: TCurveParameters;
  OriginalKeys, ReconstructedKeys: TCurveKeys;
  PEMString: string;
  OriginalPrivateHex, ReconstructedPrivateHex: string;
  OriginalPublicHex, ReconstructedPublicHex: string;
  bPrivateOK, bPublicOK, bReconstructOK: Boolean;
begin
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('--- INICIO: TEST DE DIAGN�STICO PEM ---');
  MemoLog.Lines.Add('');

  InitCurvePameters(CurveParams);
  InitCurveKeys(OriginalKeys);
  InitCurveKeys(ReconstructedKeys);
  try
    InitCurvePametersSecp256r1(CurveParams);

    // 1. Generar claves y obtener su representaci�n Hex
    GenerateCurveKeys(CurveParams, OriginalKeys);
    OriginalPrivateHex := HugeWordToHex(OriginalKeys.d, True);
    OriginalPublicHex := HugeWordToHex(OriginalKeys.H.X.Value, True) + HugeWordToHex(OriginalKeys.H.Y.Value, True);
    MemoLog.Lines.Add('--- CLAVE ORIGINAL ---');
    MemoLog.Lines.Add('Privada: ' + OriginalPrivateHex);
    MemoLog.Lines.Add('P�blica: ' + OriginalPublicHex);
    MemoLog.Lines.Add('');

    // 2. Convertir a PEM
    PEMString := TEccPem.ToPEMPrivateKey(CurveParams, OriginalKeys);
    MemoLog.Lines.Add('--- PEM GENERADO ---');
    MemoLog.Lines.Add(PEMString);
    MemoLog.Lines.Add('');

    // 3. Reconstruir desde PEM
    bReconstructOK := TEccPem.ToPrivateKey(PEMString, ReconstructedKeys);
    MemoLog.Lines.Add('--- RECONSTRUCCI�N ---');
    if bReconstructOK then
    begin
      MemoLog.Lines.Add('ToPrivateKey retorn� TRUE.');
      ReconstructedPrivateHex := HugeWordToHex(ReconstructedKeys.d, True);
      ReconstructedPublicHex := HugeWordToHex(ReconstructedKeys.H.X.Value, True) + HugeWordToHex(ReconstructedKeys.H.Y.Value, True);
      MemoLog.Lines.Add('Privada Reconstruida: ' + ReconstructedPrivateHex);
      MemoLog.Lines.Add('P�blica Reconstruida: ' + ReconstructedPublicHex);
    end
    else
    begin
      MemoLog.Lines.Add('ToPrivateKey retorn� FALSE. El parser fall�.');
      ReconstructedPrivateHex := '';
      ReconstructedPublicHex := '';
    end;
    MemoLog.Lines.Add('');

    // 4. Verificaci�n detallada
    bPrivateOK := bReconstructOK and (OriginalPrivateHex = ReconstructedPrivateHex);
    bPublicOK := bReconstructOK and (OriginalPublicHex = ReconstructedPublicHex);

    MemoLog.Lines.Add('--- RESULTADO DEL DIAGN�STICO ---');
    MemoLog.Lines.Add('Coincidencia Clave Privada: ' + BoolToStr(bPrivateOK, True));
    MemoLog.Lines.Add('Coincidencia Clave P�blica:  ' + BoolToStr(bPublicOK, True));
    MemoLog.Lines.Add('');

    if bPrivateOK and bPublicOK then
    begin
      MemoLog.Lines.Add('��XITO TOTAL! Ambas partes de la clave se reconstruyeron perfectamente.');
    end
    else
    begin
      MemoLog.Lines.Add('�FALLO DETECTADO! Revisar el log para ver qu� parte no coincide.');
    end;

  finally
    FinaliseCurvePameters(CurveParams);
    FinaliseCurveKeys(OriginalKeys);
    FinaliseCurveKeys(ReconstructedKeys);
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add('--- FIN DEL TEST ---');
  end;
end;

end.

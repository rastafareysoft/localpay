unit Crypto.Bridge.Final.Verified3;

interface

uses
  System.SysUtils, System.Classes,
  flcStdTypes, flcHugeInt, flcCipherEllipticCurve;

type
  TSignatureRec = record
    R_Hex: string;
    S_Hex: string;
  end;

  TECCFinalUtils = class
  public
    // --- FIRMA DE FUNCIÓN MODIFICADA PARA DEVOLVER TODO LO NECESARIO ---
    class procedure GenerateKeyPair(
      out APrivateKeyHex: string;
      out APublicKeyXHex: string;
      out APublicKeyYHex: string;
      out APublicKeyPEM: string);

    class function Sign(const APrivateKeyHex: string; const AMessage: string): TSignatureRec;

    class function Verify(
      const APrivateKeyHex_ForContext: string; // Parámetro añadido
      const APublicKeyXHex, APublicKeyYHex: string;
      const AMessage: string;
      const ASignature: TSignatureRec): Boolean;
  end;

implementation

uses
  System.Net.Mime, System.StrUtils, System.NetEncoding;

// --- FUNCIONES DE AYUDA VERIFICADAS ---

function HexToBytes(const Hex: string): TBytes;
var
  I: Integer;
begin
  if Odd(Length(Hex)) then
    raise Exception.Create('Hex string cannot have an odd number of characters');
  SetLength(Result, Length(Hex) div 2);
  for I := 0 to Length(Result) - 1 do
  begin
    Result[I] := StrToInt('$' + Copy(Hex, I * 2 + 1, 2));
  end;
end;

procedure HexToHugeWord(const AHex: string; var AValue: HugeWord);
var
  LBytes: TBytes;
begin
  LBytes := HexToBytes(AHex);
  HugeWordAssignBuf(AValue, LBytes, Length(LBytes), False);
end;

function BytesToPEM(const ABytes: TBytes; const AHeader, AFooter: string): string;
var
  Base64: string;
begin
  Base64 := TNetEncoding.Base64.EncodeBytesToString(ABytes);
  Result := AHeader + sLineBreak;
  while Length(Base64) > 64 do
  begin
    Result := Result + Copy(Base64, 1, 64) + sLineBreak;
    Delete(Base64, 1, 64);
  end;
  Result := Result + Base64 + sLineBreak;
  Result := Result + AFooter;
end;

{ TECCFinalUtils }

// --- IMPLEMENTACIÓN DE LA FUNCIÓN MODIFICADA ---
class procedure TECCFinalUtils.GenerateKeyPair(
  out APrivateKeyHex: string;
  out APublicKeyXHex: string;
  out APublicKeyYHex: string;
  out APublicKeyPEM: string
);
const
  PublicKeyHeader: array[0..25] of Byte =
      ($30, $59, $30, $13, $06, $07, $2A, $86, $48, $CE, $3D, $02, $01, $06, $08, $2A,
       $86, $48, $CE, $3D, $03, $01, $07, $03, $42, $00);
var
  NativeCurveParams: TCurveParameters;
  NativeKeys: TCurveKeys;
  PublicKeyPoint, PublicKeyDER: TBytes;
  BytesX, BytesY: TBytes;
begin
  InitCurvePameters(NativeCurveParams);
  InitCurveKeys(NativeKeys);
  try
    InitCurvePametersSecp256r1(NativeCurveParams);
    GenerateCurveKeys(NativeCurveParams, NativeKeys);

    // Asignar a todos los parámetros de salida
    APrivateKeyHex := HugeWordToHex(NativeKeys.d, False);
    APublicKeyXHex := HugeWordToHex(NativeKeys.H.X.Value, False);
    APublicKeyYHex := HugeWordToHex(NativeKeys.H.Y.Value, False);

    // Padding para asegurar 64 caracteres
    APrivateKeyHex := StringOfChar('0', 64 - APrivateKeyHex.Length) + APrivateKeyHex;
    APublicKeyXHex := StringOfChar('0', 64 - APublicKeyXHex.Length) + APublicKeyXHex;
    APublicKeyYHex := StringOfChar('0', 64 - APublicKeyYHex.Length) + APublicKeyYHex;

    // Construir el punto público para el PEM
    SetLength(PublicKeyPoint, 1 + 32 + 32);
    PublicKeyPoint[0] := $04; // Punto no comprimido

    BytesX := HexToBytes(APublicKeyXHex);
    BytesY := HexToBytes(APublicKeyYHex);
    System.Move(BytesX[0], PublicKeyPoint[1], 32);
    System.Move(BytesY[0], PublicKeyPoint[33], 32);

    // Construir la estructura DER completa
    SetLength(PublicKeyDER, Length(PublicKeyHeader) + Length(PublicKeyPoint));
    System.Move(PublicKeyHeader, PublicKeyDER[0], Length(PublicKeyHeader));
    System.Move(PublicKeyPoint[0], PublicKeyDER[Length(PublicKeyHeader)], Length(PublicKeyPoint));

    // Generar el string PEM
    APublicKeyPEM := BytesToPEM(PublicKeyDER, '-----BEGIN PUBLIC KEY-----', '-----END PUBLIC KEY-----');

  finally
    FinaliseCurveKeys(NativeKeys);
    FinaliseCurvePameters(NativeCurveParams);
  end;
end;

class function TECCFinalUtils.Sign(const APrivateKeyHex: string; const AMessage: string): TSignatureRec;
var
  CurveParams: TCurveParameters;
  Keys: TCurveKeys;
  SignaturePoint: TCurvePoint;
  MsgAnsi: AnsiString;
begin
  InitCurvePameters(CurveParams);
  InitCurveKeys(Keys);
  InitCurvePoint(SignaturePoint);
  try
    InitCurvePametersSecp256r1(CurveParams);
    HexToHugeWord(APrivateKeyHex, Keys.d);
    MsgAnsi := AnsiString(AMessage);
    CurveSignMessage(CurveParams, Keys, PAnsiChar(MsgAnsi)^, Length(MsgAnsi), SignaturePoint);
    Result.R_Hex := HugeWordToHex(SignaturePoint.X.Value, False);
    Result.S_Hex := HugeWordToHex(SignaturePoint.Y.Value, False);
  finally
    FinaliseCurveKeys(Keys);
    FinaliseCurvePameters(CurveParams);
    FinaliseCurvePoint(SignaturePoint);
  end;
end;

class function TECCFinalUtils.Verify(
  const APrivateKeyHex_ForContext: string; // Parámetro añadido
  const APublicKeyXHex, APublicKeyYHex: string;
  const AMessage: string;
  const ASignature: TSignatureRec
 ): Boolean;
var
  CurveParams: TCurveParameters;
  Keys: TCurveKeys;
  SignaturePoint: TCurvePoint;
  MsgAnsi: AnsiString;
begin
  InitCurvePameters(CurveParams);
  InitCurveKeys(Keys);
  InitCurvePoint(SignaturePoint);
  try
    InitCurvePametersSecp256r1(CurveParams);

    // --- CONSTRUCCIÓN COMPLETA DE LA ESTRUCTURA 'KEYS' ---
    // 1. Cargamos la clave privada. No se usará para el cálculo de verificación,
    //    pero es necesaria para que la estructura 'Keys' sea válida para la librería.
    HexToHugeWord(APrivateKeyHex_ForContext, Keys.d);

    // 2. Cargamos la clave pública que sí se usará para la verificación.
    Keys.H.HasValue := True;
    HexToHugeWord(APublicKeyXHex, Keys.H.X.Value);
    Keys.H.X.Sign := 1;
    HexToHugeWord(APublicKeyYHex, Keys.H.Y.Value);
    Keys.H.Y.Sign := 1;
    // --- FIN DE LA SECCIÓN MODIFICADA ---

    // Cargar la firma
    SignaturePoint.HasValue := True;
    HexToHugeWord(ASignature.R_Hex, SignaturePoint.X.Value);
    SignaturePoint.X.Sign := 1;
    HexToHugeWord(ASignature.S_Hex, SignaturePoint.Y.Value);
    SignaturePoint.Y.Sign := 1;

    MsgAnsi := AnsiString(AMessage);

    // Con la estructura 'Keys' ahora completa, la aserción debería pasar.
    Result := CurveVerifySignature(CurveParams, Keys, PAnsiChar(MsgAnsi)^, Length(MsgAnsi), SignaturePoint);
  finally
    FinaliseCurveKeys(Keys);
    FinaliseCurvePameters(CurveParams);
    FinaliseCurvePoint(SignaturePoint);
  end;
end;

end.

unit Crypto.Bridge.Final.Verified;

interface

uses
  System.SysUtils, System.Classes,
  flcStdTypes, flcHugeInt, flcCipherEllipticCurve;

type
  TECCFinalUtils = class
  public
    class procedure GenerateKeyPairPEM(out APublicKeyPEM: string; out APrivateKeyPEM_Hex: string);
  end;

implementation

uses
  System.Net.Mime, System.StrUtils, System.NetEncoding;

// --- FUNCIONES DE AYUDA VERIFICADAS ---

// Convierte una cadena hexadecimal a un array de bytes
function HexToBytes(const Hex: string): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(Hex) div 2);
  for I := 0 to Length(Result) - 1 do
  begin
    Result[I] := StrToInt('$' + Copy(Hex, I * 2 + 1, 2));
  end;
end;

// Convierte un TBytes a un string PEM
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

class procedure TECCFinalUtils.GenerateKeyPairPEM(out APublicKeyPEM: string; out APrivateKeyPEM_Hex: string);
// --- PASO 3: Construir el formato DER para la clave pública ---
const PublicKeyHeader: array[0..25] of Byte =
      ($30, $59, $30, $13, $06, $07, $2A, $86, $48, $CE, $3D, $02, $01, $06, $08, $2A,
       $86, $48, $CE, $3D, $03, $01, $07, $03, $42, $00);
var
  NativeCurveParams: TCurveParameters;
  NativeKeys: TCurveKeys;
  PublicKeyX_Hex, PublicKeyY_Hex: string;
  PublicKeyPoint, PublicKeyDER: TBytes;
begin
  // --- PASO 1: Generar la clave usando TU librería ---
  InitCurvePameters(NativeCurveParams);
  InitCurveKeys(NativeKeys);
  try
    InitCurvePametersSecp256r1(NativeCurveParams);
    GenerateCurveKeys(NativeCurveParams, NativeKeys);

    // --- PASO 2: Convertir los resultados a Hexadecimal usando TU función ---
    APrivateKeyPEM_Hex := HugeWordToHex(NativeKeys.d, False); // minúsculas
    PublicKeyX_Hex := HugeWordToHex(NativeKeys.H.X.Value, False);
    PublicKeyY_Hex := HugeWordToHex(NativeKeys.H.Y.Value, False);

    // El punto público es 0x04 + X + Y
    SetLength(PublicKeyPoint, 1 + 32 + 32);
    PublicKeyPoint[0] := $04; // Punto no comprimido

    // Convertimos de Hex a Bytes y los copiamos
    var BytesX := HexToBytes(PublicKeyX_Hex);
    var BytesY := HexToBytes(PublicKeyY_Hex);
    System.Move(BytesX[0], PublicKeyPoint[1], 32);
    System.Move(BytesY[0], PublicKeyPoint[33], 32);

    // Unimos la cabecera DER con el punto
    SetLength(PublicKeyDER, Length(PublicKeyHeader) + Length(PublicKeyPoint));
    System.Move(PublicKeyHeader, PublicKeyDER[0], Length(PublicKeyHeader));
    System.Move(PublicKeyPoint[0], PublicKeyDER[Length(PublicKeyHeader)], Length(PublicKeyPoint));

    // --- PASO 4: Convertir a PEM ---
    APublicKeyPEM := BytesToPEM(PublicKeyDER, '-----BEGIN PUBLIC KEY-----', '-----END PUBLIC KEY-----');

  finally
    FinaliseCurveKeys(NativeKeys);
    FinaliseCurvePameters(NativeCurveParams);
  end;
end;

end.

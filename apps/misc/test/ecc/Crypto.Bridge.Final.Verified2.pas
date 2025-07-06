unit Crypto.Bridge.Final.Verified2;

interface

uses
  System.SysUtils, System.Classes,
  flcStdTypes, flcHugeInt, flcCipherEllipticCurve;

type
  // Un registro para devolver/recibir la firma
  TSignatureRec = record
    R_Hex: string;
    S_Hex: string;
  end;

  TECCFinalUtils = class
  public
    class procedure GenerateKeyPairPEM(out APublicKeyPEM: string; out APrivateKeyPEM_Hex: string);

    // --- NUEVAS FUNCIONES AÑADIDAS ---
    class function Sign(const APrivateKeyHex: string; const AMessage: string): TSignatureRec;
    class function Verify(const APublicKeyXHex, APublicKeyYHex: string; const AMessage: string; const ASignature: TSignatureRec): Boolean;
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

class procedure TECCFinalUtils.GenerateKeyPairPEM(out APublicKeyPEM: string; out APrivateKeyPEM_Hex: string);
const
  PublicKeyHeader: array[0..25] of Byte =
      ($30, $59, $30, $13, $06, $07, $2A, $86, $48, $CE, $3D, $02, $01, $06, $08, $2A,
       $86, $48, $CE, $3D, $03, $01, $07, $03, $42, $00);
var
  NativeCurveParams: TCurveParameters;
  NativeKeys: TCurveKeys;
  PublicKeyX_Hex, PublicKeyY_Hex: string;
  PublicKeyPoint, PublicKeyDER: TBytes;
  BytesX, BytesY: TBytes;
begin
  InitCurvePameters(NativeCurveParams);
  InitCurveKeys(NativeKeys);
  try
    InitCurvePametersSecp256r1(NativeCurveParams);
    GenerateCurveKeys(NativeCurveParams, NativeKeys);

    APrivateKeyPEM_Hex := HugeWordToHex(NativeKeys.d, False);
    PublicKeyX_Hex := HugeWordToHex(NativeKeys.H.X.Value, False);
    PublicKeyY_Hex := HugeWordToHex(NativeKeys.H.Y.Value, False);

    // Asegurar que los strings Hex tengan 64 caracteres (32 bytes)
    //PublicKeyX_Hex := StringOfChar('0', 64 - PublicKeyX_Hex.Length);
    //PublicKeyY_Hex :=  StringOfChar('0', 64 - PublicKeyY_Hex.Length);
    //PublicKeyX_Hex := RightString('0'*64 + PublicKeyX_Hex, 64);
    //PublicKeyY_Hex := RightString('0'*64 + PublicKeyY_Hex, 64);
    PublicKeyX_Hex := StringOfChar('0', 64 - Length(PublicKeyX_Hex)) + PublicKeyX_Hex;
    PublicKeyY_Hex := StringOfChar('0', 64 - Length(PublicKeyY_Hex)) + PublicKeyY_Hex;
    // Y lo mismo para la clave privada
    APrivateKeyPEM_Hex := StringOfChar('0', 64 - Length(APrivateKeyPEM_Hex)) + APrivateKeyPEM_Hex;

    SetLength(PublicKeyPoint, 1 + 32 + 32);
    PublicKeyPoint[0] := $04;

    BytesX := HexToBytes(PublicKeyX_Hex);
    BytesY := HexToBytes(PublicKeyY_Hex);
    System.Move(BytesX[0], PublicKeyPoint[1], 32);
    System.Move(BytesY[0], PublicKeyPoint[33], 32);

    SetLength(PublicKeyDER, Length(PublicKeyHeader) + Length(PublicKeyPoint));
    System.Move(PublicKeyHeader, PublicKeyDER[0], Length(PublicKeyHeader));
    System.Move(PublicKeyPoint[0], PublicKeyDER[Length(PublicKeyHeader)], Length(PublicKeyPoint));

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

    // Cargar la clave privada desde la cadena Hex
    HexToHugeWord(APrivateKeyHex, Keys.d);

    MsgAnsi := AnsiString(AMessage);

    // Usar la función de TU LIBRERÍA para firmar
    CurveSignMessage(CurveParams, Keys, PAnsiChar(MsgAnsi)^, Length(MsgAnsi), SignaturePoint);

    // Devolver la firma (puntos R y S) como strings hexadecimales
    Result.R_Hex := HugeWordToHex(SignaturePoint.X.Value, False);
    Result.S_Hex := HugeWordToHex(SignaturePoint.Y.Value, False);
  finally
    FinaliseCurveKeys(Keys);
    FinaliseCurvePameters(CurveParams);
    FinaliseCurvePoint(SignaturePoint);
  end;
end;

class function TECCFinalUtils.Verify(const APublicKeyXHex, APublicKeyYHex: string; const AMessage: string; const ASignature: TSignatureRec): Boolean;
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

    // Cargar la clave pública a partir de sus componentes X e Y en hexadecimal
    Keys.H.HasValue := True;
    HexToHugeWord(APublicKeyXHex, Keys.H.X.Value);
    Keys.H.X.Sign := 1;
    HexToHugeWord(APublicKeyYHex, Keys.H.Y.Value);
    Keys.H.Y.Sign := 1;

    // Cargar la firma a partir de sus componentes R y S en hexadecimal
    SignaturePoint.HasValue := True;
    HexToHugeWord(ASignature.R_Hex, SignaturePoint.X.Value);
    SignaturePoint.X.Sign := 1;
    HexToHugeWord(ASignature.S_Hex, SignaturePoint.Y.Value);
    SignaturePoint.Y.Sign := 1;

    MsgAnsi := AnsiString(AMessage);

    // Usar la función de TU LIBRERÍA para verificar
    Result := CurveVerifySignature(CurveParams, Keys, PAnsiChar(MsgAnsi)^, Length(MsgAnsi), SignaturePoint);
  finally
    FinaliseCurveKeys(Keys);
    FinaliseCurvePameters(CurveParams);
    FinaliseCurvePoint(SignaturePoint);
  end;
end;

end.

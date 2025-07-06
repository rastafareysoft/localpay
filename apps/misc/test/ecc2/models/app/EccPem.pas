unit EccPem;

interface

uses
  flcCipherEllipticCurve, System.SysUtils, flcHugeInt;

type
  TEccPem = record
  private
    class function GetCurveOID(const ACurve: TCurveParameters): TBytes; static;
    class procedure InternalHugeWordToBuf(const A: HugeWord; var Buf: TBytes); static;
    class procedure InternalReadTagAndLength(const DERBytes: TBytes; var Index: Integer; out Tag: Byte; out Length: Integer); static;
    // NUEVO: Helper para generar correctamente la longitud ASN.1
    class function EncodeASN1Length(const ALength: Integer): TBytes; static;
  public
    class function ToPEMPublicKey(const ACurve: TCurveParameters; const APublicKey: TCurvePoint): string; static;
    class function ToPublicKey(const APEM: string; var APublicKey: TCurvePoint): Boolean; static;
    class function ToPEMPrivateKey(const ACurve: TCurveParameters; const AKeys: TCurveKeys): string; static;
    class function ToPrivateKey(const APEM: string; var AKeys: TCurveKeys): Boolean; static;
  end;

implementation

uses
  System.Math, System.NetEncoding;

{ TEccPem }

// --- Funciones de Ayuda (GetCurveOID, InternalHugeWordToBuf, InternalReadTagAndLength no cambian) ---
class function TEccPem.GetCurveOID(const ACurve: TCurveParameters): TBytes;
var TestP: HugeWord; ExpectedP: string;
begin
  HugeWordInit(TestP);
  try
    ExpectedP := 'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff';
    HexToHugeWord(ExpectedP, TestP);
    if HugeWordEquals(ACurve.p, TestP) then
    begin Result := [$2A, $86, $48, $CE, $3D, $03, $01, $07]; Exit; end;
  finally HugeWordFinalise(TestP); end;
  Result := [];
end;

class procedure TEccPem.InternalHugeWordToBuf(const A: HugeWord; var Buf: TBytes);
var SrcPtr: PHugeWordElement; SrcSize, DstSize, BytesToCopy, DstOffset, I, J: Integer; T: Byte;
begin
  DstSize := Length(Buf); FillChar(Buf[0], DstSize, 0); SrcSize := HugeWordGetSize(A) * SizeOf(HugeWordElement);
  if SrcSize = 0 then Exit; BytesToCopy := Min(SrcSize, DstSize); DstOffset := DstSize - BytesToCopy;
  SrcPtr := HugeWordGetFirstElementPtr(A); Move(SrcPtr^, Buf[DstOffset], BytesToCopy);
  I := DstOffset; J := DstOffset + BytesToCopy - 1;
  while I < J do
  begin T := Buf[I]; Buf[I] := Buf[J]; Buf[J] := T; Inc(I); Dec(J); end;
end;

class procedure TEccPem.InternalReadTagAndLength(const DERBytes: TBytes; var Index: Integer; out Tag: Byte; out Length: Integer);
var LenByte, NumLenBytes, I: Integer;
begin
  Tag := DERBytes[Index]; Inc(Index); LenByte := DERBytes[Index]; Inc(Index);
  if (LenByte and $80) = 0 then Length := LenByte
  else
  begin
    NumLenBytes := LenByte and $7F;
    if (NumLenBytes = 0) or (NumLenBytes > 4) then raise EElipticCurve.Create('Formato de longitud ASN.1 inválido.');
    Length := 0; for I := 1 to NumLenBytes do
    begin Length := (Length shl 8) + DERBytes[Index]; Inc(Index); end;
  end;
end;

// --- INICIO DE LA CORRECCIÓN ---
// Nuevo helper de ENCODING de longitud ASN.1
class function TEccPem.EncodeASN1Length(const ALength: Integer): TBytes;
begin
  if ALength < 128 then
  begin
    // Caso simple: longitud en un byte
    Result := TBytes.Create(Byte(ALength));
  end
  else
  begin
    // Caso complejo: longitud multi-byte
    var TempLen := ALength;
    var LenBytes: TBytes;
    while TempLen > 0 do
    begin
      // Extraer los bytes de la longitud en orden big-endian
      Insert(Byte(TempLen and $FF), LenBytes, 0);
      TempLen := TempLen shr 8;
    end;
    // Añadir el byte inicial 8x
    var FirstByte := Byte($80 or Length(LenBytes));
    Result := TBytes.Create(FirstByte) + LenBytes;
  end;
end;

// Función para construir un elemento TLV (Tag-Length-Value)
function MakeTLV(ATag: Byte; const AValue: TBytes): TBytes;
begin
  Result := TBytes.Create(ATag) + TEccPem.EncodeASN1Length(Length(AValue)) + AValue;
end;
// --- FIN DE LA CORRECCIÓN ---

// --- Claves Públicas (Actualizadas para usar el nuevo encoder de longitud) ---
class function TEccPem.ToPEMPublicKey(const ACurve: TCurveParameters; const APublicKey: TCurvePoint): string;
begin
  Result := ''; if not APublicKey.HasValue then Exit;
  var CurveSizeInBytes := (HugeWordGetSizeInBits(ACurve.p) + 7) div 8;
  var OID_Curve := GetCurveOID(ACurve); if Length(OID_Curve) = 0 then raise EElipticCurve.Create('Curva no soportada.');
  var X, Y: TBytes; SetLength(X, CurveSizeInBytes); SetLength(Y, CurveSizeInBytes);
  InternalHugeWordToBuf(APublicKey.X.Value, X); InternalHugeWordToBuf(APublicKey.Y.Value, Y);
  var KeyBytes := TBytes.Create($04) + X + Y;
  var OID_EC := TBytes.Create($2A, $86, $48, $CE, $3D, $02, $01);

  var AlgorithmId := MakeTLV($06, OID_EC) + MakeTLV($06, OID_Curve);
  AlgorithmId := MakeTLV($30, AlgorithmId);
  var BitString := MakeTLV($03, TBytes.Create($00) + KeyBytes);
  var SubjectPublicKeyInfo := MakeTLV($30, AlgorithmId + BitString);

  Result := '-----BEGIN PUBLIC KEY-----' + sLineBreak + TNetEncoding.Base64.EncodeBytesToString(SubjectPublicKeyInfo) + sLineBreak + '-----END PUBLIC KEY-----';
end;

class function TEccPem.ToPublicKey(const APEM: string; var APublicKey: TCurvePoint): Boolean;
var DERBytes, X, Y: TBytes; s: string; Index, Len, KeyLen, CurveSizeInBytes: Integer; Tag: Byte;
begin
  Result := False;
  if APublicKey.HasValue or ((APublicKey.X.Sign <> 0) and not HugeWordIsZero(APublicKey.X.Value)) then
    raise EElipticCurve.Create('La estructura TCurvePoint de destino debe estar limpia (inicializada).');
  s := APEM.Replace('-----BEGIN PUBLIC KEY-----', '').Replace('-----END PUBLIC KEY-----', '').Replace(sLineBreak, '');
  try DERBytes := TNetEncoding.Base64.DecodeStringToBytes(s); except Exit; end;
  try
    Index := 0; InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $30 then Exit;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $30 then Exit; Index := Index + Len;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $03 then Exit;
    if DERBytes[Index] <> $00 then Exit; Inc(Index); KeyLen := Len - 1;
    if (KeyLen <= 1) or ((KeyLen - 1) mod 2 <> 0) then Exit;
    CurveSizeInBytes := (KeyLen - 1) div 2; if DERBytes[Index] <> $04 then Exit; Inc(Index);
    SetLength(X, CurveSizeInBytes); Move(DERBytes[Index], X[0], CurveSizeInBytes); Inc(Index, CurveSizeInBytes);
    SetLength(Y, CurveSizeInBytes); Move(DERBytes[Index], Y[0], CurveSizeInBytes);
    HugeWordAssignBuf(APublicKey.X.Value, X[0], Length(X), True); APublicKey.X.Sign := 1;
    HugeWordAssignBuf(APublicKey.Y.Value, Y[0], Length(Y), True); APublicKey.Y.Sign := 1;
    APublicKey.HasValue := True; Result := True;
  except Result := False; end;
end;


// --- Claves Privadas (Actualizadas para usar el nuevo encoder de longitud) ---
class function TEccPem.ToPEMPrivateKey(const ACurve: TCurveParameters; const AKeys: TCurveKeys): string;
begin
  Result := ''; if HugeWordIsZero(AKeys.d) or not AKeys.H.HasValue then Exit;
  var CurveSizeInBytes := (HugeWordGetSizeInBits(ACurve.p) + 7) div 8;
  var OID_Curve := GetCurveOID(ACurve); if Length(OID_Curve) = 0 then raise EElipticCurve.Create('Curva no soportada.');

  var PrivateKeyBytes: TBytes; SetLength(PrivateKeyBytes, CurveSizeInBytes); InternalHugeWordToBuf(AKeys.d, PrivateKeyBytes);
  var X, Y: TBytes; SetLength(X, CurveSizeInBytes); SetLength(Y, CurveSizeInBytes);
  InternalHugeWordToBuf(AKeys.H.X.Value, X); InternalHugeWordToBuf(AKeys.H.Y.Value, Y);
  var PublicKeyBytes := TBytes.Create($04) + X + Y;

  var Version := MakeTLV($02, TBytes.Create($01));
  var PrivateKeyOctet := MakeTLV($04, PrivateKeyBytes);
  var Parameters := MakeTLV($A0, MakeTLV($06, OID_Curve));
  var PublicKeyBitString := MakeTLV($A1, MakeTLV($03, TBytes.Create($00) + PublicKeyBytes));
  var ECPrivateKey := MakeTLV($30, Version + PrivateKeyOctet + Parameters + PublicKeyBitString);

  var OID_EC := TBytes.Create($2A, $86, $48, $CE, $3D, $02, $01);
  var AlgorithmId := MakeTLV($30, MakeTLV($06, OID_EC) + MakeTLV($06, OID_Curve));
  var OuterVersion := MakeTLV($02, TBytes.Create($00));
  var OuterOctetString := MakeTLV($04, ECPrivateKey);
  var PrivateKeyInfo := MakeTLV($30, OuterVersion + AlgorithmId + OuterOctetString);

  Result := '-----BEGIN PRIVATE KEY-----' + sLineBreak + TNetEncoding.Base64.EncodeBytesToString(PrivateKeyInfo) + sLineBreak + '-----END PRIVATE KEY-----';
end;

class function TEccPem.ToPrivateKey(const APEM: string; var AKeys: TCurveKeys): Boolean;
var DERBytes, ECPrivateKeyBytes: TBytes; s: string; Index, Len: Integer; Tag: Byte;
begin
  Result := False;
  if (not HugeWordIsZero(AKeys.d)) or AKeys.H.HasValue then
    raise EElipticCurve.Create('La estructura TCurveKeys de destino debe estar limpia (inicializada).');
  s := APEM.Replace('-----BEGIN PRIVATE KEY-----', '').Replace('-----END PRIVATE KEY-----', '').Replace(sLineBreak, '');
  try DERBytes := TNetEncoding.Base64.DecodeStringToBytes(s); except Exit; end;
  try
    Index := 0; InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $30 then Exit;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $02 then Exit; Index := Index + Len;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $30 then Exit; Index := Index + Len;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $04 then Exit;
    SetLength(ECPrivateKeyBytes, Len); Move(DERBytes[Index], ECPrivateKeyBytes[0], Len);

    DERBytes := ECPrivateKeyBytes; Index := 0;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $30 then Exit;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $02 then Exit; Index := Index + Len;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $04 then Exit;
    var PrivateKeyBytes: TBytes; SetLength(PrivateKeyBytes, Len);
    Move(DERBytes[Index], PrivateKeyBytes[0], Len);
    HugeWordAssignBuf(AKeys.d, PrivateKeyBytes[0], Len, True);
    Index := Index + Len;

    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $A0 then Exit; Index := Index + Len;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $A1 then Exit;
    InternalReadTagAndLength(DERBytes, Index, Tag, Len); if Tag <> $03 then Exit;
    if DERBytes[Index] <> $00 then Exit; Inc(Index);
    var KeyLen := Len - 1; var CurveSizeInBytes := (KeyLen - 1) div 2;
    if (DERBytes[Index] <> $04) then Exit; Inc(Index);
    var X, Y: TBytes; SetLength(X, CurveSizeInBytes); SetLength(Y, CurveSizeInBytes);
    Move(DERBytes[Index], X[0], CurveSizeInBytes); Inc(Index, CurveSizeInBytes);
    Move(DERBytes[Index], Y[0], CurveSizeInBytes);
    HugeWordAssignBuf(AKeys.H.X.Value, X[0], Length(X), True); AKeys.H.X.Sign := 1;
    HugeWordAssignBuf(AKeys.H.Y.Value, Y[0], Length(Y), True); AKeys.H.Y.Sign := 1;
    AKeys.H.HasValue := True; Result := True;
  except Result := False; end;
end;

end.

unit Crypto.ECC.Native.Utils;
//unit Crypto.ECC.Native.Utils;

interface

uses
  System.SysUtils, Classes,
  // Incluimos las unidades necesarias de tu librería
  flcStdTypes,
  flcHugeInt,
  flcCipherEllipticCurve;

type
  // Un simple registro para devolver el par de claves
  TECCKeyPair = record
    PublicKeyX_Hex: string;
    PublicKeyY_Hex: string;
    PrivateKey_Hex: string;
  end;

  TNativeEccUtils = class
  public
    { Genera un nuevo par de claves ECC usando la curva P-256 (secp256r1)
      y devuelve los componentes de la clave como cadenas hexadecimales. }
    class procedure GenerateKeyPair(out AKeyPair: TECCKeyPair);
  end;

implementation

{ TNativeEccUtils }

class procedure TNativeEccUtils.GenerateKeyPair(out AKeyPair: TECCKeyPair);
var
  CurveParams: TCurveParameters;
  Keys: TCurveKeys;
begin
  // 1. Inicializar las estructuras de datos
  InitCurvePameters(CurveParams);
  InitCurveKeys(Keys);

  try
    // 2. Cargar los parámetros para nuestra curva objetivo: secp256r1 (P-256)
    // Tu unidad ya tiene una función para esto.
    InitCurvePametersSecp256r1(CurveParams);

    // 3. Generar el par de claves (privada y pública)
    // Esta función está en tu unidad y hace toda la matemática.
    GenerateCurveKeys(CurveParams, Keys);

    // 4. Convertir los resultados (que son de tipo HugeWord) a cadenas
    // hexadecimales para poder guardarlos o mostrarlos.
    AKeyPair.PrivateKey_Hex  := HugeWordToHex(Keys.d, True);
    AKeyPair.PublicKeyX_Hex  := HugeWordToHex(Keys.H.X.Value, True);
    AKeyPair.PublicKeyY_Hex  := HugeWordToHex(Keys.H.Y.Value, True);

  finally
    // 5. Liberar la memoria de las estructuras
    FinaliseCurveKeys(Keys);
    FinaliseCurvePameters(CurveParams);
  end;
end;

end.

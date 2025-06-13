unit dll.SL500;

interface

Uses
  System.SysUtils;

Type
  TBauds = (bd9600, bd14400, bd19200, bd28800, bd38400, bd57600, bd115200);
  TLight = (lgOff, lgRed, lgGreen, lgYellow);
  TCardType = (ctA, ctB, ctAT88RF020, ctISO15693);
  TCardModel = (cmNonHalt, cmAllState);
  TTagType = (ttUltraLight, ttMifare1k, ttMifare4k, ttMifareDESFire, ttMifarePro, ttMifareProX, ttSHC1102);
  TAuthenticationType = (atKeyA, atKeyB);

  //System port
  Function SL500_OpenPort(Const APor: Word; Const ABauds: TBauds): Boolean;
  Function SL500_ClosePort: Boolean;
  //System functions
  Function SL500_Light(Const ALight: TLight): Boolean;
  Function SL500_Beep(Const AMsec: Byte): Boolean;
  Function SL500_InitType(Const ACardType: TCardType = ctA): Boolean;
  Function SL500_AntennaSta(Const AOn: Boolean = True): Boolean;
  //ISO14443A Mifare Standard
  Function SL500_Request(Var ATagType: TTagType; Const ACardModel: TCardModel = cmAllState): Boolean;
  Function SL500_Anticoll(Var ASerial: TBytes): Boolean;
  Function SL500_Select(Const ASerial: TBytes; var ASize: Byte): Boolean;
  Function SL500__Authentication2(Const AKey: TBytes; Const Ablock: Byte; Const AAuthenticationType: TAuthenticationType = atKeyA): Boolean;
  Function SL500_Read(Var ABlocksData: TArray<TBytes>; Const ABlocks: TBytes): Boolean;
  Function SL500_Write(Var ABlocksData: TArray<TBytes>; Const ABlocks: TBytes): Boolean;
  Function SL500_Halt: Boolean;

implementation

Uses strs.Hex;

Const
  __DLL = 'MasterRD.dll';

  //Dll Headers
  //System port
  Function rf_init_com(Const APort: Integer; Const ABauds: LongWord): Integer; Stdcall; External __DLL;
  Function rf_ClosePort: Integer; Stdcall; External __DLL;
  //System functions
  Function rf_light(Const AIcDev, AColor: Byte): Integer; Stdcall; External __DLL;
  Function rf_beep(Const AIcDev, AMsec: Byte): Integer; Stdcall; External __DLL;
  Function rf_init_type(Const AIcDev, AType: Byte): Integer; Stdcall; External __DLL;
  Function rf_antenna_sta(Const AIcDev, AModel: Byte): Integer; Stdcall; External __DLL;
  //ISO14443A Mifare Standard
  Function rf_request(Const AIcDev, AModel: Byte; Var ATagType: Word): Integer; Stdcall; External __DLL;
  Function rf_anticoll(Const AIcDev, ABcnt{=4}: Byte; Var ASnr, ALen: Byte): Integer; Stdcall; External __DLL;
  Function rf_select(Const AIcDev: Byte; Var ASnr: Byte; Const ASnrLen: Byte; Var ASize: Byte): Integer; Stdcall; External __DLL;
  Function rf_M1_authentication2(Const AIcDev, AModel, Ablock: Byte; Var AKey: Byte): Integer; Stdcall; External __DLL;
  Function rf_M1_read(Const AIcDev, Ablock: Byte; Var AData, ALen: Byte): Integer; Stdcall; External __DLL;
  Function rf_M1_write(Const AIcDev, Ablock: Byte; Var aData: Byte): Integer; Stdcall; External __DLL;
  Function rf_halt(Const AIcDev: Byte): Integer; Stdcall; External __DLL;

{$REGION 'System port'}
Function SL500_OpenPort(Const APor: Word; Const ABauds: TBauds): Boolean;
Const
  __BAUDS: Array[TBauds] Of LongWord = (9600, 14400, 19200, 28800, 38400, 57600, 115200);
Begin
  Result := rf_init_com(APor, __BAUDS[ABauds]) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500_ClosePort: Boolean;
Begin
  Result := rf_ClosePort = 0;
End;
{$ENDREGION 'System port'}

{$REGION 'System functions'}
Function SL500_Light(Const ALight: TLight): Boolean;
Begin
  Result := rf_light(0, Byte(ALight)) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500_Beep(Const AMsec: Byte): Boolean;
Begin
  Result := rf_beep(0, AMsec) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500_InitType(Const ACardType: TCardType): Boolean;
Const
  __CARD_TYPE: Array[TCardType] Of Char = ('A', 'B', 'r', '1');
Begin
  Result := rf_init_type(0, Ord(__CARD_TYPE[ACardType])) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500_AntennaSta(Const AOn: Boolean = True): Boolean;
Begin
  Result := rf_antenna_sta(0, AOn.ToInteger) = 0;
End;
{$ENDREGION 'System functions'}

{$REGION 'ISO14443A Mifare Standard'}
Function SL500_Request(Var ATagType: TTagType; Const ACardModel: TCardModel = cmAllState): Boolean;
Const
  __CARD_MODEL: Array[TCardModel] Of Byte = ($26, $52);
Var
  LTagType: Word;
Begin
  LTagType := Word(ATagType);
  Result := rf_request(0, __CARD_MODEL[ACardModel], LTagType) = 0;
  If Result Then Case LTagType Of { TODO : Verify When use }
    $44: ATagType := ttUltraLight;
    $04: ATagType := ttMifare1k;
    $02: ATagType := ttMifare4k;
    $047: ATagType := ttMifareDESFire;
    $08: ATagType := ttMifarePro;
    $07: ATagType := ttMifareProX;
    $33: ATagType := ttSHC1102;
  End;
End;
//--------------------------------------------------------------------------------------------
Function SL500_Anticoll(Var ASerial: TBytes): Boolean;
Var
  LLength: Byte;
begin
  SetLength(ASerial, Byte.MaxValue);
  Result := rf_anticoll(0, 4, ASerial[0], LLength) = 0;
  SetLength(ASerial, LLength);
End;
//--------------------------------------------------------------------------------------------
Function SL500_Select(const ASerial: TBytes; var ASize: Byte): Boolean;
begin
  Result := rf_select(0, ASerial[0], High(ASerial)+1, ASize) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500__Authentication2(Const AKey: TBytes; Const Ablock: Byte; Const AAuthenticationType: TAuthenticationType = atKeyA): Boolean;
Const
  __AUTHENTICATION_TYPE: Array[TAuthenticationType] Of Byte = ($60, $61);
Var
  LKey: TBytes;
Begin
  LKey := AKey;
  Result := rf_M1_authentication2(0,  __AUTHENTICATION_TYPE[AAuthenticationType], Ablock, LKey[0]) = 0;
End;
//--------------------------------------------------------------------------------------------
Function SL500_Read(Var ABlocksData: TArray<TBytes>; Const ABlocks: TBytes): Boolean;
Var
  LI: Integer;
  LL: Byte;
Begin
  Result := False;
  SetLength(ABlocksData, High(ABlocks)+1);
  For LI := Low(ABlocks) To High(ABlocks) Do Begin
    SetLength(ABlocksData[LI], 16);
    Result := rf_M1_read(0, ABlocks[LI], ABlocksData[LI][0], LL) = 0;
    If Not Result Then
      Break;
  End;
End;
//--------------------------------------------------------------------------------------------
Function SL500_Write(Var ABlocksData: TArray<TBytes>; Const ABlocks: TBytes): Boolean;
Var
  LI: Integer;
Begin
  Result := False;
  For LI := Low(ABlocks) To High(ABlocks) Do Begin
    Result := rf_M1_write(0, ABlocks[LI], ABlocksData[LI][0]) = 0;
    If Not Result Then
      Break;
  End;
End;
//--------------------------------------------------------------------------------------------
Function SL500_Halt: Boolean;
Begin
  Result := rf_halt(0) = 0;
End;
{$ENDREGION 'ISO14443A Mifare Standard'}

{$REGION '...'}
{$ENDREGION '...'}

end.

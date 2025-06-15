unit view.CardRegister;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Graphics, FMX.Controls,
  FMX.Forms, FMX.Dialogs, FMX.StdCtrls, view.AppData, Data.Bind.EngExt, Fmx.Bind.DBEngExt, Data.Bind.Components,
  Data.Bind.DBScope, Data.DB, Datasnap.DBClient, Fmx.Bind.Navigator, System.Actions, FMX.ActnList,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Edit, dll.SL500;

type
  TvCardRegister = class(TvAppData)
    lytCardSerial: TLayout;
    edCardSerial: TEdit;
    lblCardSerial: TLabel;
    lytCompanyId0: TLayout;
    lblCompanyId0: TRadioButton;
    edCompanyId0: TEdit;
    lytCompanyIdentication0: TLayout;
    lblCompanyIdentication0: TLabel;
    edCompanyIdentication0: TEdit;
    lytCompanyIdentication1: TLayout;
    lblCompanyIdentication1: TLabel;
    edCompanyIdentication1: TEdit;
    lytCompanyId1: TLayout;
    lblCompanyId1: TRadioButton;
    edCompanyId1: TEdit;
    Action1: TAction;
    procedure btnSaveDataClick(Sender: TObject);
    procedure btnActionModuleClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
  private
    FDispositive, FPort, FBauds: Integer; //Temp hace global record
    FTagType: TTagType;
    FCardSerial: TBytes;
    FSize: Byte;
    FCompanies: String; //Json
    Function PrepareCard: Boolean;
  Protected
    Procedure InitializeData; Override;
    Procedure ClearInfoCard;
  public
  end;

var
  vCardRegister: TvCardRegister;

implementation

{$R *.fmx}

uses conf.App, constt.App, files.Ini, strs.Hex, XSuperObject, constt.Map.Iso14443A, types.Map, numbers.Endian, encryptions.Aes;

{ TvCardRegister }


procedure TvCardRegister.Action1Execute(Sender: TObject);
Var
  X: ISuperObject;
begin
  inherited;
  X := SO(FCompanies);
  edCompanyId0.Text := X.A['data'].A[0].S[0];
  edCompanyIdentication0.Text := X.A['data'].A[0].S[1];
  edCompanyIdentication1.Text := X.A['data'].A[1].S[0];
  edCompanyId1.Text := X.A['data'].A[1].S[1];
end;

procedure TvCardRegister.btnActionModuleClick(Sender: TObject);
Var
 LI, LBlock: Byte;
 LBlocks, LOut: TBytes;
 LBlocksData: TArray<TBytes>;
 FId: UInt64;
 S: String;
 X: ISuperObject;
begin
  edCardSerial.Text := '';
  MessageInfo := '';
  If SL500_OpenPort(FPort, TBauds(FBauds)) Then Begin
    Try
      If PrepareCard Then Begin
        LBlocks := __CARDS_MAPS[ctMifare1K].Company.Base[0];
        If SL500__Authentication2(THex.ToBytes(__CARDS_DEFAULT_KEY), LBlocks[0]) Then Begin
          SetLength(LBlocksData, 3);
          If SL500_Read(LBlocksData, LBlocks) Then Begin
            For LI := 0 To 2 Do
              LBlocksData[LI] := TAes.Decrypt(LBlocksData[LI], '123');
            For LI := 0 To 7 Do Begin
               If LBlocksData[0][LI] = 0 Then
                 Break;
               LOut := LOut + [LBlocksData[0][LI]];
            End;
            FId := TEndian.ToUInt64LE(LOut);
            edCompanyId0.Text := FId.ToString;
            SetLength(LOut, 0);
            For LI := 8 To High(LBlocksData[0]) Do
              LOut := LOut + [LBlocksData[0][LI]];
            For LI := Low(LBlocksData[1]) To High(LBlocksData[1]) Do Begin
             If LBlocksData[1][LI] = 0 Then
               Break;
             LOut := LOut + [LBlocksData[1][LI]];
            End;
            For LI := Low(LBlocksData[2]) To High(LBlocksData[2]) Do Begin
             If LBlocksData[2][LI] = 0 Then
               Break;
             LOut := LOut + [LBlocksData[2][LI]];
            End;
            S := StringOf(LOut);
            X := So(S);
            edCompanyIdentication0.Text := X.AsArray.S[0];
            lblCompanyId0.Text := X.AsArray.S[1];
            SL500_Halt;
          End;
        End Else
          MessageError := 'Fallo autenticacion en tarjeta.';
      End Else
        MessageError := 'Fallo preparacion de tarjeta.';
    Finally
      SL500_ClosePort;
    End;
  End Else
    MessageError := Format('Error Conexion al puerto com%d', [FPort, FBauds]);
end;

procedure TvCardRegister.btnSaveDataClick(Sender: TObject);
Var
 LBlock: Byte;
 LBlocks: TBytes;
 LBlocksData: TArray<TBytes>;
 LInfo: TBytes;
 X, XD: ISuperObject;
 JSon: String;
 LI: Byte;
 FID: UInt64;
 SID, S1, S2: String;
begin
  edCardSerial.Text := '';
  MessageInfo := '';
  If SL500_OpenPort(FPort, TBauds(FBauds)) Then Begin
    Try
      If PrepareCard Then Begin
        LBlocks := __CARDS_MAPS[ctMifare1K].Company.Base[0];
        SetLength(LBlocksData, 3);
        If SL500__Authentication2(THex.ToBytes(__CARDS_DEFAULT_KEY), LBlocks[0]) Then Begin
          X := SO(FCompanies);
          SID := X.A['data'].A[0].S[0];
          FId := StrToUInt(SID);
          LBlocksData[0] := TEndian.ToBytesLE(FId);
          SetLength(LBlocksData[0], 8);
          S1 := X.A['data'].A[0].S[1];
          S2 := X.A['data'].A[0].S[2];
          S1 := Format('["%s","%s"]', [S1, S2]);
          XD := SO(S1);
          JSon := XD.AsJSON;
          LInfo := BytesOf(JSon);
          For LI := 0 To 7 Do
            LBlocksData[0] := LBlocksData[0] + [LInfo[LI]];
          For LI := 0 To 15 Do
            LBlocksData[1] := LBlocksData[1] + [LInfo[8+LI]];
          For LI := 0 To 15 Do
            LBlocksData[2] := LBlocksData[2] + [LInfo[24+LI]];
          For LI := 0 To 2 Do
             LBlocksData[LI] := TAes.Encrypt(LBlocksData[LI], '123');
          If SL500_Write(LBlocksData, LBlocks) Then Begin
            SL500_Halt;
          End Else
            MessageError := 'Fallo escritura en tarjeta.';
        End Else
          MessageError := 'Fallo autenticacion en tarjeta.';
      End Else
        MessageError := 'Fallo preparacion de tarjeta.';
    Finally
      SL500_ClosePort;
    End;
  End Else
    MessageError := Format('Error Conexion al puerto com%d', [FPort, FBauds]);
end;

procedure TvCardRegister.ClearInfoCard;
begin
  edCardSerial.Text := '';
  edCompanyId0.Text := '';
  edCompanyIdentication0.Text := '';
  edCompanyIdentication1.Text := '';
  edCompanyId1.Text := '';
end;

procedure TvCardRegister.FormCreate(Sender: TObject);
Var
  X: ISuperObject;
  S: String;
begin
  inherited;
  S := Format('{"data":[["%s","%s","%s"],["%s","%s","%s"]]}', [
         edCompanyId0.Text, edCompanyIdentication0.Text,  lblCompanyId0.Text,
         edCompanyId1.Text.Trim, edCompanyIdentication1.Text, lblCompanyId1.Text]);
  X := So(S);
  FCompanies := X.AsJSON();
  ClearInfoCard;
end;

procedure TvCardRegister.InitializeData;
Var
  LIni: TArray<Variant>;
begin
  FDispositive := 0; FPort := -1; FBauds := 115200;
  LIni := TIni.Gett(FileConnection, __CONNECTION_SECTION, [__CONNECTION_MODEL, __CONNECTION_PORT, __CONNECTION_BAUDS], [FDispositive, FPort, FBauds]);
  inherited;
  FDispositive := LIni[0];
  FPort := LIni[1];
  FBauds := IndexOfBauds(LIni[2]);
  FInit := False;
end;

function TvCardRegister.PrepareCard: Boolean;
begin
  Result := False;
  ClearInfoCard;
  Try
    If Not SL500_AntennaSta Then Begin
      MessageError := 'Fallo preparando la antena.';
      Exit;
    End;
    If Not SL500_InitType Then Begin
      MessageError := 'Fallo inicializandoel tipo de tarjeta.';
      Exit;
    End;
    If Not SL500_Request(FTagType) Then Begin
      MessageError := 'Fallo octeniendo tipo de tarjeta.';
      Exit;
    End;
    If Not SL500_Anticoll(FCardSerial) Then Begin
      MessageError := 'Fallo serial de tarjeta.';
      Exit;
    End Else Begin
      edCardSerial.Text := THex.ToHex(FCardSerial);
      Result := True;
    End;
    If Not SL500_Select(FCardSerial, FSize) Then Begin
      Result := False;
      MessageError := 'Fallo Seleccionando tipo de tarjeta.';
      Exit;
    End Else
      Result := True;
  Except
    Result := False;
  End;
end;

end.

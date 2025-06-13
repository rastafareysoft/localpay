unit conf.App;

interface

Function FolderConf: String;
Function FileConf: String;
Function FileConnection: String;

implementation

uses
  constt.App, System.IOUtils, System.SysUtils;

Function FolderConf: String;
Begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), __FOLDER_CONF);
  ForceDirectories(Result);
End;

Function FileConf: String;
Begin
  Result := TPath.Combine(FolderConf, __FILE_CONF);
End;

Function FileConnection: String;
Begin
  Result := TPath.Combine(FolderConf, __CONNECTION_FILE);
End;

end.

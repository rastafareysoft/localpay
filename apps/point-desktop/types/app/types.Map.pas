unit types.Map;

interface

Uses
  System.Sysutils;

Type
  TCardType = (ctMifare1K, ctMifare4K);
  TCardSector = Record
    Base, Backup: TArray<TBytes>;
  End;
  TCardSection = Record
    Wallet, MetaData, Company, UserInfo: TCardSector;
  End;
  TCardsMaps = Array[TCardType] Of TCardSection;

implementation

end.

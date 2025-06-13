unit constt.Map.Iso14443A;

interface

uses
  types.Map;

Const
  __CARDS_MAPS: TCardsMaps = (
    //Mifare 1K
    (
      Wallet:(
        Base:   [[ 4, 5, 6]];
        Backup: [[32,33,34]]
      );
      MetaData: (
        Base:   [[ 8, 9,10]];
        Backup: [[36,37,38]]
      );
      Company: (
        Base:   [[12,13,14]];
        Backup: [[40,41,42]]
      );
      UserInfo:(
        Base:  [[16,17,18], [20,21,22], [24,25,26], [28,29,30], [ 1, 2]];
        Backup:[[44,45,46], [48,49,50], [52,53,54], [56,57,58], [61,62]];
      )
    ),

    //Mifare 4K
    (
      Wallet:(
        Base:   [[ 4, 5, 6]];
        Backup: [[32,33,34]]
      );
      MetaData: (
        Base:   [[ 8, 9,10]];
        Backup: [[36,37,38]]
      );
      Company: (
        Base:   [[12,13,14]];
        Backup: [[40,41,42]]
      );
      UserInfo:(
        Base:  [[16,17,18], [20,21,22], [24,25,26], [28,29,30], [ 1, 2]];
        Backup:[[44,45,46], [48,49,50], [52,53,54], [56,57,58], [61,62]];
      )
    )
  );

implementation

end.

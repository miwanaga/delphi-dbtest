unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, DB, DBTables, IniFiles;

type
  TForm1 = class(TForm)
    Table1: TTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Database1: TDatabase;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    procedure InitializeDatabase;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TISCStatus = array[0..19] of Longint;
  TCreateDatabase = function(Status: PLongint; NameLength: Smallint;
    Name: PChar; var Handle: Pointer; ParamsLength: Smallint;
    Params: PChar; DatabaseType: Smallint): Longint; stdcall;
  TDetachDatabase = function(Status: PLongint;
    var Handle: Pointer): Longint; stdcall;
  TInterpretStatus = function(Buffer: PChar;
    var Status: PLongint): Longint; stdcall;

{ BDE opens existing SQL databases. Use only the InterBase 6 client API to
  create an absent GDB; all table access below goes through BDE/SQL Links. }
procedure CreateInterBaseDatabase(const FileName, UserName, Password: string);
var
  Client: HMODULE;
  CreateDatabase: TCreateDatabase;
  DetachDatabase: TDetachDatabase;
  InterpretStatus: TInterpretStatus;
  Handle: Pointer;
  Status: TISCStatus;
  StatusPtr: PLongint;
  Buffer: array[0..511] of Char;
  Params, ErrorText: string;

  procedure CheckStatus(ResultCode: Longint);
  begin
    if ResultCode = 0 then
      Exit;
    ErrorText := '';
    StatusPtr := @Status[0];
    while InterpretStatus(@Buffer[0], StatusPtr) <> 0 do
    begin
      if ErrorText <> '' then
        ErrorText := ErrorText + #13#10;
      ErrorText := ErrorText + StrPas(@Buffer[0]);
    end;
    raise EDatabaseError.CreateFmt('Cannot create InterBase database "%s". %s',
      [FileName, ErrorText]);
  end;

begin
  if (Length(UserName) > 255) or (Length(Password) > 255) then
    raise EDatabaseError.Create('InterBase credentials must not exceed 255 bytes.');
  Client := LoadLibrary('gds32.dll');
  if Client = 0 then
    raise EDatabaseError.Create('Cannot load the 32-bit InterBase client gds32.dll.');
  try
    @CreateDatabase := GetProcAddress(Client, 'isc_create_database');
    @DetachDatabase := GetProcAddress(Client, 'isc_detach_database');
    @InterpretStatus := GetProcAddress(Client, 'isc_interprete');
    if not Assigned(CreateDatabase) or not Assigned(DetachDatabase) or
      not Assigned(InterpretStatus) then
      raise EDatabaseError.Create('Required InterBase 6 client API is unavailable.');

    { DPB version 1, user name, password, database SQL dialect 1.
      Dialect 1 is compatible with InterBase 6 and the BDE INTRBASE driver. }
    Params := #1#28 + Chr(Length(UserName)) + UserName +
      #29 + Chr(Length(Password)) + Password + #63#4#1#0#0#0;
    Handle := nil;
    FillChar(Status, SizeOf(Status), 0);
    try
      CheckStatus(CreateDatabase(@Status[0], Length(FileName), PChar(FileName),
        Handle, Length(Params), PChar(Params), 0));
      CheckStatus(DetachDatabase(@Status[0], Handle));
    finally
      if Handle <> nil then
        DetachDatabase(@Status[0], Handle);
    end;
  finally
    FreeLibrary(Client);
  end;
end;

procedure TForm1.InitializeDatabase;
var
  Settings: TIniFile;
  DatabaseFile, UserName, Password: string;
  Query: TQuery;
begin
  DatabaseFile := ExtractFilePath(Application.ExeName) + 'sample.gdb';
  Settings := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    UserName := Settings.ReadString('InterBase', 'UserName', 'SYSDBA');
    Password := Settings.ReadString('InterBase', 'Password', 'masterkey');
  finally
    Settings.Free;
  end;

  if not FileExists(DatabaseFile) then
    CreateInterBaseDatabase(DatabaseFile, UserName, Password);

  { DatabaseName is the BDE connection name, SERVER NAME is the GDB path. }
  Database1.Params.Values['SERVER NAME'] := DatabaseFile;
  Database1.Params.Values['USER NAME'] := UserName;
  Database1.Params.Values['PASSWORD'] := Password;
  Database1.Open;

  Query := TQuery.Create(nil);
  try
    Query.DatabaseName := Database1.DatabaseName;
    Database1.StartTransaction;
    try
      Query.SQL.Text := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ' +
        'WHERE RDB$RELATION_NAME = ''SAMPLE''';
      Query.Open;
      if Query.IsEmpty then
      begin
        Query.Close;
        Query.SQL.Text := 'CREATE TABLE SAMPLE (' +
          'ID VARCHAR(10), NAME VARCHAR(50), ADDRESS VARCHAR(100))';
        Query.ExecSQL;
      end
      else
        Query.Close;
      Database1.Commit;

      Database1.StartTransaction;
      Query.SQL.Text := 'SELECT ID FROM SAMPLE';
      Query.Open;
      if Query.IsEmpty then
      begin
        Query.Close;
        Query.SQL.Text := 'INSERT INTO SAMPLE (ID, NAME, ADDRESS) ' +
          'VALUES (:ID, :NAME, :ADDRESS)';
        Query.ParamByName('ID').AsString := '001';
        Query.ParamByName('NAME').AsString := 'Taro Yamada';
        Query.ParamByName('ADDRESS').AsString := 'Tokyo';
        Query.ExecSQL;
        Query.ParamByName('ID').AsString := '002';
        Query.ParamByName('NAME').AsString := 'Hanako Suzuki';
        Query.ParamByName('ADDRESS').AsString := 'Osaka';
        Query.ExecSQL;
        Query.ParamByName('ID').AsString := '003';
        Query.ParamByName('NAME').AsString := 'Ichiro Sato';
        Query.ParamByName('ADDRESS').AsString := 'Nagoya';
        Query.ExecSQL;
      end
      else
        Query.Close;
      Database1.Commit;
    except
      if Database1.InTransaction then
        Database1.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitializeDatabase;
  Table1.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Table1.Active then
    Table1.CheckBrowseMode;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Table1.Close;
  if Database1.InTransaction then
    Database1.Rollback;
  Database1.Close;
end;

end.

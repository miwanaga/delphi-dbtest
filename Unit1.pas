unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, DB, IBDatabase, IBTable, IBQuery, IniFiles;

type
  TForm1 = class(TForm)
    Table1: TIBTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    IBDatabase1: TIBDatabase;
    IBTransaction1: TIBTransaction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Table1AfterPost(DataSet: TDataSet);
  private
    procedure InitializeDatabase;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.InitializeDatabase;
var
  Settings: TIniFile;
  UserName, Password: string;
  Query: TIBQuery;
begin
  IBDatabase1.DatabaseName := ExtractFilePath(Application.ExeName) + 'sample.gdb';
  Settings := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    UserName := Settings.ReadString('InterBase', 'UserName', 'SYSDBA');
    Password := Settings.ReadString('InterBase', 'Password', 'masterkey');
  finally
    Settings.Free;
  end;

  if not FileExists(IBDatabase1.DatabaseName) then
  begin
    { CreateDatabase uses SQL clauses, whereas Open uses name=value pairs. }
    IBDatabase1.Params.Clear;
    IBDatabase1.Params.Add('USER ' + QuotedStr(UserName));
    IBDatabase1.Params.Add('PASSWORD ' + QuotedStr(Password));
    IBDatabase1.Params.Add('PAGE_SIZE 4096');
    IBDatabase1.CreateDatabase;
    IBDatabase1.Close;
  end;

  IBDatabase1.Params.Clear;
  IBDatabase1.Params.Values['user_name'] := UserName;
  IBDatabase1.Params.Values['password'] := Password;
  IBDatabase1.Open;

  Query := TIBQuery.Create(nil);
  try
    Query.Database := IBDatabase1;
    Query.Transaction := IBTransaction1;
    IBTransaction1.StartTransaction;
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
      { Commit DDL before preparing statements against the new table. }
      IBTransaction1.Commit;

      IBTransaction1.StartTransaction;
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
      IBTransaction1.Commit;
    except
      if IBTransaction1.InTransaction then
        IBTransaction1.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitializeDatabase;
  IBTransaction1.StartTransaction;
  Table1.Open;
end;

procedure TForm1.Table1AfterPost(DataSet: TDataSet);
begin
  { Preserve posted grid edits while keeping the display transaction open. }
  IBTransaction1.CommitRetaining;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Table1.Active then
    Table1.CheckBrowseMode;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Table1.Close;
  if IBTransaction1.InTransaction then
    IBTransaction1.Rollback;
  IBDatabase1.Close;
end;

end.

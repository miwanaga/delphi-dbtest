unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, DB, DBTables;

type
  TForm1 = class(TForm)
    Table1: TTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Table1ID: TStringField;
    Table1NAME: TStringField;
    Table1ADDRESS: TStringField;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Table1.Close;
  Table1.DatabaseName := ExtractFilePath(Application.ExeName);
  Table1.TableName := 'sample.dbf';
  Table1.TableType := ttDBase;

  if not Table1.Exists then
  begin
    Table1.FieldDefs.Clear;
    Table1.FieldDefs.Add('ID', ftString, 10);
    Table1.FieldDefs.Add('NAME', ftString, 50);
    Table1.FieldDefs.Add('ADDRESS', ftString, 100);
    Table1.CreateTable;
  end;

  Table1.Open;
  Table1.DisableControls;
  try
    if Table1.IsEmpty then
    begin
      Table1.AppendRecord(['001', 'Taro Yamada', 'Tokyo']);
      Table1.AppendRecord(['002', 'Hanako Suzuki', 'Osaka']);
      Table1.AppendRecord(['003', 'Ichiro Sato', 'Nagoya']);
    end;
    Table1.First;
  finally
    Table1.EnableControls;
  end;
end;

end.

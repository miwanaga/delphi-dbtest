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
    Table1NUM_VAL: TFloatField;
    Table1FLOAT_VAL: TFloatField;
    Table1DOUBLE_VAL: TFloatField;
    Table1BOOL_VAL: TBooleanField;
    Table1DATE_VAL: TDateField;
    Table1STAMP_VAL: TDateTimeField;
    Table1LONG_VAL: TIntegerField;
    Table1AUTO_VAL: TAutoIncField;
    Table1MEMO_VAL: TMemoField;
    Table1BIN_VAL: TBlobField;
    Table1OLE_VAL: TBlobField;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  Form1: TForm1;

implementation

uses DbfSamples;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Table1.Close;
  Table1.DatabaseName := ExtractFilePath(Application.ExeName);
  Table1.TableName := 'sample.dbf';
  Table1.TableType := ttDBase;

  PrepareSampleTable(Table1);

  Table1.Open;
  Table1.DisableControls;
  try
    AddSampleRows(Table1);
    Table1.First;
  finally
    Table1.EnableControls;
  end;
end;

end.

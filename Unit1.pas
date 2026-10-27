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
    Table1MEMO_TEXT: TStringField;
    Table1BIN_HEX: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure Table1CalcFields(DataSet: TDataSet);
  private
  public
  end;

var
  Form1: TForm1;

implementation

uses DbfSamples;

{$R *.dfm}

procedure TForm1.Table1CalcFields(DataSet: TDataSet);
const
  MaxBinaryBytes = 64;
var
  MemoText, HexText: string;
  Stream: TStream;
  Bytes: array[0..MaxBinaryBytes - 1] of Byte;
  Count, I: Integer;
begin
  Table1MEMO_TEXT.Clear;
  Table1BIN_HEX.Clear;
  if not Table1MEMO_VAL.IsNull then
  begin
    MemoText := Table1MEMO_VAL.AsString;
    MemoText := StringReplace(MemoText, #13#10, ' / ', [rfReplaceAll]);
    MemoText := StringReplace(MemoText, #13, ' / ', [rfReplaceAll]);
    MemoText := StringReplace(MemoText, #10, ' / ', [rfReplaceAll]);
    if Length(MemoText) > Table1MEMO_TEXT.Size then
      MemoText := Copy(MemoText, 1, Table1MEMO_TEXT.Size - 3) + '...';
    Table1MEMO_TEXT.AsString := MemoText;
  end;
  if not Table1BIN_VAL.IsNull then
  begin
    Stream := DataSet.CreateBlobStream(Table1BIN_VAL, bmRead);
    try
      Count := Stream.Read(Bytes, SizeOf(Bytes));
      HexText := '';
      for I := 0 to Count - 1 do
      begin
        if I > 0 then
          HexText := HexText + ' ';
        HexText := HexText + IntToHex(Bytes[I], 2);
      end;
      if Stream.Size > Count then
        HexText := HexText + ' ...';
      Table1BIN_HEX.AsString := HexText;
    finally
      Stream.Free;
    end;
  end;
end;
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

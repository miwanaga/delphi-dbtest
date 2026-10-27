unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Grids, Vcl.DBGrids, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait;

type
  TForm1 = class(TForm)
    Connection1: TFDConnection;
    Table1: TFDTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure Table1CalcFields(DataSet: TDataSet);
  end;

var
  Form1: TForm1;

implementation

uses System.IOUtils, InterBaseSamples;

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
  DataSet.FieldByName('MEMO_TEXT').Clear;
  DataSet.FieldByName('BIN_HEX').Clear;
  if not DataSet.FieldByName('MEMO_VAL').IsNull then
  begin
    MemoText := DataSet.FieldByName('MEMO_VAL').AsWideString;
    MemoText := StringReplace(MemoText, #13#10, ' / ', [rfReplaceAll]);
    MemoText := StringReplace(MemoText, #13, ' / ', [rfReplaceAll]);
    MemoText := StringReplace(MemoText, #10, ' / ', [rfReplaceAll]);
    if Length(MemoText) > 255 then
      MemoText := Copy(MemoText, 1, 252) + '...';
    DataSet.FieldByName('MEMO_TEXT').AsWideString := MemoText;
  end;
  if not DataSet.FieldByName('BIN_VAL').IsNull then
  begin
    Stream := DataSet.CreateBlobStream(DataSet.FieldByName('BIN_VAL'), bmRead);
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
      DataSet.FieldByName('BIN_HEX').AsString := HexText;
    finally
      Stream.Free;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  DataDirectory, DatabaseFile: string;
begin
  DataDirectory := TPath.Combine(
    GetEnvironmentVariable('LOCALAPPDATA'), 'DBTest');
  if ParamCount > 0 then
    DatabaseFile := ExpandFileName(ParamStr(1))
  else
    DatabaseFile := TPath.Combine(DataDirectory, 'sample.ib');
  ConfigureSampleConnection(Connection1, DatabaseFile);
  PrepareSampleDatabase(Connection1);
  OpenSampleTable(Table1);
  Caption := 'FireDAC + InterBase Lite - ' + DatabaseFile;
end;

end.

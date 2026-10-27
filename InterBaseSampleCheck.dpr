program InterBaseSampleCheck;

{ Save this program as UTF-8 with BOM. }
{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Data.DB, Vcl.Forms, FireDAC.Comp.Client,
  Unit1 in 'Unit1.pas',
  InterBaseSamples in 'InterBaseSamples.pas';

type
  TExceptionReporter = class
    procedure Report(Sender: TObject; E: Exception);
  end;

procedure TExceptionReporter.Report(Sender: TObject; E: Exception);
begin
  Writeln('FAIL: ', E.ClassName, ': ', E.Message);
  Halt(1);
end;

procedure Require(Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create(MessageText);
end;

procedure CheckBinary(Table: TDataSet);
var
  Stream: TStream;
  Bytes: TBytes;
  Expected: TBytes;
begin
  Stream := Table.CreateBlobStream(Table.FieldByName('BIN_VAL'), bmRead);
  try
    SetLength(Bytes, Stream.Size);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
  Expected := TBytes.Create(0, 1, 2, 127, 255) +
    TEncoding.ASCII.GetBytes('Binary sample 1');
  Require(Length(Bytes) = Length(Expected), 'Binary length changed.');
  Require(CompareMem(@Bytes[0], @Expected[0], Length(Expected)), 'Binary bytes changed.');
end;

procedure CheckForm(Form: TForm1; ExpectEdited: Boolean);
begin
  Form.Table1.First;
  Require(Form.Table1.FieldCount = 16, 'Expected 14 stored + 2 calculated fields.');
  Require(Form.Table1.RecordCount = 3, 'Expected three rows, without duplicates.');
  Require(Form.Table1.FieldByName('ID').AsString = '001', 'Unexpected first ID.');
  if ExpectEdited then
  begin
    Require(Form.Table1.FieldByName('NAME').AsWideString = '日本語の編集結果', 'Name edit lost.');
    Require(Form.Table1.FieldByName('ADDRESS').AsWideString = '東京都千代田区', 'Address edit lost.');
  end
  else
  begin
    Require(Form.Table1.FieldByName('NAME').AsWideString = '山田 太郎', 'Japanese name lost.');
    Require(Form.Table1.FieldByName('ADDRESS').AsWideString = '東京都', 'Japanese address lost.');
  end;
  Require(Abs(Form.Table1.FieldByName('NUM_VAL').AsFloat - 123.45) < 0.005, 'Numeric changed.');
  Require(Abs(Form.Table1.FieldByName('FLOAT_VAL').AsFloat - 1.2345) < 0.00001, 'Float changed.');
  Require(Abs(Form.Table1.FieldByName('DOUBLE_VAL').AsFloat - 123456.789012) < 0.000001, 'Double changed.');
  Require(Form.Table1.FieldByName('BOOL_VAL').AsBoolean, 'Boolean changed.');
  Require(Form.Table1.FieldByName('DATE_VAL').AsDateTime = EncodeDate(2026, 10, 21), 'Date changed.');
  Require(Abs(Form.Table1.FieldByName('STAMP_VAL').AsDateTime -
    (EncodeDate(2026, 10, 27) + EncodeTime(9, 1, 30, 125))) < 1 / 86400000, 'Timestamp changed.');
  Require(Form.Table1.FieldByName('LONG_VAL').AsInteger = 100000, 'Integer changed.');
  Require(Form.Table1.FieldByName('AUTO_VAL').AsInteger > 0, 'Generated ID missing.');
  Require(Pos('InterBaseに保存した2行目です。',
    Form.Table1.FieldByName('MEMO_VAL').AsWideString) > 0, 'Japanese memo lost.');
  Require(Pos(' / ', Form.Table1.FieldByName('MEMO_TEXT').AsWideString) > 0, 'Memo preview missing.');
  Require(Pos('00 01 02 7F FF', Form.Table1.FieldByName('BIN_HEX').AsString) = 1, 'Hex preview missing.');
  Require(Form.Table1.FieldByName('OLE_VAL').IsNull, 'OLE should be NULL.');
  CheckBinary(Form.Table1);
end;

var
  Form: TForm1;
  Query: TFDQuery;
  GeneratedID: Integer;
  Reporter: TExceptionReporter;
begin
  try
    Require(ParamCount in [1, 2], 'Pass a NEW test database path, or a tested path and --reopen.');
    if ParamCount = 2 then
      Require(ParamStr(2) = '--reopen', 'Unknown test option.')
    else
      Require(not FileExists(ParamStr(1)), 'Test database already exists; nothing was changed.');
    Application.Initialize;
    Reporter := TExceptionReporter.Create;
    Application.OnException := Reporter.Report;
    if ParamCount = 2 then
    begin
      Form := TForm1.Create(nil);
      try
        CheckForm(Form, True);
      finally
        Form.Free;
      end;
      Writeln('PASS: data and edits survived a process restart.');
      Application.OnException := nil;
      Reporter.Free;
      Exit;
    end;
    Form := TForm1.Create(nil);
    try
      CheckForm(Form, False);
      Form.Table1.Edit;
      Form.Table1.FieldByName('NAME').AsWideString := '日本語の編集結果';
      Form.Table1.FieldByName('ADDRESS').AsWideString := '東京都千代田区';
      Form.Table1.Post;
      Form.Table1.Append;
      Form.Table1.FieldByName('ID').AsWideString := '099';
      Form.Table1.FieldByName('NAME').AsWideString := '追加テスト';
      Form.Table1.Post;
      Form.Table1.Refresh;
      Require(Form.Table1.Locate('ID', '099', []), 'Inserted row missing.');
      GeneratedID := Form.Table1.FieldByName('AUTO_VAL').AsInteger;
      Require(GeneratedID > 3, 'Insert did not generate a new ID.');
      Form.Table1.Delete;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Form.Connection1;
        Query.Open('SELECT RDB$CHARACTER_SET_NAME FROM RDB$DATABASE');
        Require(Trim(Query.Fields[0].AsString) = 'UTF8', 'Database default charset is not UTF8.');
      finally
        Query.Free;
      end;
      Require(GetModuleHandle('idapi32.dll') = 0, 'BDE was loaded.');
      Require(GetModuleHandle('ibtogo.dll') <> 0, 'Embedded InterBase runtime not loaded.');
    finally
      Form.Free;
    end;
    Form := TForm1.Create(nil);
    try
      CheckForm(Form, True);
    finally
      Form.Free;
    end;
    Writeln('PASS: form loading, UTF8, all fields, binary bytes, previews, edits, generated IDs, restart, no BDE.');
    Application.OnException := nil;
    Reporter.Free;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

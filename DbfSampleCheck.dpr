program DbfSampleCheck;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, DB, DBTables,
  DbfSamples in 'DbfSamples.pas';

procedure Require(Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create(MessageText);
end;

procedure CheckFreshTable(const Directory: string);
var
  Table: TTable;
  Value: string;
begin
  Table := TTable.Create(nil);
  try
    Table.DatabaseName := Directory;
    Table.TableType := ttDBase;
    Table.TableName := 'sample.dbf';
    PrepareSampleTable(Table);
    Table.Open;
    AddSampleRows(Table);
    Require(Table.FieldCount = 14, 'Expected 14 fields covering 12 native types.');
    Require(Table.RecordCount = 3, 'Expected three seed rows.');
    Table.First;
    Require(Table.FieldByName('ID').AsString = '001', 'Unexpected first ID.');
    Require(Abs(Table.FieldByName('NUM_VAL').AsFloat - 123.45) < 0.005, 'Numeric value lost.');
    Require(Abs(Table.FieldByName('FLOAT_VAL').AsFloat - 1.2345) < 0.00005, 'Float value lost.');
    Require(Abs(Table.FieldByName('DOUBLE_VAL').AsFloat - 123456.789012) < 0.000001, 'Double value lost.');
    Require(Table.FieldByName('BOOL_VAL').AsBoolean, 'Logical value lost.');
    Require(Table.FieldByName('DATE_VAL').AsDateTime = EncodeDate(2026, 10, 21), 'Date value lost.');
    Require(Abs(Table.FieldByName('STAMP_VAL').AsDateTime -
      (EncodeDate(2026, 10, 27) + EncodeTime(9, 1, 30, 125))) < 1 / 86400000,
      'Timestamp value lost.');
    Require(Table.FieldByName('LONG_VAL').AsInteger = 100000, 'Long value lost.');
    Require(Table.FieldByName('AUTO_VAL').AsInteger > 0, 'AutoIncrement not generated.');
    Require(Pos('A second line', Table.FieldByName('MEMO_VAL').AsString) > 0, 'Memo value lost.');
    Value := TBlobField(Table.FieldByName('BIN_VAL')).AsString;
    Require(Value = #0#1#2#127#255 + 'Binary sample 1', 'Binary bytes lost.');
    Require(Table.FieldByName('OLE_VAL').IsNull, 'OLE placeholder should be NULL.');
    Table.Close;
    PrepareSampleTable(Table);
    Table.Open;
    AddSampleRows(Table);
    Require(Table.RecordCount = 3, 'Restart duplicated or lost rows.');
    Require(Pos('A second line', Table.FieldByName('MEMO_VAL').AsString) > 0,
      'Memo did not survive reopening.');
  finally
    Table.Free;
  end;
end;

procedure CheckLegacyUpgrade(const Directory: string);
var
  Table: TTable;
  Search: TSearchRec;
  BackupName: string;
begin
  Table := TTable.Create(nil);
  try
    Table.DatabaseName := Directory;
    Table.TableType := ttDBase;
    Table.TableLevel := 5;
    Table.TableName := 'sample.dbf';
    Table.FieldDefs.Add('ID', ftString, 10);
    Table.FieldDefs.Add('NAME', ftString, 50);
    Table.FieldDefs.Add('ADDRESS', ftString, 100);
    Table.CreateTable;
    Table.Open;
    Table.AppendRecord(['099', 'Existing Person', 'Existing Address']);
    Table.Close;
    PrepareSampleTable(Table);
    Table.Open;
    AddSampleRows(Table);
    Require(Table.RecordCount = 1, 'Upgrade must preserve the existing row count.');
    Require(Table.FieldByName('ID').AsString = '099', 'Upgrade changed ID.');
    Require(Table.FieldByName('NAME').AsString = 'Existing Person', 'Upgrade changed NAME.');
    Require(Table.FieldByName('ADDRESS').AsString = 'Existing Address', 'Upgrade changed ADDRESS.');
    Require(Table.FieldCount = 14, 'Upgrade did not add all native types.');
    Table.Close;
    Require(FindFirst(IncludeTrailingPathDelimiter(Directory) +
      'sample_before_alltypes_*.dbf', faAnyFile, Search) = 0, 'Backup is missing.');
    try
      BackupName := Search.Name;
    finally
      FindClose(Search);
    end;
    Table.TableName := BackupName;
    Table.Open;
    Require(Table.FieldCount = 3, 'Backup schema changed.');
    Require(Table.RecordCount = 1, 'Backup row count changed.');
    Require(Table.FieldByName('NAME').AsString = 'Existing Person', 'Backup data changed.');
  finally
    Table.Free;
  end;
end;

var
  Root, Fresh, Legacy: string;
  Buffer: array[0..MAX_PATH] of Char;
begin
  try
    if GetTempPath(SizeOf(Buffer), Buffer) = 0 then
      RaiseLastOSError;
    Root := IncludeTrailingPathDelimiter(StrPas(Buffer)) +
      'DbfSampleCheck_' + IntToHex(GetTickCount, 8);
    if DirectoryExists(Root) then
      raise Exception.Create('Test directory already exists. Retry later.');
    Fresh := Root + '\fresh';
    Legacy := Root + '\legacy';
    ForceDirectories(Fresh);
    ForceDirectories(Legacy);
    Writeln('Test files: ', Root);
    CheckFreshTable(Fresh);
    CheckLegacyUpgrade(Legacy);
    Writeln('PASS: native field codes, values, restart and legacy backup upgrade.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      Halt(1);
    end;
  end;
end.

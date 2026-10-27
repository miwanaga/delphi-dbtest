unit InterBaseSamples;

{ Save this unit as UTF-8 with BOM. }

interface

uses
  System.SysUtils, Data.DB, FireDAC.Comp.Client;

procedure ConfigureSampleConnection(Connection: TFDConnection;
  const DatabaseFile: string);
procedure PrepareSampleDatabase(Connection: TFDConnection);
procedure OpenSampleTable(Table: TFDTable);

implementation

uses
  System.Classes, System.IOUtils, FireDAC.Stan.Param, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Phys.IB, FireDAC.VCLUI.Wait;

procedure ConfigureSampleConnection(Connection: TFDConnection;
  const DatabaseFile: string);
var
  RuntimeFile: string;
begin
  {$IFDEF WIN64}
  RuntimeFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'ibtogo64.dll');
  {$ELSE}
  RuntimeFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'ibtogo.dll');
  {$ENDIF}
  if not FileExists(RuntimeFile) then
    raise EDatabaseError.CreateFmt(
      'InterBase Lite runtime not found: %s. Run Deploy-InterBase.ps1 first.',
      [RuntimeFile]);
  if not ForceDirectories(ExtractFilePath(ExpandFileName(DatabaseFile))) then
    raise EDatabaseError.Create('Cannot create the database directory.');
  Connection.Close;
  Connection.LoginPrompt := False;
  Connection.Params.Clear;
  Connection.Params.Values['DriverID'] := 'IBLite';
  Connection.Params.Values['Database'] := ExpandFileName(DatabaseFile);
  Connection.Params.Values['User_Name'] := 'sysdba';
  Connection.Params.Values['Password'] := 'masterkey';
  Connection.Params.Values['CharacterSet'] := 'UTF8';
  Connection.Params.Values['SQLDialect'] := '3';
  Connection.Params.Values['ExtendedMetadata'] := 'True';
  Connection.Params.Values['OpenMode'] := 'OpenOrCreate';
  Connection.TxOptions.AutoCommit := True;
  Connection.Connected := True;
  { CREATE DATABASE sets the database charset, but its initial attachment does
    not apply the requested client charset. Reattach before sending Unicode. }
  Connection.Close;
  Connection.Params.Values['OpenMode'] := 'Open';
  Connection.Connected := True;
end;

procedure PrepareSampleDatabase(Connection: TFDConnection);
const
  Names: array[1..3] of string = ('山田 太郎', '鈴木 花子', '佐藤 一郎');
  Addresses: array[1..3] of string = ('東京都', '大阪府', '愛知県');
var
  Query: TFDQuery;
  I: Integer;
  Bytes, TextBytes: TBytes;
  BlobStream: TBytesStream;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;
    Query.Open('SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ' +
      'WHERE RDB$RELATION_NAME = ''SAMPLE_DATA''');
    if Query.IsEmpty then
    begin
      Query.Close;
      Connection.StartTransaction;
      try
        Connection.ExecSQL(
          'CREATE TABLE SAMPLE_DATA (' +
          'ID VARCHAR(10) CHARACTER SET UTF8 NOT NULL, ' +
          'NAME VARCHAR(50) CHARACTER SET UTF8, ' +
          'ADDRESS VARCHAR(100) CHARACTER SET UTF8, ' +
          'NUM_VAL NUMERIC(12,2), FLOAT_VAL FLOAT, ' +
          'DOUBLE_VAL DOUBLE PRECISION, BOOL_VAL BOOLEAN, DATE_VAL DATE, ' +
          'STAMP_VAL TIMESTAMP, LONG_VAL INTEGER, ' +
          'AUTO_VAL INTEGER NOT NULL PRIMARY KEY, ' +
          'MEMO_VAL BLOB SUB_TYPE TEXT CHARACTER SET UTF8, ' +
          'BIN_VAL BLOB SUB_TYPE 0, OLE_VAL BLOB SUB_TYPE 0)');
        Connection.ExecSQL('CREATE GENERATOR SAMPLE_AUTO_GEN');
        Connection.ExecSQL(
          'CREATE TRIGGER SAMPLE_AUTO_BI FOR SAMPLE_DATA ' +
          'ACTIVE BEFORE INSERT POSITION 0 AS BEGIN ' +
          'IF (NEW.AUTO_VAL IS NULL) THEN ' +
          'NEW.AUTO_VAL = GEN_ID(SAMPLE_AUTO_GEN, 1); END');
        Connection.Commit;
      except
        Connection.Rollback;
        raise;
      end;
    end;
    Query.Close;
    { Seed all rows in one transaction. Existing data is never replaced. }
    Connection.StartTransaction;
    try
      Query.Open('SELECT COUNT(*) AS ROW_COUNT FROM SAMPLE_DATA');
      I := Query.FieldByName('ROW_COUNT').AsInteger;
      Query.Close;
      if I = 0 then
      begin
        Query.SQL.Text :=
          'INSERT INTO SAMPLE_DATA (ID, NAME, ADDRESS, NUM_VAL, FLOAT_VAL, ' +
          'DOUBLE_VAL, BOOL_VAL, DATE_VAL, STAMP_VAL, LONG_VAL, MEMO_VAL, BIN_VAL) ' +
          'VALUES (:ID, :NAME, :ADDRESS, :NUM_VAL, :FLOAT_VAL, :DOUBLE_VAL, ' +
          ':BOOL_VAL, :DATE_VAL, :STAMP_VAL, :LONG_VAL, :MEMO_VAL, :BIN_VAL)';
        for I := 1 to 3 do
        begin
          Query.ParamByName('ID').AsWideString := Format('%.3d', [I]);
          Query.ParamByName('NAME').AsWideString := Names[I];
          Query.ParamByName('ADDRESS').AsWideString := Addresses[I];
          Query.ParamByName('NUM_VAL').AsCurrency := I * 123.45;
          Query.ParamByName('FLOAT_VAL').AsSingle := I * 1.2345;
          Query.ParamByName('DOUBLE_VAL').AsFloat := I * 123456.789012;
          Query.ParamByName('BOOL_VAL').AsBoolean := Odd(I);
          Query.ParamByName('DATE_VAL').AsDate := EncodeDate(2026, 10, 20 + I);
          Query.ParamByName('STAMP_VAL').AsDateTime :=
            EncodeDate(2026, 10, 27) + EncodeTime(9, I, 30, 125);
          Query.ParamByName('LONG_VAL').AsInteger := I * 100000;
          Query.ParamByName('MEMO_VAL').DataType := ftWideMemo;
          Query.ParamByName('MEMO_VAL').AsWideMemo :=
            'メモのサンプル ' + IntToStr(I) + #13#10 + 'InterBaseに保存した2行目です。';
          Bytes := TBytes.Create(0, 1, 2, 127, 255);
          TextBytes := TEncoding.ASCII.GetBytes('Binary sample ' + IntToStr(I));
          Bytes := Bytes + TextBytes;
          BlobStream := TBytesStream.Create(Bytes);
          try
            Query.ParamByName('BIN_VAL').LoadFromStream(BlobStream, ftBlob);
          finally
            BlobStream.Free;
          end;
          Query.ExecSQL;
        end;
      end;
      Connection.Commit;
    except
      if Connection.InTransaction then
        Connection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure OpenSampleTable(Table: TFDTable);
var
  I: Integer;
  Field: TField;
begin
  Table.Close;
  Table.TableName := 'SAMPLE_DATA';
  Table.IndexFieldNames := 'ID';
  { Create fields from actual metadata, avoiding DBF-specific field classes. }
  if Table.FieldCount = 0 then
  begin
    Table.FieldDefs.Update;
    for I := 0 to Table.FieldDefs.Count - 1 do
      Table.FieldDefs[I].CreateField(Table);
    Field := TWideStringField.Create(Table);
    Field.FieldName := 'MEMO_TEXT';
    Field.FieldKind := fkCalculated;
    Field.Size := 255;
    Field.ReadOnly := True;
    Field.DisplayWidth := 60;
    Field.DataSet := Table;
    Field := TStringField.Create(Table);
    Field.FieldName := 'BIN_HEX';
    Field.FieldKind := fkCalculated;
    Field.Size := 255;
    Field.ReadOnly := True;
    Field.DisplayWidth := 70;
    Field.DataSet := Table;
  end;
  Table.FieldByName('AUTO_VAL').ReadOnly := True;
  Table.FieldByName('AUTO_VAL').Required := False;
  Table.FieldByName('AUTO_VAL').AutoGenerateValue := arAutoInc;
  Table.UpdateOptions.AutoIncFields := 'AUTO_VAL';
  Table.Open;
  Table.FieldByName('ID').DisplayWidth := 10;
  Table.FieldByName('NAME').DisplayWidth := 20;
  Table.FieldByName('ADDRESS').DisplayWidth := 30;
end;

end.


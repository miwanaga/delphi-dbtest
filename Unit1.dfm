object Form1: TForm1
  Left = 406
  Top = 142
  Width = 1503
  Height = 802
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object DBGrid1: TDBGrid
    Left = 96
    Top = 48
    Width = 1217
    Height = 497
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = SHIFTJIS_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = #65325#65331' '#65328#12468#12471#12483#12463
    TitleFont.Style = []
  end
  object Table1: TTable
    TableName = 'sample.dbf'
    TableType = ttDBase
    OnCalcFields = Table1CalcFields
    Left = 704
    Top = 168
    object Table1ID: TStringField
      FieldName = 'ID'
      Size = 10
    end
    object Table1NAME: TStringField
      FieldName = 'NAME'
      Size = 50
    end
    object Table1ADDRESS: TStringField
      FieldName = 'ADDRESS'
      Size = 100
    end
    object Table1NUM_VAL: TFloatField
      FieldName = 'NUM_VAL'
    end
    object Table1FLOAT_VAL: TFloatField
      FieldName = 'FLOAT_VAL'
    end
    object Table1DOUBLE_VAL: TFloatField
      FieldName = 'DOUBLE_VAL'
    end
    object Table1BOOL_VAL: TBooleanField
      FieldName = 'BOOL_VAL'
    end
    object Table1DATE_VAL: TDateField
      FieldName = 'DATE_VAL'
    end
    object Table1STAMP_VAL: TDateTimeField
      FieldName = 'STAMP_VAL'
    end
    object Table1LONG_VAL: TIntegerField
      FieldName = 'LONG_VAL'
    end
    object Table1AUTO_VAL: TAutoIncField
      FieldName = 'AUTO_VAL'
      ReadOnly = True
    end
    object Table1MEMO_VAL: TMemoField
      FieldName = 'MEMO_VAL'
    end
    object Table1BIN_VAL: TBlobField
      FieldName = 'BIN_VAL'
      BlobType = ftTypedBinary
    end
    object Table1OLE_VAL: TBlobField
      FieldName = 'OLE_VAL'
      BlobType = ftDBaseOle
    end
    object Table1MEMO_TEXT: TStringField
      FieldKind = fkCalculated
      FieldName = 'MEMO_TEXT'
      ReadOnly = True
      Size = 255
      DisplayWidth = 60
      Calculated = True
    end
    object Table1BIN_HEX: TStringField
      FieldKind = fkCalculated
      FieldName = 'BIN_HEX'
      ReadOnly = True
      Size = 255
      DisplayWidth = 70
      Calculated = True
    end
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 632
    Top = 240
  end
end

object Form1: TForm1
  Left = 192
  Top = 125
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
  OnDestroy = FormDestroy
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 12
  object DBGrid1: TDBGrid
    Left = 96
    Top = 48
    Width = 320
    Height = 120
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = SHIFTJIS_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = #65325#65331' '#65328#12468#12471#12483#12463
    TitleFont.Style = []
  end
  object Table1: TIBTable
    Database = IBDatabase1
    Transaction = IBTransaction1
    TableName = 'SAMPLE'
    AfterPost = Table1AfterPost
    AfterDelete = Table1AfterPost
    Left = 704
    Top = 168
  end
  object IBDatabase1: TIBDatabase
    LoginPrompt = False
    DefaultTransaction = IBTransaction1
    SQLDialect = 3
    Left = 800
    Top = 168
  end
  object IBTransaction1: TIBTransaction
    DefaultDatabase = IBDatabase1
    DefaultAction = TARollback
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    Left = 896
    Top = 168
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 632
    Top = 240
  end
end

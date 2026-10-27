object Form1: TForm1
  Left = 406
  Top = 142
  Caption = 'FireDAC + InterBase Lite'
  ClientHeight = 763
  ClientWidth = 1487
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Yu Gothic UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 1487
    Height = 763
    Align = alClient
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Yu Gothic UI'
    TitleFont.Style = []
  end
  object Connection1: TFDConnection
    LoginPrompt = False
    Left = 560
    Top = 168
  end
  object Table1: TFDTable
    OnCalcFields = Table1CalcFields
    Connection = Connection1
    TableName = 'SAMPLE_DATA'
    Left = 704
    Top = 168
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 632
    Top = 240
  end
end

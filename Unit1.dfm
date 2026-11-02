object Form1: TForm1
  Left = 192
  Top = 125
  Caption = 'Form1'
  ClientHeight = 763
  ClientWidth = 1487
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
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
  object Table1: TTable
    DatabaseName = 'sample'
    Left = 704
    Top = 168
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 632
    Top = 240
  end
end

object Main: TMain
  Left = 0
  Top = 0
  Caption = 'TokyoScript (c)2018 Execute SARL'
  ClientHeight = 544
  ClientWidth = 995
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object spLog: TSplitter
    Left = 0
    Top = 452
    Width = 995
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 35
    ExplicitWidth = 295
  end
  object Splitter1: TSplitter
    Left = 717
    Top = 35
    Height = 417
    Align = alRight
    ExplicitLeft = 408
    ExplicitTop = 176
    ExplicitHeight = 100
  end
  object SynEdit: TSynEdit
    Left = 0
    Top = 35
    Width = 717
    Height = 417
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    TabOrder = 0
    CodeFolding.CollapsedLineColor = clGrayText
    CodeFolding.FolderBarLinesColor = clGrayText
    CodeFolding.ShowCollapsedLine = True
    CodeFolding.IndentGuidesColor = clGray
    CodeFolding.IndentGuides = True
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Gutter.ShowLineNumbers = True
    Highlighter = SynPasSyn1
    FontSmoothing = fsmNone
    ExplicitWidth = 807
    ExplicitHeight = 295
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 995
    Height = 35
    Align = alTop
    Caption = 'Panel1'
    ParentBackground = False
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
    ExplicitWidth = 807
    object btRun: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 29
      Height = 27
      Align = alLeft
      Caption = '4'
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Webdings'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btRunClick
    end
    object cbSource: TComboBox
      AlignWithMargins = True
      Left = 39
      Top = 7
      Width = 145
      Height = 22
      Margins.Top = 6
      Margins.Bottom = 6
      Align = alLeft
      Style = csOwnerDrawVariable
      TabOrder = 1
      OnChange = cbSourceChange
    end
  end
  object mmLog: TMemo
    Left = 0
    Top = 455
    Width = 995
    Height = 89
    Align = alBottom
    Lines.Strings = (
      'mmLog')
    ScrollBars = ssBoth
    TabOrder = 2
    Visible = False
    ExplicitTop = 330
    ExplicitWidth = 807
  end
  object mmDump: TMemo
    Left = 720
    Top = 35
    Width = 275
    Height = 417
    Align = alRight
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 3
  end
  object SynPasSyn1: TSynPasSyn
    Options.AutoDetectEnabled = False
    Options.AutoDetectLineLimit = 0
    Options.Visible = False
    CommentAttri.Foreground = clGreen
    DirectiveAttri.Foreground = clTeal
    NumberAttri.Foreground = clFuchsia
    FloatAttri.Foreground = clFuchsia
    StringAttri.Foreground = clBlue
    CharAttri.Foreground = clBlue
    Left = 312
    Top = 152
  end
end

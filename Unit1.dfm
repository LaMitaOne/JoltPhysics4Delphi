object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'MRX Engine Editor - Prototype'
  ClientHeight = 642
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 200
    Top = 0
    Width = 5
    Height = 600
    ExplicitLeft = 201
    ExplicitHeight = 441
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 200
    Height = 600
    Align = alLeft
    Caption = 'pnlLeft'
    TabOrder = 0
    ExplicitHeight = 599
    object Splitter2: TSplitter
      Left = 1
      Top = 289
      Width = 198
      Height = 8
      Cursor = crVSplit
      Align = alTop
    end
    object tvSceneHierarchy: TTreeView
      Left = 1
      Top = 1
      Width = 198
      Height = 288
      Align = alTop
      Indent = 19
      TabOrder = 0
      OnChange = tvSceneHierarchyChange
    end
    object Panel1: TPanel
      Left = 1
      Top = 297
      Width = 198
      Height = 302
      Align = alClient
      Caption = 'Panel1'
      TabOrder = 1
      ExplicitHeight = 301
      object StringGrid1: TStringGrid
        Left = 1
        Top = 1
        Width = 196
        Height = 300
        Align = alClient
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goFixedRowDefAlign]
        TabOrder = 0
        OnSelectCell = StringGrid1SelectCell
        OnSetEditText = StringGrid1SetEditText
        ExplicitHeight = 299
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 600
    Width = 1100
    Height = 42
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 599
    ExplicitWidth = 1096
    DesignSize = (
      1100
      42)
    object lblInfo: TLabel
      Left = 410
      Top = 13
      Width = 3
      Height = 15
    end
    object btnSpawnCubes: TButton
      Left = 10
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Spawn Cubes'
      TabOrder = 0
      OnClick = btnSpawnCubesClick
    end
    object btnSpawnSpheres: TButton
      Left = 106
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Spawn Spheres'
      TabOrder = 1
      OnClick = btnSpawnSpheresClick
    end
    object btnSpawnPyramids: TButton
      Left = 202
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Spawn Pyramids'
      TabOrder = 2
      OnClick = btnSpawnPyramidsClick
    end
    object btnClearScene: TButton
      Left = 298
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Clear Scene'
      TabOrder = 3
      OnClick = btnClearSceneClick
    end
    object btnPlayPause: TButton
      Left = 1010
      Top = 8
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'play/pause'
      TabOrder = 4
      OnClick = btnPlayPauseClick
      ExplicitLeft = 1006
    end
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 240
    Top = 32
    object miDelete: TMenuItem
      Caption = 'Delete selected'
      OnClick = miDeleteClick
    end
    object miDuplicate: TMenuItem
      Caption = 'Duplicate selected'
      OnClick = miDuplicateClick
    end
  end
end

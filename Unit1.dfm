object btnSpawnCapsules: TbtnSpawnCapsules
  Left = 0
  Top = 0
  Caption = 'MRX Engine Editor - Prototype'
  ClientHeight = 642
  ClientWidth = 1100
  Color = 4276545
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
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
      Color = clTeal
      ParentColor = False
    end
    object tvSceneHierarchy: TTreeView
      Left = 1
      Top = 1
      Width = 198
      Height = 288
      Align = alTop
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      Indent = 19
      ParentFont = False
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
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goFixedRowDefAlign]
        ParentFont = False
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
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clSilver
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    ExplicitTop = 604
    DesignSize = (
      1100
      42)
    object lblInfo: TLabel
      Left = 546
      Top = 8
      Width = 346
      Height = 33
      AutoSize = False
      Caption = 'loading...'
      WordWrap = True
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
      Left = 434
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
    object btnToolDragThrow: TButton
      Left = 898
      Top = 8
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Drag n Throw'
      TabOrder = 5
      OnClick = btnToolDragThrowClick
    end
    object btnSpawnCapsules: TButton
      Left = 298
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Spawn Capsule'
      TabOrder = 6
      OnClick = btnSpawnCapsulesClick
    end
  end
end

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
  OnShow = FormShow
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 200
    Top = 0
    Width = 5
    Height = 600
    ExplicitLeft = 201
    ExplicitHeight = 441
  end
  object Splitter3: TSplitter
    Left = 895
    Top = 0
    Width = 5
    Height = 600
    Align = alRight
    ExplicitLeft = 208
    ExplicitTop = 8
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
      Color = 4539717
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      Indent = 19
      ParentFont = False
      TabOrder = 0
      OnChange = tvSceneHierarchyChange
      OnClick = tvSceneHierarchyClick
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
    ExplicitTop = 599
    ExplicitWidth = 1096
    DesignSize = (
      1100
      42)
    object lblInfo: TLabel
      Left = 7
      Top = 6
      Width = 887
      Height = 33
      AutoSize = False
      Caption = 'loading...'
      WordWrap = True
    end
    object btnToolDragThrow: TButton
      Left = 909
      Top = 6
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Drag n Throw'
      TabOrder = 0
      OnClick = btnToolDragThrowClick
      ExplicitLeft = 905
    end
    object btnPlayPause: TButton
      Left = 1005
      Top = 6
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'play/pause'
      TabOrder = 1
      OnClick = btnPlayPauseClick
      ExplicitLeft = 1001
    end
  end
  object Panel2: TPanel
    Left = 900
    Top = 0
    Width = 200
    Height = 600
    Align = alRight
    Caption = 'pnlRight'
    TabOrder = 2
    ExplicitLeft = 896
    ExplicitHeight = 599
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 198
      Height = 598
      ActivePage = tsScene
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      ExplicitHeight = 597
      object tsScene: TTabSheet
        Caption = 'Scene'
        DesignSize = (
          190
          568)
        object Shape1: TShape
          Left = 0
          Top = 0
          Width = 190
          Height = 568
          Align = alClient
          Brush.Color = clBlack
          ExplicitLeft = 88
          ExplicitTop = 232
          ExplicitWidth = 65
          ExplicitHeight = 65
        end
        object btnClearScene: TButton
          Left = 13
          Top = 31
          Width = 90
          Height = 25
          Caption = 'Clear Scene'
          TabOrder = 0
          OnClick = btnClearSceneClick
        end
        object btnSpawnCubes: TButton
          Left = 13
          Top = 97
          Width = 119
          Height = 25
          Caption = 'Spawn Cubes'
          TabOrder = 1
          OnClick = btnSpawnCubesClick
        end
        object btnSpawnSpheres: TButton
          Left = 13
          Top = 126
          Width = 119
          Height = 25
          Caption = 'Spawn Spheres'
          TabOrder = 2
          OnClick = btnSpawnSpheresClick
        end
        object btnSpawnPyramids: TButton
          Left = 13
          Top = 155
          Width = 119
          Height = 25
          Caption = 'Spawn Pyramids'
          TabOrder = 3
          OnClick = btnSpawnPyramidsClick
        end
        object btnSpawnCapsules: TButton
          Left = 13
          Top = 184
          Width = 119
          Height = 25
          Caption = 'Spawn Capsule'
          TabOrder = 4
          OnClick = btnSpawnCapsulesClick
        end
        object btnSceneSave: TButton
          Left = 13
          Top = 327
          Width = 52
          Height = 25
          Caption = 'Save'
          TabOrder = 5
          OnClick = btnSceneSaveClick
        end
        object btnSceneLoad: TButton
          Left = 77
          Top = 327
          Width = 52
          Height = 25
          Caption = 'Load'
          TabOrder = 6
          OnClick = btnSceneLoadClick
        end
        object btnSpawn3DModel: TButton
          Left = 13
          Top = 261
          Width = 119
          Height = 25
          Caption = 'Spawn 3d model'
          TabOrder = 7
          OnClick = btnSpawn3DModelClick
        end
        object btnSpawnPrisms: TButton
          Left = 13
          Top = 215
          Width = 119
          Height = 25
          Caption = 'Spawn Prism'
          TabOrder = 8
          OnClick = btnSpawnPrismsClick
        end
        object Memo1: TMemo
          Left = 16
          Top = 376
          Width = 161
          Height = 177
          Anchors = [akLeft, akBottom]
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clSilver
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 9
        end
      end
      object tsEngine: TTabSheet
        Caption = 'Engine'
        ImageIndex = 1
        object Label1: TLabel
          Left = 16
          Top = 56
          Width = 22
          Height = 15
          Caption = 'FPS:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object cbFPS: TComboBox
          Left = 16
          Top = 77
          Width = 145
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ItemIndex = 3
          ParentFont = False
          TabOrder = 0
          Text = '60'
          OnChange = cbFPSChange
          Items.Strings = (
            '10'
            '20'
            '30'
            '60'
            '90'
            '120'
            '144'
            '160'
            '200'
            '240'
            '320'
            '500'
            '1000'
            '5000')
        end
        object chkDistanceCulling: TCheckBox
          Left = 16
          Top = 157
          Width = 105
          Height = 17
          Caption = 'Distance culling'
          Checked = True
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 1
          StyleElements = [seClient, seBorder]
          OnClick = chkDistanceCullingClick
        end
        object cbFrustumCulling: TCheckBox
          Left = 16
          Top = 186
          Width = 129
          Height = 17
          Caption = 'Frustum culling'
          Checked = True
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 2
          StyleElements = [seClient, seBorder]
          OnClick = cbFrustumCullingClick
        end
        object chkHightlightCollision: TCheckBox
          Left = 16
          Top = 336
          Width = 145
          Height = 17
          Caption = 'Hightlight Collision'
          TabOrder = 3
          OnClick = chkHightlightCollisionClick
        end
      end
    end
  end
  object tmrStatsUpdater: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrStatsUpdaterTimer
    Left = 1065
    Top = 411
  end
end

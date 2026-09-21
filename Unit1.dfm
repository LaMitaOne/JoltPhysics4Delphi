object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'MRX Engine Editor - Prototype'
  ClientHeight = 689
  ClientWidth = 1100
  Color = 4276545
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 200
    Top = 0
    Width = 5
    Height = 647
    ExplicitLeft = 201
    ExplicitHeight = 441
  end
  object Splitter3: TSplitter
    Left = 895
    Top = 0
    Width = 5
    Height = 647
    Align = alRight
    ExplicitLeft = 208
    ExplicitTop = 8
    ExplicitHeight = 600
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 200
    Height = 647
    Align = alLeft
    Caption = 'pnlLeft'
    TabOrder = 0
    ExplicitHeight = 646
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
    end
    object Panel1: TPanel
      Left = 1
      Top = 297
      Width = 198
      Height = 349
      Align = alClient
      Caption = 'Panel1'
      TabOrder = 1
      ExplicitHeight = 348
      object StringGrid1: TStringGrid
        Left = 1
        Top = 1
        Width = 196
        Height = 347
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
        ExplicitHeight = 346
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 647
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
    ExplicitTop = 646
    ExplicitWidth = 1096
    DesignSize = (
      1100
      42)
    object lblInfo: TLabel
      Left = 7
      Top = 6
      Width = 770
      Height = 33
      AutoSize = False
      Caption = 'loading...'
      WordWrap = True
    end
    object btnToolDragThrow: TButton
      Left = 905
      Top = 6
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Drag n Throw'
      TabOrder = 0
      OnClick = btnToolDragThrowClick
      ExplicitLeft = 901
    end
    object btnPlayPause: TButton
      Left = 1001
      Top = 6
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'play/pause'
      TabOrder = 1
      OnClick = btnPlayPauseClick
      ExplicitLeft = 997
    end
    object btnShoot: TButton
      Left = 809
      Top = 6
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Shoot'
      TabOrder = 2
      OnClick = btnShootClick
      ExplicitLeft = 805
    end
  end
  object Panel2: TPanel
    Left = 900
    Top = 0
    Width = 200
    Height = 647
    Align = alRight
    Caption = 'pnlRight'
    TabOrder = 2
    ExplicitLeft = 896
    ExplicitHeight = 646
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 198
      Height = 645
      ActivePage = tsScene
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      ExplicitHeight = 644
      object tsScene: TTabSheet
        Caption = 'Scene'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSilver
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        DesignSize = (
          190
          615)
        object Shape1: TShape
          Left = 0
          Top = 0
          Width = 190
          Height = 615
          Align = alClient
          Brush.Color = clBlack
          ExplicitLeft = 88
          ExplicitTop = 232
          ExplicitWidth = 65
          ExplicitHeight = 65
        end
        object btnClearScene: TButton
          Left = 125
          Top = 303
          Width = 52
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Clear'
          TabOrder = 0
          OnClick = btnClearSceneClick
          ExplicitTop = 302
        end
        object btnSpawnCubes: TButton
          Left = 13
          Top = 17
          Width = 109
          Height = 25
          Caption = 'Spawn Cubes'
          TabOrder = 1
          OnClick = btnSpawnCubesClick
        end
        object btnSpawnSpheres: TButton
          Left = 13
          Top = 46
          Width = 109
          Height = 25
          Caption = 'Spawn Spheres'
          TabOrder = 2
          OnClick = btnSpawnSpheresClick
        end
        object btnSpawnPyramids: TButton
          Left = 13
          Top = 75
          Width = 109
          Height = 25
          Caption = 'Spawn Pyramids'
          TabOrder = 3
          OnClick = btnSpawnPyramidsClick
        end
        object btnSpawnCapsules: TButton
          Left = 13
          Top = 104
          Width = 109
          Height = 25
          Caption = 'Spawn Capsule'
          TabOrder = 4
          OnClick = btnSpawnCapsulesClick
        end
        object btnSceneSave: TButton
          Left = 125
          Top = 365
          Width = 52
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Save'
          TabOrder = 5
          OnClick = btnSceneSaveClick
          ExplicitTop = 364
        end
        object btnSceneLoad: TButton
          Left = 125
          Top = 334
          Width = 52
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Load'
          TabOrder = 6
          OnClick = btnSceneLoadClick
          ExplicitTop = 333
        end
        object btnSpawn3DModel: TButton
          Left = 13
          Top = 166
          Width = 109
          Height = 25
          Caption = 'Spawn 3d model'
          TabOrder = 7
          OnClick = btnSpawn3DModelClick
        end
        object btnSpawnPrisms: TButton
          Left = 13
          Top = 135
          Width = 109
          Height = 25
          Caption = 'Spawn Prism'
          TabOrder = 8
          OnClick = btnSpawnPrismsClick
        end
        object Memo1: TMemo
          Left = 16
          Top = 399
          Width = 161
          Height = 201
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
          ExplicitTop = 398
        end
        object btnSelectPrev: TButton
          Left = 13
          Top = 365
          Width = 28
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = '<'
          TabOrder = 10
          OnClick = btnSelectPrevClick
          ExplicitTop = 364
        end
        object btnSelectNext: TButton
          Left = 47
          Top = 365
          Width = 28
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = '>'
          TabOrder = 11
          OnClick = btnSelectNextClick
          ExplicitTop = 364
        end
        object btnSpawnSandbox: TButton
          Left = 10
          Top = 303
          Width = 109
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Spawn Sandbox'
          TabOrder = 12
          OnClick = btnSpawnSandboxClick
          ExplicitTop = 302
        end
        object btnSpawnWall: TButton
          Left = 10
          Top = 334
          Width = 109
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Spawn Wall'
          TabOrder = 13
          OnClick = btnSpawnWallClick
          ExplicitTop = 333
        end
        object btnSpawnBomb: TButton
          Left = 13
          Top = 197
          Width = 109
          Height = 25
          Caption = 'Spawn Bomb'
          TabOrder = 14
          OnClick = btnSpawnBombClick
        end
        object btnSpawnButton: TButton
          Left = 13
          Top = 228
          Width = 109
          Height = 25
          Caption = 'Spawn Button'
          TabOrder = 15
          OnClick = btnSpawnButtonClick
        end
        object cbStatic: TCheckBox
          Left = 128
          Top = 21
          Width = 57
          Height = 17
          Hint = 'spawn static'
          Caption = 'static'
          Color = clBlack
          Ctl3D = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clSilver
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentCtl3D = False
          ParentFont = False
          TabOrder = 16
          StyleElements = [seClient, seBorder]
          OnClick = cbStaticClick
        end
      end
      object tsEngine: TTabSheet
        Caption = 'Engine'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSilver
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ImageIndex = 1
        ParentFont = False
        object Label1: TLabel
          Left = 16
          Top = 56
          Width = 58
          Height = 15
          Caption = 'Target FPS:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblDaynightspeed: TLabel
          Left = 32
          Top = 324
          Width = 35
          Height = 15
          Caption = 'Speed:'
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
          Top = 129
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
          Top = 106
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
        object chkHighlightCollision: TCheckBox
          Left = 16
          Top = 368
          Width = 145
          Height = 17
          Caption = 'Highlight Collision'
          TabOrder = 3
          OnClick = chkHighlightCollisionClick
        end
        object chkDayNightRythm: TCheckBox
          Left = 16
          Top = 294
          Width = 105
          Height = 17
          Caption = 'DayNight rythm'
          Checked = True
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clSilver
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 4
          StyleElements = []
          OnClick = chkDayNightRythmClick
        end
        object TimePicker1: TTimePicker
          Left = 127
          Top = 290
          Width = 57
          Height = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = []
          TabOrder = 5
          Time = 0.583333333333333400
          TimeFormat = 'hh:nn'
          OnChange = TimePicker1Change
        end
        object SpDistance: TSpinEdit
          Left = 127
          Top = 126
          Width = 57
          Height = 24
          EditorEnabled = False
          MaxValue = 5000
          MinValue = 10
          TabOrder = 6
          Value = 160
          OnChange = SpDistanceChange
        end
        object seDayNightspeed: TSpinEdit
          Left = 127
          Top = 321
          Width = 57
          Height = 24
          MaxValue = 1000
          MinValue = 1
          TabOrder = 7
          Value = 1
          OnChange = seDayNightspeedChange
        end
        object chkSlowMotion: TCheckBox
          Left = 16
          Top = 209
          Width = 105
          Height = 17
          Caption = 'Slow Motion'
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          TabOrder = 8
          StyleElements = [seClient, seBorder]
          OnClick = chkSlowMotionClick
        end
      end
    end
  end
  object tmrStatsUpdater: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrStatsUpdaterTimer
    Left = 713
    Top = 131
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'd3dfm'
    Left = 808
    Top = 168
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'd3dfm'
    Left = 840
    Top = 120
  end
end

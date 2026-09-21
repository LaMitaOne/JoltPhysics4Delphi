unit Unit1;

{==============================================================================*
 *  Mainform of raylib sandbox & jolt phsics
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
 *
 *  Description:
 *    This unit represents the main VCL interface for the 3D Engine Editor.
 *    It hosts the TRaylibSandbox viewport and wires the editor controls
 *    to the background physics and rendering thread.
 *==============================================================================}
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, RaylibSandbox, ModelEngine, TypInfo,
  JoltPhysics, Vcl.Grids, Raylib, Vcl.Menus, Vcl.WinXPickers, Vcl.Samples.Spin, VCL3D;

type
  TForm1 = class(TForm)
    pnlLeft: TPanel;
    tvSceneHierarchy: TTreeView;
    Splitter1: TSplitter;
    pnlBottom: TPanel;
    lblInfo: TLabel;
    Splitter2: TSplitter;
    Panel1: TPanel;
    StringGrid1: TStringGrid;
    btnToolDragThrow: TButton;
    Panel2: TPanel;
    PageControl1: TPageControl;
    tsScene: TTabSheet;
    tsEngine: TTabSheet;
    Splitter3: TSplitter;
    btnClearScene: TButton;
    btnSpawnCubes: TButton;
    btnSpawnSpheres: TButton;
    btnSpawnPyramids: TButton;
    btnSpawnCapsules: TButton;
    btnSceneSave: TButton;
    btnSceneLoad: TButton;
    cbFPS: TComboBox;
    Label1: TLabel;
    btnPlayPause: TButton;
    Shape1: TShape;
    btnSpawn3DModel: TButton;
    chkDistanceCulling: TCheckBox;
    cbFrustumCulling: TCheckBox;
    btnSpawnPrisms: TButton;
    chkHighlightCollision: TCheckBox;
    Memo1: TMemo;
    tmrStatsUpdater: TTimer;
    btnShoot: TButton;
    OpenDialog1: TOpenDialog;
    chkDayNightRythm: TCheckBox;
    TimePicker1: TTimePicker;
    btnSelectPrev: TButton;
    btnSelectNext: TButton;
    SpDistance: TSpinEdit;
    seDayNightspeed: TSpinEdit;
    lblDaynightspeed: TLabel;
    btnSpawnSandbox: TButton;
    btnSpawnWall: TButton;
    btnSpawnBomb: TButton;
    btnSpawnButton: TButton;
    chkSlowMotion: TCheckBox;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    cbStatic: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSpawnCubesClick(Sender: TObject);
    procedure btnSpawnSpheresClick(Sender: TObject);
    procedure btnSpawnPyramidsClick(Sender: TObject);
    procedure btnClearSceneClick(Sender: TObject);
    procedure tvSceneHierarchyChange(Sender: TObject; Node: TTreeNode);
    procedure btnPlayPauseClick(Sender: TObject);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnToolDragThrowClick(Sender: TObject);
    procedure btnSpawnCapsulesClick(Sender: TObject);
    procedure cbFPSChange(Sender: TObject);
    procedure btnSceneSaveClick(Sender: TObject);
    procedure btnSceneLoadClick(Sender: TObject);
    procedure btnSpawn3DModelClick(Sender: TObject);
    procedure chkDistanceCullingClick(Sender: TObject);
    procedure cbFrustumCullingClick(Sender: TObject);
    procedure btnSpawnPrismsClick(Sender: TObject);
    procedure chkHighlightCollisionClick(Sender: TObject);
    procedure tmrStatsUpdaterTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnShootClick(Sender: TObject);
    procedure chkDayNightRythmClick(Sender: TObject);
    procedure TimePicker1Change(Sender: TObject);
    procedure btnSelectPrevClick(Sender: TObject);
    procedure btnSelectNextClick(Sender: TObject);
    procedure SpDistanceChange(Sender: TObject);
    procedure seDayNightspeedChange(Sender: TObject);
    procedure btnSpawnSandboxClick(Sender: TObject);
    procedure btnSpawnWallClick(Sender: TObject);
    procedure btnSpawnBombClick(Sender: TObject);
    procedure btnSpawnButtonClick(Sender: TObject);
    procedure chkSlowMotionClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure cbStaticClick(Sender: TObject);
  private
    FSandbox: TRaylibSandbox;
    FSelectedComponent: TA3DComponent;
    FIsUpdatingGrid: Boolean;
    procedure RefreshHierarchy;
    procedure HandleViewportReady(Sender: TObject);
    procedure HandleActorSpawned(Sender: TObject; const Args: TActorEventArgs);
    procedure HandleSceneCleared(Sender: TObject);
    procedure HandleEngineException(Sender: TObject; const Args: TEngineExceptionEventArgs);
    procedure LoadPropertiesIntoGrid(AComponent: TA3DComponent);
    procedure SelectActorInUI(AActor: TA3DComponent);
    procedure HandleObjectSelected(Sender: TObject; Actor: TA3DComponent);
    procedure My3DButtonClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
{$R *.dfm}

function StrToVector3(const S: string; Default: TVector3): TVector3;
var
  Parts: TArray<string>;
  v: Single;
  TempStr: string;
begin
  Result := Default;
  TempStr := StringReplace(S, ' ', '', [rfReplaceAll]);
  TempStr := StringReplace(TempStr, '.', ',', [rfReplaceAll]);
  Parts := TempStr.Split([',']);
  if Length(Parts) >= 1 then
    if TryStrToFloat(Trim(Parts[0]), v) then
      Result.x := v;
  if Length(Parts) >= 2 then
    if TryStrToFloat(Trim(Parts[1]), v) then
      Result.y := v;
  if Length(Parts) >= 3 then
    if TryStrToFloat(Trim(Parts[2]), v) then
      Result.z := v;
end;

function Vector3ToStr(const V: TVector3): string;
begin
  Result := Format('%.2f, %.2f, %.2f', [V.x, V.y, V.z], TFormatSettings.Create('en-US'));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'RaylibSandbox & JoltPhysics - Prototype';
  Width := 1200;
  Height := 800;
  StringGrid1.FixedCols := 1;
  StringGrid1.FixedRows := 1;
  StringGrid1.ColCount := 2;
  StringGrid1.RowCount := 2;
  StringGrid1.Cells[0, 0] := 'Property';
  StringGrid1.Cells[1, 0] := 'Value';
  StringGrid1.Options := StringGrid1.Options + [goEditing, goAlwaysShowEditor];
  StringGrid1.ColWidths[0] := 120;
  FSandbox := TRaylibSandbox.Create(Self);
  FSandbox.Parent := Self;
  FSandbox.Align := alClient;
  FSandbox.Active := True;
  FSandbox.OnViewportReady := HandleViewportReady;
  FSandbox.OnActorSpawned := HandleActorSpawned;
  FSandbox.OnSceneCleared := HandleSceneCleared;
  FSandbox.OnEngineException := HandleEngineException;
  FSandbox.OnObjectSelected := HandleObjectSelected;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    if Assigned(FSelectedComponent) then
    begin
      FSandbox.DeleteSelectedActor;
      Key := 0;
    end;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  tmrStatsUpdater.Enabled := True;
  Timer1.Enabled := True;
end;

procedure TForm1.btnToolDragThrowClick(Sender: TObject);
begin
  // Activate Drag & Throw Tool (Gizmo Mode gmDragAndThrow)
  FSandbox.SetGizmoMode(gmDragAndThrow);
  lblInfo.Caption := 'Tool: Drag & Throw Active.';
end;

procedure TForm1.btnSpawnButtonClick(Sender: TObject);
begin
  TVCL3D.SpawnButton(FSandbox, 'Button', Vector3Create(0, 5, 0), Vector3Create(4, 1, 0.5), My3DButtonClick);
end;

procedure TForm1.My3DButtonClick(Sender: TObject);
begin
  ShowMessage('Hello World vom 3D Button!');
end;

procedure TForm1.cbFPSChange(Sender: TObject);
begin
  // TargetFPS is just an indicator, real limit is removed in RaylibSandbox to allow 144+ FPS if VSync is off
  FSandbox.TargetFPS := StrToInt(cbFPS.Items[cbFPS.ItemIndex]);
end;

procedure TForm1.cbFrustumCullingClick(Sender: TObject);
begin
  FSandbox.FrustumCulling := cbFrustumCulling.Checked;
end;

procedure TForm1.cbStaticClick(Sender: TObject);
begin
  FSandbox.FSpawnStatic := cbStatic.Checked;
end;

procedure TForm1.chkDayNightRythmClick(Sender: TObject);
begin
  FSandbox.DayNightRhythmActive := chkDayNightRythm.Checked;
end;

procedure TForm1.chkDistanceCullingClick(Sender: TObject);
begin
  FSandbox.DistanceCulling := chkDistanceCulling.Checked;
end;

procedure TForm1.chkHighlightCollisionClick(Sender: TObject);
begin
  FSandbox.HighlightCollision := chkHighlightCollision.Checked;
end;

procedure TForm1.chkSlowMotionClick(Sender: TObject);
begin
  FSandbox.SetSlowMotion(chkSlowMotion.Checked);
end;


procedure TForm1.btnSceneSaveClick(Sender: TObject);
var
  Stream: TFileStream;
  Writer: TWriter;
  i: Integer;
  Actor: TA3DComponent;
begin
  if not Assigned(FSandbox) then Exit;

  if SaveDialog1.Execute then
  begin
    Stream := TFileStream.Create(SaveDialog1.FileName, fmCreate);
    try
      Writer := TWriter.Create(Stream, 4096);
      try
        Writer.WriteInteger(FSandbox.ItemCount);

        for i := 0 to FSandbox.ItemCount - 1 do
        begin
          Actor := FSandbox.FItems[i];
          if Assigned(Actor) then
          begin
            // Skip models for now to prevent FModel pointer corruption
            if Actor.ShapeType = stModel then
              Continue;

            Writer.WriteStr(Actor.Name);
            Writer.WriteInteger(Integer(Actor.ShapeType));

            Writer.WriteFloat(Actor.Position.x);
            Writer.WriteFloat(Actor.Position.y);
            Writer.WriteFloat(Actor.Position.z);

            Writer.WriteFloat(Actor.Quaternion.x);
            Writer.WriteFloat(Actor.Quaternion.y);
            Writer.WriteFloat(Actor.Quaternion.z);
            Writer.WriteFloat(Actor.Quaternion.w);

            Writer.WriteFloat(Actor.Scale.x);
            Writer.WriteFloat(Actor.Scale.y);
            Writer.WriteFloat(Actor.Scale.z);

            Writer.WriteFloat(Actor.Friction);
            Writer.WriteFloat(Actor.Restitution);

            Writer.WriteInteger(Actor.ActColor.r);
            Writer.WriteInteger(Actor.ActColor.g);
            Writer.WriteInteger(Actor.ActColor.b);
            Writer.WriteInteger(Actor.ActColor.a);
          end;
        end;
        Writer.FlushBuffer;
      finally
        Writer.Free;
      end;
    finally
      Stream.Free;
    end;
    lblInfo.Caption := 'Scene saved to: ' + SaveDialog1.FileName;
  end;
end;

procedure TForm1.btnSceneLoadClick(Sender: TObject);
var
  Stream: TFileStream;
  Reader: TReader;
  i, Count: Integer;
  Actor: TA3DComponent;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  ShapeType: TShapeType;
  Size: TVector3;
  Friction, Restitution: Single;
  LoadColor: TColorB;
begin
  if not Assigned(FSandbox) then Exit;

  if not OpenDialog1.Execute then
    Exit;

  // Soft reset
  FSandbox.ClearDynamicItemsOnly;
  tvSceneHierarchy.Items.Clear;

  try
    Stream := TFileStream.Create(OpenDialog1.FileName, fmOpenRead);
    try
      Reader := TReader.Create(Stream, 4096);
      try
        Count := Reader.ReadInteger;

        for i := 0 to Count - 1 do
        begin
          var AName: string := Reader.ReadStr;
          ShapeType := TShapeType(Reader.ReadInteger);

          JPos.x := Reader.ReadFloat;
          JPos.y := Reader.ReadFloat;
          JPos.z := Reader.ReadFloat;

          JRot.x := Reader.ReadFloat;
          JRot.y := Reader.ReadFloat;
          JRot.z := Reader.ReadFloat;
          JRot.w := Reader.ReadFloat;

          Size.x := Reader.ReadFloat;
          Size.y := Reader.ReadFloat;
          Size.z := Reader.ReadFloat;

          Friction := Reader.ReadFloat;
          Restitution := Reader.ReadFloat;

          LoadColor.r := Reader.ReadInteger;
          LoadColor.g := Reader.ReadInteger;
          LoadColor.b := Reader.ReadInteger;
          LoadColor.a := Reader.ReadInteger;

          // Create the Actor natively
          Actor := TA3DComponent.Create('', FSandbox.Engine, ShapeType, Size, False, @JPos, @JRot);
          Actor.Name := AName;
          Actor.Friction := Friction;
          Actor.Restitution := Restitution;
          Actor.ActColor := LoadColor;
          Actor.TargetColor := LoadColor;
          Actor.Visible := True;

          SetLength(FSandbox.FItems, Length(FSandbox.FItems) + 1);
          FSandbox.FItems[High(FSandbox.FItems)] := Actor;

          var NodeText: string;
          if Actor.Name <> '' then
            NodeText := Actor.Name
          else
            NodeText := 'Unnamed ' + GetEnumName(TypeInfo(TShapeType), Ord(Actor.ShapeType));
          tvSceneHierarchy.Items.AddChild(nil, NodeText).Data := Actor;

          // Give Jolt Physics a tiny breather so Broadphase can catch up
          // This prevents bodies from spawning at 0,0,0
          Sleep(20);
        end;
      finally
        Reader.Free;
      end;
    finally
      Stream.Free;
    end;
  finally

  end;

  lblInfo.Caption := 'Scene loaded from: ' + OpenDialog1.FileName;
end;
procedure TForm1.btnSelectNextClick(Sender: TObject);
begin
  FSandbox.SelectNextObject;
end;

procedure TForm1.btnSelectPrevClick(Sender: TObject);
begin
  FSandbox.SelectPrevObject;
end;

procedure TForm1.btnShootClick(Sender: TObject);
begin
  FSandbox.PublicShootBall;
end;

procedure TForm1.btnSpawnSandboxClick(Sender: TObject);
begin
  TVCL3D.SpawnSandbox(FSandbox);
end;


procedure TForm1.btnSpawnWallClick(Sender: TObject);
begin
  TVCL3D.SpawnDynamicWall(FSandbox, 10,10, false, true);
end;


procedure TForm1.btnSpawn3DModelClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FSandbox.LoadCustomModel(OpenDialog1.FileName);
   // lblInfo.Caption := 'Brush: 3D Model Selected.';
  end;
end;

procedure TForm1.btnSpawnBombClick(Sender: TObject);
begin
  FSandbox.SetBrush(stBomb);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Bomb Selected.';
end;

procedure TForm1.btnSpawnCapsulesClick(Sender: TObject);
begin
  FSandbox.SetBrush(stCapsule);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Capsule Selected.';
end;

procedure TForm1.btnSpawnCubesClick(Sender: TObject);
begin
  FSandbox.SetBrush(stBox);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Cube Selected.';
end;

procedure TForm1.btnSpawnSpheresClick(Sender: TObject);
begin
  FSandbox.SetBrush(stSphere);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Sphere Selected.';
end;

procedure TForm1.btnSpawnPyramidsClick(Sender: TObject);
begin
  FSandbox.SetBrush(stPyramid);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Pyramid Selected.';
end;

procedure TForm1.btnSpawnPrismsClick(Sender: TObject);
begin
  FSandbox.SetBrush(stPrism);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Prism Selected.';
end;

procedure TForm1.btnClearSceneClick(Sender: TObject);
begin
  FSandbox.SetBrush(TShapeType(-1));
  FSandbox.ClearItems;


  lblInfo.Caption := 'Scene Cleared.';
end;

procedure TForm1.btnPlayPauseClick(Sender: TObject);
begin
  if FSandbox.GetSimulationRunning then
  begin
    FSandbox.SetSimulationRunning(False);
    btnPlayPause.Caption := 'PLAY';
    lblInfo.Caption := 'Editor Mode (Paused). Place objects freely.';
  end
  else
  begin
    FSandbox.SetSimulationRunning(True);
    btnPlayPause.Caption := 'PAUSE';
    lblInfo.Caption := 'Simulation Running.';
  end;
end;
// === Object Inspector Logic ===

procedure TForm1.LoadPropertiesIntoGrid(AComponent: TA3DComponent);
var
  PropList: PPropList;
  Count, i: Integer;
  PropInfo: PPropInfo;
  StrVal: string;
  ColorVal: TColorB;
  IntColor: Cardinal;
  PropName: string;
begin
  FIsUpdatingGrid := True;
  try
    if not Assigned(AComponent) then
    begin
      StringGrid1.RowCount := 2;
      StringGrid1.Cells[0, 1] := '';
      StringGrid1.Cells[1, 1] := '';
      Exit;
    end;
    Count := GetPropList(AComponent.ClassInfo, tkAny, nil, true);
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      GetPropList(AComponent.ClassInfo, tkAny, PropList, true);
      StringGrid1.RowCount := Count + 1;
      StringGrid1.Cells[0, 0] := 'Property';
      StringGrid1.Cells[1, 0] := 'Value';
      for i := 0 to Count - 1 do
      begin
        PropInfo := PropList^[i];
        PropName := string(PropInfo^.Name);
        StringGrid1.Cells[0, i + 1] := PropName;
        if PropName = 'ActColor' then
        begin
          ColorVal := AComponent.ActColor;
          Move(ColorVal, IntColor, SizeOf(TColorB));
          StrVal := IntToHex(IntColor, 8);
        end
        else if PropName = 'TargetColor' then
        begin
          ColorVal := AComponent.TargetColor;
          Move(ColorVal, IntColor, SizeOf(TColorB));
          StrVal := IntToHex(IntColor, 8);
        end
        else if PropName = 'Position' then
          StrVal := Vector3ToStr(AComponent.Position)
        else if PropName = 'Scale' then
          StrVal := Vector3ToStr(AComponent.Scale)
        else if PropName = 'Rotation' then
          StrVal := Vector3ToStr(AComponent.Rotation)
        else if PropName = 'Quaternion' then
          StrVal := Vector3ToStr(Vector3Create(AComponent.Quaternion.x, AComponent.Quaternion.y, AComponent.Quaternion.z))
        else
        begin
          case PropInfo^.PropType^.Kind of
            tkFloat:
              StrVal := FloatToStrF(GetFloatProp(AComponent, PropInfo), ffGeneral, 4, 4);
            tkInteger:
              StrVal := IntToStr(GetOrdProp(AComponent, PropInfo));
            tkEnumeration:
              StrVal := GetEnumName(PropInfo^.PropType^, GetOrdProp(AComponent, PropInfo));
            tkString, tkLString, tkWString, tkUString:
              StrVal := GetStrProp(AComponent, PropInfo);
          else
            StrVal := '(Unsupported)';
          end;
        end;
        StringGrid1.Cells[1, i + 1] := StrVal;
      end;
    finally
      FreeMem(PropList);
    end;
  finally
    FIsUpdatingGrid := False;
  end;
end;

procedure TForm1.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := (ACol = 1) and (ARow > 0) and Assigned(FSelectedComponent);
end;

procedure TForm1.StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
var
  PropName: string;
  PropInfo: PPropInfo;
  FloatVal: Extended;
  IntVal: Integer;
  HexVal: Cardinal;
  ColorVal: TColorB;
  VecVal: TVector3;
  Rx, Ry, Rz: Single;
  CY, SY, CP, SP, CR, SR: Single;
  CYCP, SYCP, CYSP, SYSP: Single;
begin
  if FIsUpdatingGrid or (ARow = 0) or not Assigned(FSelectedComponent) then
    Exit;
  PropName := StringGrid1.Cells[0, ARow];
  if PropName = 'Name' then
  begin
    FSelectedComponent.Name := Value;
    RefreshHierarchy;
  end;

  PropInfo := GetPropInfo(FSelectedComponent, PropName);
  if not Assigned(PropInfo) then
    Exit;
  try
    if PropName = 'ActColor' then
    begin
      HexVal := StrToIntDef(Value, 0);
      Move(HexVal, ColorVal, SizeOf(TColorB));
      FSelectedComponent.ActColor := ColorVal;
    end
    else if PropName = 'TargetColor' then
    begin
      HexVal := StrToIntDef(Value, 0);
      Move(HexVal, ColorVal, SizeOf(TColorB));
      FSelectedComponent.TargetColor := ColorVal;
    end
    else if PropName = 'Position' then
    begin
      VecVal := StrToVector3(Value, FSelectedComponent.Position);
      FSelectedComponent.Position := VecVal;
    end
    else if PropName = 'Scale' then
    begin
      VecVal := StrToVector3(Value, FSelectedComponent.Scale);
      FSelectedComponent.Scale := VecVal;
    end
    else if PropName = 'Rotation' then
    begin
      VecVal := StrToVector3(Value, FSelectedComponent.Rotation);
      Rx := DegToRad(VecVal.x);
      Ry := DegToRad(VecVal.y);
      Rz := DegToRad(VecVal.z);
      CY := Cos(Ry * 0.5);
      SY := Sin(Ry * 0.5);
      CP := Cos(Rx * 0.5);
      SP := Sin(Rx * 0.5);
      CR := Cos(Rz * 0.5);
      SR := Sin(Rz * 0.5);
      CYCP := CY * CP;
      SYSP := SY * SP;
      CYSP := CY * CP;
      SYCP := SY * CP;
      FSelectedComponent.Quaternion := Vector4Create(CYCP * SR - SYSP * CR, CYSP * CR + SYCP * SR, SYCP * CR - CYSP * SR, CYCP * CR + SYSP * SR);
    end
    else if PropName = 'Quaternion' then
    begin
      VecVal := StrToVector3(Value, Vector3Create(FSelectedComponent.Quaternion.x, FSelectedComponent.Quaternion.y, FSelectedComponent.Quaternion.z));
      FSelectedComponent.Quaternion := Vector4Create(VecVal.x, VecVal.y, VecVal.z, FSelectedComponent.Quaternion.w);
    end
    else
    begin
      case PropInfo^.PropType^.Kind of
        tkFloat:
          if TryStrToFloat(Value, FloatVal) then
            SetFloatProp(FSelectedComponent, PropInfo, FloatVal);
        tkInteger:
          if TryStrToInt(Value, IntVal) then
            SetOrdProp(FSelectedComponent, PropInfo, IntVal);
        tkEnumeration:
          if TryStrToInt(Value, IntVal) then
            SetOrdProp(FSelectedComponent, PropInfo, IntVal);
        tkString, tkLString, tkWString, tkUString:
          SetStrProp(FSelectedComponent, PropInfo, Value);
      end;
    end;
  except
    on E: Exception do
      lblInfo.Caption := 'ERR SetProp: ' + E.Message;
  end;
end;

procedure TForm1.TimePicker1Change(Sender: TObject);
begin
  FSandbox.DayNightTime := TImepicker1.Time;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  Stream: TFileStream;
  Reader: TReader;
  i, Count: Integer;
  Actor: TA3DComponent;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  ShapeType: TShapeType;
  Size: TVector3;
  Friction, Restitution: Single;
  LoadColor: TColorB;
begin

  if not Assigned(FSandbox) then Exit;
  Timer1.Enabled := False;
  // Clear the current scene dynamically (keeps floor, skybox and lights alive)
  FSandbox.ClearDynamicItemsOnly;
  tvSceneHierarchy.Items.Clear;
  Stream := TFileStream.Create(ExtractFilepath(Application.ExeName)+'scenes\test.d3dfm', fmOpenRead);
  try
    Reader := TReader.Create(Stream, 4096);
    try
      Count := Reader.ReadInteger;
      for i := 0 to Count - 1 do
      begin
        // 1. Read manually serialized properties from the stream
        var AName: string := Reader.ReadStr;
        ShapeType := TShapeType(Reader.ReadInteger);
        JPos.x := Reader.ReadFloat;
        JPos.y := Reader.ReadFloat;
        JPos.z := Reader.ReadFloat;
        JRot.x := Reader.ReadFloat;
        JRot.y := Reader.ReadFloat;
        JRot.z := Reader.ReadFloat;
        JRot.w := Reader.ReadFloat;
        Size.x := Reader.ReadFloat;
        Size.y := Reader.ReadFloat;
        Size.z := Reader.ReadFloat;
        Friction := Reader.ReadFloat;
        Restitution := Reader.ReadFloat;
        LoadColor.r := Reader.ReadInteger;
        LoadColor.g := Reader.ReadInteger;
        LoadColor.b := Reader.ReadInteger;
        LoadColor.a := Reader.ReadInteger;
        // 2. Use safe engine constructor!
        // This creates the Jolt Body properly without VCL RTTI crashes.
        Actor := TA3DComponent.Create('', FSandbox.Engine, ShapeType, Size, False, @JPos, @JRot);
        // 3. Overwrite the properties that were just created with the loaded ones
        Actor.Name := AName;
        Actor.Friction := Friction;
        Actor.Restitution := Restitution;
        Actor.ActColor := LoadColor;
        Actor.TargetColor := LoadColor;
        // 4. Make it visible and add to Sandbox list and VCL TreeView
        Actor.Visible := True;
        SetLength(FSandbox.FItems, Length(FSandbox.FItems) + 1);
        FSandbox.FItems[High(FSandbox.FItems)] := Actor;
        var NodeText: string;
        if Actor.Name <> '' then
          NodeText := Actor.Name
        else
          NodeText := 'Unnamed ' + GetEnumName(TypeInfo(TShapeType), Ord(Actor.ShapeType));
        tvSceneHierarchy.Items.AddChild(nil, NodeText).Data := Actor;
      end;
    finally
      Reader.Free;
    end;
  finally
    Stream.Free;
  end;
  lblInfo.Caption := 'Scene loaded from: scenes\test.d3dfm';
end;

procedure TForm1.HandleObjectSelected(Sender: TObject; Actor: TA3DComponent);
begin
  TThread.Queue(nil,
    procedure
    begin
      SelectActorInUI(Actor);
      if Assigned(Actor) then
        FSandbox.SetSelectedActor(Actor);
    end);
end;

procedure TForm1.SelectActorInUI(AActor: TA3DComponent);
var
  Idx: Integer;
begin
  FSelectedComponent := AActor;
  LoadPropertiesIntoGrid(AActor);
  if Assigned(AActor) then
  begin
    Idx := -1;
    for Idx := 0 to FSandbox.ItemCount - 1 do
      if FSandbox.FItems[Idx] = AActor then
        Break;
    if (Idx >= 0) and (Idx < tvSceneHierarchy.Items.Count) then
    begin
      tvSceneHierarchy.OnChange := nil;
      try
        tvSceneHierarchy.Select(tvSceneHierarchy.Items[Idx]);
      finally
        tvSceneHierarchy.OnChange := tvSceneHierarchyChange;
      end;
    end;
  end
  else
  begin
    if tvSceneHierarchy.Selected <> nil then
    begin
      tvSceneHierarchy.OnChange := nil;
      try
        tvSceneHierarchy.Selected := nil;
      finally
        tvSceneHierarchy.OnChange := tvSceneHierarchyChange;
      end;
    end;
  end;
end;

procedure TForm1.SpDistanceChange(Sender: TObject);
begin
  FSandbox.MaxRenderDistance := SpDistance.Value;
end;

procedure TForm1.HandleViewportReady(Sender: TObject);
begin
  lblInfo.Caption := 'Engine Viewport Ready.';
  btnPlayPause.Caption := 'PAUSE';
end;

procedure TForm1.HandleActorSpawned(Sender: TObject; const Args: TActorEventArgs);
var
  NodeText: string;
  Node: TTreeNode;
begin
  if Args.Actor <> nil then
  begin
    // Determine the display name for the TreeView node
    if Args.Actor.Name <> '' then
      NodeText := Args.Actor.Name
    else
      NodeText := 'Unnamed ' + GetEnumName(TypeInfo(TShapeType), Ord(Args.Actor.ShapeType));
    // Add the node to the TreeView
    Node := tvSceneHierarchy.Items.AddChild(nil, NodeText);
    // CRITICAL: Store the actual Actor object pointer in the Node's Data property.
    // This ensures that clicking the node immediately gives us the Actor.
    Node.Data := Args.Actor;
  end;
end;

procedure TForm1.HandleSceneCleared(Sender: TObject);
begin
  tvSceneHierarchy.Items.Clear;
  lblInfo.Caption := 'Scene Cleared.';
  LoadPropertiesIntoGrid(nil);
end;

procedure TForm1.HandleEngineException(Sender: TObject; const Args: TEngineExceptionEventArgs);
begin
  lblInfo.Caption := Format('ERR [%s]: %s', [Args.Context, Args.Message]);
end;

procedure TForm1.tmrStatsUpdaterTimer(Sender: TObject);
var
  TotalObjects: Integer;
  SimStatus: string;
  SelectedInfo: string;
  i: Integer;
begin
  if not Assigned(FSandbox) then
    Exit;

  TotalObjects := FSandbox.ItemCount;

  if FSandbox.GetSimulationRunning then
    SimStatus := 'Running'
  else
    SimStatus := 'Paused';

  SelectedInfo := 'None';
  if Assigned(FSelectedComponent) then
    SelectedInfo := Format('%s (ID: %d)', [GetEnumName(TypeInfo(TShapeType), Ord(FSelectedComponent.ShapeType)), FSelectedComponent.BodyID]);

  Memo1.Lines.BeginUpdate;
  try
    Memo1.Lines.Clear;
    Memo1.Lines.Add('=== ENGINE STATS ===');
    Memo1.Lines.Add(Format('State:      %s', [SimStatus]));
    Memo1.Lines.Add(Format('FPS:         %d', [GetFPS()])); // Raylib GetFPS()
    Memo1.Lines.Add('-------------------');
    Memo1.Lines.Add(Format('Objects:     %d', [TotalObjects]));
    Memo1.Lines.Add(Format('In movement:    %d', [FSandbox.ActiveBodies]));
    Memo1.Lines.Add('-------------------');
    Memo1.Lines.Add(Format('Physic-Time: %.2f ms', [FSandbox.LastPhysicsTime]));
    Memo1.Lines.Add('-------------------');
    Memo1.Lines.Add(Format('Selected:     %s', [SelectedInfo]));
    Memo1.Lines.Add('-------------------');
    // Count models specifically
    var ModelCount: Integer := 0;
    for i := 0 to FSandbox.ItemCount - 1 do
      if Assigned(FSandbox.FItems[i]) and (FSandbox.FItems[i].ShapeType = stModel) then
        Inc(ModelCount);
    Memo1.Lines.Add(Format('3D Models:   %d', [ModelCount]));
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

procedure TForm1.tvSceneHierarchyChange(Sender: TObject; Node: TTreeNode);
var
  Actor: TA3DComponent;
  i: Integer;
begin
  // If nothing is selected, or the Node has no Data (Actor), clear selection
  if (Node = nil) or (Node.Data = nil) then
  begin
    FSelectedComponent := nil;
    FSandbox.SetSelectedActor(nil);
    LoadPropertiesIntoGrid(nil); // Clear the Object Inspector
    Exit;
  end;
  // Retrieve the actual Actor object from the selected Node's Data pointer
  Actor := TA3DComponent(Node.Data);
  if Assigned(Actor) then
  begin
    // Clear previous glow states on all items in the background
    for i := 0 to FSandbox.ItemCount - 1 do
      if Assigned(FSandbox.FItems[i]) then
        FSandbox.FItems[i].TealGlow := False;
    // Apply new selection state (make it glow teal in the 3D scene)
    Actor.TealGlow := True;
    FSelectedComponent := Actor;
    // Notify the Raylib Sandbox engine about the new selection
    FSandbox.SetSelectedActor(Actor);
    // Update the Object Inspector grid with the selected Actor's properties
    LoadPropertiesIntoGrid(Actor);
    // Update the status label at the bottom
    lblInfo.Caption := Format('Selected: %s | Pos: %.1f, %.1f, %.1f',
      [Actor.Name, Actor.Position.x, Actor.Position.y, Actor.Position.z]);
  end;
end;

procedure TForm1.RefreshHierarchy;
var
  i: Integer;
  Actor: TA3DComponent;
  NodeText: string;
  Node: TTreeNode;
begin
  tvSceneHierarchy.Items.BeginUpdate;
  try
    tvSceneHierarchy.Items.Clear;
    for i := 0 to FSandbox.ItemCount - 1 do
    begin
      Actor := FSandbox.FItems[i];
      if Assigned(Actor) then
      begin
        // Determine the display name for the TreeView node
        if Actor.Name <> '' then
          NodeText := Actor.Name
        else
          NodeText := 'Unnamed ' + GetEnumName(TypeInfo(TShapeType), Ord(Actor.ShapeType));
        // Add the node to the TreeView
        Node := tvSceneHierarchy.Items.AddChild(nil, NodeText);
        // CRITICAL: Store the actual Actor object pointer in the Node's Data property.
        // This allows us to instantly access the Actor when the user clicks the node.
        Node.Data := Actor;
      end;
    end;
  finally
    tvSceneHierarchy.Items.EndUpdate;
  end;
end;

procedure TForm1.seDayNightspeedChange(Sender: TObject);
var
  UserVal: Integer;
  ActualSpeed: Single;
begin
  UserVal := seDayNightspeed.Value;

  // Scale 1-100 to 0.001-0.1
  ActualSpeed := UserVal / 1000.0;
  FSandbox.DayNightSpeed := ActualSpeed;
end;

initialization
  // CRITICAL: Register the class so TReader.ReadComponent can instantiate it!
  // TReader is paranoid and refuses to create classes it doesn't know.
  RegisterClass(TA3DComponent);
finalization
  // Optional, aber sauber:
  UnRegisterClass(TA3DComponent);

end.


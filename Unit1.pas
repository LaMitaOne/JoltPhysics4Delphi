unit Unit1;

{==============================================================================*
 *  Mainform of raylib sandobox & jolt phsics
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
  JoltPhysics, Vcl.Grids, Raylib, Vcl.Menus;

type
  TbtnSpawnCapsules = class(TForm)
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
    chkHightlightCollision: TCheckBox;
    Memo1: TMemo;
    tmrStatsUpdater: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
    procedure tvSceneHierarchyClick(Sender: TObject);
    procedure btnSpawn3DModelClick(Sender: TObject);
    procedure chkDistanceCullingClick(Sender: TObject);
    procedure cbFrustumCullingClick(Sender: TObject);
    procedure btnSpawnPrismsClick(Sender: TObject);
    procedure chkHightlightCollisionClick(Sender: TObject);
    procedure tmrStatsUpdaterTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FSandbox: TRaylibSandbox;
    FSelectedComponent: TA3DComponent;
    FIsUpdatingGrid: Boolean;
    procedure RefreshHierarchy;
    procedure ProcessEditorSelection;
    procedure HandleViewportReady(Sender: TObject);
    procedure HandleActorSpawned(Sender: TObject; const Args: TActorEventArgs);
    procedure HandleSceneCleared(Sender: TObject);
    procedure HandleEngineException(Sender: TObject; const Args: TEngineExceptionEventArgs);
    procedure LoadPropertiesIntoGrid(AComponent: TA3DComponent);
    procedure SelectActorInUI(AActor: TA3DComponent);
    procedure HandleObjectSelected(Sender: TObject; Actor: TA3DComponent);
    procedure HandleViewportRightClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  btnSpawnCapsules: TbtnSpawnCapsules;

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

procedure TbtnSpawnCapsules.FormCreate(Sender: TObject);
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
  FSandbox.OnViewportRightClick := HandleViewportRightClick;
end;

procedure TbtnSpawnCapsules.FormDestroy(Sender: TObject);
begin
  // Sandbox is owned by Self and destroyed automatically
end;

procedure TbtnSpawnCapsules.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TbtnSpawnCapsules.FormShow(Sender: TObject);
begin
  tmrStatsUpdater.Enabled := True;
end;

procedure TbtnSpawnCapsules.HandleViewportRightClick(Sender: TObject);
begin
  // Empty. Context menu is fully handled internally.
end;

procedure TbtnSpawnCapsules.btnToolDragThrowClick(Sender: TObject);
begin
  // Activate Drag & Throw Tool (Gizmo Mode None)
  FSandbox.SetGizmoMode(gmNone);
  lblInfo.Caption := 'Tool: Drag & Throw Active.';
end;

procedure TbtnSpawnCapsules.cbFPSChange(Sender: TObject);
begin
  // TargetFPS is just an indicator, real limit is removed in RaylibSandbox to allow 144+ FPS if VSync is off
  FSandbox.TargetFPS := StrToInt(cbFPS.Items[cbFPS.ItemIndex]);
end;

procedure TbtnSpawnCapsules.cbFrustumCullingClick(Sender: TObject);
begin
  FSandbox.FrustumCulling := cbFrustumCulling.Checked;
end;

procedure TbtnSpawnCapsules.chkDistanceCullingClick(Sender: TObject);
begin
  FSandbox.DistanceCulling := chkDistanceCulling.Checked;
end;

procedure TbtnSpawnCapsules.chkHightlightCollisionClick(Sender: TObject);
begin
  FSandbox.HighlightCollision := chkHightlightCollision.Checked;
end;

procedure TbtnSpawnCapsules.btnSceneLoadClick(Sender: TObject);
begin
 //
end;

procedure TbtnSpawnCapsules.btnSceneSaveClick(Sender: TObject);
begin
  //
end;

procedure TbtnSpawnCapsules.btnSpawn3DModelClick(Sender: TObject);
begin
  //
end;

procedure TbtnSpawnCapsules.btnSpawnCapsulesClick(Sender: TObject);
begin
  FSandbox.SetBrush(stCapsule);
  lblInfo.Caption := 'Brush: Capsule Selected.';
end;

procedure TbtnSpawnCapsules.btnSpawnCubesClick(Sender: TObject);
begin
  FSandbox.SetBrush(stBox);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Cube Selected.';
end;

procedure TbtnSpawnCapsules.btnSpawnSpheresClick(Sender: TObject);
begin
  FSandbox.SetBrush(stSphere);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Sphere Selected.';
end;

procedure TbtnSpawnCapsules.btnSpawnPyramidsClick(Sender: TObject);
begin
  FSandbox.SetBrush(stPyramid);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Pyramid Selected.';
end;

procedure TbtnSpawnCapsules.btnSpawnPrismsClick(Sender: TObject);
begin
  FSandbox.SetBrush(stPrism);
  FSandbox.SetGizmoMode(gmTranslate);
  lblInfo.Caption := 'Brush: Prism Selected.';
end;

procedure TbtnSpawnCapsules.btnClearSceneClick(Sender: TObject);
begin
  FSandbox.ClearItems;
  FSandbox.SetBrush(TShapeType(-1));
  lblInfo.Caption := 'Scene Cleared.';
end;

procedure TbtnSpawnCapsules.btnPlayPauseClick(Sender: TObject);
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

procedure TbtnSpawnCapsules.LoadPropertiesIntoGrid(AComponent: TA3DComponent);
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
    Count := GetPropList(AComponent.ClassInfo, tkAny, nil);
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      GetPropList(AComponent.ClassInfo, tkAny, PropList);
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

procedure TbtnSpawnCapsules.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := (ACol = 1) and (ARow > 0) and Assigned(FSelectedComponent);
end;

procedure TbtnSpawnCapsules.StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
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

procedure TbtnSpawnCapsules.HandleObjectSelected(Sender: TObject; Actor: TA3DComponent);
begin
  TThread.Queue(nil,
    procedure
    begin
      SelectActorInUI(Actor);
      if Assigned(Actor) then
        FSandbox.SetSelectedActor(Actor);
    end);
end;

procedure TbtnSpawnCapsules.SelectActorInUI(AActor: TA3DComponent);
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

procedure TbtnSpawnCapsules.HandleViewportReady(Sender: TObject);
begin
  lblInfo.Caption := 'Engine Viewport Ready.';
  btnPlayPause.Caption := 'PAUSE';
end;

procedure TbtnSpawnCapsules.HandleActorSpawned(Sender: TObject; const Args: TActorEventArgs);
var
  Data: PItemData;
  NodeText: string;
begin
  if Args.Actor <> nil then
  begin
    Data := Args.Actor.UserData;
    if Assigned(Data) then
      NodeText := Format('%s (%s)', [Data^.Name, GetEnumName(TypeInfo(TShapeType), Ord(Args.Actor.ShapeType))])
    else
      NodeText := 'Unknown Actor';
    tvSceneHierarchy.Items.AddChild(nil, NodeText);
  end;
end;

procedure TbtnSpawnCapsules.HandleSceneCleared(Sender: TObject);
begin
  tvSceneHierarchy.Items.Clear;
  lblInfo.Caption := 'Scene Cleared.';
  LoadPropertiesIntoGrid(nil);
end;

procedure TbtnSpawnCapsules.HandleEngineException(Sender: TObject; const Args: TEngineExceptionEventArgs);
begin
  lblInfo.Caption := Format('ERR [%s]: %s', [Args.Context, Args.Message]);
end;

procedure TbtnSpawnCapsules.tmrStatsUpdaterTimer(Sender: TObject);
var
  TotalObjects, Projectiles: Integer;
  SimStatus: string;
  SelectedInfo: string;
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
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

procedure TbtnSpawnCapsules.tvSceneHierarchyChange(Sender: TObject; Node: TTreeNode);
begin
  ProcessEditorSelection;
end;

procedure TbtnSpawnCapsules.tvSceneHierarchyClick(Sender: TObject);
begin
  //slected in tree
end;

procedure TbtnSpawnCapsules.RefreshHierarchy;
var
  i: Integer;
  Actor: TA3DComponent;
  NodeText: string;
begin
  tvSceneHierarchy.Items.BeginUpdate;
  try
    tvSceneHierarchy.Items.Clear;
    for i := 0 to FSandbox.ItemCount - 1 do
    begin
      Actor := FSandbox.FItems[i];
      if Assigned(Actor) then
      begin
        NodeText := Format('%d: %s', [i, GetEnumName(TypeInfo(TShapeType), Ord(Actor.ShapeType))]);
        tvSceneHierarchy.Items.AddChild(nil, NodeText);
      end;
    end;
  finally
    tvSceneHierarchy.Items.EndUpdate;
  end;
end;

procedure TbtnSpawnCapsules.ProcessEditorSelection;
var
  SelectedIndex: Integer;
  Actor: TA3DComponent;
  i: Integer;
begin
  if tvSceneHierarchy.Selected = nil then
    Exit;
  SelectedIndex := tvSceneHierarchy.Selected.Index;
  for i := 0 to FSandbox.ItemCount - 1 do
    if Assigned(FSandbox.FItems[i]) then
      FSandbox.FItems[i].TealGlow := False;
  if (SelectedIndex >= 0) and (SelectedIndex < FSandbox.ItemCount) then
  begin
    Actor := FSandbox.FItems[SelectedIndex];
    if Assigned(Actor) then
    begin
      Actor.TealGlow := True;
      FSandbox.SetSelectedActor(Actor);
      SelectActorInUI(Actor);
      lblInfo.Caption := Format('Selected: %s | Pos: %.1f, %.1f, %.1f', [GetEnumName(TypeInfo(TShapeType), Ord(Actor.ShapeType)), Actor.Position.x, Actor.Position.y, Actor.Position.z]);
    end;
  end
  else
  begin
    FSandbox.SetSelectedActor(nil);
    SelectActorInUI(nil);
  end;
end;

end.


unit RaylibSandbox;

{==============================================================================*
 *  RaylibSandbox v0.2 - VCL Wrapper for a multi-threaded Raylib + Jolt Physics
 *------------------------------------------------------------------------------
 *  Description:
 *    This component embeds a Raylib rendering window inside a standard Delphi
 *    VCL application. It runs the Raylib main loop and physics simulation
 *    (via JoltPhysics) in a separate background thread to prevent blocking
 *    the VCL UI thread.
 *
 *  Architecture:
 *    - TRaylibSandbox inherits from TWinControl to provide a HWND parent
 *      for the Raylib window.
 *    - A TThread is used to run InitWindow, the main Update/Render loop, and
 *      shutdown procedures.
 *    - The component intercepts desktop mouse inputs globally to allow
 *      dragging objects in the 3D space and manipulating the camera.
 *
 *  Features:
 *    - Spawning dynamic objects (Cubes, Spheres, Cylinders) that interact
 *      with a static floor and walls using Jolt Physics.
 *    - Raycasting from the 2D screen coordinates to drag dynamic bodies
 *      across the floor.
 *    - Orbit camera (Right Mouse Button) and Zoom (Mouse Wheel).
 *    - Custom UI drawn directly in Raylib to trigger spawns and clear scenes.
 *    - Glow and Spawn animation effects driven by custom UserData.
 *==============================================================================}

{$POINTERMATH ON}
{$Q-}
{$R-}
interface

uses
  Winapi.Windows, Winapi.MultiMon, Winapi.MMSystem, System.SysUtils,
  System.Classes, System.Math, System.SyncObjs, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, Raylib, RayMath, rlgl, ModelEngine, JoltPhysics;

type
  PItemData = ^TItemData;

  TItemData = record
    SpawnTime: Double;
    LastHitTime: Double;
  end;

  TRaylibSandbox = class(TWinControl)
  private
    FThread: TThread;
    FLock: TCriticalSection;
    FTargetFPS: Integer;
    FThreadActive: Boolean;
    FPaused: Boolean;
    FActive: Boolean;
    FRaylibWnd: HWND;
    FInitialized: Boolean;
    FTxtBuf: AnsiString;
    FEngine: TModelEngine;
    FFloorActor: TModelActor;
    FWalls: array[0..3] of TModelActor;
    FItems: TArray<TModelActor>;
    FWallpaperModel: TModel;
    FWallpaperTex: TTexture2D;
    FItemSelected: TModelActor;
    FDragging: Boolean;
    FDragTargetPos: TVector3;
    FMousePos: TVector2;
    FCamera: TCamera3D;
    FCamYaw, FCamPitch, FCamDist: single;
    FLastMouse: TPoint;
    FDraggingRMB: boolean;
    FHUDAnimY: single;
    FSceneStartTime: Double;
    FSpawnQueue: Integer;
    FSpawnTimer: Single;
    FSpawnShape: TShapeType;
    FClearItemsQueued: Boolean;
    procedure InitScene;
    procedure ClearItems;
    procedure SpawnObjects(Count: Integer; ShapeType: TShapeType);
    procedure ProcessSpawnQueue(dt: Single);
    procedure HandleCameraInput;
    procedure HandleDesktopInput;
    procedure UpdateGame;
    procedure RenderGame;
    procedure Render3DScene;
    procedure DrawGUI;
    function CheckButton(x, y, w, h: Integer): Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetTargetFPS(const Value: Integer);
    procedure StartThread;
    procedure StopThread;
  protected
    procedure Resize; override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property Visible;
    property Active: Boolean read FActive write SetActive default False;
    property TargetFPS: Integer read FTargetFPS write SetTargetFPS default 60;
  end;

implementation

function GetTealGlowColor(intensity: Single): TColorB;
begin
  if intensity < 0 then
    intensity := 0;
  if intensity > 1 then
    intensity := 1;
  Result.r := Round(64 * intensity);
  Result.g := Round(224 * intensity);
  Result.b := Round(208 * intensity);
  Result.a := 255;
end;

constructor TRaylibSandbox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLock := TCriticalSection.Create;
  FThreadActive := False;
  FPaused := True;
  FActive := False;
  FTargetFPS := 60;
  Width := 800;
  Height := 600;
  FInitialized := False;
  FWallpaperTex.id := 0;
  FHUDAnimY := -150.0;
  FSceneStartTime := 0.0;
  FSpawnQueue := 0;
  FSpawnTimer := 0.0;
  FSpawnShape := stBox;
  FClearItemsQueued := False;
end;

destructor TRaylibSandbox.Destroy;
begin
  StopThread;
  FreeAndNil(FLock);
  inherited;
end;

procedure TRaylibSandbox.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
end;

procedure TRaylibSandbox.DestroyWindowHandle;
begin
  StopThread;
  inherited;
end;

procedure TRaylibSandbox.Resize;
begin
  inherited;
  if FInitialized and (FRaylibWnd <> 0) then
    SetWindowPos(FRaylibWnd, 0, 0, 0, ClientWidth, ClientHeight, SWP_NOZORDER);
end;

procedure TRaylibSandbox.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if FActive then
    begin
      if not FThreadActive then
        StartThread;
      FPaused := False;
    end
    else
      FPaused := True;
  end;
end;

procedure TRaylibSandbox.SetTargetFPS(const Value: Integer);
begin
  if FTargetFPS <> Value then
    FTargetFPS := Value;
end;

procedure TRaylibSandbox.StartThread;
var
  FilePath: string;
  floorMesh: TMesh;
begin
  if FThreadActive then
    Exit;
  FThreadActive := True;
  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      Freq: Int64;
      FrameStart, FrameEnd, FrameTicks: Int64;
      RestMs: Double;
    begin
      try
        SetConfigFlags(FLAG_WINDOW_RESIZABLE or FLAG_MSAA_4X_HINT);
        InitWindow(1280, 720, 'Raylib Sandbox');
        FRaylibWnd := FindWindow(nil, 'Raylib Sandbox');
        if FRaylibWnd <> 0 then
        begin
          Winapi.Windows.SetParent(FRaylibWnd, Self.Handle);
          SetWindowLong(FRaylibWnd, GWL_STYLE, WS_CHILD or WS_VISIBLE);
          SetWindowPos(FRaylibWnd, 0, 0, 0, Self.ClientWidth, Self.ClientHeight, SWP_NOZORDER);
        end;
        FEngine := TModelEngine.Create;

        FCamYaw := -0.5;
        FCamPitch := 0.8;
        FCamDist := 60.0;
        FCamera.target := Vector3Create(0, 0, 0);
        FCamera.position := Vector3Create(20, 20, 20);
        FCamera.up := Vector3Create(0, 1, 0);
        FCamera.fovy := 45.0;
        FCamera.projection := CAMERA_PERSPECTIVE;
        FDraggingRMB := False;
        FDragging := False;
        FItemSelected := nil;
        FHUDAnimY := -150.0;
        InitScene;
        JPH_PhysicsSystem_OptimizeBroadPhase(FEngine.PhysicsSystem);
        FilePath := ExtractFilePath(ParamStr(0)) + 'wallpaper.jpg';
        if FileExists(PAnsiChar(AnsiString(FilePath))) then
        begin
          FWallpaperTex := LoadTexture(PAnsiChar(AnsiString(FilePath)));
          if FWallpaperTex.id > 0 then
          begin
            SetTextureFilter(FWallpaperTex, TEXTURE_FILTER_TRILINEAR);
            floorMesh := GenMeshPlane(100, 100, 1, 1);
            FWallpaperModel := LoadModelFromMesh(floorMesh);
            FWallpaperModel.transform := MatrixTranslate(0, 0.01, 0);
            FWallpaperModel.materials[0].maps[0].texture := FWallpaperTex;
            FWallpaperModel.materials[0].maps[0].color := WHITE;
          end;
        end;
        FInitialized := True;
        FSceneStartTime := GetTime();

        QueryPerformanceFrequency(Freq);
        timeBeginPeriod(1);
        while not TThread.CheckTerminated do
        begin
          QueryPerformanceCounter(FrameStart);
          if WindowShouldClose() then
            Break;
          if not FPaused then
            UpdateGame;
          RenderGame;
          if FTargetFPS > 0 then
          begin
            FrameTicks := Freq div FTargetFPS;
            QueryPerformanceCounter(FrameEnd);
            RestMs := (FrameTicks - (FrameEnd - FrameStart)) * 1000 / Freq;
            if RestMs > 0 then
            begin
              if RestMs > 2 then
                Sleep(Trunc(RestMs) - 2);
              repeat
                QueryPerformanceCounter(FrameEnd);
              until (FrameEnd - FrameStart) >= FrameTicks;
            end;
          end
          else
            Sleep(1);
        end;
        // --- CLEANUP ---
        timeEndPeriod(1);
        FInitialized := False;
        ClearItems;
        FreeAndNil(FFloorActor);
        FreeAndNil(FWalls[0]);
        FreeAndNil(FWalls[1]);
        FreeAndNil(FWalls[2]);
        FreeAndNil(FWalls[3]);
        FreeAndNil(FEngine);
        if FWallpaperTex.id > 0 then
        begin
          UnloadTexture(FWallpaperTex);
          UnloadModel(FWallpaperModel);
        end;
        CloseWindow();
      except
        on E: Exception do
          OutputDebugString(PChar('Raylib Thread Exception: ' + E.Message));
      end;
      FThreadActive := False;
    end);
  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

procedure TRaylibSandbox.StopThread;
begin
  if not FThreadActive then
    Exit;
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    Sleep(100);
  end;
end;

procedure TRaylibSandbox.InitScene;
begin
  FFloorActor := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 1, 100), True);
  FFloorActor.SetPosition(Vector3Create(0, -0.5, 0));
  FFloorActor.Visible := False;
  FFloorActor.Friction := 0.5;

  FWalls[0] := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[0].SetPosition(Vector3Create(0, 10, -50));
  FWalls[0].Visible := False;
  FWalls[1] := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[1].SetPosition(Vector3Create(0, 10, 50));
  FWalls[1].Visible := False;
  FWalls[2] := TModelActor.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[2].SetPosition(Vector3Create(-50, 10, 0));
  FWalls[2].Visible := False;
  FWalls[3] := TModelActor.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[3].SetPosition(Vector3Create(50, 10, 0));
  FWalls[3].Visible := False;

  FItems := nil;
end;

procedure TRaylibSandbox.ClearItems;
begin
  // Queue the clear command to be executed in the render thread
  FClearItemsQueued := True;
end;

procedure TRaylibSandbox.SpawnObjects(Count: Integer; ShapeType: TShapeType);
begin
  FSpawnQueue := FSpawnQueue + Count;
  FSpawnShape := ShapeType;
end;

procedure TRaylibSandbox.ProcessSpawnQueue(dt: Single);
var
  Obj: TModelActor;
  oldLen: Integer;
  Data: PItemData;
  Size: TVector3;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  RandQuat: TQuaternion;
  RX, RY, RZ: Single;
begin
  if FSpawnQueue <= 0 then
    Exit;
  FSpawnTimer := FSpawnTimer - dt;
  if FSpawnTimer > 0 then
    Exit;
  FSpawnQueue := FSpawnQueue - 1;
  FSpawnTimer := 0.04;
  oldLen := Length(FItems);
  SetLength(FItems, oldLen + 1);
  New(Data);
  Data^.SpawnTime := GetTime();
  Data^.LastHitTime := 0;

  Size := Vector3Create(1, 1, 1);
  if FSpawnShape = stSphere then
    Size := Vector3Create(0.5, 0.5, 0.5)
  else if FSpawnShape = stPyramid then
    Size := Vector3Create(0.8, 1.5, 0.8);

  JPos.x := -20.0 + (Random * 40.0);
  JPos.y := 25.0 + (Random * 10.0);
  JPos.z := -20.0 + (Random * 40.0);

  // Add more tilt on the X-axis
  RX := DegToRad(-45 + (Random * 90.0));
  // Full 360-degree randomness on Y
  RY := DegToRad(-180 + (Random * 360.0));
  RZ := DegToRad(-0.2 + (Random * 0.4));

  RandQuat := QuaternionFromEuler(RX, RY, RZ);
  JRot.x := RandQuat.x;
  JRot.y := RandQuat.y;
  JRot.z := RandQuat.z;
  JRot.w := RandQuat.w;

  Obj := TModelActor.Create('', FEngine, FSpawnShape, Size, False, @JPos, @JRot);

  Obj.Friction := 0.8;
  Obj.Restitution := 0.2;

  Obj.UserData := Data;
  Obj.Visible := True;
  FItems[oldLen] := Obj;
end;

procedure TRaylibSandbox.HandleCameraInput;
var
  p: TPoint;
begin
  GetCursorPos(p);
  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if FDraggingRMB then
    begin
      FCamYaw := FCamYaw - (p.x - FLastMouse.x) * 0.006;
      FCamPitch := EnsureRange(FCamPitch + (p.y - FLastMouse.y) * 0.006, 0.05, 1.5);
    end;
    FDraggingRMB := True;
  end
  else
    FDraggingRMB := False;
  FLastMouse := p;
  if GetMouseWheelMove() <> 0 then
    FCamDist := EnsureRange(FCamDist - GetMouseWheelMove() * 3.0, 10, 100);
  FCamera.position := Vector3Create(FCamera.target.x + Cos(FCamPitch) * Sin(FCamYaw) * FCamDist, FCamera.target.y + Sin(FCamPitch) * FCamDist, FCamera.target.z + Cos(FCamPitch) * Cos(FCamYaw) * FCamDist);
end;

function TRaylibSandbox.CheckButton(x, y, w, h: Integer): Boolean;
var
  p: TPoint;
  RealY: Integer;
begin
  Result := False;
  if FHUDAnimY > -1 then
  begin
    GetCursorPos(p);
    Winapi.Windows.ScreenToClient(FRaylibWnd, p);
    FMousePos := Vector2Create(p.x, p.y);
    RealY := y + Trunc(FHUDAnimY);
    if (FMousePos.x >= x) and (FMousePos.x <= x + w) and (FMousePos.y >= RealY) and (FMousePos.y <= RealY + h) then
    begin
      if (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0 then
        Result := True;
    end;
  end;
end;

procedure TRaylibSandbox.HandleDesktopInput;
var
  ray: TRay;
  itemBox: TBoundingBox;
  hitInfo: TRayCollision;
  t: single;
  i: Integer;
begin
  if CheckButton(10, 10, 40, 40) then
  begin
    SpawnObjects(30, stBox);
    Exit;
  end;
  if CheckButton(60, 10, 40, 40) then
  begin
    ClearItems;
    Exit;
  end;
  if CheckButton(110, 10, 40, 40) then
  begin
    SpawnObjects(30, stSphere);
    Exit;
  end;
  if CheckButton(160, 10, 40, 40) then
  begin
    SpawnObjects(30, stPyramid);
    Exit;
  end;
  ray := GetScreenToWorldRay(FMousePos, FCamera);
  if (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0 then
  begin
    if not FDragging then
    begin
      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;
        itemBox.min := Vector3Create(FItems[i].Position.x - 0.5, FItems[i].Position.y - 0.5, FItems[i].Position.z - 0.5);
        itemBox.max := Vector3Create(FItems[i].Position.x + 0.5, FItems[i].Position.y + 0.5, FItems[i].Position.z + 0.5);
        hitInfo := GetRayCollisionBox(ray, itemBox);
        if hitInfo.hit then
        begin
          FItemSelected := FItems[i];
          FItemSelected.ActivateBody;
          FDragging := True;
          Break;
        end;
      end;
    end;
    if FDragging and Assigned(FItemSelected) then
    begin
      if Abs(ray.direction.y) > 0.0001 then
      begin
        t := (FItemSelected.Position.y - ray.position.y) / ray.direction.y;
        if t > 0 then
        begin
          FDragTargetPos.x := ray.position.x + ray.direction.x * t;
          FDragTargetPos.z := ray.position.z + ray.direction.z * t;
        end;
      end;
    end;
  end
  else
  begin
    FDragging := False;
    FItemSelected := nil;
  end;
end;

procedure TRaylibSandbox.UpdateGame;
var
  dt: single;
  Dir: TVector3;
  Dist: single;
  NewVel: TVector3;
  ItemVel: TVector3;
  i: Integer;
  IsTeal: Boolean;
begin
  // Execute the clear command if it is queued
  if FClearItemsQueued then
  begin
    FDragging := False;
    FItemSelected := nil;
    FSpawnQueue := 0;

  // Free the actors themselves
    for i := High(FItems) downto 0 do
    begin
      if Assigned(FItems[i]) then
      begin
        FItems[i].Visible := False;
        FItems[i].Free;
        FItems[i] := nil;
      end;
    end;

    SetLength(FItems, 0);

    FClearItemsQueued := False;
  end;
  dt := GetFrameTime();
  HandleCameraInput;
  HandleDesktopInput;
  ProcessSpawnQueue(dt);
  FEngine.Update(dt);
  if (FSceneStartTime > 0) and (GetTime() - FSceneStartTime > 1.0) then
    FSceneStartTime := 0;
  if (FSceneStartTime = 0) and (FHUDAnimY < 0) then
  begin
    FHUDAnimY := FHUDAnimY * (1.0 - dt * 6.0);
    if FHUDAnimY > -0.5 then
    begin
      FHUDAnimY := 0;
      SpawnObjects(100, stBox);
    end;
  end;

  for i := 0 to High(FItems) do
  begin
    if Assigned(FItems[i]) and (FItems[i].UserData <> nil) then
    begin
      ItemVel := FItems[i].GetLinearVelocity;
      if (Abs(ItemVel.x) > 2.0) or (Abs(ItemVel.y) > 2.0) or (Abs(ItemVel.z) > 2.0) then
        PItemData(FItems[i].UserData)^.LastHitTime := GetTime();

      IsTeal := (GetTime() - PItemData(FItems[i].UserData)^.LastHitTime) < 0.3;
      FItems[i].TealGlow := IsTeal;
    end;
  end;

  if FDragging and Assigned(FItemSelected) then
  begin
    Dir.x := FDragTargetPos.x - FItemSelected.Position.x;
    Dir.y := 0;
    Dir.z := FDragTargetPos.z - FItemSelected.Position.z;
    Dist := Sqrt(Dir.x * Dir.x + Dir.z * Dir.z);
    if Dist > 0.05 then
    begin
      FItemSelected.ActivateBody;
      NewVel.x := Dir.x * 10.0;
      NewVel.y := FItemSelected.GetLinearVelocity.y;
      NewVel.z := Dir.z * 10.0;
      FItemSelected.SetLinearVelocity(NewVel);
      NewVel := FItemSelected.GetAngularVelocity;
      NewVel.x := NewVel.x * 0.9;
      NewVel.y := NewVel.y * 0.9;
      NewVel.z := NewVel.z * 0.9;
      FItemSelected.SetAngularVelocity(NewVel);
    end
    else
    begin
      NewVel := FItemSelected.GetLinearVelocity;
      NewVel.x := 0;
      NewVel.z := 0;
      FItemSelected.SetLinearVelocity(NewVel);
    end;
  end;
end;

procedure TRaylibSandbox.RenderGame;
begin
  BeginDrawing();
  ClearBackground(BLACK);
  Render3DScene;
  DrawGUI;
  EndDrawing();
  if FRaylibWnd <> 0 then
    RedrawWindow(FRaylibWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW);
end;

procedure TRaylibSandbox.Render3DScene;
var
  i: Integer;
  Actor: TModelActor;
  Dist, MaxDist: Single;
  CamForward, ToActor, ToActorNorm: TVector3;
  Axis: TVector3;
  Angle: Single;
  DotP: Single;
  Pos: TVector3;
begin
  BeginMode3D(FCamera);

  if FWallpaperTex.id > 0 then
    DrawModel(FWallpaperModel, Vector3Create(0, 0, 0), 1.0, WHITE)
  else
    DrawPlane(Vector3Create(0, 0.01, 0), Vector2Create(100, 100), DARKGRAY);

  for i := 0 to 3 do
  begin
    if i < 2 then
    begin
      DrawCube(FWalls[i].Position, 100, 20, 1, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].Position, 100, 20, 1, BLACK);
    end
    else
    begin
      DrawCube(FWalls[i].Position, 1, 20, 100, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].Position, 1, 20, 100, BLACK);
    end;
  end;

  MaxDist := 120.0;
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      // 1. DISTANCE CULLING
      Dist := Vector3Distance(Actor.Position, FCamera.position);
      if Dist > MaxDist then
        Continue;

      // 2. FRUSTUM CULLING
      ToActor := Vector3Subtract(Actor.Position, FCamera.position);
      ToActorNorm := Vector3Normalize(ToActor);
      DotP := Vector3DotProduct(ToActorNorm, CamForward);
      if DotP < 0.5 then
        Continue;

      // 3. DRAWING
      rlPushMatrix();

      // Position
      Pos := Actor.Position;
      rlTranslatef(Pos.x, Pos.y, Pos.z);

      // Rotation
      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

      // Draw
      if Actor.ShapeType = stSphere then
      begin
        if Actor.TealGlow then
          DrawSphere(Vector3Create(0, 0, 0), 0.5, GetTealGlowColor(1.0))
        else
          DrawSphere(Vector3Create(0, 0, 0), 0.5, RED);
      end
      else if Actor.ShapeType = stPyramid then
      begin
        // IMPORTANT: Slightly offset the pyramid to prevent perfect balancing!
        rlTranslatef(0.1, 0, 0.1);

        if Actor.TealGlow then
          DrawCylinderEx(Vector3Create(0, 0.75, 0),   // Center of the top tip
            Vector3Create(0, -0.75, 0),  // Center of the bottom base
            0.0,                          // Top radius (tip)
            0.5,                          // Bottom radius (base)
            4,                            // 4 edges for a pyramid
            GetTealGlowColor(1.0))
        else
          DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, RED);

        DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, BLACK);
      end
      else
      begin
        if Actor.TealGlow then
          DrawCube(Vector3Create(0, 0, 0), 1, 1, 1, GetTealGlowColor(1.0))
        else
          DrawCube(Vector3Create(0, 0, 0), 1, 1, 1, RED);
        DrawCubeWires(Vector3Create(0, 0, 0), 1, 1, 1, BLACK);
      end;

      rlPopMatrix();
    end;
  end;

  if Assigned(FItemSelected) and FItemSelected.Visible then
  begin
    rlPushMatrix();

    Pos := FItemSelected.Position;
    rlTranslatef(Pos.x, Pos.y, Pos.z);

    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if FItemSelected.Quaternion.w < 1.0 then
      QuaternionToAxisAngle(FItemSelected.Quaternion, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

    if FItemSelected.ShapeType = stSphere then
    begin
      if FItemSelected.TealGlow then
        DrawSphere(Vector3Create(0, 0, 0), 0.5, GetTealGlowColor(1.0))
      else
        DrawSphere(Vector3Create(0, 0, 0), 0.5, RED);
    end
    else if FItemSelected.ShapeType = stPyramid then
    begin
      // Apply the slight offset here as well
      rlTranslatef(0.1, 0, 0.1);

      if FItemSelected.TealGlow then
        DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, GetTealGlowColor(1.0))
      else
        DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, RED);

      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, YELLOW);
    end
    else
    begin
      if FItemSelected.TealGlow then
        DrawCube(Vector3Create(0, 0, 0), 1, 1, 1, GetTealGlowColor(1.0))
      else
        DrawCube(Vector3Create(0, 0, 0), 1, 1, 1, RED);
      DrawCubeWires(Vector3Create(0, 0, 0), 1.05, 1.05, 1.05, YELLOW);
    end;

    rlPopMatrix();
  end;

  EndMode3D();
end;

procedure TRaylibSandbox.DrawGUI;
var
  fpsBuf: AnsiString;
  YOffset: Integer;
begin
  YOffset := Trunc(FHUDAnimY);
  DrawRectangle(10, 10 + YOffset, 210, 50, Fade(BLACK, 0.8));
  DrawRectangleLines(10, 10 + YOffset, 210, 50, RAYWHITE);
  DrawRectangleLines(15, 15 + YOffset, 30, 30, RAYWHITE);
  DrawRectangle(20, 20 + YOffset, 20, 20, Fade(BLUE, 0.8));
  DrawRectangleLines(65, 15 + YOffset, 30, 30, RAYWHITE);
  DrawLine(70, 20 + YOffset, 90, 40 + YOffset, RED);
  DrawLine(90, 20 + YOffset, 70, 40 + YOffset, RED);
  DrawRectangleLines(115, 15 + YOffset, 30, 30, RAYWHITE);
  DrawCircle(130, 30 + YOffset, 10, Fade(GREEN, 0.8));
  DrawRectangleLines(165, 15 + YOffset, 30, 30, RAYWHITE);
  DrawTriangle(Vector2Create(175, 42 + YOffset), Vector2Create(185, 42 + YOffset), Vector2Create(180, 18 + YOffset), Fade(PURPLE, 0.8));
  DrawTriangleLines(Vector2Create(175, 42 + YOffset), Vector2Create(185, 42 + YOffset), Vector2Create(180, 18 + YOffset), PURPLE);
  fpsBuf := AnsiString(Format('FPS: %d', [GetFPS()]));
  DrawText(PAnsiChar(fpsBuf), 10, GetScreenHeight() - 30, 20, GREEN);
end;

end.


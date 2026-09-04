unit RaylibSandbox;

{==============================================================================*
 *  RaylibSandbox - VCL Wrapper for a multi-threaded Raylib + Jolt Physics
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
  /// <summary>
  /// Custom user data attached to each dynamic actor to handle
  /// spawn fading and impact glow effects.
  /// </summary>
  PCubeData = ^TCubeData;

  TCubeData = record
    SpawnTime: Double;
    LastHitTime: Double;
  end;
  /// <summary>
  /// VCL Control that encapsulates a threaded Raylib 3D environment.
  /// Place this on a Form and set Active := True to start the simulation.
  /// </summary>

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
    FTxtBuf: AnsiString;              // Buffer for converting Delphi strings to PAnsiChar for Raylib
    // Engine & Actors
    FEngine: TModelEngine;
    FFloorActor: TModelActor;
    FWalls: array[0..3] of TModelActor;
    FCubes: TArray<TModelActor>;
    FWallpaperModel: TModel;
    FWallpaperTex: TTexture2D;
    // Interaction State
    FCubeSelected: TModelActor;
    FDragging: Boolean;
    FDragTargetPos: TVector3;
    FMousePos: TVector2;
    // Camera State
    FCamera: TCamera3D;
    FCamYaw, FCamPitch, FCamDist: single;
    FLastMouse: TPoint;
    FDraggingRMB: boolean;
    // UI & Animation State
    FHUDAnimY: single;               // Offset for HUD slide-in animation
    FSceneStartTime: Double;
    // Spawn Management
    FSpawnQueue: Integer;
    FSpawnTimer: Single;
    FSpawnShape: TShapeType;
    function Txt(const AText: string): PAnsiChar;
    procedure InitScene;
    procedure ClearCubes;
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
    /// <summary> Start or stop the Raylib thread and physics simulation. </summary>
    property Active: Boolean read FActive write SetActive default False;
    /// <summary> Target frame rate for the background rendering loop. </summary>
    property TargetFPS: Integer read FTargetFPS write SetTargetFPS default 60;
  end;

implementation
/// <summary>
/// Helper to generate a teal color based on an intensity factor (0.0 to 1.0).
/// Used for the collision glow effect on cubes.
/// </summary>

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
  FHUDAnimY := -150.0; // Start HUD offscreen
  FSceneStartTime := 0.0;
  FSpawnQueue := 0;
  FSpawnTimer := 0.0;
  FSpawnShape := stBox;
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
  // Ensure the thread is safely terminated before the VCL window handle is destroyed
  StopThread;
  inherited;
end;

procedure TRaylibSandbox.Resize;
begin
  inherited;
  // Update the Raylib child window size to match the VCL control bounds
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
  // Run Raylib in an anonymous background thread
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
        // Reparent the Raylib window to this VCL control
        if FRaylibWnd <> 0 then
        begin
          Winapi.Windows.SetParent(FRaylibWnd, Self.Handle);
          SetWindowLong(FRaylibWnd, GWL_STYLE, WS_CHILD or WS_VISIBLE);
          SetWindowPos(FRaylibWnd, 0, 0, 0, Self.ClientWidth, Self.ClientHeight, SWP_NOZORDER);
        end;
        // Initialize Physics & Camera
        FEngine := TModelEngine.Create;
        FCamYaw := -0.5;
        FCamPitch := 0.8;
        FCamDist := 60.0;
        FCamera.target := Vector3Create(0, 0, 0);
        FCamera.position := Vector3Create(20, 20, 20);
        FCamera.up := Vector3Create(0, 1, 0);
        FCamera.fovy := 45.0;
        FCamera.projection := CAMERA_PERSPECTIVE;
        // Initialize Input Flags
        FDraggingRMB := False;
        FDragging := False;
        FCubeSelected := nil;
        FHUDAnimY := -150.0;
        // Setup Physics Scene
        InitScene;
        JPH_PhysicsSystem_OptimizeBroadPhase(FEngine.PhysicsSystem);
        // Load Wallpaper Texture if available
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
        // Manual Frame Limiting using High Precision Timer
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
          // Manual frame pacing
          if FTargetFPS > 0 then
          begin
            FrameTicks := Freq div FTargetFPS;
            QueryPerformanceCounter(FrameEnd);
            RestMs := (FrameTicks - (FrameEnd - FrameStart)) * 1000 / Freq;
            if RestMs > 0 then
            begin
              if RestMs > 2 then
                Sleep(Trunc(RestMs) - 2);
              // Spin wait for remaining time to ensure accurate FPS
              repeat
                QueryPerformanceCounter(FrameEnd);
              until (FrameEnd - FrameStart) >= FrameTicks;
            end;
          end
          else
            Sleep(1);
        end;
        // Cleanup Phase
        timeEndPeriod(1);
        FInitialized := False;
        ClearCubes;
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
    // Allow the thread to finish its current frame and clean up
    Sleep(100);
  end;
end;
/// <summary>
/// Utility to safely cast Delphi Strings to PAnsiChar required by Raylib.
/// Uses an internal buffer to persist the memory address during the call.
/// </summary>

function TRaylibSandbox.Txt(const AText: string): PAnsiChar;
begin
  FTxtBuf := AnsiString(AText);
  Result := PAnsiChar(FTxtBuf);
end;

procedure TRaylibSandbox.InitScene;
begin
  // Static Floor
  FFloorActor := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 1, 100), True);
  FFloorActor.SetPosition(Vector3Create(0, -0.5, 0));
  // Static Walls (Box Arena)
  FWalls[0] := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[0].SetPosition(Vector3Create(0, 10, -50));
  FWalls[1] := TModelActor.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[1].SetPosition(Vector3Create(0, 10, 50));
  FWalls[2] := TModelActor.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[2].SetPosition(Vector3Create(-50, 10, 0));
  FWalls[3] := TModelActor.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[3].SetPosition(Vector3Create(50, 10, 0));
  FCubes := nil;
end;

procedure TRaylibSandbox.ClearCubes;
var
  i: Integer;
  Data: PCubeData;
begin
  FDragging := False;
  FCubeSelected := nil;
  FSpawnQueue := 0;
  // Free custom allocated user data attached to the actors
  for i := High(FCubes) downto 0 do
  begin
    if Assigned(FCubes[i]) then
    begin
      if FCubes[i].UserData <> nil then
      begin
        Data := FCubes[i].UserData;
        Dispose(Data);
      end;
    end;
  end;
  // Free the actors themselves
  for i := High(FCubes) downto 0 do
  begin
    if Assigned(FCubes[i]) then
    begin
      FCubes[i].Free;
      FCubes[i] := nil;
    end;
  end;
  SetLength(FCubes, 0);
end;

procedure TRaylibSandbox.SpawnObjects(Count: Integer; ShapeType: TShapeType);
begin
  // Queue objects instead of instantiating all at once to avoid frame drops
  FSpawnQueue := FSpawnQueue + Count;
  FSpawnShape := ShapeType;
end;

procedure TRaylibSandbox.ProcessSpawnQueue(dt: Single);
var
  Obj: TModelActor;
  oldLen: Integer;
  Data: PCubeData;
  Pos, Size: TVector3;
begin
  if FSpawnQueue <= 0 then
    Exit;
  // Limit spawn rate to one object every 0.04 seconds
  FSpawnTimer := FSpawnTimer - dt;
  if FSpawnTimer > 0 then
    Exit;
  FSpawnQueue := FSpawnQueue - 1;
  FSpawnTimer := 0.04;
  oldLen := Length(FCubes);
  SetLength(FCubes, oldLen + 1);
  // Allocate custom data for glow/fade effects
  New(Data);
  Data^.SpawnTime := GetTime();
  Data^.LastHitTime := 0;
  // Define Sizes based on shape
  Size := Vector3Create(1, 1, 1);
  case FSpawnShape of
    stSphere:
      Size := Vector3Create(0.5, 0.5, 0.5);
    stCylinder:
      Size := Vector3Create(0.5, 1.5, 0.5);
  end;
  // Create the dynamic actor
  Obj := TModelActor.Create('', FEngine, FSpawnShape, Size, False);
  // Random spawn position in the air
  Pos.X := -10.0 + (Random * 20.0);
  Pos.Y := 25.0;
  Pos.Z := -10.0 + (Random * 20.0);
  Obj.SetPosition(Pos);
  Obj.ActivateBody;
  Obj.UserData := Data;
  FCubes[oldLen] := Obj;
end;

procedure TRaylibSandbox.HandleCameraInput;
var
  p: TPoint;
begin
  GetCursorPos(p);
  // Orbit Camera Logic (Right Mouse Button)
  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if FDraggingRMB then
    begin
      FCamYaw := FCamYaw - (p.x - FLastMouse.x) * 0.006;
      // Clamp pitch to prevent flipping
      FCamPitch := EnsureRange(FCamPitch + (p.y - FLastMouse.y) * 0.006, 0.05, 1.5);
    end;
    FDraggingRMB := True;
  end
  else
    FDraggingRMB := False;
  FLastMouse := p;
  // Zoom Logic (Mouse Wheel)
  if GetMouseWheelMove() <> 0 then
    FCamDist := EnsureRange(FCamDist - GetMouseWheelMove() * 3.0, 10, 100);
  // Calculate Camera Position using Spherical Coordinates
  FCamera.position := Vector3Create(FCamera.target.x + Cos(FCamPitch) * Sin(FCamYaw) * FCamDist, FCamera.target.y + Sin(FCamPitch) * FCamDist, FCamera.target.z + Cos(FCamPitch) * Cos(FCamYaw) * FCamDist);
end;
/// <summary>
/// Checks if the left mouse button is pressed within a specific Raylib UI rectangle.
/// Also updates the FMousePos variable for 3D raycasting.
/// </summary>

function TRaylibSandbox.CheckButton(x, y, w, h: Integer): Boolean;
var
  p: TPoint;
  RealY: Integer;
begin
  Result := False;
  // Only register clicks if the HUD has finished sliding in
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
  cubeBox: TBoundingBox;
  hitInfo: TRayCollision;
  t: single;
  i: Integer;
begin
  // 1. Check GUI Buttons
  if CheckButton(10, 10, 40, 40) then
  begin
    SpawnObjects(30, stBox);
    Exit;
  end;
  if CheckButton(60, 10, 40, 40) then
  begin
    ClearCubes;
    Exit;
  end;
  if CheckButton(110, 10, 40, 40) then
  begin
    SpawnObjects(30, stSphere);
    Exit;
  end;
  if CheckButton(160, 10, 40, 40) then
  begin
    SpawnObjects(30, stCylinder);
    Exit;
  end;
  // 2. Object Picking (Left Mouse Button)
  ray := GetScreenToWorldRay(FMousePos, FCamera);
  if (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0 then
  begin
    if not FDragging then
    begin
      // Iterate through cubes and find the first one intersected by the ray
      for i := 0 to High(FCubes) do
      begin
        if FCubes[i] = nil then
          Continue;
        cubeBox.min := Vector3Create(FCubes[i].Position.x - 0.5, FCubes[i].Position.y - 0.5, FCubes[i].Position.z - 0.5);
        cubeBox.max := Vector3Create(FCubes[i].Position.x + 0.5, FCubes[i].Position.y + 0.5, FCubes[i].Position.z + 0.5);
        hitInfo := GetRayCollisionBox(ray, cubeBox);
        if hitInfo.hit then
        begin
          FCubeSelected := FCubes[i];
          FDragging := True;
          Break;
        end;
      end;
    end;
    // Dragging Logic: Project mouse ray onto the Y-plane of the selected cube
    if FDragging and Assigned(FCubeSelected) then
    begin
      if Abs(ray.direction.y) > 0.0001 then
      begin
        t := (FCubeSelected.Position.y - ray.position.y) / ray.direction.y;
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
    // Released LMB
    FDragging := False;
    FCubeSelected := nil;
  end;
end;

procedure TRaylibSandbox.UpdateGame;
var
  dt: single;
  Dir: TVector3;
  Dist: single;
  NewVel: TVector3;
  CubeVel: TVector3;
  i: Integer;
begin
  dt := GetFrameTime();
  HandleCameraInput;
  HandleDesktopInput;
  ProcessSpawnQueue(dt);
  // Advance Jolt Physics Simulation
  FEngine.Update(dt);
  // HUD Slide-in Animation
  if (FSceneStartTime > 0) and (GetTime() - FSceneStartTime > 1.0) then
    FSceneStartTime := 0;
  if (FSceneStartTime = 0) and (FHUDAnimY < 0) then
  begin
    FHUDAnimY := FHUDAnimY * (1.0 - dt * 6.0);
    if FHUDAnimY > -0.5 then
      FHUDAnimY := 0;
  end;
  // Update Glow Effects: Check for fast moving cubes
  for i := 0 to High(FCubes) do
  begin
    if Assigned(FCubes[i]) and (FCubes[i].UserData <> nil) then
    begin
      CubeVel := FCubes[i].GetLinearVelocity;
      // If velocity exceeds threshold, update LastHitTime for teal glow
      if (Abs(CubeVel.x) > 2.0) or (Abs(CubeVel.y) > 2.0) or (Abs(CubeVel.z) > 2.0) then
      begin
        PCubeData(FCubes[i].UserData)^.LastHitTime := GetTime();
      end;
    end;
  end;
  // Drag Selected Object: Move towards target position via velocity
  if FDragging and Assigned(FCubeSelected) then
  begin
    Dir.x := FDragTargetPos.x - FCubeSelected.Position.x;
    Dir.y := 0;
    Dir.z := FDragTargetPos.z - FCubeSelected.Position.z;
    Dist := Sqrt(Dir.x * Dir.x + Dir.z * Dir.z);
    if Dist > 0.05 then
    begin
      FCubeSelected.ActivateBody;
      // Set horizontal velocity towards target, preserve vertical velocity (gravity)
      NewVel.x := Dir.x * 10.0;
      NewVel.y := FCubeSelected.GetLinearVelocity.y;
      NewVel.z := Dir.z * 10.0;
      FCubeSelected.SetLinearVelocity(NewVel);
      // Dampen angular velocity so it doesn't spin chaotically while dragging
      NewVel := FCubeSelected.GetAngularVelocity;
      NewVel.x := NewVel.x * 0.9;
      NewVel.y := NewVel.y * 0.9;
      NewVel.z := NewVel.z * 0.9;
      FCubeSelected.SetAngularVelocity(NewVel);
    end
    else
    begin
      // Stop horizontal movement if close enough to target
      NewVel := FCubeSelected.GetLinearVelocity;
      NewVel.x := 0;
      NewVel.z := 0;
      FCubeSelected.SetLinearVelocity(NewVel);
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
  // Force VCL window to update since Raylib handles its own buffer
  if FRaylibWnd <> 0 then
    RedrawWindow(FRaylibWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW);
end;

procedure TRaylibSandbox.Render3DScene;
var
  i: Integer;
  BaseColor, GlowColor, CubeColor, WireColor: TColorB;
  CurrentTime: Double;
  Data: PCubeData;
  Alpha, Glow, SpawnGlow: Single;
begin
  BeginMode3D(FCamera);
  // Draw Floor
  if FWallpaperTex.id > 0 then
    DrawModel(FWallpaperModel, Vector3Create(0, 0, 0), 1.0, WHITE)
  else
    DrawPlane(Vector3Create(0, 0.01, 0), Vector2Create(100, 100), DARKGRAY);
  // Draw Walls
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
  CurrentTime := GetTime();
  // Draw Dynamic Cubes
  for i := 0 to High(FCubes) do
  begin
    if FCubes[i] = nil then
      Continue;
    Alpha := 1.0;
    Glow := 0;
    SpawnGlow := 0;
    // Calculate Effects based on UserData
    if FCubes[i].UserData <> nil then
    begin
      Data := FCubes[i].UserData;
      // Fade in animation
      Alpha := (CurrentTime - Data^.SpawnTime) * 4.0;
      if Alpha > 1.0 then
        Alpha := 1.0;
      // Spawn glow fade out
      SpawnGlow := Max(0, 1.0 - (CurrentTime - Data^.SpawnTime) * 2.0);
      // Impact glow fade out
      if Data^.LastHitTime > 0 then
        Glow := Max(0, 1.0 - ((CurrentTime - Data^.LastHitTime) / 0.15));
    end;
    // Determine Colors
    if FCubes[i] = FCubeSelected then
    begin
      CubeColor := Fade(YELLOW, Alpha);
      WireColor := Fade(BLACK, Alpha);
    end
    else
    begin
      GlowColor := GetTealGlowColor(Max(Glow, SpawnGlow * 0.5));
      BaseColor.r := 190;
      BaseColor.g := 33;
      BaseColor.b := 55;
      BaseColor.a := 255; // Crimson Red
      // Lerp between base color and glow color
      CubeColor.r := Round(BaseColor.r * (1.0 - Glow) + GlowColor.r * Glow);
      CubeColor.g := Round(BaseColor.g * (1.0 - Glow) + GlowColor.g * Glow);
      CubeColor.b := Round(BaseColor.b * (1.0 - Glow) + GlowColor.b * Glow);
      CubeColor.a := 255;
      CubeColor := Fade(CubeColor, Alpha);
      WireColor := Fade(BLACK, Alpha);
    end;
    // Render Primitive based on ShapeType
    case FCubes[i].ShapeType of
      stSphere:
        begin
          DrawSphere(FCubes[i].Position, 0.5, CubeColor);
          DrawSphereWires(FCubes[i].Position, 0.5, 12, 12, WireColor);
        end;
      stCylinder:
        begin
          DrawCylinder(FCubes[i].Position, 0.5, 0.5, 1.5, 12, CubeColor);
          DrawCylinderWires(FCubes[i].Position, 0.5, 0.5, 1.5, 12, WireColor);
        end;
    else
      begin
        DrawCube(FCubes[i].Position, 1, 1, 1, CubeColor);
        DrawCubeWires(FCubes[i].Position, 1, 1, 1, WireColor);
      end;
    end;
  end;
  EndMode3D();
end;

procedure TRaylibSandbox.DrawGUI;
var
  fpsBuf: AnsiString;
  YOffset: Integer;
begin
  YOffset := Trunc(FHUDAnimY);
  // Background Panel
  DrawRectangle(10, 10 + YOffset, 210, 50, Fade(BLACK, 0.8));
  DrawRectangleLines(10, 10 + YOffset, 210, 50, RAYWHITE);
  // 1. Spawn Cubes Button
  DrawRectangleLines(15, 15 + YOffset, 30, 30, RAYWHITE);
  DrawRectangle(20, 20 + YOffset, 20, 20, Fade(BLUE, 0.8));
  // 2. Clear All Button
  DrawRectangleLines(65, 15 + YOffset, 30, 30, RAYWHITE);
  DrawLine(70, 20 + YOffset, 90, 40 + YOffset, RED);
  DrawLine(90, 20 + YOffset, 70, 40 + YOffset, RED);
  // 3. Spawn Spheres Button
  DrawRectangleLines(115, 15 + YOffset, 30, 30, RAYWHITE);
  DrawCircle(130, 30 + YOffset, 10, Fade(GREEN, 0.8));
  // 4. Spawn Cylinders Button
  DrawRectangleLines(165, 15 + YOffset, 30, 30, RAYWHITE);
  DrawRectangle(175, 18 + YOffset, 10, 24, Fade(PURPLE, 0.8));
  DrawLine(175, 18 + YOffset, 185, 18 + YOffset, PURPLE);
  DrawLine(175, 42 + YOffset, 185, 42 + YOffset, PURPLE);
  // FPS Counter
  fpsBuf := AnsiString(Format('FPS: %d', [GetFPS()]));
  DrawText(PAnsiChar(fpsBuf), 10, GetScreenHeight() - 30, 20, GREEN);
end;

end.


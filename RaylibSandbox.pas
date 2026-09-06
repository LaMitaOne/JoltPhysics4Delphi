unit RaylibSandbox;


{==============================================================================*
 *  RaylibSandbox v0.3 - VCL Wrapper for a multi-threaded Raylib + Jolt Physics
 *------------------------------------------------------------------------------
   Author:  Lara Miriam Tamy Reschke / LamitaOne
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
 *    - Spawning dynamic objects (Cubes, Spheres, Pyramids) that interact
 *      with a static floor and walls using Jolt Physics.
 *    - Raycasting from the 2D screen coordinates to drag dynamic bodies
 *      across the floor and forcefully throw them.
 *    - Orbit camera (Right Mouse Button), Zoom (Mouse Wheel), and WASD/Arrow
 *      key panning with world boundaries to prevent scrolling into the void.
 *    - Shooting mechanic: Fire persistent blue cannonball projectiles using
 *      the Spacebar with a cooldown to knock objects away.
 *    - Custom GLSL Lighting System implementing basic ambient and diffuse
 *      shading for the floor, walls, and actors.
 *    - Dynamic Fake Shadows: Flat shadows drawn under objects that scale
 *      in size and opacity based on the object's height.
 *    - Custom UI drawn directly in Raylib to trigger spawns and clear scenes.
 *    - Glow and Spawn animation effects driven by custom UserData.

 Latest changes:

 v0.3:
     Shooting Mechanic (Projectiles): Added the ability to shoot dynamic physics spheres by pressing SPACE. Projectiles use a 250ms cooldown to prevent machine-gun fire.
     Dynamic Fake Shadows: Implemented custom flat shadows (DrawFlatShadow / DrawCylinderEx) for the floor, walls, and all actors. Shadow radius and alpha opacity scale dynamically based on the object's Y-height to simulate realistic light scattering.
     Camera Panning & Bounds: Added WASD and Arrow Key panning. Camera movement is now clamped to world bounds (-80 to +80) to prevent the user from scrolling infinitely into the void.
     Custom Lighting System: Implemented a custom GLSL shader for basic ambient and diffuse lighting that affects the floor, walls, and objects, giving the scene proper depth.
     CCD (Continuous Collision Detection): Projectiles use JPH_MotionQuality_LinearCast to prevent fast-moving spheres from tunneling through walls or objects.
     Z-Fighting Fix: Enabled rlEnableDepthTest() for custom shadow drawing to prevent them from flickering or being hidden behind the wallpaper texture.
     Sphere Clipping Fix: Applied a manual Y-offset (+0.3 for spheres) during rendering to visually lift them out of the floor, bypassing Jolt's internal convex radius penetration.
     Raylib DrawSphere Workaround: Implemented manual matrix scaling (rlScalef) because Raylib's DrawSphere ignores the radius parameter when drawing inside a manually pushed rotation matrix.
     Memory Initialization: Used FillChar for TItemData upon spawn to prevent random memory garbage from causing projectiles to render incorrectly.

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
    IsProjectile: Boolean; // Flag to distinguish bullets from normal cubes
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

    // Lighting System
    FLightShader: TShader;
    FLightPos: TVector3;
    FLightPosLoc: Integer;
    FViewPosLoc: Integer;
    FAmbientLoc: Integer;
    FDiffuseLoc: Integer;
    FCameraMoved: Boolean;
    FLightAngle: Single;
    FLightSpeed: Single;

    // Projectile System (Shooting)
    FProjectiles: TArray<TModelActor>;
    FShootCooldown: Single;

    procedure ShootBall;
    procedure UpdateProjectiles(dt: Single);
    procedure InitScene;
    procedure InitLighting;
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
  if intensity < 0 then intensity := 0;
  if intensity > 1 then intensity := 1;
  Result.r := Round(64 * intensity);
  Result.g := Round(224 * intensity);
  Result.b := Round(208 * intensity);
  Result.a := 255;
end;

// Helper to draw a perfectly flat, filled shadow circle without hard borders
procedure DrawFlatShadow(position: TVector3; radius: Single; color: TColorB);
var
  segments, i: Integer;
  angle: Single;
  v1, v2: TVector3;
begin
  if radius <= 0 then Exit;
  segments := 24; // Smoothness of the circle

  // Force Raylib to respect the depth buffer so the shadow draws over the floor texture
  rlEnableDepthTest();

  rlBegin(RL_TRIANGLES);
    rlColor4ub(color.r, color.g, color.b, color.a);
    for i := 0 to segments - 1 do
    begin
      angle := (i / segments) * 2.0 * PI;
      v1.x := position.x + Cos(angle) * radius;
      v1.y := position.y;
      v1.z := position.z + Sin(angle) * radius;

      angle := ((i + 1) / segments) * 2.0 * PI;
      v2.x := position.x + Cos(angle) * radius;
      v2.y := position.y;
      v2.z := position.z + Sin(angle) * radius;

      rlVertex3f(position.x, position.y, position.z); // Center
      rlVertex3f(v1.x, v1.y, v1.z);                   // Edge 1
      rlVertex3f(v2.x, v2.y, v2.z);                   // Edge 2
    end;
  rlEnd();
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
  FShootCooldown := 0.0;
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

procedure TRaylibSandbox.InitLighting;
const
  VERT: AnsiString =
    '#version 330' + #10 +
    'in vec3 vertexPosition;' + #10 +
    'in vec3 vertexNormal;' + #10 +
    'in vec2 vertexTexCoord;' + #10 +
    'in vec4 vertexColor;' + #10 +
    'uniform mat4 mvp;' + #10 +
    'uniform mat4 matModel;' + #10 +
    'out vec3 vNormal;' + #10 +
    'out vec2 vTexCoord;' + #10 +
    'out vec4 vColor;' + #10 +
    'void main()' + #10 +
    '{' + #10 +
    '  vNormal = normalize(mat3(matModel) * vertexNormal);' + #10 +
    '  vTexCoord = vertexTexCoord;' + #10 +
    '  vColor = vertexColor;' + #10 +
    '  gl_Position = mvp * vec4(vertexPosition, 1.0);' + #10 +
    '}';
  FRAG: AnsiString =
    '#version 330' + #10 +
    'in vec3 vNormal;' + #10 +
    'in vec2 vTexCoord;' + #10 +
    'in vec4 vColor;' + #10 +
    'uniform vec3 lightPos;' + #10 +
    'uniform vec3 viewPos;' + #10 +
    'uniform vec4 ambient;' + #10 +
    'uniform vec4 diffuse;' + #10 +
    'uniform sampler2D texture0;' + #10 +
    'out vec4 finalColor;' + #10 +
    'void main()' + #10 +
    '{' + #10 +
    '  vec3 lightDir = normalize(lightPos - viewPos);' + #10 +
    '  vec3 normal = normalize(vNormal);' + #10 +
    '  float diff = max(dot(normal, lightDir), 0.0);' + #10 +
    '  vec4 texColor = texture(texture0, vTexCoord);' + #10 +
    '  vec4 baseColor = texColor * vColor;' + #10 +
    '  vec4 ambientColor = ambient * baseColor;' + #10 +
    '  vec4 diffuseColor = diffuse * diff * baseColor;' + #10 +
    '  finalColor = ambientColor + diffuseColor;' + #10 +
    '}';
begin
  FLightShader := LoadShaderFromMemory(PAnsiChar(VERT), PAnsiChar(FRAG));
  FLightPosLoc := GetShaderLocation(FLightShader, 'lightPos');
  FViewPosLoc := GetShaderLocation(FLightShader, 'viewPos');
  FAmbientLoc := GetShaderLocation(FLightShader, 'ambient');
  FDiffuseLoc := GetShaderLocation(FLightShader, 'diffuse');

  if FWallpaperTex.id > 0 then
    FWallpaperModel.materials[0].shader := FLightShader;

  FLightAngle := 0.5;
  FLightSpeed := 0.05;
  FLightPos := Vector3Create(50, 80, 30);
  FCameraMoved := True;
end;

procedure TRaylibSandbox.StartThread;
var
  FilePath: string;
  floorMesh: TMesh;
begin
  if FThreadActive then Exit;
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
            FWallpaperModel.transform := MatrixTranslate(0, 0.001, 0);
            FWallpaperModel.materials[0].maps[0].texture := FWallpaperTex;
            FWallpaperModel.materials[0].maps[0].color := WHITE;
          end;
        end;

        InitLighting;
        FInitialized := True;
        FSceneStartTime := GetTime();

        QueryPerformanceFrequency(Freq);
        timeBeginPeriod(1);
        while not TThread.CheckTerminated do
        begin
          QueryPerformanceCounter(FrameStart);
          if WindowShouldClose() then Break;
          if not FPaused then UpdateGame;
          RenderGame;

          if FTargetFPS > 0 then
          begin
            FrameTicks := Freq div FTargetFPS;
            QueryPerformanceCounter(FrameEnd);
            RestMs := (FrameTicks - (FrameEnd - FrameStart)) * 1000 / Freq;
            if RestMs > 0 then
            begin
              if RestMs > 2 then Sleep(Trunc(RestMs) - 2);
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
        if FLightShader.id > 0 then
          UnloadShader(FLightShader);
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
  if not FThreadActive then Exit;
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    Sleep(100);
  end;
end;

procedure TRaylibSandbox.InitScene;
begin
  // Floor perfectly aligned so objects sit on Y=0
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
  if FSpawnQueue <= 0 then Exit;
  FSpawnTimer := FSpawnTimer - dt;
  if FSpawnTimer > 0 then Exit;

  FSpawnQueue := FSpawnQueue - 1;
  FSpawnTimer := 0.04;
  oldLen := Length(FItems);
  SetLength(FItems, oldLen + 1);
  New(Data);
  // Initialize all fields to prevent random memory garbage
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := False; // Crucial: Mark as a normal item, not a bullet

  Size := Vector3Create(1, 1, 1);
  if FSpawnShape = stSphere then
    Size := Vector3Create(0.5, 0.5, 0.5)
  else if FSpawnShape = stPyramid then
    Size := Vector3Create(0.8, 1.5, 0.8);

  JPos.x := -20.0 + (Random * 40.0);
  JPos.y := 25.0 + (Random * 10.0);
  JPos.z := -20.0 + (Random * 40.0);

  RX := DegToRad(-45 + (Random * 90.0));
  RY := DegToRad(-180 + (Random * 360.0));
  RZ := DegToRad(-0.2 + (Random * 0.4));

  RandQuat := QuaternionFromEuler(RX, RY, RZ);
  JRot.x := RandQuat.x;
  JRot.y := RandQuat.y;
  JRot.z := RandQuat.z;
  JRot.w := RandQuat.w;

  Obj := TModelActor.Create('', FEngine, FSpawnShape, Size, False, @JPos, @JRot);
  Obj.Friction := 0.2;
  Obj.Restitution := 0.2;
  Obj.UserData := Data;
  Obj.Visible := True;
  FItems[oldLen] := Obj;
end;

procedure TRaylibSandbox.HandleCameraInput;
var
  p: TPoint;
  dt, panSpeed: Single;
  fwdX, fwdZ, rightX, rightZ: Single;
begin
  dt := GetFrameTime();
  if dt <= 0 then dt := 1 / 60;

  GetCursorPos(p);
  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if FDraggingRMB then
    begin
      FCamYaw := FCamYaw - (p.x - FLastMouse.x) * 0.006;
      FCamPitch := EnsureRange(FCamPitch + (p.y - FLastMouse.y) * 0.006, 0.05, 1.5);
      FCameraMoved := True;
    end;
    FDraggingRMB := True;
  end
  else
    FDraggingRMB := False;
  FLastMouse := p;

  // WASD and Arrow Keys Panning
  fwdX := -Sin(FCamYaw);   fwdZ := -Cos(FCamYaw);
  rightX := Cos(FCamYaw);  rightZ := -Sin(FCamYaw);
  panSpeed := 25.0 * dt;

  if ((GetAsyncKeyState(Ord('W')) and $8000) <> 0) or ((GetAsyncKeyState(VK_UP) and $8000) <> 0) then
  begin
    FCamera.target.x := FCamera.target.x + fwdX * panSpeed;
    FCamera.target.z := FCamera.target.z + fwdZ * panSpeed;
    FCameraMoved := True;
  end;
  if ((GetAsyncKeyState(Ord('S')) and $8000) <> 0) or ((GetAsyncKeyState(VK_DOWN) and $8000) <> 0) then
  begin
    FCamera.target.x := FCamera.target.x - fwdX * panSpeed;
    FCamera.target.z := FCamera.target.z - fwdZ * panSpeed;
    FCameraMoved := True;
  end;
  if ((GetAsyncKeyState(Ord('A')) and $8000) <> 0) or ((GetAsyncKeyState(VK_LEFT) and $8000) <> 0) then
  begin
    FCamera.target.x := FCamera.target.x - rightX * panSpeed;
    FCamera.target.z := FCamera.target.z - rightZ * panSpeed;
    FCameraMoved := True;
  end;
  if ((GetAsyncKeyState(Ord('D')) and $8000) <> 0) or ((GetAsyncKeyState(VK_RIGHT) and $8000) <> 0) then
  begin
    FCamera.target.x := FCamera.target.x + rightX * panSpeed;
    FCamera.target.z := FCamera.target.z + rightZ * panSpeed;
    FCameraMoved := True;
  end;

  // Camera Bounds: Keep the user from scrolling forever into the void
  FCamera.target.x := EnsureRange(FCamera.target.x, -80.0, 80.0);
  FCamera.target.z := EnsureRange(FCamera.target.z, -80.0, 80.0);

  if GetMouseWheelMove() <> 0 then
  begin
    FCamDist := EnsureRange(FCamDist - GetMouseWheelMove() * 3.0, 10, 100);
    FCameraMoved := True;
  end;

  FCamera.position := Vector3Create(
    FCamera.target.x + Cos(FCamPitch) * Sin(FCamYaw) * FCamDist,
    FCamera.target.y + Sin(FCamPitch) * FCamDist,
    FCamera.target.z + Cos(FCamPitch) * Cos(FCamYaw) * FCamDist
  );
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

procedure TRaylibSandbox.ShootBall;
var
  Obj: TModelActor;
  oldLen: Integer;
  Data: PItemData;
  Size: TVector3;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  CamForward, ThrowVel: TVector3;
  JVel: JPH_Vec3;
begin
  oldLen := Length(FProjectiles);
  SetLength(FProjectiles, oldLen + 1);

  // WICHTIG: Physikalischer Radius ist 0.5 (wie normale Würfel), damit sie nicht durchtunnelt!
  Size := Vector3Create(0.5, 0.5, 0.5);

  // Calculate camera forward direction
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  // Spawn position: slightly below camera and forward
  JPos.x := FCamera.position.x + (CamForward.x * 2.0);
  JPos.y := FCamera.position.y - 1.0 + (CamForward.y * 2.0);
  JPos.z := FCamera.position.z + (CamForward.z * 2.0);

  JRot.x := 0; JRot.y := 0; JRot.z := 0; JRot.w := 1;

  Obj := TModelActor.Create('', FEngine, stSphere, Size, False, @JPos, @JRot);

  // Standard mass and friction like normal items
  Obj.Mass := 1.0;
  Obj.Friction := 0.2;
  Obj.Restitution := 0.2;

  // Activate the body immediately (crucial for waking it up)
  Obj.ActivateBody;

  Obj.Visible := True;

  New(Data);
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := True;
  Obj.UserData := Data;

  // --- DRAG THROW LOGIC (80.0 Speed = Perfect Impact) ---
  ThrowVel.x := CamForward.x * 80.0;
  ThrowVel.y := CamForward.y * 80.0;
  ThrowVel.z := CamForward.z * 80.0;
  Obj.SetLinearVelocity(ThrowVel);

  FProjectiles[oldLen] := Obj;
end;


procedure TRaylibSandbox.UpdateProjectiles(dt: Single);
var
  i: Integer;
  Actor: TModelActor;
  Pos, ShadowPos: TVector3;
  Rad, Alpha: Single;
begin
  // 1. Draw projectiles
  for i := 0 to High(FProjectiles) do
  begin
    if FProjectiles[i] = nil then Continue;
    Actor := FProjectiles[i];

    // Draw dynamic shadow (Black)
    Pos := Actor.Position;
    Rad := EnsureRange(0.4 - (Pos.y * 0.1), 0.05, 0.4);
    Alpha := EnsureRange(0.5 - (Pos.y * 0.02), 0, 0.5);
    ShadowPos := Vector3Create(Pos.x, 0.06, Pos.z);
    DrawCylinderEx(ShadowPos, Vector3Create(Pos.x, 0.05, Pos.z), Rad, Rad, 24, Fade(BLACK, Alpha));

    // Draw the projectile as a small BLUE sphere (Y+0.3 to prevent floor clipping)
    BeginShaderMode(FLightShader);
    rlPushMatrix();

    Pos.y := Pos.y + 0.3; // Lift it visually out of the floor
    rlTranslatef(Pos.x, Pos.y, Pos.z);
    rlScalef(0.3, 0.3, 0.3); // Optisch verkleinern, damit sie wie eine kleine Kugel wirkt
    DrawSphere(Vector3Create(0, 0, 0), 1.0, SKYBLUE); // Blau!

    rlPopMatrix();
    EndShaderMode();
  end;

end;

procedure TRaylibSandbox.HandleDesktopInput;
var
  ray: TRay;
  itemBox: TBoundingBox;
  hitInfo: TRayCollision;
  t: single;
  i: Integer;
  TargetY: Single;
  dt: Single;
begin
  dt := GetFrameTime();

  // Shoot with Space key (with a small cooldown)
  if FShootCooldown > 0 then
    FShootCooldown := FShootCooldown - dt;

  if (GetAsyncKeyState(VK_SPACE) and $8000) <> 0 then
  begin
    if FShootCooldown <= 0 then
    begin
      ShootBall;
      FShootCooldown := 0.25; // 250ms cooldown
    end;
  end;

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
        if FItems[i] = nil then Continue;
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
        // +0.5 ensures we drag across the surface (above y=0) and keeps the object from clipping
        TargetY := FItemSelected.Position.y + 0.5;
        t := (TargetY - ray.position.y) / ray.direction.y;
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
  Ambient: array[0..3] of Single;
  Diffuse: array[0..3] of Single;
  CamPosArr: array[0..2] of Single;
  LightPosArr: array[0..2] of Single;
begin
  if FClearItemsQueued then
  begin
    FDragging := False;
    FItemSelected := nil;
    FSpawnQueue := 0;

    //Spawned items
    for i := High(FItems) downto 0 do
    begin
      if Assigned(FItems[i]) then
      begin
        FItems[i].Visible := False;
        FItems[i].Free;
        FItems[i] := nil;
      end;
    end;
    //Projectiles
    for i := High(FProjectiles) downto 0 do
    begin
      if Assigned(FProjectiles[i]) then
      begin
        if FProjectiles[i].UserData <> nil then
          Dispose(PItemData(FProjectiles[i].UserData));
        FProjectiles[i].Free;
        FProjectiles[i] := nil;
      end;
    end;
    SetLength(FProjectiles, 0);

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
      // Skip projectiles in the normal item logic
      if PItemData(FItems[i].UserData)^.IsProjectile then Continue;

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

  // --- Dynamic Light Update ---
  FLightAngle := FLightAngle + (FLightSpeed * dt);
  FLightPos.x := Cos(FLightAngle) * 50.0;
  FLightPos.y := 80.0;
  FLightPos.z := Sin(FLightAngle) * 50.0;

  if FCameraMoved then
  begin
    CamPosArr[0] := FCamera.position.x;
    CamPosArr[1] := FCamera.position.y;
    CamPosArr[2] := FCamera.position.z;
    SetShaderValue(FLightShader, FViewPosLoc, @CamPosArr, SHADER_UNIFORM_VEC3);

    LightPosArr[0] := FLightPos.x;
    LightPosArr[1] := FLightPos.y;
    LightPosArr[2] := FLightPos.z;
    SetShaderValue(FLightShader, FLightPosLoc, @LightPosArr, SHADER_UNIFORM_VEC3);

    Ambient[0] := 0.6; Ambient[1] := 0.6; Ambient[2] := 0.6; Ambient[3] := 1.0;
    SetShaderValue(FLightShader, FAmbientLoc, @Ambient, SHADER_UNIFORM_VEC4);

    Diffuse[0] := 0.4; Diffuse[1] := 0.4; Diffuse[2] := 0.4; Diffuse[3] := 1.0;
    SetShaderValue(FLightShader, FDiffuseLoc, @Diffuse, SHADER_UNIFORM_VEC4);

    FCameraMoved := False;
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
  ShadowPos: TVector3;
  dt: Single;
begin
  BeginMode3D(FCamera);

  // 1. Floor
  BeginShaderMode(FLightShader);
  if FWallpaperTex.id > 0 then
    DrawModel(FWallpaperModel, Vector3Create(0, 0.05, 0), 1.0, WHITE)
  else
    DrawPlane(Vector3Create(0, 0.05, 0), Vector2Create(100, 100), DARKGRAY);
  EndShaderMode();

  // 2. Walls and Shadows
  for i := 0 to 3 do
  begin
    ShadowPos := FWalls[i].Position;
    ShadowPos.y := 0.1;
    if i < 2 then
    begin
      DrawFlatShadow(ShadowPos, 50.0, Fade(BLACK, 0.4));
      DrawCube(FWalls[i].Position, 100, 20, 1, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].Position, 100, 20, 1, BLACK);
    end
    else
    begin
      DrawFlatShadow(ShadowPos, 50.0, Fade(BLACK, 0.4));
      DrawCube(FWalls[i].Position, 1, 20, 100, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].Position, 1, 20, 100, BLACK);
    end;
  end;

  MaxDist := 120.0;
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  // 3. Actors
  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      // Skip projectiles here! They are drawn in UpdateProjectiles
      if (Actor.UserData <> nil) and PItemData(Actor.UserData)^.IsProjectile then
        Continue;

      Dist := Vector3Distance(Actor.Position, FCamera.position);
      if Dist > MaxDist then Continue;

      ToActor := Vector3Subtract(Actor.Position, FCamera.position);
      ToActorNorm := Vector3Normalize(ToActor);
      DotP := Vector3DotProduct(ToActorNorm, CamForward);
      if DotP < 0.5 then Continue;

      // Drop Shadow - Radius and Alpha scale dynamically with height
      if Actor.ShapeType = stSphere then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else if Actor.ShapeType = stPyramid then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)));

      // 3D Object
      BeginShaderMode(FLightShader);
      rlPushMatrix();

      Pos := Actor.Position;
      // Manual render offset to prevent visual clipping with the floor
      Pos.y := Pos.y + 0.07;
      if Actor.ShapeType = stSphere then Pos.y := Pos.y + 0.3;

      rlTranslatef(Pos.x, Pos.y, Pos.z);

      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

      if Actor.ShapeType = stSphere then
      begin
        // DrawSphere ignores radius in manual matrix mode, so we scale manually
        rlScalef(0.5, 0.5, 0.5);
        if Actor.TealGlow then
          DrawSphere(Vector3Create(0, 0, 0), 1.0, GetTealGlowColor(1.0))
        else
          DrawSphere(Vector3Create(0, 0, 0), 1.0, RED);
      end
      else if Actor.ShapeType = stPyramid then
      begin
        rlTranslatef(0.1, 0, 0.1);
        if Actor.TealGlow then
          DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, GetTealGlowColor(1.0))
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
      EndShaderMode();
    end;
  end;

  // 4. Selected Item
  if Assigned(FItemSelected) and FItemSelected.Visible then
  begin
    // Drop Shadow for Selected Item
    if FItemSelected.ShapeType = stSphere then
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.6 - (FItemSelected.Position.y * 0.15), 0.1, 0.6), EnsureRange(0.6 - (FItemSelected.Position.y * 0.15), 0.1, 0.6), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)))
    else if FItemSelected.ShapeType = stPyramid then
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.7 - (FItemSelected.Position.y * 0.15), 0.1, 0.7), EnsureRange(0.7 - (FItemSelected.Position.y * 0.15), 0.1, 0.7), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)))
    else
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.8 - (FItemSelected.Position.y * 0.15), 0.1, 0.8), EnsureRange(0.8 - (FItemSelected.Position.y * 0.15), 0.1, 0.8), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)));

    BeginShaderMode(FLightShader);
    rlPushMatrix();

    Pos := FItemSelected.Position;
    Pos.y := Pos.y + 0.07;
    if FItemSelected.ShapeType = stSphere then Pos.y := Pos.y + 0.3;
    rlTranslatef(Pos.x, Pos.y, Pos.z);

    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if FItemSelected.Quaternion.w < 1.0 then
      QuaternionToAxisAngle(FItemSelected.Quaternion, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

    if FItemSelected.ShapeType = stSphere then
    begin
      rlScalef(0.5, 0.5, 0.5);
      if FItemSelected.TealGlow then
        DrawSphere(Vector3Create(0, 0, 0), 1.0, GetTealGlowColor(1.0))
      else
        DrawSphere(Vector3Create(0, 0, 0), 1.0, RED);
    end
    else if FItemSelected.ShapeType = stPyramid then
    begin
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
    EndShaderMode();
  end;

  // 5. Update and Draw Projectiles (Shooting System)
  dt := GetFrameTime();
  UpdateProjectiles(dt);

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

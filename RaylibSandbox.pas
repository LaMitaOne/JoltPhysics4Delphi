unit RaylibSandbox;


{==============================================================================*
 *  RaylibSandbox v0.4 - VCL Wrapper for a multi-threaded Raylib + Jolt Editor
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
 *  License: Follows the licensing of the original Jolt Physics project.
 *
 *  Description:
 *    This component embeds a Raylib rendering window inside a standard Delphi
 *    VCL application. It runs the Raylib main loop and physics simulation
 *    (via JoltPhysics) in a separate background thread to prevent blocking
 *    the VCL UI thread. It implements a full 3D scene editor core.
 *
 *  Architecture:
 *    - TRaylibSandbox inherits from TWinControl to provide a HWND parent
 *      for the Raylib window.
 *    - A TThread is used to run InitWindow, the main Update/Render loop, and
 *      shutdown procedures.
 *    - The component intercepts desktop mouse inputs globally to allow
 *      dragging objects in the 3D space, manipulating the camera, and
 *      interacting with 3D Gizmos.
 *
 *  Core Features:
 *    - Spawning dynamic objects (Cubes, Spheres, Pyramids) that interact
 *      with a static floor and walls using Jolt Physics.
 *    - Orbit camera (Middle Mouse Button), Zoom (Mouse Wheel), and WASD/Arrow
 *      key panning with world boundaries.
 *    - Shooting mechanic: Fire persistent blue cannonball projectiles using
 *      the Spacebar.
 *    - Custom GLSL Lighting System implementing basic ambient and diffuse
 *      shading.
 *    - Dynamic Fake Shadows: Flat shadows drawn under objects that scale
 *      in size and opacity based on the object's Y-height.
 *    - Context Menu & Selection: Right-click context menus, TreeView sync,
 *      and Object Inspector property editing via RTTI.
 *
 *  Editor Gizmo System:
 *    - Full Translate, Rotate, and Scale Gizmos (toggled via CTRL).
 *    - Gizmos align perfectly to the object's local rotation.
 *    - Per-Axis Scaling: Gizmo arrows dynamically resize to match the
 *      object's scale on each specific axis, ensuring they are always
 *      grabbable regardless of object dimensions.
 *    - Robust Raycasting: Thick, invisible bounding boxes are used for
 *      picking Gizmo axes to guarantee reliable mouse grabbing.
 *    - Safe Editing: When a Gizmo is dragged, the target object is detached
 *      from Jolt Physics (preventing crashes or physics jitter). Changes are
 *      applied directly to Delphi variables. Upon mouse release, the object
 *      is cleanly re-attached to the physics world with its new transform.
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

  TObjectSelectedEvent = procedure(Sender: TObject; Actor: TBy3DComponent) of object;

  TItemData = record
    SpawnTime: Double;
    LastHitTime: Double;
    IsProjectile: Boolean;
    Name: string;
  end;

  TRaylibSandbox = class;

  TActorEventArgs = record
    Actor: TBy3DComponent;
    Index: Integer;
  end;

  TEngineExceptionEventArgs = record
    Message: string;
    Context: string;
    Timestamp: TDateTime;
  end;

  TActorEvent = procedure(Sender: TObject; const Args: TActorEventArgs) of object;

  TNotifyEngineEvent = procedure(Sender: TObject) of object;

  TEngineExceptionEvent = procedure(Sender: TObject; const Args: TEngineExceptionEventArgs) of object;

  TGizmoMode = (gmNone, gmTranslate, gmRotate, gmScale);

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
    FEngine: TModelEngine;
    FFloorActor: TBy3DComponent;
    FWalls: array[0..3] of TBy3DComponent;
    FWallpaperModel: TModel;
    FWallpaperTex: TTexture2D;
    FItemSelected: TBy3DComponent;
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
    FLightShader: TShader;
    FLightPos: TVector3;
    FLightPosLoc: Integer;
    FViewPosLoc: Integer;
    FAmbientLoc: Integer;
    FDiffuseLoc: Integer;
    FCameraMoved: Boolean;
    FLightAngle: Single;
    FLightSpeed: Single;
    FProjectiles: TArray<TBy3DComponent>;
    FShootCooldown: Single;
    FRightClickHandled: Boolean;
    FRightClickWasPressed: Boolean;
    FOnViewportReady: TNotifyEngineEvent;
    FOnActorSpawned: TActorEvent;
    FOnSceneCleared: TNotifyEngineEvent;
    FOnEngineException: TEngineExceptionEvent;
    FOnObjectSelected: TObjectSelectedEvent;
    FOnViewportRightClick: TNotifyEngineEvent;
    FBrushShape: TShapeType;
    FIsBrushActive: Boolean;
    FSimulationRunning: Boolean;
    FGhostPos: TVector3;
    FGhostVisible: Boolean;
    FGizmoMode: TGizmoMode;
    FGizmoAxis: Integer; // 0=None, 1=X, 2=Y, 3=Z
    FGizmoDragging: Boolean;
    FGizmoStartMouse: TVector2;
    FGizmoStartVal: TVector3;
    FGizmoStartQuat: TQuaternion;
    FCtrlWasPressed: Boolean;
    FMouseLeftPressed: Boolean;

    procedure ShootBall;
    procedure UpdateProjectiles(dt: Single);
    procedure InitScene;
    procedure InitLighting;
    procedure ProcessSpawnQueue(dt: Single);
    procedure HandleCameraInput;
    procedure HandleDesktopInput;
    procedure UpdateGame;
    procedure RenderGame;
    procedure Render3DScene;
    procedure DrawGUI;
    procedure DrawGizmo;
    procedure DrawThickRing(Axis: Integer; Radius, Thickness: Single; Color: TColorB);
    procedure UpdateGizmoInteraction;
    function CheckGizmoAxisHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckGizmoRingHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckGizmoScaleHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckButton(x, y, w, h: Integer): Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetTargetFPS(const Value: Integer);
    procedure StartThread;
    procedure StopThread;
    procedure DoViewportReady;
    procedure DoActorSpawned(Actor: TBy3DComponent; Index: Integer);
    procedure DoSceneCleared;
    procedure DoEngineException(const Msg, Context: string);
    procedure DoObjectSelected(Actor: TBy3DComponent);
    procedure DoViewportRightClick;
  protected
    procedure Resize; override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
  public
    FItems: TArray<TBy3DComponent>;
    FMouseLeftHandled: Boolean;
    function ItemCount: Integer;
    procedure ClearItems;
    procedure SpawnObjects(Count: Integer; ShapeType: TShapeType);
    procedure SetBrush(AShape: TShapeType);
    procedure SetSimulationRunning(AValue: Boolean);
    function GetSimulationRunning: Boolean;
    procedure SpawnAtMouse(Pos: TVector3);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property OnViewportReady: TNotifyEngineEvent read FOnViewportReady write FOnViewportReady;
    property OnActorSpawned: TActorEvent read FOnActorSpawned write FOnActorSpawned;
    property OnSceneCleared: TNotifyEngineEvent read FOnSceneCleared write FOnSceneCleared;
    property OnEngineException: TEngineExceptionEvent read FOnEngineException write FOnEngineException;
    property OnObjectSelected: TObjectSelectedEvent read FOnObjectSelected write FOnObjectSelected;
    property OnViewportRightClick: TNotifyEngineEvent read FOnViewportRightClick write FOnViewportRightClick;
    procedure SetSelectedActor(AActor: TBy3DComponent);
    property Engine: TModelEngine read FEngine;
  published
    property PopupMenu;
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

procedure DrawFlatShadow(position: TVector3; radius: Single; color: TColorB);
var
  segments, i: Integer;
  angle: Single;
  v1, v2: TVector3;
begin
  if radius <= 0 then
    Exit;
  segments := 24;
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
    rlVertex3f(position.x, position.y, position.z);
    rlVertex3f(v1.x, v1.y, v1.z);
    rlVertex3f(v2.x, v2.y, v2.z);
  end;
  rlEnd();
end;

{ TRaylibSandbox }

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
  FIsBrushActive := False;
  FSimulationRunning := True;
  FGhostVisible := False;
  FGizmoMode := gmTranslate;
  FGizmoAxis := 0;
  FGizmoDragging := False;
  FRightClickWasPressed := False;
  FCtrlWasPressed := False;
  FMouseLeftPressed := False;
  FMouseLeftHandled := False;
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

procedure TRaylibSandbox.SetBrush(AShape: TShapeType);
begin
  FBrushShape := AShape;
  FIsBrushActive := True;
end;

procedure TRaylibSandbox.SetSimulationRunning(AValue: Boolean);
begin
  FSimulationRunning := AValue;
end;

function TRaylibSandbox.GetSimulationRunning: Boolean;
begin
  Result := FSimulationRunning;
end;

procedure TRaylibSandbox.InitLighting;
const
  VERT: AnsiString = '#version 330' + #10 + 'in vec3 vertexPosition;' + #10 + 'in vec3 vertexNormal;' + #10 + 'in vec2 vertexTexCoord;' + #10 + 'in vec4 vertexColor;' + #10 + 'uniform mat4 mvp;' + #10 + 'uniform mat4 matModel;' + #10 + 'out vec3 vNormal;' + #10 + 'out vec2 vTexCoord;' + #10 + 'out vec4 vColor;' + #10 + 'void main()' + #10 + '{' + #10 + '  vNormal = normalize(mat3(matModel) * vertexNormal);' + #10 + '  vTexCoord = vertexTexCoord;' + #10 + '  vColor = vertexColor;' + #10 + '  gl_Position = mvp * vec4(vertexPosition, 1.0);' + #10 + '}';
  FRAG: AnsiString = '#version 330' + #10 + 'in vec3 vNormal;' + #10 + 'in vec2 vTexCoord;' + #10 + 'in vec4 vColor;' + #10 + 'uniform vec3 lightPos;' + #10 + 'uniform vec3 viewPos;' + #10 + 'uniform vec4 ambient;' + #10 + 'uniform vec4 diffuse;' + #10 + 'uniform sampler2D texture0;' + #10 + 'out vec4 finalColor;' + #10 + 'void main()' + #10 + '{' + #10 + '  vec3 lightDir = normalize(lightPos - viewPos);' + #10 + '  vec3 normal = normalize(vNormal);' + #10 + '  float diff = max(dot(normal, lightDir), 0.0);'
    + #10 + '  vec4 texColor = texture(texture0, vTexCoord);' + #10 + '  vec4 baseColor = texColor * vColor;' + #10 + '  vec4 ambientColor = ambient * baseColor;' + #10 + '  vec4 diffuseColor = diffuse * diff * baseColor;' + #10 + '  finalColor = ambientColor + diffuseColor;' + #10 + '}';
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
          DoViewportReady;
          QueryPerformanceFrequency(Freq);
          timeBeginPeriod(1);
          while not TThread.CheckTerminated do
          begin
            try
              QueryPerformanceCounter(FrameStart);
              if WindowShouldClose() then
                Break;

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
            except
              on E: Exception do
                DoEngineException(E.Message, 'RenderLoop');
            end;
          end;
        except
          on E: Exception do
            DoEngineException(E.Message, 'EngineInit');
        end;
      finally
        try
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
            DoEngineException(E.Message, 'EngineCleanup');
        end;
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
  FFloorActor := TBy3DComponent.Create('', FEngine, stBox, Vector3Create(100, 1, 100), True);
  FFloorActor.SetPosition(Vector3Create(0, -0.5, 0));
  FFloorActor.Visible := False;
  FFloorActor.Friction := 0.5;

  FWalls[0] := TBy3DComponent.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[0].SetPosition(Vector3Create(0, 10, -50));
  FWalls[0].Visible := False;

  FWalls[1] := TBy3DComponent.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[1].SetPosition(Vector3Create(0, 10, 50));
  FWalls[1].Visible := False;

  FWalls[2] := TBy3DComponent.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[2].SetPosition(Vector3Create(-50, 10, 0));
  FWalls[2].Visible := False;

  FWalls[3] := TBy3DComponent.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[3].SetPosition(Vector3Create(50, 10, 0));
  FWalls[3].Visible := False;

  FItems := nil;
end;

function TRaylibSandbox.ItemCount: Integer;
begin
  Result := Length(FItems);
end;

procedure TRaylibSandbox.ClearItems;
begin
  FLock.Enter;
  try
    FClearItemsQueued := True;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.SpawnObjects(Count: Integer; ShapeType: TShapeType);
begin
  FLock.Enter;
  try
    FSpawnQueue := FSpawnQueue + Count;
    FSpawnShape := ShapeType;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.ProcessSpawnQueue(dt: Single);
var
  Obj: TBy3DComponent;
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
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := False;
  case FSpawnShape of
    stBox:
      Data^.Name := 'Cube_' + IntToStr(oldLen);
    stSphere:
      Data^.Name := 'Sphere_' + IntToStr(oldLen);
    stPyramid:
      Data^.Name := 'Pyramid_' + IntToStr(oldLen);
  end;

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

  Obj := TBy3DComponent.Create('', FEngine, FSpawnShape, Size, False, @JPos, @JRot);
  Obj.Friction := 0.2;
  Obj.Restitution := 0.2;
  Obj.UserData := Data;
  Obj.Visible := True;

  FItems[oldLen] := Obj;
  DoActorSpawned(Obj, oldLen);
end;

procedure TRaylibSandbox.HandleCameraInput;
var
  p: TPoint;
  dt, panSpeed: Single;
  fwdX, fwdZ, rightX, rightZ: Single;
begin
  dt := GetFrameTime();
  if dt <= 0 then
    dt := 1 / 60;

  GetCursorPos(p);
  if (GetAsyncKeyState(VK_MBUTTON) and $8000) <> 0 then
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
  fwdX := -Sin(FCamYaw);
  fwdZ := -Cos(FCamYaw);
  rightX := Cos(FCamYaw);
  rightZ := -Sin(FCamYaw);
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

  FCamera.target.x := EnsureRange(FCamera.target.x, -80.0, 80.0);
  FCamera.target.z := EnsureRange(FCamera.target.z, -80.0, 80.0);

  if GetMouseWheelMove() <> 0 then
  begin
    FCamDist := EnsureRange(FCamDist - GetMouseWheelMove() * 3.0, 10, 100);
    FCameraMoved := True;
  end;

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
      if FMouseLeftPressed then
        Result := True;
    end;
  end;
end;

procedure TRaylibSandbox.ShootBall;
var
  Obj: TBy3DComponent;
  oldLen: Integer;
  Data: PItemData;
  Size: TVector3;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  CamForward, ThrowVel: TVector3;
begin
  oldLen := Length(FProjectiles);
  SetLength(FProjectiles, oldLen + 1);
  Size := Vector3Create(0.5, 0.5, 0.5);
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  JPos.x := FCamera.position.x + (CamForward.x * 2.0);
  JPos.y := FCamera.position.y - 1.0 + (CamForward.y * 2.0);
  JPos.z := FCamera.position.z + (CamForward.z * 2.0);

  JRot.x := 0;
  JRot.y := 0;
  JRot.z := 0;
  JRot.w := 1;

  Obj := TBy3DComponent.Create('', FEngine, stSphere, Size, False, @JPos, @JRot);
  Obj.Mass := 1.0;
  Obj.Friction := 0.2;
  Obj.Restitution := 0.2;
  Obj.ActivateBody;
  Obj.Visible := True;

  New(Data);
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := True;
  Obj.UserData := Data;

  ThrowVel.x := CamForward.x * 80.0;
  ThrowVel.y := CamForward.y * 80.0;
  ThrowVel.z := CamForward.z * 80.0;
  Obj.SetLinearVelocity(ThrowVel);

  FProjectiles[oldLen] := Obj;
end;

procedure TRaylibSandbox.UpdateProjectiles(dt: Single);
var
  i: Integer;
  Actor: TBy3DComponent;
  Pos, ShadowPos: TVector3;
  Rad, Alpha: Single;
begin
  for i := 0 to High(FProjectiles) do
  begin
    if FProjectiles[i] = nil then
      Continue;
    Actor := FProjectiles[i];
    Pos := Actor.Position;
    Rad := EnsureRange(0.4 - (Pos.y * 0.1), 0.05, 0.4);
    Alpha := EnsureRange(0.5 - (Pos.y * 0.02), 0, 0.5);
    ShadowPos := Vector3Create(Pos.x, 0.06, Pos.z);
    DrawCylinderEx(ShadowPos, Vector3Create(Pos.x, 0.05, Pos.z), Rad, Rad, 24, Fade(BLACK, Alpha));

    BeginShaderMode(FLightShader);
    rlPushMatrix();
    Pos.y := Pos.y + 0.3;
    rlTranslatef(Pos.x, Pos.y, Pos.z);
    rlScalef(0.3, 0.3, 0.3);
    DrawSphere(Vector3Create(0, 0, 0), 1.0, SKYBLUE);
    rlPopMatrix();
    EndShaderMode();
  end;
end;

procedure TRaylibSandbox.HandleDesktopInput;
var
  ray: TRay;
  itemBox: TBoundingBox;
  hitInfo: TRayCollision;
  i: Integer;
  dt: Single;
  groundBox: TBoundingBox;
  p: TPoint;
  CanSpawn: Boolean;
  downRay: TRay;
  downHit: TRayCollision;
  topY: Single;
  HalfH, HalfX, HalfZ, HalfY: Single;
  GScaleX, GScaleY, GScaleZ: Single;
begin
  dt := GetFrameTime();
  if FShootCooldown > 0 then
    FShootCooldown := FShootCooldown - dt;

  if Self.Tag = 1 then
  begin
    if ((GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0) or ((GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0) then
      Exit
    else
      Self.Tag := 0;
  end;

  GetCursorPos(p);
  Winapi.Windows.ScreenToClient(FRaylibWnd, p);
  FMousePos := Vector2Create(p.x, p.y);

  FMouseLeftPressed := (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0;

  if FMouseLeftPressed and not FMouseLeftHandled then
    FMouseLeftHandled := True
  else if not FMouseLeftPressed and FMouseLeftHandled then
    FMouseLeftHandled := False;

  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if not FRightClickWasPressed then
    begin
      DoViewportRightClick;
      FRightClickWasPressed := True;
    end;
  end
  else
    FRightClickWasPressed := False;

  if (GetAsyncKeyState(VK_CONTROL) and $8000) <> 0 then
  begin
    if not FCtrlWasPressed then
    begin
      if FGizmoMode = gmTranslate then
        FGizmoMode := gmRotate
      else if FGizmoMode = gmRotate then
        FGizmoMode := gmScale
      else if FGizmoMode = gmScale then
        FGizmoMode := gmTranslate;
      FCtrlWasPressed := True;
    end;
  end
  else
    FCtrlWasPressed := False;

  if (GetAsyncKeyState(VK_MBUTTON) and $8000) <> 0 then
  begin
    FGhostVisible := False;
    Exit;
  end;

  ray := GetScreenToWorldRay(FMousePos, FCamera);

  // Handle active Gizmo dragging
  if FGizmoDragging then
  begin
    UpdateGizmoInteraction;
    if not FMouseLeftPressed then
    begin
      FGizmoDragging := False;
      FGizmoAxis := 0;

      // Reattach to Jolt physics
      if Assigned(FItemSelected) then
        FItemSelected.ReattachToPhysics;
    end
    else
    begin
      // Accumulate start values so it doesn't jump
      if (FGizmoMode = gmTranslate) then
      begin
        FGizmoStartMouse := FMousePos;
        FGizmoStartVal := FItemSelected.Position;
      end
      else if (FGizmoMode = gmScale) then
      begin
        FGizmoStartMouse := FMousePos;
        FGizmoStartVal := FItemSelected.Scale;
      end;
    end;
    Exit;
  end;

  // Handle Gizmo picking if an item is selected
  if Assigned(FItemSelected) and not FIsBrushActive then
  begin
    if FMouseLeftPressed then
    begin
      // Calculate gizmo scale per axis, exactly as drawn in DrawGizmo
      GScaleX := EnsureRange(FItemSelected.Scale.x + 0.3, 1.0, 20.0);
      GScaleY := EnsureRange(FItemSelected.Scale.y + 0.3, 1.0, 20.0);
      GScaleZ := EnsureRange(FItemSelected.Scale.z + 0.3, 1.0, 20.0);

      if FGizmoMode = gmTranslate then
      begin
        // Increased RayRadius to 0.25 for much easier grabbing
        if CheckGizmoAxisHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), 0.25, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Position;
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end
      else if FGizmoMode = gmRotate then
      begin
        if CheckGizmoRingHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), 0.15, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Position;
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end
      else if FGizmoMode = gmScale then
      begin
        if CheckGizmoScaleHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), 0.25, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Scale;
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end;
    end;
  end;

  // Brush Ghost Preview & Spawn Logic
  if FIsBrushActive then
  begin
    groundBox.min := Vector3Create(-1000, -0.1, -1000);
    groundBox.max := Vector3Create(1000, 0.1, 1000);
    hitInfo := GetRayCollisionBox(ray, groundBox);

    if hitInfo.hit then
    begin
      downRay.position := Vector3Create(hitInfo.point.x, 100.0, hitInfo.point.z);
      downRay.direction := Vector3Create(0, -1, 0);
      topY := 0;

      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;
        HalfX := FItems[i].Scale.x * 0.5;
        HalfY := FItems[i].Scale.y * 0.5;
        HalfZ := FItems[i].Scale.z * 0.5;
        itemBox.min := Vector3Create(FItems[i].position.x - HalfX, FItems[i].position.y - HalfY, FItems[i].position.z - HalfZ);
        itemBox.max := Vector3Create(FItems[i].position.x + HalfX, FItems[i].position.y + HalfY, FItems[i].position.z + HalfZ);
        downHit := GetRayCollisionBox(downRay, itemBox);
        if downHit.hit and (itemBox.max.y > topY) then
          topY := itemBox.max.y;
      end;

      FGhostPos.x := hitInfo.point.x;
      FGhostPos.y := topY;
      FGhostPos.z := hitInfo.point.z;
      FGhostVisible := True;

      CanSpawn := FMouseLeftPressed;
      if CanSpawn and (FShootCooldown <= 0) then
      begin
        SpawnAtMouse(FGhostPos);
        FShootCooldown := 0.15;
        FIsBrushActive := False;
        FGhostVisible := False;
        FMouseLeftHandled := True;
      end;
    end
    else
      FGhostVisible := False;

    Exit;
  end
  else
    FGhostVisible := False;

  if CheckButton(10, 10, 40, 40) then
  begin
    SpawnObjects(30, stBox);
    FMouseLeftHandled := True;
    Exit;
  end;
  if CheckButton(60, 10, 40, 40) then
  begin
    ClearItems;
    FMouseLeftHandled := True;
    Exit;
  end;
  if CheckButton(110, 10, 40, 40) then
  begin
    SpawnObjects(30, stSphere);
    FMouseLeftHandled := True;
    Exit;
  end;
  if CheckButton(160, 10, 40, 40) then
  begin
    SpawnObjects(30, stPyramid);
    FMouseLeftHandled := True;
    Exit;
  end;

  if FSimulationRunning then
  begin
    if (GetAsyncKeyState(VK_SPACE) and $8000) <> 0 then
    begin
      if FShootCooldown <= 0 then
      begin
        ShootBall;
        FShootCooldown := 0.25;
      end;
    end;
  end;

  if FShootCooldown > 0 then
    Exit;

  // Selection logic
  if FMouseLeftPressed then
  begin
    if not FDragging then
    begin
      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;

        HalfH := FItems[i].Scale.y * 0.5;
        itemBox.min := Vector3Create(FItems[i].position.x - (FItems[i].Scale.x * 0.5), FItems[i].position.y - HalfH, FItems[i].position.z - (FItems[i].Scale.z * 0.5));
        itemBox.max := Vector3Create(FItems[i].position.x + (FItems[i].Scale.x * 0.5), FItems[i].position.y + HalfH, FItems[i].position.z + (FItems[i].Scale.z * 0.5));

        hitInfo := GetRayCollisionBox(ray, itemBox);
        if hitInfo.hit then
        begin
          if FItemSelected <> FItems[i] then
          begin
            FItemSelected := FItems[i];
            DoObjectSelected(FItemSelected);
          end;
          FDragging := True;
          Break;
        end;
      end;
    end;
  end
  else
  begin
    FDragging := False;
  end;
end;

procedure TRaylibSandbox.UpdateGizmoInteraction;
var
  MouseDeltaX, MouseDeltaY: Single;
  ScaleChange: Single;
  NewPos, EndScale: TVector3;
  RotDelta: TQuaternion;
  RotAngle: Single;
  RotAxis: TVector3;
begin
  MouseDeltaX := FMousePos.x - FGizmoStartMouse.x;
  MouseDeltaY := FMousePos.y - FGizmoStartMouse.y;

  if FGizmoMode = gmTranslate then
  begin
    NewPos := FGizmoStartVal;
    if FGizmoAxis = 1 then
      NewPos.x := FGizmoStartVal.x + (MouseDeltaX * 0.1) + (MouseDeltaY * 0.1)
    else if FGizmoAxis = 2 then
      NewPos.y := FGizmoStartVal.y + (MouseDeltaX * 0.1) - (MouseDeltaY * 0.1)
    else if FGizmoAxis = 3 then
      NewPos.z := FGizmoStartVal.z + (MouseDeltaX * 0.1) - (MouseDeltaY * 0.1);
    FItemSelected.SetPosition(NewPos);
  end
  else if FGizmoMode = gmRotate then
  begin
    RotAxis := Vector3Create(0, 0, 0);
    if FGizmoAxis = 1 then
      RotAxis.x := 1
    else if FGizmoAxis = 2 then
      RotAxis.y := 1
    else if FGizmoAxis = 3 then
      RotAxis.z := 1;

    RotAngle := ((MouseDeltaX) + (MouseDeltaY)) * 0.25;

    if Abs(RotAngle) > 0.1 then
    begin
      RotDelta := QuaternionFromAxisAngle(RotAxis, DegToRad(RotAngle));
      FItemSelected.SetRotation(QuaternionMultiply(FGizmoStartQuat, RotDelta));
      FGizmoStartMouse := FMousePos;
      FGizmoStartQuat := FItemSelected.Quaternion;
    end;
  end
  // --- SCALE ---
  else if FGizmoMode = gmScale then
  begin
    // Mouse Right or Down = Larger. Mouse Left or Up = Smaller.
    // Note: MouseDeltaY is inverted because screen Y goes down, but we want to pull UP to make it larger.
    ScaleChange := (MouseDeltaX * 0.05) + (-MouseDeltaY * 0.05);

    EndScale := FGizmoStartVal;
    if FGizmoAxis = 1 then
      EndScale.x := EnsureRange(EndScale.x + ScaleChange, 0.05, 100)
    else if FGizmoAxis = 2 then
      EndScale.y := EnsureRange(EndScale.y + ScaleChange, 0.05, 100)
    else if FGizmoAxis = 3 then
      EndScale.z := EnsureRange(EndScale.z + ScaleChange, 0.05, 100);

    FItemSelected.Scale := EndScale;
  end;
end;

function TRaylibSandbox.CheckGizmoAxisHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
var
  CylEnd: TVector3;
  Box: TBoundingBox;
  Hit: TRayCollision;
begin
  Result := False;
  Axis := 0;

  CylEnd := Vector3Add(Pos, Vector3Create(Scale.x, 0, 0));
  Box.min := Vector3Create(Pos.x, Pos.y - RayRadius, Pos.z - RayRadius);
  Box.max := Vector3Create(CylEnd.x + RayRadius, Pos.y + RayRadius, Pos.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  CylEnd := Vector3Add(Pos, Vector3Create(0, Scale.y, 0));
  Box.min := Vector3Create(Pos.x - RayRadius, Pos.y, Pos.z - RayRadius);
  Box.max := Vector3Create(Pos.x + RayRadius, CylEnd.y + RayRadius, Pos.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  CylEnd := Vector3Add(Pos, Vector3Create(0, 0, Scale.z));
  Box.min := Vector3Create(Pos.x - RayRadius, Pos.y - RayRadius, Pos.z);
  Box.max := Vector3Create(Pos.x + RayRadius, Pos.y + RayRadius, CylEnd.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 3;
    Exit;
  end;
end;

function TRaylibSandbox.CheckGizmoRingHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
var
  Box: TBoundingBox;
  Hit: TRayCollision;
begin
  Result := False;
  Axis := 0;

  Box.min := Vector3Create(Pos.x - RayRadius, Pos.y - Scale.y, Pos.z - Scale.z);
  Box.max := Vector3Create(Pos.x + RayRadius, Pos.y + Scale.y, Pos.z + Scale.z);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  Box.min := Vector3Create(Pos.x - Scale.x, Pos.y - RayRadius, Pos.z - Scale.z);
  Box.max := Vector3Create(Pos.x + Scale.x, Pos.y + RayRadius, Pos.z + Scale.z);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  Box.min := Vector3Create(Pos.x - Scale.x, Pos.y - Scale.y, Pos.z - RayRadius);
  Box.max := Vector3Create(Pos.x + Scale.x, Pos.y + Scale.y, Pos.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 3;
    Exit;
  end;
end;

function TRaylibSandbox.CheckGizmoScaleHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
var
  BoxEnd: TVector3;
  Box: TBoundingBox;
  Hit: TRayCollision;
begin
  Result := False;
  Axis := 0;

  BoxEnd := Vector3Add(Pos, Vector3Create(Scale.x, 0, 0));
  Box.min := Vector3Create(BoxEnd.x - RayRadius, Pos.y - RayRadius, Pos.z - RayRadius);
  Box.max := Vector3Create(BoxEnd.x + RayRadius, Pos.y + RayRadius, Pos.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  BoxEnd := Vector3Add(Pos, Vector3Create(0, Scale.y, 0));
  Box.min := Vector3Create(Pos.x - RayRadius, BoxEnd.y - RayRadius, Pos.z - RayRadius);
  Box.max := Vector3Create(Pos.x + RayRadius, BoxEnd.y + RayRadius, Pos.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  BoxEnd := Vector3Add(Pos, Vector3Create(0, 0, Scale.z));
  Box.min := Vector3Create(Pos.x - RayRadius, Pos.y - RayRadius, BoxEnd.z - RayRadius);
  Box.max := Vector3Create(Pos.x + RayRadius, Pos.y + RayRadius, BoxEnd.z + RayRadius);
  Hit := GetRayCollisionBox(Ray, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 3;
    Exit;
  end;
end;

procedure TRaylibSandbox.SetSelectedActor(AActor: TBy3DComponent);
begin
  FItemSelected := AActor;
end;

procedure TRaylibSandbox.SpawnAtMouse(Pos: TVector3);
var
  Obj: TBy3DComponent;
  oldLen: Integer;
  Data: PItemData;
  Size: TVector3;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
begin
  oldLen := Length(FItems);
  SetLength(FItems, oldLen + 1);

  New(Data);
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := False;
  case FBrushShape of
    stBox:
      Data^.Name := 'Cube_' + IntToStr(oldLen);
    stSphere:
      Data^.Name := 'Sphere_' + IntToStr(oldLen);
    stPyramid:
      Data^.Name := 'Pyramid_' + IntToStr(oldLen);
  end;

  Size := Vector3Create(1, 1, 1);
  if FBrushShape = stSphere then
    Size := Vector3Create(0.5, 0.5, 0.5)
  else if FBrushShape = stPyramid then
    Size := Vector3Create(0.8, 1.5, 0.8);

  JPos.x := Pos.x;
  JPos.y := Pos.y + (Size.y * 0.5);
  JPos.z := Pos.z;

  JRot.x := 0;
  JRot.y := 0;
  JRot.z := 0;
  JRot.w := 1;

  Obj := TBy3DComponent.Create('', FEngine, FBrushShape, Size, False, @JPos, @JRot);

  Obj.Friction := 1.0;
  Obj.Restitution := 0.0;
  Obj.UserData := Data;
  Obj.Visible := True;

  FItems[oldLen] := Obj;
  DoActorSpawned(Obj, oldLen);
end;

procedure TRaylibSandbox.UpdateGame;
var
  dt: single;
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
    FLock.Enter;
    try
      FDragging := False;
      FItemSelected := nil;
      FSpawnQueue := 0;
      for i := High(FItems) downto 0 do
      begin
        if Assigned(FItems[i]) then
        begin
          FItems[i].Visible := False;
          FItems[i].Free;
          FItems[i] := nil;
        end;
      end;
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
      DoSceneCleared;
    finally
      FLock.Leave;
    end;
  end;

  dt := GetFrameTime();
  HandleCameraInput;
  HandleDesktopInput;
  ProcessSpawnQueue(dt);

  if FSimulationRunning then
  begin
    try
      FEngine.Update(dt);
    except
      on E: Exception do
        DoEngineException(E.Message, 'PhysicsUpdate');
    end;
  end;

  if (FSceneStartTime > 0) and (GetTime() - FSceneStartTime > 1.0) then
    FSceneStartTime := 0;

  if (FSceneStartTime = 0) and (FHUDAnimY < 0) then
  begin
    FHUDAnimY := FHUDAnimY * (1.0 - dt * 6.0);
    if FHUDAnimY > -0.5 then
      FHUDAnimY := 0;
  end;

  for i := 0 to High(FItems) do
  begin
    if Assigned(FItems[i]) and (FItems[i].UserData <> nil) then
    begin
      if PItemData(FItems[i].UserData)^.IsProjectile then
        Continue;

      ItemVel := FItems[i].GetLinearVelocity;
      if (Abs(ItemVel.x) > 2.0) or (Abs(ItemVel.y) > 2.0) or (Abs(ItemVel.z) > 2.0) then
        PItemData(FItems[i].UserData)^.LastHitTime := GetTime();

      IsTeal := (GetTime() - PItemData(FItems[i].UserData)^.LastHitTime) < 0.3;
      FItems[i].TealGlow := IsTeal;
    end;
  end;

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

    Ambient[0] := 0.6;
    Ambient[1] := 0.6;
    Ambient[2] := 0.6;
    Ambient[3] := 1.0;
    SetShaderValue(FLightShader, FAmbientLoc, @Ambient, SHADER_UNIFORM_VEC4);

    Diffuse[0] := 0.4;
    Diffuse[1] := 0.4;
    Diffuse[2] := 0.4;
    Diffuse[3] := 1.0;
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
  Actor: TBy3DComponent;
  Dist, MaxDist: Single;
  CamForward, ToActor, ToActorNorm: TVector3;
  Axis: TVector3;
  Angle: Single;
  DotP: Single;
  Pos: TVector3;
  ShadowPos: TVector3;
  dt: Single;

  function GetActorColor(A: TBy3DComponent): TColorB;
  const
    COL_CUBE: TColorB = (
    r: 230;
    g: 41;
    b: 55;
    A: 255
  );
    COL_PYRAMID: TColorB = (
    r: 255;
    g: 161;
    b: 0;
    A: 255
  );
    COL_SPHERE: TColorB = (
    r: 179;
    g: 71;
    b: 217;
    A: 255
  );
    COL_TEAL: TColorB = (
    r: 64;
    g: 224;
    b: 208;
    A: 255
  );
  begin
    if A.TealGlow then
      Exit(COL_TEAL);
    case A.ShapeType of
      stBox:
        Exit(COL_CUBE);
      stPyramid:
        Exit(COL_PYRAMID);
      stSphere:
        Exit(COL_SPHERE);
    else
      Exit(WHITE);
    end;
  end;

begin
  BeginMode3D(FCamera);

  BeginShaderMode(FLightShader);
  if FWallpaperTex.id > 0 then
    DrawModel(FWallpaperModel, Vector3Create(0, 0.05, 0), 1.0, WHITE)
  else
    DrawPlane(Vector3Create(0, 0.05, 0), Vector2Create(100, 100), DARKGRAY);
  EndShaderMode();

  for i := 0 to 3 do
  begin
    ShadowPos := FWalls[i].position;
    ShadowPos.y := 0.1;
    if i < 2 then
    begin
      DrawFlatShadow(ShadowPos, 50.0, Fade(BLACK, 0.4));
      DrawCube(FWalls[i].position, 100, 20, 1, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].position, 100, 20, 1, BLACK);
    end
    else
    begin
      DrawFlatShadow(ShadowPos, 50.0, Fade(BLACK, 0.4));
      DrawCube(FWalls[i].position, 1, 20, 100, Fade(DARKGRAY, 0.8));
      DrawCubeWires(FWalls[i].position, 1, 20, 100, BLACK);
    end;
  end;

  MaxDist := 120.0;
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      if (Actor.UserData <> nil) and PItemData(Actor.UserData)^.IsProjectile then
        Continue;
      Dist := Vector3Distance(Actor.Position, FCamera.position);
      if Dist > MaxDist then
        Continue;
      ToActor := Vector3Subtract(Actor.Position, FCamera.position);
      ToActorNorm := Vector3Normalize(ToActor);
      DotP := Vector3DotProduct(ToActorNorm, CamForward);
      if DotP < 0.5 then
        Continue;

      if Actor.ShapeType = stSphere then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else if Actor.ShapeType = stPyramid then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)));

      BeginShaderMode(FLightShader);
      rlPushMatrix();
      Pos := Actor.Position;
      Pos.y := Pos.y + 0.07;
      if Actor.ShapeType = stSphere then
        Pos.y := Pos.y + 0.3;
      rlTranslatef(Pos.x, Pos.y, Pos.z);
      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

      if Actor.ShapeType = stSphere then
      begin
        DrawSphere(Vector3Create(0, 0, 0), Actor.Scale.x * 0.5, GetActorColor(Actor));
      end
      else if Actor.ShapeType = stPyramid then
      begin
        rlTranslatef(0.1, 0, 0.1);
        DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, Actor.Scale.x, 4, GetActorColor(Actor));
        DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, Actor.Scale.x, 4, BLACK);
      end
      else
      begin
        DrawCube(Vector3Create(0, 0, 0), Actor.Scale.x, Actor.Scale.y, Actor.Scale.z, GetActorColor(Actor));
        DrawCubeWires(Vector3Create(0, 0, 0), Actor.Scale.x, Actor.Scale.y, Actor.Scale.z, BLACK);
      end;
      rlPopMatrix();
      EndShaderMode();
    end;
  end;

  if Assigned(FItemSelected) and FItemSelected.Visible then
  begin
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
    if FItemSelected.ShapeType = stSphere then
      Pos.y := Pos.y + 0.3;
    rlTranslatef(Pos.x, Pos.y, Pos.z);
    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if FItemSelected.Quaternion.w < 1.0 then
      QuaternionToAxisAngle(FItemSelected.Quaternion, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

    if FItemSelected.ShapeType = stSphere then
    begin
      DrawSphere(Vector3Create(0, 0, 0), FItemSelected.Scale.x * 0.5, GetActorColor(FItemSelected));
    end
    else if FItemSelected.ShapeType = stPyramid then
    begin
      rlTranslatef(0.1, 0, 0.1);
      DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, FItemSelected.Scale.x, 4, GetActorColor(FItemSelected));
      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, FItemSelected.Scale.x, 4, YELLOW);
    end
    else
    begin
      DrawCube(Vector3Create(0, 0, 0), FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z, GetActorColor(FItemSelected));
      DrawCubeWires(Vector3Create(0, 0, 0), FItemSelected.Scale.x + 0.05, FItemSelected.Scale.y + 0.05, FItemSelected.Scale.z + 0.05, YELLOW);
    end;
    rlPopMatrix();
    EndShaderMode();
  end;

  if FIsBrushActive and FGhostVisible then
  begin
    rlPushMatrix();
    var SurfaceY: Single := FGhostPos.y + 0.1;

    if FBrushShape = stBox then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawCube(Vector3Create(0, 0.5, 0), 1, 1, 1, Fade(WHITE, 0.4));
      DrawCubeWires(Vector3Create(0, 0.5, 0), 1, 1, 1, YELLOW);
    end
    else if FBrushShape = stSphere then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawSphere(Vector3Create(0, 0.5, 0), 0.5, Fade(WHITE, 0.4));
      DrawSphereWires(Vector3Create(0, 0.5, 0), 0.5, 16, 16, YELLOW);
    end
    else if FBrushShape = stPyramid then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawCylinderEx(Vector3Create(0, 1.5, 0), Vector3Create(0, 0, 0), 0.0, 0.5, 4, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 1.5, 0), Vector3Create(0, 0, 0), 0.0, 0.5, 4, YELLOW);
    end;

    rlPopMatrix();
  end;

  if Assigned(FItemSelected) and not FIsBrushActive then
    DrawGizmo;

  dt := GetFrameTime();
  UpdateProjectiles(dt);
  EndMode3D();
end;

procedure TRaylibSandbox.DrawThickRing(Axis: Integer; Radius, Thickness: Single; Color: TColorB);
var
  i: Integer;
  Segments: Integer;
  Angle: Single;
  V1, V2: TVector3;
begin
  Segments := 32;
  for i := 0 to Segments - 1 do
  begin
    Angle := (i / Segments) * 2.0 * PI;
    V1 := Vector3Create(0, 0, 0);
    V2 := Vector3Create(0, 0, 0);

    if Axis = 1 then // X-Axis
    begin
      V1.y := Cos(Angle) * Radius;
      V1.z := Sin(Angle) * Radius;
      Angle := ((i + 1) / Segments) * 2.0 * PI;
      V2.y := Cos(Angle) * Radius;
      V2.z := Sin(Angle) * Radius;
    end
    else if Axis = 2 then // Y-Axis
    begin
      V1.x := Cos(Angle) * Radius;
      V1.z := Sin(Angle) * Radius;
      Angle := ((i + 1) / Segments) * 2.0 * PI;
      V2.x := Cos(Angle) * Radius;
      V2.z := Sin(Angle) * Radius;
    end
    else if Axis = 3 then // Z-Axis
    begin
      V1.x := Cos(Angle) * Radius;
      V1.y := Sin(Angle) * Radius;
      Angle := ((i + 1) / Segments) * 2.0 * PI;
      V2.x := Cos(Angle) * Radius;
      V2.y := Sin(Angle) * Radius;
    end;

    DrawCylinderEx(V1, V2, Thickness, Thickness, 6, Color);
  end;
end;

procedure TRaylibSandbox.DrawGizmo;
var
  Pos: TVector3;
  ScaleX, ScaleY, ScaleZ: Single;
  ColX, ColY, ColZ: TColorB;
  MatLoc: TMatrix;
begin
  Pos := FItemSelected.Position;

  // Calculate gizmo length per axis based on the object's actual scale.
  // This ensures the arrow sticks out exactly relative to the object's size on that axis.
  ScaleX := EnsureRange(FItemSelected.Scale.x + 1.0, 1.0, 20.0);
  ScaleY := EnsureRange(FItemSelected.Scale.y + 1.0, 1.0, 20.0);
  ScaleZ := EnsureRange(FItemSelected.Scale.z + 1.0, 1.0, 20.0);

  ColX := RED;
  ColY := GREEN;
  ColZ := BLUE;

  // Highlight the active axis yellow while dragging
  if FGizmoDragging then
  begin
    if FGizmoAxis = 1 then
      ColX := YELLOW
    else if FGizmoAxis = 2 then
      ColY := YELLOW
    else if FGizmoAxis = 3 then
      ColZ := YELLOW;
  end;

  rlPushMatrix();
  rlTranslatef(Pos.x, Pos.y, Pos.z);

  // Apply the item's rotation so the gizmo aligns with the object's local axes
  MatLoc := QuaternionToMatrix(FItemSelected.Quaternion);
  rlMultMatrixf(@MatLoc);

  if FGizmoMode = gmTranslate then
  begin
    // Draw axes lines (cylinders)
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(ScaleX, 0, 0), 0.08, 0.08, 8, ColX);
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(0, ScaleY, 0), 0.08, 0.08, 8, ColY);
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(0, 0, ScaleZ), 0.08, 0.08, 8, ColZ);

    // Draw arrow tips (cones)
    DrawCylinderEx(Vector3Create(ScaleX, 0, 0), Vector3Create(ScaleX + 0.3, 0, 0), 0.2, 0.0, 8, ColX);
    DrawCylinderEx(Vector3Create(0, ScaleY, 0), Vector3Create(0, ScaleY + 0.3, 0), 0.2, 0.0, 8, ColY);
    DrawCylinderEx(Vector3Create(0, 0, ScaleZ), Vector3Create(0, 0, ScaleZ + 0.3), 0.2, 0.0, 8, ColZ);
  end
  else if FGizmoMode = gmRotate then
  begin
    // Draw rotation rings
    DrawThickRing(1, ScaleX, 0.06, ColX);
    DrawThickRing(2, ScaleY, 0.06, ColY);
    DrawThickRing(3, ScaleZ, 0.06, ColZ);
  end
  else if FGizmoMode = gmScale then
  begin
    // Draw axes lines (cylinders)
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(ScaleX, 0, 0), 0.08, 0.08, 8, ColX);
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(0, ScaleY, 0), 0.08, 0.08, 8, ColY);
    DrawCylinderEx(Vector3Create(0, 0, 0), Vector3Create(0, 0, ScaleZ), 0.08, 0.08, 8, ColZ);

    // Draw scale handles (cubes) at the ends
    DrawCube(Vector3Create(ScaleX, 0, 0), 0.2, 0.2, 0.2, ColX);
    DrawCube(Vector3Create(0, ScaleY, 0), 0.2, 0.2, 0.2, ColY);
    DrawCube(Vector3Create(0, 0, ScaleZ), 0.2, 0.2, 0.2, ColZ);

    // Draw center cube
    DrawCube(Vector3Create(0, 0, 0), 0.2, 0.2, 0.2, WHITE);
  end;

  rlPopMatrix();
end;

procedure TRaylibSandbox.DrawGUI;
var
  fpsBuf: AnsiString;
  YOffset: Integer;
  ModeStr: AnsiString;
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

  if FSimulationRunning then
    DrawText('SIMULATION RUNNING', 10, GetScreenHeight() - 60, 20, GREEN)
  else
    DrawText('SIMULATION PAUSED', 10, GetScreenHeight() - 60, 20, YELLOW);

  case FGizmoMode of
    gmTranslate:
      ModeStr := 'Mode: Translate (Move)';
    gmRotate:
      ModeStr := 'Mode: Rotate (Turn)';
    gmScale:
      ModeStr := 'Mode: Scale (Resize)';
  else
    ModeStr := 'Mode: None';
  end;
  DrawText(PAnsiChar(ModeStr), 10, GetScreenHeight() - 90, 20, RAYWHITE);
end;

{ Event Dispatchers }

procedure TRaylibSandbox.DoViewportReady;
begin
  if Assigned(FOnViewportReady) then
    TThread.Queue(nil,
      procedure
      begin
        FOnViewportReady(Self);
      end);
end;

procedure TRaylibSandbox.DoActorSpawned(Actor: TBy3DComponent; Index: Integer);
var
  Args: TActorEventArgs;
begin
  if Assigned(FOnActorSpawned) then
  begin
    Args.Actor := Actor;
    Args.Index := Index;
    TThread.Queue(nil,
      procedure
      begin
        FOnActorSpawned(Self, Args);
      end);
  end;
end;

procedure TRaylibSandbox.DoSceneCleared;
begin
  if Assigned(FOnSceneCleared) then
    TThread.Queue(nil,
      procedure
      begin
        FOnSceneCleared(Self);
      end);
end;

procedure TRaylibSandbox.DoEngineException(const Msg, Context: string);
var
  Args: TEngineExceptionEventArgs;
begin
  if Assigned(FOnEngineException) then
  begin
    Args.Message := Msg;
    Args.Context := Context;
    Args.Timestamp := Now;
    TThread.Queue(nil,
      procedure
      begin
        FOnEngineException(Self, Args);
      end);
  end
  else
    OutputDebugString(PChar('[' + Context + '] ' + Msg));
end;

procedure TRaylibSandbox.DoObjectSelected(Actor: TBy3DComponent);
begin
  if Assigned(FOnObjectSelected) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        FOnObjectSelected(Self, Actor);
      end);
  end;
end;

procedure TRaylibSandbox.DoViewportRightClick;
begin
  if Assigned(FOnViewportRightClick) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        FOnViewportRightClick(Self);
      end);
  end;
end;

end.


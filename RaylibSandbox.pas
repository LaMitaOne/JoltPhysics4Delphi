unit RaylibSandbox;

{==============================================================================*
 *  RaylibSandbox v0.52 - VCL Wrapper for a multi-threaded Raylib + Jolt Editor
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
 *    - Spawning dynamic objects (Cubes, Spheres, Pyramids, Capsules, Prisms) that interact
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
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
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

  TObjectSelectedEvent = procedure(Sender: TObject; Actor: TA3DComponent) of object;

  TItemData = record
    SpawnTime: Double;
    LastHitTime: Double;
    IsProjectile: Boolean;
    Name: string;
  end;

  TRaylibSandbox = class;

  TActorEventArgs = record
    Actor: TA3DComponent;
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
    FFloorActor: TA3DComponent;
    FWalls: array[0..3] of TA3DComponent;
    FWallpaperModel: TModel;
    FWallpaperTex: TTexture2D;
    FItemSelected: TA3DComponent;
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
    FProjectiles: TArray<TA3DComponent>;
    FShootCooldown: Single;
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
    FGizmoAxis: Integer;
    FGizmoHoverAxis: Integer;
    FGizmoDragging: Boolean;
    FGizmoStartMouse: TVector2;
    FGizmoStartVal: TVector3;
    FGizmoStartQuat: TQuaternion;
    FCtrlWasPressed: Boolean;
    FMouseLeftPressed: Boolean;
    FHighlightCollision: Boolean;
    FActiveBodies: Integer;
    FLastPhysicsTime: Single;
    FSpawnButton1WasDown: Boolean;
    FSpawnButton2WasDown: Boolean;
    FSpawnButton3WasDown: Boolean;
    FSpawnButton4WasDown: Boolean;
    FSpawnButton5WasDown: Boolean;
    // Render Settings
    FFrustumCulling: Boolean;
    FDistanceCulling: Boolean;
    // Native Popup System
    FPopupOpen: Boolean;
    FPopupPos: TVector2;
    FPopupSegments: array of string;
    FPopupHoverIndex: Integer;
    FPopupCloseLock: Boolean;
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
    procedure DrawThickRingAt(Center, NormalAxis: TVector3; Radius, Thickness: Single; Color: TColorB);
    procedure UpdateGizmoInteraction;
    function CheckGizmoAxisHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckGizmoRingHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckGizmoScaleHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
    function CheckButton(x, y, w, h: Integer): Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetTargetFPS(const Value: Integer);
    procedure SetHighlightCollision(const Value: Boolean);
    procedure StartThread;
    procedure StopThread;
    procedure DoViewportReady;
    procedure DoActorSpawned(Actor: TA3DComponent; Index: Integer);
    procedure DoSceneCleared;
    procedure DoEngineException(const Msg, Context: string);
    procedure DoObjectSelected(Actor: TA3DComponent);
    procedure DoViewportRightClick;
    procedure DrawNativePopup;
    procedure HandlePopupInput;
    procedure ExecutePopupAction(Index: Integer);
    procedure SetFrustumCulling(const Value: Boolean);
    procedure SetDistanceCulling(const Value: Boolean);
  protected
    procedure Resize; override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
  public
    FItems: TArray<TA3DComponent>;
    FMouseLeftHandled: Boolean;
    function ItemCount: Integer;
    procedure ClearItems;
    procedure DeleteSelectedActor;
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
    procedure SetSelectedActor(AActor: TA3DComponent);
    procedure SetGizmoMode(AMode: TGizmoMode);
    property Engine: TModelEngine read FEngine;
    property FrustumCulling: Boolean read FFrustumCulling write SetFrustumCulling;
    property DistanceCulling: Boolean read FDistanceCulling write SetDistanceCulling;
  published
    property Align;
    property Anchors;
    property Visible;
    property Active: Boolean read FActive write SetActive default False;
    property TargetFPS: Integer read FTargetFPS write SetTargetFPS default 60;
    property HighlightCollision: Boolean read FHighlightCollision write SetHighlightCollision;
    property ActiveBodies: Integer read FActiveBodies;
    property LastPhysicsTime: Single read FLastPhysicsTime;
  end;

implementation

const
  // Define color constant for the Prism shape globally in this unit
  COL_PRISM: TColorB = (
    r: 102;
    g: 205;
    b: 170;
    A: 255
  );

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
  FHighlightCollision := False;
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
  FIsBrushActive := false;
  FSimulationRunning := True;
  FGhostVisible := False;
  FGizmoMode := gmTranslate;
  FGizmoAxis := 0;
  FGizmoHoverAxis := 0;
  FGizmoDragging := False;
  FRightClickWasPressed := False;
  FCtrlWasPressed := False;
  FMouseLeftPressed := False;
  FMouseLeftHandled := False;
  FPopupOpen := False;
  FFrustumCulling := True;
  FDistanceCulling := True;
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

procedure TRaylibSandbox.SetHighlightCollision(const Value: Boolean);
begin
  if FHighlightCollision <> Value then
    FHighlightCollision := Value;
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

procedure TRaylibSandbox.SetGizmoMode(AMode: TGizmoMode);
begin
  FGizmoMode := AMode;
end;

procedure TRaylibSandbox.SetFrustumCulling(const Value: Boolean);
begin
  FFrustumCulling := Value;
end;

procedure TRaylibSandbox.SetDistanceCulling(const Value: Boolean);
begin
  FDistanceCulling := Value;
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
          SetConfigFlags(FLAG_MSAA_4X_HINT or FLAG_WINDOW_RESIZABLE);
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
  FFloorActor := TA3DComponent.Create('', FEngine, stBox, Vector3Create(100, 1, 100), True);
  FFloorActor.SetPosition(Vector3Create(0, -0.5, 0));
  FFloorActor.Visible := False;
  FFloorActor.Friction := 0.5;
  FWalls[0] := TA3DComponent.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[0].SetPosition(Vector3Create(0, 10, -50));
  FWalls[0].Visible := False;
  FWalls[1] := TA3DComponent.Create('', FEngine, stBox, Vector3Create(100, 20, 1), True);
  FWalls[1].SetPosition(Vector3Create(0, 10, 50));
  FWalls[1].Visible := False;
  FWalls[2] := TA3DComponent.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
  FWalls[2].SetPosition(Vector3Create(-50, 10, 0));
  FWalls[2].Visible := False;
  FWalls[3] := TA3DComponent.Create('', FEngine, stBox, Vector3Create(1, 20, 100), True);
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
    FGizmoMode := gmNone;
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
  Obj: TA3DComponent;
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
  // Process a fixed amount per frame to avoid freezing the thread,
  // but independent of variable time / FPS limits
  if FSpawnTimer > 0 then
  begin
    FSpawnTimer := FSpawnTimer - dt;
    Exit;
  end;
  FSpawnQueue := FSpawnQueue - 1;
  FSpawnTimer := 0.04; // Fixed 40ms delay between spawns
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
    stCapsule:
      Data^.Name := 'Capsule_' + IntToStr(oldLen);
    stPrism:
      Data^.Name := 'Prism_' + IntToStr(oldLen);
  end;
  // Uniform size of 1.0 matching standard cube scale
  Size := Vector3Create(1, 1, 1);
  if FSpawnShape = stPrism then
    Size := Vector3Create(1, 1.5, 1)
  else if FSpawnShape = stPyramid then
    Size := Vector3Create(1, 1.5, 1);
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
  Obj := TA3DComponent.Create('', FEngine, FSpawnShape, Size, False, @JPos, @JRot);
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
  Obj: TA3DComponent;
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
  Obj := TA3DComponent.Create('', FEngine, stSphere, Size, False, @JPos, @JRot);
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
  Actor: TA3DComponent;
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
  TargetY, t: Single;
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

  if (GetAsyncKeyState(VK_CONTROL) and $8000) <> 0 then
  begin
    if not FCtrlWasPressed then
    begin
      if FGizmoMode = gmTranslate then
        FGizmoMode := gmRotate
      else if FGizmoMode = gmRotate then
        FGizmoMode := gmScale
      else if FGizmoMode = gmScale then
        FGizmoMode := gmNone // <-- Neu: Wechsel zurück zu Drag & Throw
      else if FGizmoMode = gmNone then
        FGizmoMode := gmTranslate; // <-- Neu: Von Drag wieder zu Translate
      FCtrlWasPressed := True;
    end;
  end
  else
    FCtrlWasPressed := False;

  // Intercept native popup input
  if FPopupOpen then
  begin
    HandlePopupInput;
    Exit;
  end;
  // Intercept right click for popup
  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if not FRightClickWasPressed then
    begin
      // Allow popup opening regardless of object selection if not in brush mode
      if not FIsBrushActive and (FGizmoMode <> gmNone) then
      begin
        FPopupOpen := True;
        FPopupPos := FMousePos;
        // Calculate ground position before opening popup so spawned items land where clicked
        ray := GetScreenToWorldRay(FMousePos, FCamera);
        groundBox.min := Vector3Create(-1000, -0.1, -1000);
        groundBox.max := Vector3Create(1000, 0.1, 1000);
        hitInfo := GetRayCollisionBox(ray, groundBox);
        if hitInfo.hit then
        begin
          FGhostPos.x := hitInfo.point.x;
          FGhostPos.y := 0; // Exact surface point
          FGhostPos.z := hitInfo.point.z;
        end;
        // Add edit actions only if an item is selected
        if Assigned(FItemSelected) then
        begin
          SetLength(FPopupSegments, 2);
          FPopupSegments[0] := 'Delete';
          FPopupSegments[1] := 'Duplicate';
        end
        else
        begin
          SetLength(FPopupSegments, 0);
        end;
        FPopupHoverIndex := -1;
        FPopupCloseLock := True;
      end;
      FRightClickWasPressed := True;
    end;
  end
  else
    FRightClickWasPressed := False;
  // Shooting logic (always allowed if sim is running)
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
  if (GetAsyncKeyState(VK_MBUTTON) and $8000) <> 0 then
  begin
    FGhostVisible := False;
    Exit;
  end;
  ray := GetScreenToWorldRay(FMousePos, FCamera);
  // --- DRAG & THROW MODE (Test Tool) ---
  if FGizmoMode = gmNone then
  begin
    // If we are already dragging, keep the target updated
    if FDragging and Assigned(FItemSelected) then
    begin
      if FMouseLeftPressed then
      begin
        if Abs(ray.direction.y) > 0.0001 then
        begin
          TargetY := FItemSelected.Position.y + 0.5;
          t := (TargetY - ray.position.y) / ray.direction.y;
          if t > 0 then
          begin
            FDragTargetPos.x := ray.position.x + ray.direction.x * t;
            FDragTargetPos.z := ray.position.z + ray.direction.z * t;
          end;
        end;
      end
      else
      begin
        FDragging := False;
      end;
    end
    // Only select a new object to drag if we are NOT already dragging
    else if FMouseLeftPressed then
    begin
      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;
        // Calculate ACTUAL bounding box based on scale
        HalfX := FItems[i].Scale.x * 0.5;
        HalfY := FItems[i].Scale.y * 0.5;
        HalfZ := FItems[i].Scale.z * 0.5;
        itemBox.min := Vector3Create(FItems[i].position.x - HalfX, FItems[i].position.y - HalfY, FItems[i].position.z - HalfZ);
        itemBox.max := Vector3Create(FItems[i].position.x + HalfX, FItems[i].position.y + HalfY, FItems[i].position.z + HalfZ);
        hitInfo := GetRayCollisionBox(ray, itemBox);
        if hitInfo.hit then
        begin
          if FItemSelected <> FItems[i] then
          begin
            FItemSelected := FItems[i];
            DoObjectSelected(FItemSelected);
          end;
          FItemSelected.ActivateBody;
          FDragging := True;
          Break;
        end;
      end;
    end;
    Exit; // IMPORTANT: Skip the rest of the input handling completely!
  end;
  // --- GIZMO MODE ---
  if FGizmoDragging then
  begin
    UpdateGizmoInteraction;
    if not FMouseLeftPressed then
    begin
      FGizmoDragging := False;
      FGizmoAxis := 0;
      if Assigned(FItemSelected) then
        FItemSelected.ReattachToPhysics;
    end
    else
    begin
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
  if Assigned(FItemSelected) and not FIsBrushActive then
  begin
    if FMouseLeftPressed then
    begin
      // Calculate dynamic scale for gizmo bounding boxes, matching object scale + offset so they stay grabbable
      GScaleX := EnsureRange(FItemSelected.Scale.x + 1.0, 1.0, 100.0);
      GScaleY := EnsureRange(FItemSelected.Scale.y + 1.0, 1.0, 100.0);
      GScaleZ := EnsureRange(FItemSelected.Scale.z + 1.0, 1.0, 100.0);
      if FGizmoMode = gmTranslate then
      begin
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
        if CheckGizmoRingHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), 0.2, ray, FGizmoAxis) then
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
  // Mass spawn buttons in HUD (Nur einmal pro Mausklick auslösen!)
  if CheckButton(0, 10, 40, 40) then
  begin
    if not FSpawnButton1WasDown then
    begin
      SpawnObjects(30, stBox);
      FSpawnButton1WasDown := True;
    end;
    FMouseLeftHandled := True;
    Exit;
  end
  else
    FSpawnButton1WasDown := False;

  if CheckButton(40, 10, 40, 40) then
  begin
    if not FSpawnButton2WasDown then
    begin
      SpawnObjects(30, stSphere);
      FSpawnButton2WasDown := True;
    end;
    FMouseLeftHandled := True;
    Exit;
  end
  else
    FSpawnButton2WasDown := False;

  if CheckButton(80, 10, 40, 40) then
  begin
    if not FSpawnButton3WasDown then
    begin
      SpawnObjects(30, stCapsule);
      FSpawnButton3WasDown := True;
    end;
    FMouseLeftHandled := True;
    Exit;
  end
  else
    FSpawnButton3WasDown := False;

  if CheckButton(120, 10, 40, 40) then
  begin
    if not FSpawnButton4WasDown then
    begin
      SpawnObjects(30, stPyramid);
      FSpawnButton4WasDown := True;
    end;
    FMouseLeftHandled := True;
    Exit;
  end
  else
    FSpawnButton4WasDown := False;

  if CheckButton(160, 10, 40, 40) then
  begin
    if not FSpawnButton5WasDown then
    begin
      SpawnObjects(30, stPrism);
      FSpawnButton5WasDown := True;
    end;
    FMouseLeftHandled := True;
    Exit;
  end
  else
    FSpawnButton5WasDown := False;
  if FShootCooldown > 0 then
    Exit;
  // Object Selection (Nur in Gizmo Modes)
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
      if not FDragging then
      begin
        if Assigned(FItemSelected) then
        begin
          FItemSelected := nil;
          DoObjectSelected(nil);
        end;
      end;
    end;
  end
  else
  begin
    FDragging := False;
  end;
end;

procedure TRaylibSandbox.HandlePopupInput;
var
  I: Integer;
  Rect: TRectangle;
  NewHover: Integer;
  IconRect: TRectangle;
begin
  NewHover := -1;
  // Check icon bar hits
  for I := 0 to 4 do
  begin
    IconRect.x := FPopupPos.x + 4 + (I * 34);
    IconRect.y := FPopupPos.y + 4;
    IconRect.width := 30;
    IconRect.height := 30;
    if CheckCollisionPointRec(FMousePos, IconRect) then
    begin
      NewHover := I;
      Break;
    end;
  end;
  // Check standard list items hits
  if NewHover = -1 then
  begin
    for I := 0 to High(FPopupSegments) do
    begin
      Rect.x := FPopupPos.x;
      Rect.y := FPopupPos.y + 45 + (I * 40);
      Rect.width := 150;
      Rect.height := 38;
      if CheckCollisionPointRec(FMousePos, Rect) then
      begin
        NewHover := I + 100; // Offset to distinguish from icons
        Break;
      end;
    end;
  end;
  if FPopupHoverIndex <> NewHover then
    FPopupHoverIndex := NewHover;
  if FPopupCloseLock then
  begin
    if (GetAsyncKeyState(VK_RBUTTON) and $8000) = 0 then
      FPopupCloseLock := False;
    Exit;
  end;
  if (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0 then
  begin
    if FPopupHoverIndex >= 0 then
    begin
      if FPopupHoverIndex < 100 then
        ExecutePopupAction(FPopupHoverIndex) // It's an icon
      else
        ExecutePopupAction(FPopupHoverIndex - 100); // It's a standard item
    end;
    FPopupOpen := False;
    FMouseLeftHandled := True;
  end;
end;

procedure TRaylibSandbox.ExecutePopupAction(Index: Integer);
var
  SelectedIdx, I: Integer;
  NewActor: TA3DComponent;
  NewPos: TVector3;
  NewRot: JPH_Quat;
  NewSize: TVector3;
  NewData: PItemData;
  OldLen: Integer;
begin
  // Handle Icon Clicks (Index 0 to 4)
  case Index of
    0:
      begin
        SetBrush(stBox);
        SpawnAtMouse(FGhostPos);
        FIsBrushActive := False;
      end;
    1:
      begin
        SetBrush(stSphere);
        SpawnAtMouse(FGhostPos);
        FIsBrushActive := False;
      end;
    2:
      begin
        SetBrush(stCapsule);
        SpawnAtMouse(FGhostPos);
        FIsBrushActive := False;
      end;
    3:
      begin
        SetBrush(stPyramid);
        SpawnAtMouse(FGhostPos);
        FIsBrushActive := False;
      end;
    4:
      begin
        SetBrush(stPrism);
        SpawnAtMouse(FGhostPos);
        FIsBrushActive := False;
      end;
  end;
  // Handle Standard List Items (Delete and Duplicate)
  if (Index < 0) or (Index > High(FPopupSegments)) then
    Exit;
  if FPopupSegments[Index] = 'Delete' then
    DeleteSelectedActor
  else if FPopupSegments[Index] = 'Duplicate' then
  begin
    if not Assigned(FItemSelected) then
      Exit;
    OldLen := Length(FItems);
    SetLength(FItems, OldLen + 1);
    NewPos.x := FItemSelected.Position.x + 1.0;
    NewPos.y := FItemSelected.Position.y;
    NewPos.z := FItemSelected.Position.z;
    NewRot.x := FItemSelected.Quaternion.x;
    NewRot.y := FItemSelected.Quaternion.y;
    NewRot.z := FItemSelected.Quaternion.z;
    NewRot.w := FItemSelected.Quaternion.w;
    NewSize := FItemSelected.Scale;
    NewActor := TA3DComponent.Create('', FEngine, FItemSelected.ShapeType, NewSize, False, @NewPos, @NewRot);
    NewActor.Friction := FItemSelected.Friction;
    NewActor.Restitution := FItemSelected.Restitution;
    NewActor.TargetColor := FItemSelected.TargetColor;
    New(NewData);
    FillChar(NewData^, SizeOf(TItemData), 0);
    NewData^.SpawnTime := GetTime();
    NewData^.IsProjectile := False;
    case NewActor.ShapeType of
      stBox:
        NewData^.Name := 'Cube_' + IntToStr(OldLen);
      stSphere:
        NewData^.Name := 'Sphere_' + IntToStr(OldLen);
      stPyramid:
        NewData^.Name := 'Pyramid_' + IntToStr(OldLen);
      stPrism:
        NewData^.Name := 'Prism_' + IntToStr(OldLen);
      stCapsule:
        NewData^.Name := 'Capsule_' + IntToStr(OldLen);
    end;
    NewActor.UserData := NewData;
    NewActor.Visible := True;
    FItems[OldLen] := NewActor;
    DoActorSpawned(NewActor, OldLen);
    DoObjectSelected(NewActor);
  end;
end;

procedure TRaylibSandbox.DeleteSelectedActor;
var
  SelectedIdx, I: Integer;
begin
  if not Assigned(FItemSelected) then
    Exit;
  SelectedIdx := -1;
  for I := 0 to High(FItems) do
    if FItems[I] = FItemSelected then
    begin
      SelectedIdx := I;
      Break;
    end;
  if SelectedIdx >= 0 then
  begin
    FItemSelected.Visible := False;
    FItemSelected.Free;
    for I := SelectedIdx to High(FItems) - 1 do
      FItems[I] := FItems[I + 1];
    SetLength(FItems, Length(FItems) - 1);
    FItemSelected := nil;
    DoObjectSelected(nil);
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
  else if FGizmoMode = gmScale then
  begin
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
  Box: TBoundingBox;
  Hit: TRayCollision;
  InvRot: TQuaternion;
  LocalRay: TRay;
  LocalDir: TVector3;
begin
  Result := False;
  Axis := 0;

  // To accurately detect hover/click on rotated axes, we transform the world ray
  // into the local space of the actor. This allows using simple axis-aligned
  // bounding boxes (AABB) that perfectly align with the visual gizmo,
  // regardless of the object's rotation.
  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);

  // Check X-Axis (bidirectional)
  Box.min := Vector3Create(-Scale.x - RayRadius, -RayRadius, -RayRadius);
  Box.max := Vector3Create(Scale.x + RayRadius, RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  // Check Y-Axis (bidirectional)
  Box.min := Vector3Create(-RayRadius, -Scale.y - RayRadius, -RayRadius);
  Box.max := Vector3Create(RayRadius, Scale.y + RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  // Check Z-Axis (bidirectional)
  Box.min := Vector3Create(-RayRadius, -RayRadius, -Scale.z - RayRadius);
  Box.max := Vector3Create(RayRadius, RayRadius, Scale.z + RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
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
  InvRot: TQuaternion;
  LocalRay: TRay;
  LocalDir: TVector3;
begin
  Result := False;
  Axis := 0;

  // Transform the ray into the actor's local space to ensure the invisible
  // picking boxes align perfectly with the rotated rotation rings.
  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);

  // Check X-Axis Ring (flattened box around YZ plane)
  Box.min := Vector3Create(-RayRadius, -Scale.y, -Scale.z);
  Box.max := Vector3Create(RayRadius, Scale.y, Scale.z);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  // Check Y-Axis Ring (flattened box around XZ plane)
  Box.min := Vector3Create(-Scale.x, -RayRadius, -Scale.z);
  Box.max := Vector3Create(Scale.x, RayRadius, Scale.z);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  // Check Z-Axis Ring (flattened box around XY plane)
  Box.min := Vector3Create(-Scale.x, -Scale.y, -RayRadius);
  Box.max := Vector3Create(Scale.x, Scale.y, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 3;
    Exit;
  end;
end;

function TRaylibSandbox.CheckGizmoScaleHit(Pos, Scale: TVector3; RayRadius: Single; Ray: TRay; out Axis: Integer): Boolean;
var
  Box: TBoundingBox;
  Hit: TRayCollision;
  InvRot: TQuaternion;
  LocalRay: TRay;
  LocalDir: TVector3;
begin
  Result := False;
  Axis := 0;

  // Transform the ray into the actor's local space so the scale handle boxes
  // are accurately checked at the exact tips of the arrows.
  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);

  // Check positive X-Axis Scale Handle
  Box.min := Vector3Create(Scale.x - RayRadius, -RayRadius, -RayRadius);
  Box.max := Vector3Create(Scale.x + RayRadius, RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  // Check positive Y-Axis Scale Handle
  Box.min := Vector3Create(-RayRadius, Scale.y - RayRadius, -RayRadius);
  Box.max := Vector3Create(RayRadius, Scale.y + RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  // Check positive Z-Axis Scale Handle
  Box.min := Vector3Create(-RayRadius, -RayRadius, Scale.z - RayRadius);
  Box.max := Vector3Create(RayRadius, RayRadius, Scale.z + RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 3;
    Exit;
  end;
end;

procedure TRaylibSandbox.SetSelectedActor(AActor: TA3DComponent);
begin
  FItemSelected := AActor;
end;

procedure TRaylibSandbox.SpawnAtMouse(Pos: TVector3);
var
  Obj: TA3DComponent;
  oldLen: Integer;
  Data: PItemData;
  Size: TVector3;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  YOffset: Single;
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
    stCapsule:
      Data^.Name := 'Capsule_' + IntToStr(oldLen);
    stPrism:
      Data^.Name := 'Prism_' + IntToStr(oldLen);
  end;

  // Base size 1.0 for standard visual parity
  Size := Vector3Create(1, 1, 1);
  if FBrushShape = stPrism then
    Size := Vector3Create(1, 1.5, 1)
  else if FBrushShape = stPyramid then
    Size := Vector3Create(1, 1.5, 1);

  JPos.x := Pos.x;
  YOffset := Size.y * 0.5;
  JPos.y := Pos.y + YOffset;
  JPos.z := Pos.z;
  JRot.x := 0;
  JRot.y := 0;
  JRot.z := 0;
  JRot.w := 1;

  Obj := TA3DComponent.Create('', FEngine, FBrushShape, Size, False, @JPos, @JRot);
  Obj.Friction := 1.0;
  Obj.Restitution := 0.0;
  Obj.UserData := Data;
  Obj.Visible := True;

  Obj.SetPosition(Vector3Create(JPos.x, JPos.y, JPos.z));
  Obj.SetRotation(QuaternionFromEuler(0, 0, 0));

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
  HoverRay: TRay;
  HoverScaleX, HoverScaleY, HoverScaleZ: Single;
  HoverAxis: Integer;
  Dir: TVector3;
  Dist: single;
  NewVel: TVector3;
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
      // Wir messen die Zeit, die Jolt braucht
      var StartTime: Int64;
      QueryPerformanceCounter(StartTime);

      FEngine.Update(dt);

      var EndTime: Int64;
      QueryPerformanceCounter(EndTime);
      var Freq: Int64;
      QueryPerformanceFrequency(Freq);
      FLastPhysicsTime := (EndTime - StartTime) * 1000.0 / Freq; // In Millisekunden

      // Zählen, wie viele Objekte sich bewegen
      FActiveBodies := 0;
      for i := 0 to High(FItems) do
      begin
        if Assigned(FItems[i]) then
        begin
          var Vel := FItems[i].GetLinearVelocity;
          if (Abs(Vel.x) > 0.1) or (Abs(Vel.y) > 0.1) or (Abs(Vel.z) > 0.1) then
            Inc(FActiveBodies);
        end;
      end;
    except
      on E: Exception do
        DoEngineException(E.Message, 'PhysicsUpdate');
    end;
  end
  else
  begin
    FActiveBodies := 0;
    FLastPhysicsTime := 0;
  end;

  if (FSceneStartTime > 0) and (GetTime() - FSceneStartTime > 1.0) then
    FSceneStartTime := 0;
  if (FSceneStartTime = 0) and (FHUDAnimY < 0) then
  begin
    FHUDAnimY := FHUDAnimY * (1.0 - dt * 6.0);
    if FHUDAnimY > -0.5 then
      FHUDAnimY := 0;
  end;
            // Gizmo Hover Check
  FGizmoHoverAxis := 0;
  if FInitialized and Assigned(FItemSelected) and not FGizmoDragging and not FDragging and not FPopupOpen and (FGizmoMode <> gmNone) then
  begin
    HoverRay := GetScreenToWorldRay(FMousePos, FCamera);
    // Calculate dynamic scale for gizmo hover bounding boxes, matching object scale + offset so they stay grabbable
    HoverScaleX := EnsureRange(FItemSelected.Scale.x + 1.0, 1.0, 100.0);
    HoverScaleY := EnsureRange(FItemSelected.Scale.y + 1.0, 1.0, 100.0);
    HoverScaleZ := EnsureRange(FItemSelected.Scale.z + 1.0, 1.0, 100.0);
    if FGizmoMode = gmTranslate then
    begin
      if CheckGizmoAxisHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.25, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end
    else if FGizmoMode = gmRotate then
    begin
      if CheckGizmoRingHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.2, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end
    else if FGizmoMode = gmScale then
    begin
      if CheckGizmoScaleHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.25, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end;
  end;
  //Highlight collision
  if FHighlightCollision then
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
  // Drag & Throw Force Update
  if FDragging and Assigned(FItemSelected) and (FGizmoMode = gmNone) then
  begin
    Dir.x := FDragTargetPos.x - FItemSelected.Position.x;
    Dir.y := 0; // Keep it flat on the XZ plane
    Dir.z := FDragTargetPos.z - FItemSelected.Position.z;
    Dist := Sqrt(Dir.x * Dir.x + Dir.z * Dir.z);
    if Dist > 0.05 then
    begin
      // Object is far from the target: apply force to move it
      FItemSelected.ActivateBody;
      NewVel.x := Dir.x * 10.0;
      NewVel.y := FItemSelected.GetLinearVelocity.y; // Keep gravity/fall speed
      NewVel.z := Dir.z * 10.0;
      FItemSelected.SetLinearVelocity(NewVel);
      // Dampen angular velocity (spinning) while dragging
      NewVel := FItemSelected.GetAngularVelocity;
      NewVel.x := NewVel.x * 0.9;
      NewVel.y := NewVel.y * 0.9;
      NewVel.z := NewVel.z * 0.9;
      FItemSelected.SetAngularVelocity(NewVel);
    end
    else
    begin
      // Object is at the target: stop X/Z movement so it doesn't jitter
      NewVel := FItemSelected.GetLinearVelocity;
      NewVel.x := 0;
      NewVel.z := 0;
      FItemSelected.SetLinearVelocity(NewVel);
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
  DrawNativePopup;
  EndDrawing();
  if FRaylibWnd <> 0 then
    RedrawWindow(FRaylibWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW);
end;

procedure TRaylibSandbox.Render3DScene;
var
  i: Integer;
  Actor: TA3DComponent;
  Dist, MaxDist: Single;
  CamForward, ToActor, ToActorNorm: TVector3;
  Axis: TVector3;
  Angle: Single;
  DotP: Single;
  Pos: TVector3;
  ShadowPos: TVector3;
  dt: Single;
  // Helper function to get the color based on actor type and glow state

  function GetActorColor(A: TA3DComponent): TColorB;
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
    COL_CAPSULE: TColorB = (
    r: 0;
    g: 168;
    b: 150;
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
      stCapsule:
        Exit(COL_CAPSULE);
      stPrism:
        Exit(COL_PRISM);
    else
      Exit(WHITE);
    end;
  end;

begin
  BeginMode3D(FCamera);
  // Draw Floor
  BeginShaderMode(FLightShader);
  if FWallpaperTex.id > 0 then
    DrawModel(FWallpaperModel, Vector3Create(0, 0.05, 0), 1.0, WHITE)
  else
    DrawPlane(Vector3Create(0, 0.05, 0), Vector2Create(100, 100), DARKGRAY);
  EndShaderMode();
  // Draw Walls and their shadows
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
  // Render all actors in the engine
  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      if (Actor.UserData <> nil) and PItemData(Actor.UserData)^.IsProjectile then
        Continue;
      // Culling: Distance and View Frustum check
      Dist := Vector3Distance(Actor.Position, FCamera.position);
      if FDistanceCulling and (Dist > MaxDist) then
        Continue;
      ToActor := Vector3Subtract(Actor.Position, FCamera.position);
      ToActorNorm := Vector3Normalize(ToActor);
      DotP := Vector3DotProduct(ToActorNorm, CamForward);
      if FFrustumCulling and (DotP < 0.5) then
        Continue;

      // Draw Fake 2D Shadows on the ground plane
      if Actor.ShapeType = stSphere then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), EnsureRange(0.6 - (Actor.Position.y * 0.15), 0.1, 0.6), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else if (Actor.ShapeType = stPyramid) or (Actor.ShapeType = stCapsule) or (Actor.ShapeType = stPrism) then
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), EnsureRange(0.7 - (Actor.Position.y * 0.15), 0.1, 0.7), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)))
      else
        DrawCylinderEx(Vector3Create(Actor.Position.x, 0.06, Actor.Position.z), Vector3Create(Actor.Position.x, 0.05, Actor.Position.z), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), EnsureRange(0.8 - (Actor.Position.y * 0.15), 0.1, 0.8), 24, Fade(BLACK, EnsureRange(0.5 - (Actor.Position.y * 0.02), 0, 0.5)));

      // Draw 3D Object
      BeginShaderMode(FLightShader);
      rlPushMatrix();
      Pos := Actor.Position;
      Pos.y := Pos.y + 0.07; // Slight offset to prevent z-fighting with the floor
      rlTranslatef(Pos.x, Pos.y, Pos.z);
      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);
      // Render specific shapes perfectly aligned to physics center (0,0,0)
      if Actor.ShapeType = stSphere then
      begin
        // Use max axis for sphere radius to ensure it visually matches standard scale
        DrawSphere(Vector3Create(0, 0, 0), Max(Actor.Scale.x, Max(Actor.Scale.y, Actor.Scale.z)) * 0.5, GetActorColor(Actor));
      end
      else if Actor.ShapeType = stCapsule then
      begin
        // Capsule is drawn centered around the Jolt physics origin (0,0,0)
        // Scale.y is the total height, Scale.x is the diameter (so radius is * 0.5)
        DrawCylinderEx(Vector3Create(0, Actor.Scale.y * 0.5, 0), Vector3Create(0, -Actor.Scale.y * 0.5, 0), Actor.Scale.x * 0.5, Actor.Scale.x * 0.5, 24, GetActorColor(Actor));
        DrawCylinderWiresEx(Vector3Create(0, Actor.Scale.y * 0.5, 0), Vector3Create(0, -Actor.Scale.y * 0.5, 0), Actor.Scale.x * 0.5, Actor.Scale.x * 0.5, 24, BLACK);
      end
      else if (Actor.ShapeType = stPyramid) or (Actor.ShapeType = stPrism) then
      begin
        var TopR: Single := 0.0;
        if Actor.ShapeType = stPrism then
          TopR := Actor.Scale.x * 0.5; // Flat top for prism
        var Segs: Integer := 4;
        if Actor.ShapeType = stPrism then
          Segs := 3;
        DrawCylinderEx(Vector3Create(0, Actor.Scale.y * 0.5, 0), Vector3Create(0, -Actor.Scale.y * 0.5, 0), TopR, Actor.Scale.x * 0.5, Segs, GetActorColor(Actor));
        DrawCylinderWiresEx(Vector3Create(0, Actor.Scale.y * 0.5, 0), Vector3Create(0, -Actor.Scale.y * 0.5, 0), TopR, Actor.Scale.x * 0.5, Segs, BLACK);
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
  // Render Selected Actor Outline (Yellow Wireframe)
  if Assigned(FItemSelected) and FItemSelected.Visible then
  begin
    if FItemSelected.ShapeType = stSphere then
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.6 - (FItemSelected.Position.y * 0.15), 0.1, 0.6), EnsureRange(0.6 - (FItemSelected.Position.y * 0.15), 0.1, 0.6), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)))
    else if (FItemSelected.ShapeType = stPyramid) or (FItemSelected.ShapeType = stCapsule) or (FItemSelected.ShapeType = stPrism) then
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.7 - (FItemSelected.Position.y * 0.15), 0.1, 0.7), EnsureRange(0.7 - (FItemSelected.Position.y * 0.15), 0.1, 0.7), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)))
    else
      DrawCylinderEx(Vector3Create(FItemSelected.Position.x, 0.06, FItemSelected.Position.z), Vector3Create(FItemSelected.Position.x, 0.05, FItemSelected.Position.z), EnsureRange(0.8 - (FItemSelected.Position.y * 0.15), 0.1, 0.8), EnsureRange(0.8 - (FItemSelected.Position.y * 0.15), 0.1, 0.8), 24, Fade(BLACK, EnsureRange(0.5 - (FItemSelected.Position.y * 0.02), 0, 0.5)));
    BeginShaderMode(FLightShader);
    rlPushMatrix();
    Pos := FItemSelected.Position;
    Pos.y := Pos.y + 0.07;
    rlTranslatef(Pos.x, Pos.y, Pos.z);
    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if FItemSelected.Quaternion.w < 1.0 then
      QuaternionToAxisAngle(FItemSelected.Quaternion, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);
    if FItemSelected.ShapeType = stSphere then
    begin
      // Use max axis for sphere radius to ensure it visually matches standard scale
      DrawSphere(Vector3Create(0, 0, 0), Max(FItemSelected.Scale.x, Max(FItemSelected.Scale.y, FItemSelected.Scale.z)) * 0.5, GetActorColor(FItemSelected));
    end
    else if FItemSelected.ShapeType = stCapsule then
    begin
      // Draw selected capsule perfectly centered
      DrawCylinderEx(Vector3Create(0, FItemSelected.Scale.y * 0.5, 0), Vector3Create(0, -FItemSelected.Scale.y * 0.5, 0), FItemSelected.Scale.x * 0.5, FItemSelected.Scale.x * 0.5, 24, GetActorColor(FItemSelected));
      DrawCylinderWiresEx(Vector3Create(0, FItemSelected.Scale.y * 0.5, 0), Vector3Create(0, -FItemSelected.Scale.y * 0.5, 0), FItemSelected.Scale.x * 0.5, FItemSelected.Scale.x * 0.5, 24, YELLOW);
    end
    else if (FItemSelected.ShapeType = stPyramid) or (FItemSelected.ShapeType = stPrism) then
    begin
      var TopR: Single := 0.0;
      if FItemSelected.ShapeType = stPrism then
        TopR := FItemSelected.Scale.x * 0.5; // Flat top for prism
      var Segs: Integer := 4;
      if FItemSelected.ShapeType = stPrism then
        Segs := 3;
      DrawCylinderEx(Vector3Create(0, FItemSelected.Scale.y * 0.5, 0), Vector3Create(0, -FItemSelected.Scale.y * 0.5, 0), TopR, FItemSelected.Scale.x * 0.5, Segs, GetActorColor(FItemSelected));
      DrawCylinderWiresEx(Vector3Create(0, FItemSelected.Scale.y * 0.5, 0), Vector3Create(0, -FItemSelected.Scale.y * 0.5, 0), TopR, FItemSelected.Scale.x * 0.5, Segs, YELLOW);
    end
    else
    begin
      DrawCube(Vector3Create(0, 0, 0), FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z, GetActorColor(FItemSelected));
      DrawCubeWires(Vector3Create(0, 0, 0), FItemSelected.Scale.x + 0.05, FItemSelected.Scale.y + 0.05, FItemSelected.Scale.z + 0.05, YELLOW);
    end;
    rlPopMatrix();
    EndShaderMode();
  end;
  // Render Ghost (Brush Preview)
  if FIsBrushActive and FGhostVisible then
  begin
    rlPushMatrix();
    // Sphere und Cube (Default) behalten ihren leichten 0.1 Offset (wie vorher).
    // Für Capsule, Pyramid und Prism heben wir das Phantom um exakt Size.y * 0.5 + 0.1 an,
    // damit das Phantom nicht im Boden steckt, sondern exakt da schwebt, wo dann auch gespawnt wird.
    var SurfaceY: Single := FGhostPos.y + 0.1;
    if (FBrushShape = stCapsule) or (FBrushShape = stPyramid) or (FBrushShape = stPrism) then
    begin
      if (FBrushShape = stPyramid) or (FBrushShape = stPrism) then
        SurfaceY := FGhostPos.y + (1.5 * 0.5) + 0.1
      else
        SurfaceY := FGhostPos.y + (1.0 * 0.5) + 0.1;
    end;
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
    else if FBrushShape = stCapsule then
    begin
      // Draw ghost capsule exactly as the real one, perfectly resting on the surface
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawCylinderEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, YELLOW);
    end
    else if FBrushShape = stPyramid then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, YELLOW);
    end
    else if FBrushShape = stPrism then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      // Draw flat top for prism shape preview with 3 segments (Triangle)
      DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.5, 0.5, 3, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.5, 0.5, 3, YELLOW);
    end;
    rlPopMatrix();
  end;
  // Draw Gizmo if applicable
  if Assigned(FItemSelected) and not FIsBrushActive and (FGizmoMode <> gmNone) then
    DrawGizmo;
  // Update and draw projectiles
  dt := GetFrameTime();
  UpdateProjectiles(dt);
  EndMode3D();
end;

procedure TRaylibSandbox.DrawGizmo;
var
  Pos: TVector3;
  ScaleX, ScaleY, ScaleZ: Single;
  ColX, ColY, ColZ: TColorB;
  AxisX, AxisY, AxisZ: TVector3;
  EndX, EndY, EndZ: TVector3;
  NegEndX, NegEndY, NegEndZ: TVector3;
  TipX, TipY, TipZ: TVector3;
  NegTipX, NegTipY, NegTipZ: TVector3;
  ArrowRadius, HandleSize: Single;
begin
  Pos := FItemSelected.Position;
  // Dynamic scale length so gizmo matches object size + offset so they stay visible
  ScaleX := EnsureRange(FItemSelected.Scale.x + 1.0, 1.0, 100.0);
  ScaleY := EnsureRange(FItemSelected.Scale.y + 1.0, 1.0, 100.0);
  ScaleZ := EnsureRange(FItemSelected.Scale.z + 1.0, 1.0, 100.0);
  // Fixed thickness so they don't get excessively thick
  ArrowRadius := 0.08;
  HandleSize := ArrowRadius * 2.5;
  ColX := RED;
  ColY := GREEN;
  ColZ := BLUE;
  if FGizmoDragging then
  begin
    if FGizmoAxis = 1 then
      ColX := YELLOW
    else if FGizmoAxis = 2 then
      ColY := YELLOW
    else if FGizmoAxis = 3 then
      ColZ := YELLOW;
  end
  else if FGizmoHoverAxis > 0 then
  begin
    if FGizmoHoverAxis = 1 then
      ColX := YELLOW
    else if FGizmoHoverAxis = 2 then
      ColY := YELLOW
    else if FGizmoHoverAxis = 3 then
      ColZ := YELLOW;
  end;
  AxisX := Vector3RotateByQuaternion(Vector3Create(1, 0, 0), FItemSelected.Quaternion);
  AxisY := Vector3RotateByQuaternion(Vector3Create(0, 1, 0), FItemSelected.Quaternion);
  AxisZ := Vector3RotateByQuaternion(Vector3Create(0, 0, 1), FItemSelected.Quaternion);
  EndX := Vector3Add(Pos, Vector3Scale(AxisX, ScaleX));
  EndY := Vector3Add(Pos, Vector3Scale(AxisY, ScaleY));
  EndZ := Vector3Add(Pos, Vector3Scale(AxisZ, ScaleZ));
  NegEndX := Vector3Subtract(Pos, Vector3Scale(AxisX, ScaleX));
  NegEndY := Vector3Subtract(Pos, Vector3Scale(AxisY, ScaleY));
  NegEndZ := Vector3Subtract(Pos, Vector3Scale(AxisZ, ScaleZ));
  TipX := Vector3Add(Pos, Vector3Scale(AxisX, ScaleX + (ArrowRadius * 3)));
  TipY := Vector3Add(Pos, Vector3Scale(AxisY, ScaleY + (ArrowRadius * 3)));
  TipZ := Vector3Add(Pos, Vector3Scale(AxisZ, ScaleZ + (ArrowRadius * 3)));
  NegTipX := Vector3Subtract(Pos, Vector3Scale(AxisX, ScaleX + (ArrowRadius * 3)));
  NegTipY := Vector3Subtract(Pos, Vector3Scale(AxisY, ScaleY + (ArrowRadius * 3)));
  NegTipZ := Vector3Subtract(Pos, Vector3Scale(AxisZ, ScaleZ + (ArrowRadius * 3)));
  if FGizmoMode = gmTranslate then
  begin
    // Draw bidirectional axes
    DrawCylinderEx(Pos, EndX, ArrowRadius, ArrowRadius, 8, ColX);
    DrawCylinderEx(Pos, NegEndX, ArrowRadius, ArrowRadius, 8, ColX);
    DrawCylinderEx(Pos, EndY, ArrowRadius, ArrowRadius, 8, ColY);
    DrawCylinderEx(Pos, NegEndY, ArrowRadius, ArrowRadius, 8, ColY);
    DrawCylinderEx(Pos, EndZ, ArrowRadius, ArrowRadius, 8, ColZ);
    DrawCylinderEx(Pos, NegEndZ, ArrowRadius, ArrowRadius, 8, ColZ);
    DrawCylinderEx(EndX, TipX, ArrowRadius * 2, 0.0, 8, ColX);
    DrawCylinderEx(NegEndX, NegTipX, ArrowRadius * 2, 0.0, 8, ColX);
    DrawCylinderEx(EndY, TipY, ArrowRadius * 2, 0.0, 8, ColY);
    DrawCylinderEx(NegEndY, NegTipY, ArrowRadius * 2, 0.0, 8, ColY);
    DrawCylinderEx(EndZ, TipZ, ArrowRadius * 2, 0.0, 8, ColZ);
    DrawCylinderEx(NegEndZ, NegTipZ, ArrowRadius * 2, 0.0, 8, ColZ);
  end
  else if FGizmoMode = gmRotate then
  begin
    DrawThickRingAt(Pos, AxisX, ScaleX, ArrowRadius * 0.8, ColX);
    DrawThickRingAt(Pos, AxisY, ScaleY, ArrowRadius * 0.8, ColY);
    DrawThickRingAt(Pos, AxisZ, ScaleZ, ArrowRadius * 0.8, ColZ);
  end
  else if FGizmoMode = gmScale then
  begin
    // Draw bidirectional axes
    DrawCylinderEx(Pos, EndX, ArrowRadius, ArrowRadius, 8, ColX);
    DrawCylinderEx(Pos, NegEndX, ArrowRadius, ArrowRadius, 8, ColX);
    DrawCylinderEx(Pos, EndY, ArrowRadius, ArrowRadius, 8, ColY);
    DrawCylinderEx(Pos, NegEndY, ArrowRadius, ArrowRadius, 8, ColY);
    DrawCylinderEx(Pos, EndZ, ArrowRadius, ArrowRadius, 8, ColZ);
    DrawCylinderEx(Pos, NegEndZ, ArrowRadius, ArrowRadius, 8, ColZ);
    DrawCube(EndX, HandleSize, HandleSize, HandleSize, ColX);
    DrawCube(NegEndX, HandleSize, HandleSize, HandleSize, ColX);
    DrawCube(EndY, HandleSize, HandleSize, HandleSize, ColY);
    DrawCube(NegEndY, HandleSize, HandleSize, HandleSize, ColY);
    DrawCube(EndZ, HandleSize, HandleSize, HandleSize, ColZ);
    DrawCube(NegEndZ, HandleSize, HandleSize, HandleSize, ColZ);
    DrawCube(Pos, HandleSize, HandleSize, HandleSize, WHITE);
  end;
end;

procedure TRaylibSandbox.DrawThickRingAt(Center, NormalAxis: TVector3; Radius, Thickness: Single; Color: TColorB);
var
  I: Integer;
  Segments: Integer;
  Angle: Single;
  LocalV, V1, V2: TVector3;
  OrthoAxis: TVector3;
begin
  Segments := 32;
  if Abs(NormalAxis.y) < 0.9 then
    OrthoAxis := Vector3Normalize(Vector3CrossProduct(NormalAxis, Vector3Create(0, 1, 0)))
  else
    OrthoAxis := Vector3Normalize(Vector3CrossProduct(NormalAxis, Vector3Create(1, 0, 0)));
  for I := 0 to Segments - 1 do
  begin
    Angle := (I / Segments) * 2.0 * PI;
    LocalV := Vector3Add(Vector3Scale(OrthoAxis, Cos(Angle) * Radius), Vector3Scale(Vector3CrossProduct(NormalAxis, OrthoAxis), Sin(Angle) * Radius));
    V1 := Vector3Add(Center, LocalV);
    Angle := ((I + 1) / Segments) * 2.0 * PI;
    LocalV := Vector3Add(Vector3Scale(OrthoAxis, Cos(Angle) * Radius), Vector3Scale(Vector3CrossProduct(NormalAxis, OrthoAxis), Sin(Angle) * Radius));
    V2 := Vector3Add(Center, LocalV);
    DrawCylinderEx(V1, V2, Thickness, Thickness, 6, Color);
  end;
end;

procedure TRaylibSandbox.DrawNativePopup;
var
  I: Integer;
  Rect: TRectangle;
  BgColor, BorderColor, TextColor: TColorB;
  IconRect: TRectangle;
begin
  if not FPopupOpen then
    Exit;
  // Draw Top Icon Bar
  DrawRectangleRec(RectangleCreate(FPopupPos.x, FPopupPos.y, 174, 38), Fade(BLACK, 0.9));
  DrawRectangleLinesEx(RectangleCreate(FPopupPos.x, FPopupPos.y, 174, 38), 2, GRAY);
  for I := 0 to 4 do
  begin
    IconRect.x := FPopupPos.x + 4 + (I * 34);
    IconRect.y := FPopupPos.y + 4;
    IconRect.width := 30;
    IconRect.height := 30;
    if FPopupHoverIndex = I then
    begin
      DrawRectangleRec(IconRect, Fade(SKYBLUE, 0.8));
      DrawRectangleLinesEx(IconRect, 1, YELLOW);
    end
    else
    begin
      DrawRectangleRec(IconRect, BLACK);
      DrawRectangleLinesEx(IconRect, 1, RAYWHITE);
    end;
    if I = 0 then
      DrawRectangle(Round(IconRect.x + 8), Round(IconRect.y + 8), 14, 14, RED)
    else if I = 1 then
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 15), 7, PURPLE)
    else if I = 2 then
    begin
      DrawRectangle(Round(IconRect.x + 11), Round(IconRect.y + 6), 8, 18, GREEN);
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 6), 4, GREEN);
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 24), 4, GREEN);
    end
    else if I = 3 then // Pyramid Icon (Rectangle with X inside)
    begin
      DrawRectangle(Round(IconRect.x + 5), Round(IconRect.y + 5), 20, 20, ORANGE);
      DrawLine(Round(IconRect.x + 5), Round(IconRect.y + 5), Round(IconRect.x + 25), Round(IconRect.y + 25), BLACK);
      DrawLine(Round(IconRect.x + 25), Round(IconRect.y + 5), Round(IconRect.x + 5), Round(IconRect.y + 25), BLACK);
    end
    else if I = 4 then // Prism/Triangle Icon
    begin
      DrawTriangle(Vector2Create(IconRect.x + 5, IconRect.y + 25), Vector2Create(IconRect.x + 25, IconRect.y + 25), Vector2Create(IconRect.x + 15, IconRect.y + 5), COL_PRISM);
    end;
  end;
  // Draw standard items below
  for I := 0 to High(FPopupSegments) do
  begin
    Rect.x := FPopupPos.x;
    Rect.y := FPopupPos.y + 45 + (I * 40);
    Rect.width := 150;
    Rect.height := 38;
    if (FPopupHoverIndex - 100) = I then
    begin
      BgColor := Fade(BLUE, 0.8);
      BorderColor := SKYBLUE;
      TextColor := WHITE;
    end
    else
    begin
      BgColor := Fade(BLACK, 0.8);
      BorderColor := GRAY;
      TextColor := RAYWHITE;
    end;
    DrawRectangleRec(Rect, BgColor);
    DrawRectangleLinesEx(Rect, 2, BorderColor);
    DrawText(PAnsiChar(AnsiString(FPopupSegments[I])), Round(Rect.x + 15), Round(Rect.y + 10), 20, TextColor);
  end;
end;

procedure TRaylibSandbox.DrawGUI;
var
  fpsBuf: AnsiString;
  YOffset: Integer;
  ModeStr: AnsiString;
  IconRect: TRectangle;
  I: Integer;
begin
  YOffset := Trunc(FHUDAnimY);
  // Adjust width to fit 5 spawn icons
  DrawRectangle(10, 10 + YOffset, 214, 50, Fade(BLACK, 0.8));
  DrawRectangleLines(10, 10 + YOffset, 214, 50, RAYWHITE);
  // Draw Spawn Icons in HUD (matches popup icons exactly)
  for I := 0 to 4 do
  begin
    IconRect.x := 15 + (I * 40);
    IconRect.y := 15 + YOffset;
    IconRect.width := 30;
    IconRect.height := 30;
    DrawRectangleLines(Round(IconRect.x), Round(IconRect.y), 30, 30, RAYWHITE);
    if I = 0 then
      DrawRectangle(Round(IconRect.x + 8), Round(IconRect.y + 8), 14, 14, Fade(BLUE, 0.8))
    else if I = 1 then
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 15), 10, Fade(GREEN, 0.8))
    else if I = 2 then
    begin
      DrawRectangle(Round(IconRect.x + 11), Round(IconRect.y + 6), 8, 18, Fade(GREEN, 0.8));
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 6), 4, Fade(GREEN, 0.8));
      DrawCircle(Round(IconRect.x + 15), Round(IconRect.y + 24), 4, Fade(GREEN, 0.8));
    end
    else if I = 3 then // Pyramid Icon
    begin
      DrawRectangle(Round(IconRect.x + 5), Round(IconRect.y + 5), 20, 20, Fade(PURPLE, 0.8));
      DrawLine(Round(IconRect.x + 5), Round(IconRect.y + 5), Round(IconRect.x + 25), Round(IconRect.y + 25), RAYWHITE);
      DrawLine(Round(IconRect.x + 25), Round(IconRect.y + 5), Round(IconRect.x + 5), Round(IconRect.y + 25), RAYWHITE);
    end
    else if I = 4 then // Prism Icon
    begin
      DrawTriangle(Vector2Create(IconRect.x + 5, IconRect.y + 25), Vector2Create(IconRect.x + 25, IconRect.y + 25), Vector2Create(IconRect.x + 15, IconRect.y + 5), Fade(COL_PRISM, 0.8));
    end;
  end;
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
    ModeStr := 'Mode: Drag & Throw (Test Tool)';
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

procedure TRaylibSandbox.DoActorSpawned(Actor: TA3DComponent; Index: Integer);
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

procedure TRaylibSandbox.DoObjectSelected(Actor: TA3DComponent);
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


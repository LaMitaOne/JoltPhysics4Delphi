unit RaylibSandbox;

{==============================================================================*
 *  RaylibSandbox v0.61 - VCL Wrapper for a multi-threaded Raylib + Jolt Editor
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
 *      Button.
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
  Vcl.Graphics, Raylib, RayMath, rlgl, ModelEngine, JoltPhysics,
  MiniAudio4Delphi, MPVManager, MPVEmbedded;

type
  PItemData = ^TItemData;

  TObjectSelectedEvent = procedure(Sender: TObject; Actor: TA3DComponent) of object;

  TItemData = record
    SpawnTime: Double;
    LastHitTime: Double;
    IsProjectile: Boolean;
    Name: string;
    OldVelocity: TVector3;
  end;
  // Custom Spawn Request record for external tools like VCL3D.pas

  TSpawnRequest = record
    Shape: TShapeType;
    Pos: TVector3;
    Size: TVector3;
    IsStatic: Boolean;
    Name: string;
    Color: TColorB;
    Caption: string;
    BaseColor: TColorB;
    HoverColor: TColorB;
    OnClick: TNotifyEvent;
    GenerateTestTexture: Boolean;
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

  TGizmoMode = (gmNone, gmTranslate, gmRotate, gmScale, gmDragAndThrow);

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
    FUnitCylinder: TMesh;
    FUnitCone: TMesh;
    FUnitPrism: TMesh;
    FBoxModel: TModel;
    FSphereModel: TModel;
    FCapsuleModel: TModel;
    FPyramidModel: TModel;
    FPrismModel: TModel;

    // Lighting & Shadow Map
    FLightShader: TShader;
    FLightPos: TVector3;
    FLightPosLoc: Integer;
    FViewPosLoc: Integer;
    FAmbientLoc: Integer;
    FDiffuseLoc: Integer;
    FShadowMap: TRenderTexture2D;
    FDefaultMat: TMaterial;
    FWhiteTex: TTexture2D;
    FDefaultWhiteTex: TTexture2D; // Safe base texture for standard models
    FLightCam: TCamera3D;
    FShadowMapLoc: Integer;
    FLightViewLoc: Integer;
    FLightProjLoc: Integer;
    FShadowBias: Single;
    FUnitBox: TMesh;
    FUnitSphere: TMesh;
    FCameraMoved: Boolean;

    // Optimization: Cached default shader for shadow map rendering
    FDefaultShader: TShader;

    // Skybox & Environment
    FSkyboxModel: TModel;
    FSkyboxShader: TShader;
    FSkyboxDaytimeLoc: Integer;
    FSkyboxViewLoc: Integer;
    FSkyboxProjLoc: Integer;
    FSkyboxTex: TTexture2D;

    FCloudModel: TModel;
    FCloudShader: TShader;
    FCloudTex: TTexture2D;
    FCloudMoveFactor: Single;
    FCloudMoveFactorLoc: Integer;
    FCloudDaytimeLoc: Integer;

    FAmbientGradientTex: TTexture2D;
    FDayTime: Single;
    FDaySpeed: Single;
    FSunPos: TVector3;
    FSunColor: TVector4;
    FAmbientColor: TVector4;

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
    FSimulationRunning: Boolean;
    FGhostPos: TVector3;
    FGizmoMode: TGizmoMode;
    FGizmoAxis: Integer;
    FGizmoHoverAxis: Integer;
    FGizmoDragging: Boolean;
    FGizmoStartMouse: TVector2;
    FGizmoStartVal: TVector3;
    FGizmoStartPos: TVector3; // Needed for Y-Lift calculation in Scale Mode!
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
    FFrustumCulling: Boolean;
    FDistanceCulling: Boolean;
    FPopupOpen: Boolean;
    FPopupPos: TVector2;
    FPopupSegments: array of string;
    FPopupHoverIndex: Integer;
    FPopupCloseLock: Boolean;
    FLoadModelQueued: Boolean;
    FQueuedModelPath: string;
    FAudioEngine: ma_engine;
    FNavIndex: Integer;

    // Manual Day/Night Properties
    FDayNightRhythmActive: Boolean;

    // Distance Culling customizable property
    FMaxRenderDistance: Single;

    // Thread-safe Custom Spawn Queue
    FCustomSpawnQueue: TArray<TSpawnRequest>;
    FCustomSpawnTimer: Single;

    // Bomb System Variables
    FBombActor: TA3DComponent;
    FBombTimer: Single;
    FBombExploded: Boolean;

    // Slow Motion System Variables
    FTimeScale: Single;
    FSlowMotionActive: Boolean;

    // Scene Save/Load Queues
    FSaveSceneQueued: Boolean;
    FQueuedSavePath: string;
    FLoadSceneQueued: Boolean;
    FQueuedLoadPath: string;

    // Video System
    FMPVPlayer: TMPVPlayer;

    procedure UpdateBomb(dt: Single);
    procedure ExplodeBomb;

    procedure ProcessCustomSpawnQueue(dt: Single);

    procedure SetDayNightTime(const Value: Single);
    procedure SetDayNightRhythmActive(const Value: Boolean);
    procedure SetDayNightSpeed(const Value: Single);

    procedure LoadModelInThread(const FilePath: string);
    procedure ShootBall;
    procedure UpdateProjectiles(dt: Single);
    procedure InitScene;
    procedure InitLightingAndEnvironment;
    procedure ProcessSpawnQueue(dt: Single);
    procedure HandleCameraInput;
    procedure HandleDesktopInput;
    procedure UpdateGame;
    procedure RenderGame;
    procedure Render3DScene;
    procedure RenderShadowMap;
    procedure DrawSceneShadows;
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
    procedure DrawNativePopup;
    procedure HandlePopupInput;
    procedure ExecutePopupAction(Index: Integer);
    procedure SetFrustumCulling(const Value: Boolean);
    procedure SetDistanceCulling(const Value: Boolean);
    procedure SetMaxRenderDistance(const Value: Single);
    procedure PlayTestSound;
    procedure PlayImpactSound;
    procedure PlaySpawnSound;

    // Internal execution in the main thread
    procedure ExecuteSceneSave(const FileName: string);
    procedure ExecuteSceneLoad(const FileName: string);

  protected
    procedure Resize; override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
  public
    FCustomModel: TModel;
    FItems: TArray<TA3DComponent>;
    FMouseLeftHandled: Boolean;
    FSandboxSpawned: Boolean;
    FSpawnStatic: Boolean;
    FGhostVisible: Boolean;
    FIsBrushActive: Boolean;
    function ItemCount: Integer;
    procedure ClearItems;
    procedure DeleteSelectedActor;
    procedure SpawnObjects(Count: Integer; ShapeType: TShapeType);
    procedure SetBrush(AShape: TShapeType);
    procedure SetSimulationRunning(AValue: Boolean);
    procedure LoadCustomModel(const FilePath: string);
    function GetSimulationRunning: Boolean;
    function GetActorBoundingBoxWS(Actor: TA3DComponent): TBoundingBox;
    procedure SpawnAtMouse(Pos: TVector3);
    procedure SelectNextObject;
    procedure SelectPrevObject;

    // Exposes the custom spawn queue to external threads/UI
    procedure QueueCustomSpawn(const Request: TSpawnRequest);

    // External method to toggle slow motion externally
    procedure SetSlowMotion(Active: Boolean);

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
    procedure PublicShootBall;
    property Engine: TModelEngine read FEngine;
    property FrustumCulling: Boolean read FFrustumCulling write SetFrustumCulling;
    property DistanceCulling: Boolean read FDistanceCulling write SetDistanceCulling;
    // Exposed setter to control how far away objects get culled
    property MaxRenderDistance: Single read FMaxRenderDistance write SetMaxRenderDistance;
    procedure ReattachLoadedActor(Actor: TA3DComponent);
    procedure ClearDynamicItemsOnly;

    // Called from VCL to safely queue save/load in the render thread
    procedure SaveSceneToFile(const FileName: string);
    procedure LoadSceneFromFile(const FileName: string);
  published
    property Align;
    property Anchors;
    property Visible;
    property Active: Boolean read FActive write SetActive default False;
    property TargetFPS: Integer read FTargetFPS write SetTargetFPS default 60;
    property HighlightCollision: Boolean read FHighlightCollision write SetHighlightCollision;
    property ActiveBodies: Integer read FActiveBodies;
    property LastPhysicsTime: Single read FLastPhysicsTime;
    // Exposed for Object Inspector to allow manual day/night override
    property DayNightRhythmActive: Boolean read FDayNightRhythmActive write SetDayNightRhythmActive default True;
    property DayNightTime: Single read FDayTime write SetDayNightTime;
    property DayNightSpeed: Single read FDaySpeed write SetDayNightSpeed;
  end;

implementation

const
  COL_PRISM: TColorB = (
    r: 102;
    g: 205;
    b: 170;
    A: 255
  );
// Helper function to render text into a texture so it can be applied to 3D meshes

function DrawTextToTexture(const AText: string; FontSize: Integer; TextColor, BGColor: TColorB): TTexture2D;
var
  Img: TImage;
  W, H: Integer;
  Txt: AnsiString;
begin
  Txt := AnsiString(' ' + AText + ' ');
  if Length(Txt) = 0 then
    Txt := ' ';

  // Calculate width and height for the image canvas
  W := MeasureText(PAnsiChar(Txt), FontSize) + 4;
  H := FontSize + 4;

  // Generate an image filled with the BUTTON COLOR (not transparent!)
  Img := GenImageColor(W, H, BGColor);

  // Draw the text onto the image
  ImageDrawText(@Img, PAnsiChar(Txt), 2, 2, FontSize, TextColor);

  ImageFlipVertical(@Img);

  // Convert the image to a GPU texture
  Result := LoadTextureFromImage(Img);

  // Set trilinear filter so the text doesn't look pixelated up close
  SetTextureFilter(Result, TEXTURE_FILTER_TRILINEAR);

  // Free the CPU-side image data
  UnloadImage(Img);
end;

function GetCollisionHighlightingColor(intensity: Single): TColorB;
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
  FShadowMap.id := 0;
  FCustomModel.meshes := nil;
  FHUDAnimY := -150.0;
  FSceneStartTime := 0.0;
  FSpawnQueue := 0;
  FSpawnTimer := 0.0;
  FSpawnShape := stBox;
  FSpawnStatic := False;
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
  FLoadModelQueued := False;
  FQueuedModelPath := '';
  FAudioEngine := nil;
  FShadowBias := 0.003;
  FDayTime := 0.3; // Start at morning
  FDaySpeed := 0.01; // Day cycle speed
  FDayNightRhythmActive := True; // Enable automatic cycle by default
  FNavIndex := -1;

  // Optimization: Initialize default shader ID to 0
  FDefaultShader.id := 0;

  // Default render culling distance
  FMaxRenderDistance := 160.0;

  // Initialize Custom Spawn Queue
  FCustomSpawnQueue := nil;
  FCustomSpawnTimer := 0.0;

  // Initialize Slow Motion System
  FTimeScale := 1.0; // Default to normal speed
  FSlowMotionActive := False;

  // Init Scene Load/Save flags
  FSaveSceneQueued := False;
  FLoadSceneQueued := False;
  FQueuedSavePath := '';
  FQueuedLoadPath := '';
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
var
  i: Integer;
begin
  if FHighlightCollision <> Value then
  begin
    FHighlightCollision := Value;
    if not FHighlightCollision then
    begin
      for i := 0 to High(FItems) do
      begin
        if Assigned(FItems[i]) and (FItems[i] <> FItemSelected) then
          FItems[i].CollisionHighlighting := False;
      end;
    end;
  end;
end;

procedure TRaylibSandbox.SetDayNightRhythmActive(const Value: Boolean);
begin
  if FDayNightRhythmActive <> Value then
    FDayNightRhythmActive := Value;
end;

procedure TRaylibSandbox.SetDayNightTime(const Value: Single);
begin
  // Clamp the value between 0.0 and 1.0 to represent a full 24h cycle
  FDayTime := EnsureRange(Value, 0.0, 1.0);
end;

procedure TRaylibSandbox.SetDayNightSpeed(const Value: Single);
begin
  // Clamp the value to a reasonable range (e.g., 0.0 to pause, up to 1.0 for very fast)
  // Ensure the speed cannot be negative to prevent time going backwards unintentionally
  FDaySpeed := EnsureRange(Value, 0.0, 1.0);
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

procedure TRaylibSandbox.SetMaxRenderDistance(const Value: Single);
begin
  // Allow custom distance culling ranges, enforcing a sane minimum
  if Value > 10.0 then
    FMaxRenderDistance := Value
  else
    FMaxRenderDistance := 10.0;
end;

procedure TRaylibSandbox.InitLightingAndEnvironment;
const
  VERT: AnsiString = '#version 330' + #10 + 'in vec3 vertexPosition;' + #10 + 'in vec3 vertexNormal;' + #10 + 'in vec2 vertexTexCoord;' + #10 + 'in vec4 vertexColor;' + #10 + 'uniform mat4 mvp;' + #10 + 'uniform mat4 matModel;' + #10 + 'uniform mat4 lightView;' + #10 + 'uniform mat4 lightProj;' + #10 + 'out vec3 vNormal;' + #10 + 'out vec2 vTexCoord;' + #10 + 'out vec4 vColor;' + #10 + 'out vec4 vWorldPos;' + #10 + 'out vec4 vLightSpacePos;' + #10 + 'void main()' + #10 + '{' + #10 +
    '  vWorldPos = matModel * vec4(vertexPosition, 1.0);' + #10 + '  vNormal = normalize(mat3(matModel) * vertexNormal);' + #10 + '  vTexCoord = vertexTexCoord;' + #10 + '  vColor = vertexColor;' + #10 + '  vLightSpacePos = lightProj * lightView * vWorldPos;' + #10 + '  gl_Position = mvp * vec4(vertexPosition, 1.0);' + #10 + '}';
  FRAG: AnsiString = '#version 330' + #10 + 'in vec3 vNormal;' + #10 + 'in vec2 vTexCoord;' + #10 + 'in vec4 vColor;' + #10 + 'in vec4 vWorldPos;' + #10 + 'in vec4 vLightSpacePos;' + #10 + 'uniform vec3 lightPos;' + #10 + 'uniform vec3 viewPos;' + #10 + 'uniform vec4 ambient;' + #10 + 'uniform vec4 diffuse;' + #10 + 'uniform sampler2D texture0;' + #10 + 'uniform sampler2D shadowMap;' + #10 + 'uniform float shadowBias;' + #10 + 'out vec4 finalColor;' + #10 + 'void main()' + #10 + '{' + #10 +
    '  vec3 lightDir = normalize(lightPos - vWorldPos.xyz);' + #10 + '  vec3 normal = normalize(vNormal);' + #10 + '  float diff = max(dot(normal, lightDir), 0.0);' + #10 + '  vec4 texColor = texture(texture0, vTexCoord);' + #10 + 'vec4 baseColor = vec4(vColor.rgb, 1.0) * vec4(texColor.rgb, 1.0);' + #10 + '  vec4 ambientColor = ambient * baseColor;' + #10 + '  vec4 diffuseColor = diffuse * diff * baseColor;' + #10 + '  vec3 projCoords = vLightSpacePos.xyz / vLightSpacePos.w;' + #10 +
    '  projCoords = projCoords * 0.5 + 0.5;' + #10 + '  float shadow = 0.0;' + #10 + '  if(projCoords.z <= 1.0 && projCoords.x >= 0.0 && projCoords.x <= 1.0 && projCoords.y >= 0.0 && projCoords.y <= 1.0) {' + #10 + '    float closestDepth = texture(shadowMap, projCoords.xy).r;' + #10 + '    float currentDepth = projCoords.z;' + #10 + '    shadow = currentDepth - shadowBias > closestDepth ? 1.0 : 0.0;' + #10 + '  }' + #10 + '  finalColor = ambientColor + diffuseColor * (1.0 - shadow);' + #10 + '}';  // Procedural Skybox Shader
  SKYBOX_VERT: AnsiString = '#version 330' + #10 + 'in vec3 vertexPosition;' + #10 + 'out vec3 fragPosition;' + #10 + 'uniform mat4 projection;' + #10 + 'uniform mat4 view;' + #10 + 'void main()' + #10 + '{' + #10 + '  fragPosition = vertexPosition;' + #10 + '  mat4 rotView = mat4(mat3(view));' + #10 + // Remove translation
    '  vec4 clipPos = projection * rotView * vec4(vertexPosition, 1.0);' + #10 + '  gl_Position = clipPos.xyww;' + #10 + // Force depth to 1.0 (background)
    '}';
  SKYBOX_FRAG: AnsiString = '#version 330' + #10 + 'in vec3 fragPosition;' + #10 + 'uniform float daytime;' + #10 + 'out vec4 finalColor;' + #10 + 'void main()' + #10 + '{' + #10 + '  vec3 dir = normalize(fragPosition);' + #10 + '  float t = dir.y * 0.5 + 0.5;' + #10 +
    // Mix horizon and zenith colors based on day/night
    '  vec3 horizonColor = mix(vec3(0.8, 0.4, 0.1), vec3(0.2, 0.4, 0.8), smoothstep(0.0, 0.3, daytime));' + #10 + '  vec3 zenithColor = mix(vec3(0.05, 0.05, 0.1), vec3(0.0, 0.4, 0.9), smoothstep(0.0, 0.5, daytime));' + #10 + '  vec3 skyColor = mix(horizonColor, zenithColor, smoothstep(0.0, 0.4, t));' + #10 + '  finalColor = vec4(skyColor, 1.0);' + #10 + '}';
  // Cloud Shader
  CLOUD_VERT: AnsiString = '#version 330' + #10 + 'in vec3 vertexPosition;' + #10 + 'in vec2 vertexTexCoord;' + #10 + 'out vec2 vTexCoord;' + #10 + 'uniform mat4 mvp;' + #10 + 'void main()' + #10 + '{' + #10 + '  vTexCoord = vertexTexCoord;' + #10 + '  gl_Position = mvp * vec4(vertexPosition, 1.0);' + #10 + '}';
  CLOUD_FRAG: AnsiString = '#version 330' + #10 + 'in vec2 vTexCoord;' + #10 + 'out vec4 finalColor;' + #10 + 'uniform sampler2D texture0;' + #10 + 'uniform float moveFactor;' + #10 + 'uniform float daytime;' + #10 + 'void main()' + #10 + '{' + #10 + '  vec2 uv = vTexCoord + vec2(moveFactor, moveFactor * 0.5);' + #10 + '  vec4 cloudTex = texture(texture0, uv);' + #10 + '  vec3 cloudColor = mix(vec3(0.2, 0.2, 0.2), vec3(1.0, 1.0, 1.0), daytime);' + #10 + '  finalColor = vec4(cloudColor, cloudTex.a * 0.8);' + #10 + '}';
var
  SkyMesh, CloudMesh: TMesh;
  FilePath: string;
begin
  // Sichere 1x1 weiße Textur generieren, damit Shader nie ins Leere laufen (Schwarz)
  var WhiteImg := GenImageColor(1, 1, WHITE);
  FDefaultWhiteTex := LoadTextureFromImage(WhiteImg);
  UnloadImage(WhiteImg);

  // Initialize Main Lighting Shader
  FLightShader := LoadShaderFromMemory(PAnsiChar(VERT), PAnsiChar(FRAG));
  FLightPosLoc := GetShaderLocation(FLightShader, 'lightPos');
  FViewPosLoc := GetShaderLocation(FLightShader, 'viewPos');
  FAmbientLoc := GetShaderLocation(FLightShader, 'ambient');
  FDiffuseLoc := GetShaderLocation(FLightShader, 'diffuse');
  FShadowMapLoc := GetShaderLocation(FLightShader, 'shadowMap');
  FLightViewLoc := GetShaderLocation(FLightShader, 'lightView');
  FLightProjLoc := GetShaderLocation(FLightShader, 'lightProj');

  // Optimization: Create the default shader once to prevent loading/unloading it every frame in RenderShadowMap
  FDefaultShader := LoadShader(nil, nil);

  FShadowMap := LoadRenderTexture(2048, 2048);
  SetTextureFilter(FShadowMap.texture, TEXTURE_FILTER_TRILINEAR);

  FLightPos := Vector3Create(50, 80, 30);
  FCameraMoved := True;

  FLightCam.position := Vector3Create(0, 80, 0);
  FLightCam.target := Vector3Create(0, 0, 0);
  FLightCam.up := Vector3Create(0, 1, 0);
  FLightCam.fovy := 20.0;
  FLightCam.projection := CAMERA_ORTHOGRAPHIC;

  SetTextureFilter(FWhiteTex, TEXTURE_FILTER_TRILINEAR);
  FDefaultMat := LoadMaterialDefault();
  FDefaultMat.shader := FLightShader;
  FDefaultMat.maps[MATERIAL_MAP_ALBEDO].Color := WHITE;

  FUnitBox := GenMeshCube(1.0, 1.0, 1.0);
  UploadMesh(@FUnitBox, False);
  FUnitSphere := GenMeshSphere(1.0, 16, 16);
  UploadMesh(@FUnitSphere, False);

  // Generate standard meshes for solid drawing
  FUnitCylinder := GenMeshCylinder(0.5, 1.0, 24);
  UploadMesh(@FUnitCylinder, False);
  FUnitCone := GenMeshCone(0.5, 1.0, 4);
  UploadMesh(@FUnitCone, False);
  FUnitPrism := GenMeshCylinder(0.5, 1.0, 3);
  UploadMesh(@FUnitPrism, False);

  // Generate models for all primitive shapes to ensure consistent shader handling
  FBoxModel := LoadModelFromMesh(GenMeshCube(1.0, 1.0, 1.0));
  FSphereModel := LoadModelFromMesh(GenMeshSphere(1.0, 16, 16));
  FCapsuleModel := LoadModelFromMesh(GenMeshCylinder(0.5, 1.0, 24));
  FPyramidModel := LoadModelFromMesh(GenMeshCone(0.5, 1.0, 4));
  FPrismModel := LoadModelFromMesh(GenMeshCylinder(0.5, 1.0, 3));

  // We assign a rotation quaternion so the shader knows the normals rotate with the object
  FPrismModel.transform := MatrixRotateY(120.0 * DEG2RAD);
  FBoxModel.materials[0].shader := FLightShader;
  FSphereModel.materials[0].shader := FLightShader;
  FCapsuleModel.materials[0].shader := FLightShader;
  FPyramidModel.materials[0].shader := FLightShader;
  FPyramidModel.transform := MatrixRotateY(45.0 * DEG2RAD);
  FPrismModel.transform := MatrixRotateY(120.0 * DEG2RAD);
  FPrismModel.materials[0].shader := FLightShader;

  // Sichere weiße Standard-Textur für alle Modelle setzen!
  FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;
  FSphereModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;
  FCapsuleModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;

  // Initialize Skybox
  FSkyboxShader := LoadShaderFromMemory(PAnsiChar(SKYBOX_VERT), PAnsiChar(SKYBOX_FRAG));
  FSkyboxDaytimeLoc := GetShaderLocation(FSkyboxShader, 'daytime');
  FSkyboxViewLoc := GetShaderLocation(FSkyboxShader, 'view');
  FSkyboxProjLoc := GetShaderLocation(FSkyboxShader, 'projection');

  SkyMesh := GenMeshCube(1.0, 1.0, 1.0);
  FSkyboxModel := LoadModelFromMesh(SkyMesh);
  FSkyboxModel.materials[0].shader := FSkyboxShader;

  // Load Skybox textures
  FilePath := ExtractFilePath(ParamStr(0)) + 'resources/';
  if FileExists(PAnsiChar(AnsiString(FilePath + 'skyGradient.png'))) then
  begin
    FSkyboxTex := LoadTexture(PAnsiChar(AnsiString(FilePath + 'skyGradient.png')));
    SetTextureFilter(FSkyboxTex, TEXTURE_FILTER_TRILINEAR);
    // Procedural shader is used for simplicity here.
  end;

  // Initialize Clouds
  FCloudShader := LoadShaderFromMemory(PAnsiChar(CLOUD_VERT), PAnsiChar(CLOUD_FRAG));
  FCloudMoveFactorLoc := GetShaderLocation(FCloudShader, 'moveFactor');
  FCloudDaytimeLoc := GetShaderLocation(FCloudShader, 'daytime');

  CloudMesh := GenMeshPlane(2000, 2000, 1, 1);
  FCloudModel := LoadModelFromMesh(CloudMesh);
  FCloudModel.transform := MatrixTranslate(0, 150, 0);
  FCloudModel.materials[0].shader := FCloudShader;

  if FileExists(PAnsiChar(AnsiString(FilePath + 'clouds.png'))) then
  begin
    FCloudTex := LoadTexture(PAnsiChar(AnsiString(FilePath + 'clouds.png')));
    SetTextureFilter(FCloudTex, TEXTURE_FILTER_TRILINEAR);
    SetTextureWrap(FCloudTex, TEXTURE_WRAP_REPEAT);
    FCloudModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FCloudTex;
  end;

  // Load Ambient Gradient
  if FileExists(PAnsiChar(AnsiString(FilePath + 'ambientGradient.png'))) then
  begin
    FAmbientGradientTex := LoadTexture(PAnsiChar(AnsiString(FilePath + 'ambientGradient.png')));
    SetTextureFilter(FAmbientGradientTex, TEXTURE_FILTER_TRILINEAR);
  end;
end;

procedure TRaylibSandbox.PlayTestSound;
var
  Res: Integer;
begin
  if FAudioEngine <> nil then
  begin
    Res := ma_engine_play_sound(FAudioEngine, 'ressources\audio\test.wav', nil);
    if Res <> MA_SUCCESS then
      DoEngineException('Failed to play test.wav', 'AudioEngine');
  end;
end;

procedure TRaylibSandbox.PlaySpawnSound;
var
  Res: Integer;
begin
  if FAudioEngine <> nil then
  begin
    Res := ma_engine_play_sound(FAudioEngine, 'ressources\audio\impactPlank_medium_000.wav', nil);
    if Res <> MA_SUCCESS then
      DoEngineException('Failed to play impactPlank_medium_000.wav', 'AudioEngine');
  end;
end;

procedure TRaylibSandbox.PlayImpactSound;
var
  Res: Integer;
begin
  if FAudioEngine <> nil then
  begin
    Res := ma_engine_play_sound(FAudioEngine, 'ressources\audio\explosionCrunch_004.wav', nil);
    if Res <> MA_SUCCESS then
      DoEngineException('Failed to play explosionCrunch_004.wav', 'AudioEngine');
  end;
end;

procedure TRaylibSandbox.StartThread;
var
  AudioRes: Integer;
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
          GetMem(FAudioEngine, ma_engine_sizeof());
          AudioRes := ma_engine_init(nil, FAudioEngine);
          if AudioRes <> MA_SUCCESS then
            DoEngineException('Audio Engine Init failed: ' + IntToStr(AudioRes), 'AudioInit');

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

          InitLightingAndEnvironment;
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
          begin
            DoEngineException(E.Message, 'EngineInit');
            // Fallback to ensure we don't freeze if InitWindow fails catastrophically
            FInitialized := True;
          end;
        end;
      finally
        try
          timeEndPeriod(1);
          FInitialized := False;
          ClearItems;
          FreeAndNil(FFloorActor);
          FreeAndNil(FEngine);
          if FShadowMap.id > 0 then
            UnloadRenderTexture(FShadowMap);
          if FCustomModel.meshes <> nil then
            UnloadModel(FCustomModel);
          if FLightShader.id > 0 then
            UnloadShader(FLightShader);

          // Optimization: Unload cached default shader used for shadow mapping
              if FDefaultShader.id > 0 then
            UnloadShader(FDefaultShader);

          if FSkyboxShader.id > 0 then
          begin
            UnloadShader(FSkyboxShader);
            UnloadModel(FSkyboxModel);
            if FSkyboxTex.id > 0 then
              UnloadTexture(FSkyboxTex);
          end;
          if FCloudShader.id > 0 then
          begin
            UnloadShader(FCloudShader);
            UnloadModel(FCloudModel);
            if FCloudTex.id > 0 then
              UnloadTexture(FCloudTex);
          end;
          if FAmbientGradientTex.id > 0 then
            UnloadTexture(FAmbientGradientTex);
          if FWhiteTex.id > 0 then
            UnloadTexture(FWhiteTex);
          if FDefaultWhiteTex.id > 0 then
            UnloadTexture(FDefaultWhiteTex);
          UnloadMesh(FUnitBox);
          UnloadMesh(FUnitSphere);
          if FAudioEngine <> nil then
          begin
            ma_engine_uninit(FAudioEngine);
            FreeMem(FAudioEngine);
            FAudioEngine := nil;
          end;
          if Assigned(FMPVPlayer) then
            FreeAndNil(FMPVPlayer);
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
  // No walls are generated to keep the skybox horizon fully visible
  FFloorActor := TA3DComponent.Create('', FEngine, stBox, Vector3Create(1000, 1, 1000), True);
  FFloorActor.SetPosition(Vector3Create(0, -0.5, 0));
  FFloorActor.Visible := False;
  FFloorActor.Friction := 0.5;

  // Initialize items array
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
    // Clear custom spawn queue to prevent further scripted spawns after clearing
    FCustomSpawnQueue := nil;
    FBombActor := nil;
    FBombExploded := False;
    SetBrush(TShapeType(-1));
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

procedure TRaylibSandbox.QueueCustomSpawn(const Request: TSpawnRequest);
begin
  // Thread-safe addition to the custom spawn queue
  FLock.Enter;
  try
    SetLength(FCustomSpawnQueue, Length(FCustomSpawnQueue) + 1);
    FCustomSpawnQueue[High(FCustomSpawnQueue)] := Request;
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
  if FSpawnTimer > 0 then
  begin
    FSpawnTimer := FSpawnTimer - dt;
    Exit;
  end;
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
    stCapsule:
      Data^.Name := 'Capsule_' + IntToStr(oldLen);
    stPrism:
      Data^.Name := 'Prism_' + IntToStr(oldLen);
  end;
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
  Obj := TA3DComponent.Create('', FEngine, FSpawnShape, Size, FSpawnStatic, @JPos, @JRot);
  Obj.Name := Data^.Name;
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
      FCamPitch := EnsureRange(FCamPitch + (p.y - FLastMouse.y) * 0.006, 0.05, 1.53);
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
  FCamera.target.x := EnsureRange(FCamera.target.x, -450.0, 450.0);
  FCamera.target.z := EnsureRange(FCamera.target.z, -450.0, 450.0);
  if GetMouseWheelMove() <> 0 then
  begin
    FCamDist := EnsureRange(FCamDist - GetMouseWheelMove() * 3.0, 10, 250);
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

procedure TRaylibSandbox.PublicShootBall;
begin
  PlayTestSound;
  ShootBall;
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
  CurrVel: TVector3;
  SpeedSq: Single;
begin
  for i := High(FProjectiles) downto 0 do
  begin
    if FProjectiles[i] = nil then
      Continue;

    Actor := FProjectiles[i];

    // If the projectile is already marked as dead, free its memory and nil the pointer
    if Actor.FIsDead then
    begin
      if Actor.UserData <> nil then
        Dispose(PItemData(Actor.UserData));
      Actor.Free;
      FProjectiles[i] := nil;
      Continue;
    end;

    if Actor.UserData <> nil then
    begin
      // Lifespan check: Destroy the projectile after 5 seconds
      if GetTime() - PItemData(Actor.UserData)^.SpawnTime > 5.0 then
      begin
        Actor.FIsDead := True;
        Continue;
      end;

      // Velocity check: Destroy the projectile if it slows down too much
      CurrVel := Actor.GetLinearVelocity;

      // We calculate the squared length of the velocity vector (Speed * Speed).
      // This is much faster than using Vector3Length as it avoids a square root operation.
      // We compare it against 25.0, which means the projectile dies if its speed drops below 5.0 units/sec.
      SpeedSq := (CurrVel.x * CurrVel.x) + (CurrVel.y * CurrVel.y) + (CurrVel.z * CurrVel.z);

      if SpeedSq < 25.0 then
      begin
        Actor.FIsDead := True;
        Continue;
      end;

      // Store the current velocity for the next frame (useful for debugging or future logic)
      PItemData(Actor.UserData)^.OldVelocity := CurrVel;
    end;
  end;

  // Compress the array: Remove all nil pointers so the array doesn't grow infinitely
  if Length(FProjectiles) > 0 then
  begin
    var CurrIdx: Integer := 0;
    for i := 0 to High(FProjectiles) do
    begin
      if FProjectiles[i] <> nil then
      begin
        FProjectiles[CurrIdx] := FProjectiles[i];
        Inc(CurrIdx);
      end;
    end;
    // Resize the array to fit only the surviving projectiles
    SetLength(FProjectiles, CurrIdx);
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
  downRay: TRay;
  downHit: TRayCollision;
  topY: Single;
  HalfH, HalfX, HalfZ, HalfY: Single;
  GScaleX, GScaleY, GScaleZ: Single;
  TargetY, t: Single;
  bIsModelBrush: Boolean;
  bLeftMouseDown: Boolean;
  bLeftMouseClicked: Boolean;
  R: TRect;
begin
  // PREVENT BACKGROUND CLICKS: Only process input if the mouse cursor
  // is actually hovering over the Raylib window area!
  GetWindowRect(FRaylibWnd, R);
  GetCursorPos(p);
  if not PtInRect(R, p) then
  begin
    FMouseLeftPressed := False;
    FDragging := False;
    Exit;
  end;

  // Handle Delete Key directly inside the sandbox thread
  if (GetAsyncKeyState(VK_DELETE) and $1) <> 0 then
  begin
    if Assigned(FItemSelected) then
    begin
      // Disable brush to prevent instant respawn of a standard cube
      FIsBrushActive := False;
      FGhostVisible := False;
      DeleteSelectedActor;
      Exit;
    end;
  end;

  // Prevent background clicks and accidental brushing when the popup menu is open
  if FPopupOpen then
  begin
    HandlePopupInput;
    Exit;
  end;

  // Select next/prev object
  if (GetAsyncKeyState(VK_CONTROL) and $8000) <> 0 then
  begin
    if (GetAsyncKeyState(Ord('Q')) and $1) <> 0 then
    begin
      SelectPrevObject;
      Exit;
    end
    else if (GetAsyncKeyState(Ord('E')) and $1) <> 0 then
    begin
      SelectNextObject;
      Exit;
    end;
  end;

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
  bLeftMouseDown := (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0;
  bLeftMouseClicked := bLeftMouseDown and not FMouseLeftPressed;
  FMouseLeftPressed := bLeftMouseDown;

  if (GetAsyncKeyState(VK_CONTROL) and $8000) <> 0 then
  begin
    if not FCtrlWasPressed then
    begin
      // Cycle through tools including the new explicit Drag & Throw tool
      if FGizmoMode = gmTranslate then
        FGizmoMode := gmRotate
      else if FGizmoMode = gmRotate then
        FGizmoMode := gmScale
      else if FGizmoMode = gmScale then
        FGizmoMode := gmDragAndThrow
      else if FGizmoMode = gmDragAndThrow then
        FGizmoMode := gmNone
      else if FGizmoMode = gmNone then
        FGizmoMode := gmTranslate;
      FCtrlWasPressed := True;
    end;
  end
  else
    FCtrlWasPressed := False;

  ray := GetScreenToWorldRay(FMousePos, FCamera);

  // ====================================================================
  // 3D BUTTON INTERACTION LOGIC (Hover & Click)
  // Handles UI clicks independent from physics tools
  // ====================================================================
  var ClosestButtonDist: Single := 1e9;
  var HoveredButton: TA3DComponent := nil;

  // Reset hover states for all buttons
  for i := 0 to High(FItems) do
    if Assigned(FItems[i]) and (FItems[i].ShapeType = stButton) then
      FItems[i].IsHovered := False;

  // Find the closest button under the mouse cursor
  for i := 0 to High(FItems) do
  begin
    if Assigned(FItems[i]) and (FItems[i].ShapeType = stButton) then
    begin
      HalfX := FItems[i].Scale.x * 0.5;
      HalfY := FItems[i].Scale.y * 0.5;
      HalfZ := FItems[i].Scale.z * 0.5;
      itemBox.min := Vector3Create(FItems[i].position.x - HalfX, FItems[i].position.y - HalfY, FItems[i].position.z - HalfZ);
      itemBox.max := Vector3Create(FItems[i].position.x + HalfX, FItems[i].position.y + HalfY, FItems[i].position.z + HalfZ);

      hitInfo := GetRayCollisionBox(ray, itemBox);
      if hitInfo.hit and (hitInfo.distance < ClosestButtonDist) then
      begin
        ClosestButtonDist := hitInfo.distance;
        HoveredButton := FItems[i];
      end;
    end;
  end;

  if Assigned(HoveredButton) then
  begin
    HoveredButton.IsHovered := True;

    if bLeftMouseClicked then
    begin
      HoveredButton.IsPressed := True;
      FMouseLeftHandled := True;
    end
    else if (not FMouseLeftPressed) and HoveredButton.IsPressed then
    begin
      // Mouse released -> Trigger OnClick!
      HoveredButton.IsPressed := False;
      FMouseLeftHandled := True;

      // Fire Event thread-safe to avoid VCL cross-thread exceptions
      if Assigned(HoveredButton.OnClick) then
      begin
        var Callback := HoveredButton.OnClick;
        var BtnRef := HoveredButton;

        // CRITICAL: Set to nil to prevent spam firing in the next frames!
        HoveredButton.OnClick := nil;

        TThread.Queue(nil,
          procedure
          begin
            Callback(BtnRef);
            // Restore the OnClick event for the next time
            BtnRef.OnClick := Callback;
          end);
      end;
    end;

    Exit; // Prevent selecting 3D objects behind the button
  end
  else
  begin
    // If mouse is released outside any button, unpress all buttons
    if not FMouseLeftPressed then
    begin
      for i := 0 to High(FItems) do
        if Assigned(FItems[i]) and (FItems[i].ShapeType = stButton) then
          FItems[i].IsPressed := False;
    end;
  end;

  if (GetAsyncKeyState(VK_RBUTTON) and $8000) <> 0 then
  begin
    if not FRightClickWasPressed then
    begin
      if not FIsBrushActive then
      begin
        FPopupOpen := True;
        FPopupPos := FMousePos;

        // If gmNone is active, we do strictly nothing else (no object dragging)
        if FGizmoMode = gmNone then
          Exit;

        groundBox.min := Vector3Create(-1000, -0.1, -1000);
        groundBox.max := Vector3Create(1000, 0.1, 1000);
        hitInfo := GetRayCollisionBox(ray, groundBox);
        if hitInfo.hit then
        begin
          FGhostPos.x := hitInfo.point.x;
          FGhostPos.y := 0;
          FGhostPos.z := hitInfo.point.z;
        end;

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

  if (GetAsyncKeyState(VK_MBUTTON) and $8000) <> 0 then
  begin
    FGhostVisible := False;
    Exit;
  end;

  ray := GetScreenToWorldRay(FMousePos, FCamera);

  if FGizmoMode = gmDragAndThrow then
  begin
    if FDragging and Assigned(FItemSelected) then
    begin
      if bLeftMouseDown then
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
        FDragging := False;
    end
    else if bLeftMouseDown then
    begin
      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;
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
    Exit;
  end;

  if FGizmoDragging then
  begin
    UpdateGizmoInteraction;
    if not bLeftMouseDown then
    begin
      FGizmoDragging := False;
      FGizmoAxis := 0;
      if Assigned(FItemSelected) then
      begin
        // CRITICAL FIX: Force the physics engine to accept the new shape size immediately!
        // Otherwise Jolt will reject the reattach and slowly push the object out of the ground.
        FItemSelected.Scale := FItemSelected.Scale;
        FItemSelected.SetPosition(FItemSelected.Position);
        FItemSelected.ReattachToPhysics;
      end;
    end;
    // CRITICAL: DO NOT update FGizmoStartMouse here!
    Exit;
  end;

  if Assigned(FItemSelected) and not FIsBrushActive then
  begin
    if bLeftMouseDown then
    begin
      // Calculate default gizmo bounds for primitives
      GScaleX := EnsureRange((FItemSelected.Scale.x * 0.5) + 1.0, 1.0, 100.0);
      GScaleY := EnsureRange((FItemSelected.Scale.y * 0.5) + 1.0, 1.0, 100.0);
      GScaleZ := EnsureRange((FItemSelected.Scale.z * 0.5) + 1.0, 1.0, 100.0);

      // Increase the thickness of the invisible click-box for primitives
      var ClickRadius: Single := 0.4;

      if FItemSelected.ShapeType = stModel then
      begin
        var BBox := GetModelBoundingBox(FItemSelected.FModel);
        var PhysRadius := Max(BBox.max.x - BBox.min.x, Max(BBox.max.y - BBox.min.y, BBox.max.z - BBox.min.z)) * Max(FItemSelected.Scale.x, Max(FItemSelected.Scale.y, FItemSelected.Scale.z)) * 0.5;

        // Make arms reach outside the mesh
        GScaleX := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
        GScaleY := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
        GScaleZ := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);

        // Make the invisible click-box thicker so the mouse ray definitely hits the arrow before the mesh!
        ClickRadius := 1.0;
      end;

      if FGizmoMode = gmTranslate then
      begin
        if CheckGizmoAxisHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), ClickRadius, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Position;
          FGizmoStartPos := FItemSelected.Position; // Save position for Scale mode
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end
      else if FGizmoMode = gmRotate then
      begin
        if CheckGizmoRingHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), ClickRadius, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Position;
          FGizmoStartPos := FItemSelected.Position; // Save position for Scale mode
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end
      else if FGizmoMode = gmScale then
      begin
        if CheckGizmoScaleHit(FItemSelected.Position, Vector3Create(GScaleX, GScaleY, GScaleZ), ClickRadius, ray, FGizmoAxis) then
        begin
          FGizmoDragging := True;
          FGizmoStartMouse := FMousePos;
          FGizmoStartVal := FItemSelected.Scale;
          FGizmoStartPos := FItemSelected.Position; // Save position to calculate Y-Lift
          FGizmoStartQuat := FItemSelected.Quaternion;
          FMouseLeftHandled := True;
          FItemSelected.DetachFromPhysics;
          Exit;
        end;
      end;
    end;
  end;

  bIsModelBrush := FIsBrushActive and (FBrushShape = stModel);
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
      if not bIsModelBrush then
        FGhostPos.y := topY
      else
        FGhostPos.y := hitInfo.point.y;
      FGhostPos.z := hitInfo.point.z;
      FGhostVisible := True;
      if bLeftMouseClicked and (FShootCooldown <= 0) then
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

  if FShootCooldown > 0 then
    Exit;

  // CRITICAL OBJECT SELECTION BLOCK
  if bLeftMouseDown then
  begin
    if not FDragging then
    begin
      // Find the CLOSEST object to the camera under the mouse cursor
      var ClosestActor: TA3DComponent := nil;
      var ClosestDist: Single := 1e9;
      var TempHit: TRayCollision;

      for i := 0 to High(FItems) do
      begin
        if FItems[i] = nil then
          Continue;

        HalfX := FItems[i].Scale.x * 0.5;
        HalfY := FItems[i].Scale.y * 0.5;
        HalfZ := FItems[i].Scale.z * 0.5;

        itemBox.min := Vector3Create(FItems[i].Position.x - HalfX, FItems[i].Position.y - HalfY, FItems[i].Position.z - HalfZ);
        itemBox.max := Vector3Create(FItems[i].Position.x + HalfX, FItems[i].Position.y + HalfY, FItems[i].Position.z + HalfZ);

        TempHit := GetRayCollisionBox(ray, itemBox);
        if TempHit.hit then
        begin
          if TempHit.distance < ClosestDist then
          begin
            ClosestDist := TempHit.distance;
            ClosestActor := FItems[i];
          end;
        end;
      end;

      // After checking all objects, select the closest one
      if Assigned(ClosestActor) then
      begin
        if FItemSelected <> ClosestActor then
        begin
          FItemSelected := ClosestActor;
          DoObjectSelected(FItemSelected);
        end;
        FDragging := True; // JUST MARK IT, DO NOT DETACH FROM PHYSICS HERE!
      end
      else
      begin
        // Clicked into empty space -> deselect
        if Assigned(FItemSelected) then
        begin
          FItemSelected := nil;
          DoObjectSelected(nil);
        end;
      end;
    end;
  end
  else
    FDragging := False;
end;

procedure TRaylibSandbox.HandlePopupInput;
var
  I: Integer;
  Rect: TRectangle;
  NewHover: Integer;
  IconRect: TRectangle;
begin
  FMousePos := GetMousePosition();
  NewHover := -1;

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
        NewHover := I + 100;
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
        ExecutePopupAction(FPopupHoverIndex)
      else
        ExecutePopupAction(FPopupHoverIndex - 100);
    end;

    FPopupOpen := False;
    // Prevents the click that closed the popup from selecting/deselecting 3D objects in the background!
    FMouseLeftHandled := True;
  end;
end;

procedure TRaylibSandbox.ExecutePopupAction(Index: Integer);
var
  NewActor: TA3DComponent;
  NewPos: TVector3;
  NewRot: JPH_Quat;
  NewSize: TVector3;
  NewData: PItemData;
  OldLen: Integer;
begin
  if (Index >= 0) and (Index <= High(FPopupSegments)) then
  begin
    if FPopupSegments[Index] = 'Delete' then
    begin
      FIsBrushActive := False;
      FGhostVisible := False;
      DeleteSelectedActor;
      Exit;
    end
    else if FPopupSegments[Index] = 'Duplicate' then
    begin
      if not Assigned(FItemSelected) then
        Exit;

      OldLen := Length(FItems);
      SetLength(FItems, OldLen + 1);

      NewPos.x := FItemSelected.Position.x + 1.0;
      NewPos.y := FItemSelected.Position.y + (FItemSelected.Scale.y * 0.5);
      NewPos.z := FItemSelected.Position.z;

      NewRot.x := FItemSelected.Quaternion.x;
      NewRot.y := FItemSelected.Quaternion.y;
      NewRot.z := FItemSelected.Quaternion.z;
      NewRot.w := FItemSelected.Quaternion.w;
      NewSize := FItemSelected.Scale;

      NewActor := TA3DComponent.Create('', FEngine, FItemSelected.ShapeType, NewSize, FSpawnStatic, @NewPos, @NewRot);
      NewActor.Friction := FItemSelected.Friction;
      NewActor.Restitution := FItemSelected.Restitution;
      NewActor.TargetColor := FItemSelected.TargetColor;
      NewActor.ActColor := FItemSelected.ActColor;

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
      PlaySpawnSound;
      DoActorSpawned(NewActor, OldLen);
      DoObjectSelected(NewActor);
      FItemSelected := NewActor;

      Exit;
    end;
  end;

  if (Index >= 0) and (Index <= 4) then
  begin
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
  end;

  FMouseLeftPressed := True;
  FMouseLeftHandled := True;
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
    if FItemSelected.FBodyID <> 0 then
    begin
      JPH_BodyInterface_RemoveAndDestroyBody(FEngine.BodyInterface, FItemSelected.FBodyID);
      FItemSelected.FBodyID := 0;
    end;
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
  RotAxis, WorldAxis, CamForward, MoveDir: TVector3;
  LocalMove: TVector3;
  CamDot: Single;
  // Variables for Y-Lift ground stabilization
  OldScaleY, NewScaleY, YLift: Single;
begin
  MouseDeltaX := FMousePos.x - FGizmoStartMouse.x;
  MouseDeltaY := FMousePos.y - FGizmoStartMouse.y;

  if Abs(MouseDeltaX) < 0.5 then
    MouseDeltaX := 0;
  if Abs(MouseDeltaY) < 0.5 then
    MouseDeltaY := 0;

  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  if FGizmoMode = gmTranslate then
  begin
    WorldAxis := Vector3Create(0, 0, 0);
    if FGizmoAxis = 1 then
      WorldAxis := Vector3Create(1, 0, 0)
    else if FGizmoAxis = 2 then
      WorldAxis := Vector3Create(0, 1, 0)
    else if FGizmoAxis = 3 then
      WorldAxis := Vector3Create(0, 0, 1);

    WorldAxis := Vector3RotateByQuaternion(WorldAxis, FItemSelected.Quaternion);

    var ScreenRight := Vector3Create(1, 0, 0);
    var ScreenUp := Vector3Create(0, 1, 0);

    MoveDir := Vector3Add(Vector3Scale(ScreenRight, MouseDeltaX * 0.1), Vector3Scale(ScreenUp, -MouseDeltaY * 0.1));

    CamDot := Vector3DotProduct(WorldAxis, MoveDir);
    LocalMove := Vector3Scale(WorldAxis, CamDot);

    NewPos := Vector3Add(FGizmoStartVal, LocalMove);
    FItemSelected.SetPosition(NewPos);
  end
  else if FGizmoMode = gmRotate then
  begin
    RotAxis := Vector3Create(0, 0, 0);
    if FGizmoAxis = 1 then
      RotAxis := Vector3RotateByQuaternion(Vector3Create(1, 0, 0), FItemSelected.Quaternion)
    else if FGizmoAxis = 2 then
      RotAxis := Vector3RotateByQuaternion(Vector3Create(0, 1, 0), FItemSelected.Quaternion)
    else if FGizmoAxis = 3 then
      RotAxis := Vector3RotateByQuaternion(Vector3Create(0, 0, 1), FItemSelected.Quaternion);

    if FGizmoAxis = 2 then
      RotAngle := (MouseDeltaX * 0.25) + (MouseDeltaY * 0.25)
    else
      RotAngle := (-MouseDeltaY * 0.5) + (MouseDeltaX * 0.25);

    if Abs(RotAngle) > 0.1 then
    begin
      RotDelta := QuaternionFromAxisAngle(RotAxis, DegToRad(RotAngle));
      FItemSelected.SetRotation(QuaternionMultiply(RotDelta, FGizmoStartQuat));
      if (Abs(FMousePos.x - FGizmoStartMouse.x) > 0.5) or (Abs(FMousePos.y - FGizmoStartMouse.y) > 0.5) then
      begin
        FGizmoStartMouse := FMousePos;
        FGizmoStartQuat := FItemSelected.Quaternion;
      end;
    end;
  end
  else if FGizmoMode = gmScale then
  begin
    ScaleChange := (MouseDeltaX * 0.01) + (-MouseDeltaY * 0.01);
    EndScale := FGizmoStartVal;

    if FGizmoAxis = 1 then
    begin
      EndScale.x := EnsureRange(EndScale.x + ScaleChange, 0.05, 100);
    end
    else if FGizmoAxis = 2 then
    begin
      EndScale.y := EnsureRange(EndScale.y + ScaleChange, 0.05, 100);
    end
    else if FGizmoAxis = 3 then
    begin
      EndScale.z := EnsureRange(EndScale.z + ScaleChange, 0.05, 100);
    end;

    FItemSelected.Scale := EndScale;

    // Y-LIFT STABILIZATION
    // Now that models are perfectly centered, they behave like primitives.
    // We lift the Y-Position by half the height change to keep the bottom on the ground.
    if FGizmoAxis = 2 then
    begin
      OldScaleY := FGizmoStartVal.y;
      NewScaleY := EndScale.y;
      YLift := (NewScaleY - OldScaleY) * 0.5;

      FItemSelected.SetPosition(Vector3Create(FGizmoStartPos.x, FGizmoStartPos.y + YLift, FGizmoStartPos.z));
    end;
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
  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);
  Box.min := Vector3Create(-Scale.x - RayRadius, -RayRadius, -RayRadius);
  Box.max := Vector3Create(Scale.x + RayRadius, RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;
  Box.min := Vector3Create(-RayRadius, -Scale.y - RayRadius, -RayRadius);
  Box.max := Vector3Create(RayRadius, Scale.y + RayRadius, RayRadius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;
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
  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);
  Box.min := Vector3Create(-RayRadius, -Scale.y, -Scale.z);
  Box.max := Vector3Create(RayRadius, Scale.y, Scale.z);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;
  Box.min := Vector3Create(-Scale.x, -RayRadius, -Scale.z);
  Box.max := Vector3Create(Scale.x, RayRadius, Scale.z);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;
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
  Radius: Single;
begin
  Result := False;
  Axis := 0;

  // Make the radius thicker by default to make it easily grabbable
  Radius := RayRadius + 0.2;

  InvRot := QuaternionInvert(FItemSelected.Quaternion);
  LocalRay.position := Vector3RotateByQuaternion(Vector3Subtract(Ray.position, Pos), InvRot);
  LocalDir := Vector3RotateByQuaternion(Ray.direction, InvRot);
  LocalRay.direction := Vector3Normalize(LocalDir);

  // X Axis: Full thick line on BOTH sides (negative and positive) including handle cubes
  Box.min := Vector3Create(-Scale.x - Radius, -Radius, -Radius);
  Box.max := Vector3Create(Scale.x + Radius, Radius, Radius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 1;
    Exit;
  end;

  // Y Axis: Full thick line on BOTH sides
  Box.min := Vector3Create(-Radius, -Scale.y - Radius, -Radius);
  Box.max := Vector3Create(Radius, Scale.y + Radius, Radius);
  Hit := GetRayCollisionBox(LocalRay, Box);
  if Hit.hit then
  begin
    Result := True;
    Axis := 2;
    Exit;
  end;

  // Z Axis: Full thick line on BOTH sides
  Box.min := Vector3Create(-Radius, -Radius, -Scale.z - Radius);
  Box.max := Vector3Create(Radius, Radius, Scale.z + Radius);
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

function TRaylibSandbox.GetActorBoundingBoxWS(Actor: TA3DComponent): TBoundingBox;
var
  LocalBBox: TBoundingBox;
  Corners: array[0..7] of TVector3;
  RotatedCorners: array[0..7] of TVector3;
  RotQuat: TQuaternion;
  InvScale: TVector3;
  i: Integer;
  MinV, MaxV: TVector3;
  Sx, Sy, Sz: Single;
  HasSize: Boolean;
begin
  Result.min := Vector3Create(0, 0, 0);
  Result.max := Vector3Create(0, 0, 0);

  if not Assigned(Actor) then
    Exit;
  if Actor.ShapeType = stModel then
  begin
    if Actor.FModel.meshes = nil then
      Exit;
    LocalBBox := GetModelBoundingBox(Actor.FModel);
  end
  else
  begin
    LocalBBox.min := Vector3Create(-0.5, -0.5, -0.5);
    LocalBBox.max := Vector3Create(0.5, 0.5, 0.5);
  end;

  Sx := Actor.Scale.x;
  Sy := Actor.Scale.y;
  Sz := Actor.Scale.z;
  if Sx <= 0 then
    Sx := 0.0001;
  if Sy <= 0 then
    Sy := 0.0001;
  if Sz <= 0 then
    Sz := 0.0001;

  InvScale := Vector3Create(1.0 / Sx, 1.0 / Sy, 1.0 / Sz);
  LocalBBox.min := Vector3Multiply(LocalBBox.min, InvScale);
  LocalBBox.max := Vector3Multiply(LocalBBox.max, InvScale);

  Corners[0] := Vector3Create(LocalBBox.min.x, LocalBBox.min.y, LocalBBox.min.z);
  Corners[1] := Vector3Create(LocalBBox.max.x, LocalBBox.min.y, LocalBBox.min.z);
  Corners[2] := Vector3Create(LocalBBox.min.x, LocalBBox.max.y, LocalBBox.min.z);
  Corners[3] := Vector3Create(LocalBBox.max.x, LocalBBox.max.y, LocalBBox.min.z);
  Corners[4] := Vector3Create(LocalBBox.min.x, LocalBBox.min.y, LocalBBox.max.z);
  Corners[5] := Vector3Create(LocalBBox.max.x, LocalBBox.min.y, LocalBBox.max.z);
  Corners[6] := Vector3Create(LocalBBox.min.x, LocalBBox.max.y, LocalBBox.max.z);
  Corners[7] := Vector3Create(LocalBBox.max.x, LocalBBox.max.y, LocalBBox.max.z);

  RotQuat := Actor.Quaternion;

  HasSize := False;
  for i := 0 to 7 do
  begin
    RotatedCorners[i] := Vector3RotateByQuaternion(Corners[i], RotQuat);
    if not HasSize then
    begin
      MinV := RotatedCorners[i];
      MaxV := RotatedCorners[i];
      HasSize := True;
    end
    else
    begin
      if RotatedCorners[i].x < MinV.x then
        MinV.x := RotatedCorners[i].x;
      if RotatedCorners[i].y < MinV.y then
        MinV.y := RotatedCorners[i].y;
      if RotatedCorners[i].z < MinV.z then
        MinV.z := RotatedCorners[i].z;
      if RotatedCorners[i].x > MaxV.x then
        MaxV.x := RotatedCorners[i].x;
      if RotatedCorners[i].y > MaxV.y then
        MaxV.y := RotatedCorners[i].y;
      if RotatedCorners[i].z > MaxV.z then
        MaxV.z := RotatedCorners[i].z;
    end;
  end;

  Result.min := Vector3Add(MinV, Actor.Position);
  Result.max := Vector3Add(MaxV, Actor.Position);
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
  BBox: TBoundingBox;
  MeshSize: TVector3;
  MaxDim, MeshH, UniformScale: Single;
begin
  oldLen := Length(FItems);
  SetLength(FItems, oldLen + 1);
  New(Data);
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := False;
  if FBrushShape = stModel then
    Data^.Name := 'Model_' + IntToStr(oldLen)
  else
  begin
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
      stBomb:
        Data^.Name := 'Placed_Bomb_' + IntToStr(oldLen);
    end;
  end;

  Size := Vector3Create(1, 1, 1);
  if FBrushShape = stPrism then
    Size := Vector3Create(1, 1.5, 1)
  else if FBrushShape = stPyramid then
    Size := Vector3Create(1, 1.5, 1);

  if FBrushShape = stModel then
  begin
    BBox := GetModelBoundingBox(FCustomModel);
    MeshSize := Vector3Create(BBox.max.x - BBox.min.x, BBox.max.y - BBox.min.y, BBox.max.z - BBox.min.z);

    MaxDim := Max(MeshSize.x, Max(MeshSize.y, MeshSize.z));
    if MaxDim <= 0 then
      MaxDim := 1.0;
    UniformScale := 1.0 / MaxDim;

    // Pass size to Jolt Physics and add 0.1 to force Jolt to lift the object higher
    Size := Vector3Create((MeshSize.x * UniformScale) + 0.1, (MeshSize.y * UniformScale) + 0.1, (MeshSize.z * UniformScale) + 0.1);
  end;

  JPos.x := Pos.x;

  // Default Y-Offset for primitives (Cube etc. has height 1, so 0.5)
  YOffset := 0.5;

  // FOR CAPSULES: Because the engine code (Scale.y * 0.5 + 0.5) results in a 1.0 height
  // for a base scale of 1.0, we need to lift it by 1.0 to sit perfectly on the ground!
  if FBrushShape = stCapsule then
    YOffset := 1.0;

  if FBrushShape = stPrism then
    YOffset := 0.0;

  // FOR MODELS: Calculate exactly half the height of the scaled model!
  if FBrushShape = stModel then
  begin
    MeshH := (MeshSize.y * UniformScale);
    // Half height of the model + half padding (0.05)
    YOffset := (MeshH * 0.5) + 0.05;
  end;

  JPos.y := Pos.y + YOffset;
  JPos.z := Pos.z;
  JRot.x := 0;
  JRot.y := 0;
  JRot.z := 0;
  JRot.w := 1;

  Obj := TA3DComponent.Create('', FEngine, FBrushShape, Size, FSpawnStatic, @JPos, @JRot);
  Obj.Name := Data^.Name;

  if FBrushShape = stModel then
  begin
    Obj.FModel := FCustomModel;
    Obj.FMeshSize := MeshSize;

    MeshH := BBox.max.y - BBox.min.y;
    MaxDim := Max(BBox.max.x - BBox.min.x, Max(MeshH, BBox.max.z - BBox.min.z));
    if MaxDim <= 0 then
      MaxDim := 1.0;
    UniformScale := 1.0 / MaxDim;

    // Shift the mesh so its origin sits perfectly in the center of the Jolt collider
    var NormMinY := BBox.min.y * UniformScale;
    var CenterX := ((BBox.max.x + BBox.min.x) / 2) * UniformScale;
    var CenterZ := ((BBox.max.z + BBox.min.z) / 2) * UniformScale;
    // Push Y from bottom to center (Jolt standard goes from -0.5 to +0.5)
    Obj.FModelOffset := Vector3Create(-CenterX, -NormMinY - (MeshH * UniformScale * 0.5) + 0.5, -CenterZ);

    FCustomModel.meshes := nil;
  end;

  Obj.Friction := 1.0;
  Obj.Restitution := 0.0;
  Obj.UserData := Data;
  Obj.Visible := True;

  if FBrushShape = stBomb then
  begin
    Obj.Friction := 0.5;
    Obj.Restitution := 0.2;
    Obj.TargetColor := RED;
    Obj.ActColor := RED;
    Obj.FModel := FSphereModel;
    FBombActor := Obj;
    FBombTimer := 2.0;
    FBombExploded := False;
    if Assigned(FItemSelected) then
    begin
      FItemSelected := nil;
      DoObjectSelected(nil);
    end;
  end;

  Obj.SetPosition(Vector3Create(JPos.x, JPos.y, JPos.z));
  Obj.SetRotation(QuaternionFromEuler(0, 0, 0));
  FItems[oldLen] := Obj;
  PlaySpawnSound;
  DoActorSpawned(Obj, oldLen);
end;

procedure TRaylibSandbox.LoadCustomModel(const FilePath: string);
begin
  FLock.Enter;
  try
    FQueuedModelPath := FilePath;
    FLoadModelQueued := True;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.LoadModelInThread(const FilePath: string);
var
  PathBuf: array[0..1023] of AnsiChar;
  Ext: string;
begin
  if FCustomModel.meshes <> nil then
    UnloadModel(FCustomModel);
  if not System.SysUtils.FileExists(FilePath) then
  begin
    DoEngineException('Model file not found: ' + FilePath, 'LoadModelInThread');
    FIsBrushActive := False;
    FGhostVisible := False;
    Exit;
  end;
  FillChar(PathBuf, SizeOf(PathBuf), 0);
  StrPCopy(PathBuf, AnsiString(FilePath));
  OutputDebugString(PChar('Loading model safely in Raylib-Thread: ' + FilePath));
  FCustomModel := LoadModel(PathBuf);
  if FCustomModel.meshes <> nil then
  begin
    OutputDebugString('Model loaded successfully. Meshes assigned.');
    if (FCustomModel.materialCount > 0) and (FCustomModel.materials <> nil) then
    begin
      // Apply lighting shader to all materials of the model
      var matIdx: Integer;
      for matIdx := 0 to FCustomModel.materialCount - 1 do
        FCustomModel.materials[matIdx].shader := FLightShader;
    end;
    FBrushShape := stModel;
    FIsBrushActive := True;
    FGhostVisible := True;
  end
  else
  begin
    Ext := LowerCase(ExtractFileExt(FilePath));
    if (Ext = '.glb') or (Ext = '.gltf') then
      DoEngineException('Model loading FAILED. Meshes are nil. (GLB/GLTF requires libstdc++-6.dll or 64-bit)', 'LoadModelInThread')
    else if (Ext = '.obj') or (Ext = '.iqe') or (Ext = '.m3d') then
      DoEngineException('Model loading FAILED. Meshes are nil. Check for missing texture paths or corrupt mesh data.', 'LoadModelInThread')
    else
      DoEngineException('Model loading FAILED. Meshes are nil. Unsupported format?', 'LoadModelInThread');
    FIsBrushActive := False;
    FGhostVisible := False;
  end;
end;

procedure TRaylibSandbox.UpdateGame;
var
  dt: single;
  ItemVel: TVector3;
  i: Integer;
  IsTeal: Boolean;
  CamPosArr: array[0..2] of Single;
  LightPosArr: array[0..2] of Single;
  HoverRay: TRay;
  HoverScaleX, HoverScaleY, HoverScaleZ: Single;
  HoverAxis: Integer;
  Dir: TVector3;
  Dist: single;
  NewVel: TVector3;
  StartTime, EndTime, Freq: Int64;
  SunAngle, nDaytime: Single;
begin
  // Handle Scene Save
  if FSaveSceneQueued then
  begin
    FLock.Enter;
    try
      FSaveSceneQueued := False;
      ExecuteSceneSave(FQueuedSavePath);
      FQueuedSavePath := '';
    finally
      FLock.Leave;
    end;
  end;

  // Handle Scene Load
  if FLoadSceneQueued then
  begin
    FLock.Enter;
    try
      FLoadSceneQueued := False;
      ExecuteSceneLoad(FQueuedLoadPath);
      FQueuedLoadPath := '';
    finally
      FLock.Leave;
    end;
  end;

  if FLoadModelQueued then
  begin
    FLock.Enter;
    try
      FLoadModelQueued := False;
      LoadModelInThread(FQueuedModelPath);
    finally
      FLock.Leave;
    end;
  end;
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
          // Unload the button text texture if it exists
          if FItems[i].FButtonTexture.id > 0 then
            UnloadTexture(FItems[i].FButtonTexture);
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
      FSandboxSpawned := False;
      FClearItemsQueued := False;
      DoSceneCleared;
    finally
      FLock.Leave;
    end;
  end;
  dt := GetFrameTime();

  if Assigned(FMPVPlayer) then
    FMPVPlayer.Update;

  // Slow Motion calculation: Scale time if active, otherwise normal speed
  if FSlowMotionActive then
    FTimeScale := 0.2 // 20% speed
  else
    FTimeScale := 1.0; // Normal speed

  // Calculate physics delta time based on slow motion scale
  var PhysDt: Single := dt * FTimeScale;

  HandleCameraInput;
  HandleDesktopInput;
  ProcessSpawnQueue(dt);
  ProcessCustomSpawnQueue(dt); // Process custom external spawns
  UpdateBomb(PhysDt); // Pass slowed down time to bomb timer
  if FSimulationRunning then
  begin
    try
      QueryPerformanceCounter(StartTime);
      FEngine.Update(PhysDt); // Pass slowed down time to Jolt Physics
      QueryPerformanceCounter(EndTime);
      QueryPerformanceFrequency(Freq);
      FLastPhysicsTime := (EndTime - StartTime) * 1000.0 / Freq;
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
  FGizmoHoverAxis := 0;
  if FInitialized and Assigned(FItemSelected) and not FGizmoDragging and not FDragging and not FPopupOpen and (FGizmoMode <> gmNone) then
  begin
    HoverRay := GetScreenToWorldRay(FMousePos, FCamera);

    // Calculate default hover scale
    HoverScaleX := EnsureRange((FItemSelected.Scale.x * 0.5) + 1.0, 1.0, 100.0);
    HoverScaleY := EnsureRange((FItemSelected.Scale.y * 0.5) + 1.0, 1.0, 100.0);
    HoverScaleZ := EnsureRange((FItemSelected.Scale.z * 0.5) + 1.0, 1.0, 100.0);

    // FOR MODELS: Scale the hover boxes to match the new giant gizmo arms!
    if FItemSelected.ShapeType = stModel then
    begin
      var BBox := GetModelBoundingBox(FItemSelected.FModel);
      var PhysRadius := Max(BBox.max.x - BBox.min.x, Max(BBox.max.y - BBox.min.y, BBox.max.z - BBox.min.z)) * Max(FItemSelected.Scale.x, Max(FItemSelected.Scale.y, FItemSelected.Scale.z)) * 0.5;

      HoverScaleX := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
      HoverScaleY := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
      HoverScaleZ := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
    end;

    if FGizmoMode = gmTranslate then
    begin
      if CheckGizmoAxisHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.4, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end
    else if FGizmoMode = gmRotate then
    begin
      if CheckGizmoRingHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.2, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end
    else if FGizmoMode = gmScale then
    begin
      if CheckGizmoScaleHit(FItemSelected.Position, Vector3Create(HoverScaleX, HoverScaleY, HoverScaleZ), 0.4, HoverRay, HoverAxis) then
        FGizmoHoverAxis := HoverAxis;
    end;
  end;
  if FHighlightCollision then
  begin
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
        FItems[i].CollisionHighlighting := IsTeal or (FItems[i] = FItemSelected);
      end;
    end;
  end
  else
  begin
    for i := 0 to High(FItems) do
    begin
      if Assigned(FItems[i]) then
        FItems[i].CollisionHighlighting := (FItems[i] = FItemSelected);
    end;
  end;
  if FDragging and Assigned(FItemSelected) and (FGizmoMode = gmDragAndThrow) then
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

  // Only advance day/night cycle if the rhythm is active
  if FDayNightRhythmActive then
  begin
    FDayTime := FDayTime + (FDaySpeed * dt);
    if FDayTime > 1.0 then
      FDayTime := FDayTime - 1.0;
    if FDayTime < 0.0 then
      FDayTime := FDayTime + 1.0;
  end;

  SunAngle := Lerp(-90, 270, FDayTime) * DEG2RAD;
  nDaytime := Sin(SunAngle);

  FSunPos := Vector3Create(Cos(SunAngle) * 100.0, Sin(SunAngle) * 100.0, 50.0);
  FLightPos := FSunPos;

  // Center the shadow camera between all active objects
  FLightCam.target := FCamera.target; // Fallback: Look where the camera looks
  if Length(FItems) > 0 then
  begin
    FLightCam.target := Vector3Create(0, 0, 0);
    for i := 0 to High(FItems) do
      if Assigned(FItems[i]) then
        FLightCam.target := Vector3Add(FLightCam.target, FItems[i].Position);
    FLightCam.target := Vector3Scale(FLightCam.target, 1.0 / Length(FItems));
  end;

  // Position the light camera high up along the sun ray
  FLightCam.position := Vector3Add(FLightCam.target, Vector3Scale(FLightPos, 50.0));

  if nDaytime < 0 then
  begin
    FSunColor := Vector4Create(0.1, 0.1, 0.2, 1.0);
    FAmbientColor := Vector4Create(0.1, 0.1, 0.15, 1.0);
  end
  else
  begin
    FSunColor := Vector4Create(1.0, EnsureRange(nDaytime * 1.5, 0, 1), EnsureRange(nDaytime * 0.8, 0, 1), 1.0);
    FAmbientColor := Vector4Create(0.2 + nDaytime * 0.3, 0.2 + nDaytime * 0.3, 0.2 + nDaytime * 0.4, 1.0);
  end;

  if FSkyboxShader.id > 0 then
    SetShaderValue(FSkyboxShader, FSkyboxDaytimeLoc, @nDaytime, SHADER_UNIFORM_FLOAT);

  // Update Clouds
  FCloudMoveFactor := FCloudMoveFactor + 0.002 * dt;
  if FCloudMoveFactor > 1.0 then
    FCloudMoveFactor := FCloudMoveFactor - 1.0;
  if FCloudShader.id > 0 then
  begin
    SetShaderValue(FCloudShader, FCloudMoveFactorLoc, @FCloudMoveFactor, SHADER_UNIFORM_FLOAT);
    SetShaderValue(FCloudShader, FCloudDaytimeLoc, @nDaytime, SHADER_UNIFORM_FLOAT);
  end;

  // Update Lighting Uniforms EVERY FRAME
  CamPosArr[0] := FCamera.position.x;
  CamPosArr[1] := FCamera.position.y;
  CamPosArr[2] := FCamera.position.z;
  SetShaderValue(FLightShader, FViewPosLoc, @CamPosArr, SHADER_UNIFORM_VEC3);

  LightPosArr[0] := FLightPos.x;
  LightPosArr[1] := FLightPos.y;
  LightPosArr[2] := FLightPos.z;
  SetShaderValue(FLightShader, FLightPosLoc, @LightPosArr, SHADER_UNIFORM_VEC3);

  SetShaderValue(FLightShader, FAmbientLoc, @FAmbientColor, SHADER_UNIFORM_VEC4);
  SetShaderValue(FLightShader, FDiffuseLoc, @FSunColor, SHADER_UNIFORM_VEC4);

  var LightViewMat := GetCameraMatrix(FLightCam);
  // Increase the orthographic shadow view area to cover the map
  var LightProjMat := MatrixOrtho(-400, 400, -400, 400, 0.1, 2000.0);

  SetShaderValueMatrix(FLightShader, FLightViewLoc, LightViewMat);
  SetShaderValueMatrix(FLightShader, FLightProjLoc, LightProjMat);

  SetShaderValueTexture(FLightShader, FShadowMapLoc, FShadowMap.texture);

  // Bias to prevent shadow acne
  var TempBias: Single := 0.05;
  SetShaderValue(FLightShader, GetShaderLocation(FLightShader, 'shadowBias'), @TempBias, SHADER_UNIFORM_FLOAT);
end;

procedure TRaylibSandbox.RenderGame;
begin
  // Render the Shadow Map from the light's perspective
  RenderShadowMap;

  // Render the main scene
  BeginDrawing();
  ClearBackground(BLACK);
  if Assigned(FMPVPlayer) then
    FMPVPlayer.Render;
  Render3DScene;
  DrawGUI;
  DrawNativePopup;
  EndDrawing();

  if FRaylibWnd <> 0 then
    RedrawWindow(FRaylibWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW);
end;

procedure TRaylibSandbox.RenderShadowMap;
begin
  if FShadowMap.id = 0 then
    Exit;

  BeginTextureMode(FShadowMap);

  // Optimization: Re-use the pre-allocated default shader instead of loading/unloading every frame
  BeginShaderMode(FDefaultShader);

  rlDrawRenderBatchActive();

  BeginMode3D(FLightCam);
  DrawSceneShadows;
  EndMode3D();

  // Disable default shader
  EndShaderMode();

  EndTextureMode();
end;

procedure TRaylibSandbox.DrawSceneShadows;
var
  i: Integer;
  Actor: TA3DComponent;
  Pos: TVector3;
  Axis: TVector3;
  Angle: Single;
begin
  // Draw static floor to the shadow map
  DrawPlane(Vector3Create(0, 0, 0), Vector2Create(1000, 1000), BLACK);

  // Draw all items to the shadow map
  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      rlPushMatrix();
      Pos := Actor.Position;
      rlTranslatef(Pos.x, Pos.y, Pos.z);

      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

      rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);

      if Actor.ShapeType = stBox then
        DrawCube(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, BLACK)
      else if Actor.ShapeType = stSphere then
        DrawSphere(Vector3Create(0, 0, 0), 0.5, BLACK)
      else if Actor.ShapeType = stCapsule then
        DrawCylinderEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, BLACK)
      else if Actor.ShapeType = stModel then
        DrawCube(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, BLACK) // Approximation for custom models
      else if (Actor.ShapeType = stPyramid) or (Actor.ShapeType = stPrism) then
      begin
        var TopR: Single := 0.0;
        if Actor.ShapeType = stPrism then
          TopR := 0.5;
        var Segs: Integer := 4;
        if Actor.ShapeType = stPrism then
          Segs := 3;

        // Offset in Y to align with Jolt physics center of mass
        if Actor.ShapeType = stPyramid then
          rlTranslatef(0.0, -0.25, 0.0)
        else if Actor.ShapeType = stPrism then
          rlTranslatef(0.0, -0.5, 0.0);

        DrawCylinderEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), TopR, 0.5, Segs, BLACK);
      end;

      rlPopMatrix();
    end;
  end;
end;

procedure TRaylibSandbox.Render3DScene;
var
  i: Integer;
  Actor: TA3DComponent;
  Dist, MaxDist: Single;
  CamForward, ToActor, ToActorNorm: TVector3;
  DotP: Single;
  Pos: TVector3;
  Axis: TVector3;
  Angle: Single;
  dt: Single;
  ViewMat, ProjMat: TMatrix;
  ModelMat: TMatrix;
  ModelMatLoc: Integer;
  ActorColorLoc: Integer;
  ColorShaderVec: array[0..3] of Single;

  function GetActorColor(A: TA3DComponent): TColorB;
  const
    COL_CUBE: TColorB = (
    R: 230;
    g: 41;
    b: 55;
    A: 255
  );
    COL_PYRAMID: TColorB = (
    R: 255;
    g: 161;
    b: 0;
    A: 255
  );
    COL_SPHERE: TColorB = (
    R: 179;
    g: 71;
    b: 217;
    A: 255
  );
    COL_CAPSULE: TColorB = (
    R: 0;
    g: 168;
    b: 150;
    A: 255
  );
    COL_TEAL: TColorB = (
    R: 64;
    g: 224;
    b: 208;
    A: 255
  );
  begin
    if A.CollisionHighlighting then
      Exit(COL_TEAL);

    // If the Actor has a custom color assigned (like spawned walls), use it!
    if (A.ActColor.r <> WHITE.r) or (A.ActColor.g <> WHITE.g) or (A.ActColor.b <> WHITE.b) or (A.ActColor.a <> WHITE.a) then
      Exit(A.ActColor);

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
      stBomb:
        Exit(RED);
    else
      Exit(WHITE);
    end;
  end;

begin
  ActorColorLoc := GetShaderLocation(FLightShader, 'diffuse');

  BeginMode3D(FCamera);

  // 1. Draw Skybox (Infinite background)
  if FSkyboxModel.meshes <> nil then
  begin
    rlDisableDepthMask();
    ViewMat := GetCameraMatrix(FCamera);
    ProjMat := MatrixPerspective(FCamera.fovy * DEG2RAD, GetScreenWidth() / GetScreenHeight(), 0.01, 1000.0);
    SetShaderValueMatrix(FSkyboxShader, FSkyboxViewLoc, ViewMat);
    SetShaderValueMatrix(FSkyboxShader, FSkyboxProjLoc, ProjMat);

    rlDisableBackfaceCulling();
    DrawModel(FSkyboxModel, FCamera.position, 1.0, WHITE);
    rlEnableBackfaceCulling();
    rlEnableDepthMask();
  end;

  // 2. Draw Floor with Lighting Shader
  BeginShaderMode(FLightShader);
  DrawPlane(Vector3Create(0, 0, 0), Vector2Create(1000, 1000), DARKGREEN);
  EndShaderMode();

  // 3. Draw Clouds (Transparency)
  if FCloudModel.meshes <> nil then
  begin
    BeginShaderMode(FCloudShader);
    DrawModel(FCloudModel, Vector3Create(FCamera.position.x, 150, FCamera.position.z), 1.0, WHITE);
    EndShaderMode();
  end;

  // 4. Draw Actors
  // Optimization: Use the customizable MaxRenderDistance property instead of a hardcoded value
  MaxDist := FMaxRenderDistance;
  CamForward := Vector3Normalize(Vector3Subtract(FCamera.target, FCamera.position));

  ModelMatLoc := GetShaderLocation(FLightShader, 'matModel');

  for i := 0 to FEngine.Count - 1 do
  begin
    Actor := FEngine.Items[i];
    if Assigned(Actor) and Actor.Visible then
    begin
      if (Actor.UserData <> nil) and PItemData(Actor.UserData)^.IsProjectile then
        Continue;
      Dist := Vector3Distance(Actor.Position, FCamera.position);
      if FDistanceCulling and (Dist > MaxDist) then
        Continue;
      ToActor := Vector3Subtract(Actor.Position, FCamera.position);
      ToActorNorm := Vector3Normalize(ToActor);
      DotP := Vector3DotProduct(ToActorNorm, CamForward);
      if FFrustumCulling and (DotP < 0.5) then
        Continue;

      rlPushMatrix();
      Pos := Actor.Position;
      rlTranslatef(Pos.x, Pos.y, Pos.z);
      Axis := Vector3Create(1, 1, 1);
      Angle := 0;
      if Actor.Quaternion.w < 1.0 then
        QuaternionToAxisAngle(Actor.Quaternion, @Axis, @Angle);
      rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

      rlDrawRenderBatchActive();
      BeginShaderMode(FLightShader);

      ModelMat := rlGetMatrixTransform();
      SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

      if Actor.ShapeType = stModel then
      begin
        rlTranslatef(Actor.FModelOffset.x, Actor.FModelOffset.y, Actor.FModelOffset.z);
        rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);
        DrawModel(Actor.FModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(Actor));
      end
      else
      begin
        // Enable the lighting shader
        BeginShaderMode(FLightShader);

        // Create the color array from the actor's color
        var C: TColorB := GetActorColor(Actor);

        ColorShaderVec[0] := C.r / 255.0; // Red (0.0 to 1.0)
        ColorShaderVec[1] := C.g / 255.0; // Green (0.0 to 1.0)
        ColorShaderVec[2] := C.b / 255.0; // Blue (0.0 to 1.0)
        ColorShaderVec[3] := C.A / 255.0; // Alpha (0.0 to 1.0)

        // Send the color directly to the shader uniform
        SetShaderValue(FLightShader, ActorColorLoc, @ColorShaderVec, SHADER_UNIFORM_VEC4);

        if Actor.ShapeType = stSphere then
        begin
          var SphereScale: Single := Max(Actor.Scale.x, Max(Actor.Scale.y, Actor.Scale.z)) * 0.5;

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawModel(FSphereModel, Vector3Create(0, 0, 0), SphereScale, GetActorColor(Actor));
        end
        else if Actor.ShapeType = stBox then
        begin
          // If this box has a video texture, assign it.
          if Actor.FVideoTexture.id > 0 then
          begin
            FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := Actor.FVideoTexture;

            ColorShaderVec[0] := 1.0;
            ColorShaderVec[1] := 1.0;
            ColorShaderVec[2] := 1.0;
            ColorShaderVec[3] := 1.0;
            SetShaderValue(FLightShader, ActorColorLoc, @ColorShaderVec, SHADER_UNIFORM_VEC4);
          end
          else
          begin
            FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;
          end;

          rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          if Actor.FVideoTexture.id > 0 then
            DrawModel(FBoxModel, Vector3Create(0, 0, 0), 1.0, WHITE)
          else
            DrawModel(FBoxModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(Actor));

          DrawCubeWires(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, BLACK);
        end
        // ====================================================================
        // BOMB
        // ====================================================================
        else if Actor.ShapeType = stBomb then
        begin
          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawModel(FSphereModel, Vector3Create(0, 0, 0), 0.5, GetActorColor(Actor));
        end
        // ====================================================================
        // CAPSULE / CYLINDER
        // ====================================================================
        else if Actor.ShapeType = stCapsule then
        begin
          rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);

          rlPushMatrix();

          // Shift down to align mesh bottom with physics bottom
          rlTranslatef(0.0, -0.5, 0.0);

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          // Offset Y position to lower mesh by half its height
          DrawModel(FCapsuleModel, Vector3Create(0, -0.5, 0), 1.0, GetActorColor(Actor));

          DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, BLACK);

          rlPopMatrix();
        end

        // ====================================================================
        // PYRAMID
        // ====================================================================
        else if Actor.ShapeType = stPyramid then
        begin
          rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);

          // Offset to align physics center of mass with visual mesh
          rlTranslatef(0.0, -0.25, 0.0);

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawModel(FPyramidModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(Actor));

          rlPushMatrix();
          rlRotatef(45.0, 0.0, 1.0, 0.0);
          DrawCylinderWiresEx(Vector3Create(0, 1, 0), Vector3Create(0, 0, 0), 0.0, 0.5, 4, BLACK);
          rlPopMatrix();
        end

        // ====================================================================
        // PRISM
        // ====================================================================
        else if Actor.ShapeType = stPrism then
        begin
          rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);

          rlPushMatrix();
          rlTranslatef(0.0, -0.5, 0.0);

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawModel(FPrismModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(Actor));
          rlPopMatrix();

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          // Rotate the wireframe on the Y axis to match the mesh
          rlPushMatrix();
          rlRotatef(90.0, 0.0, 1.0, 0.0);

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 3, BLACK);
          rlPopMatrix();
        end
        // ====================================================================
        // 3D BUTTON
        // ====================================================================
        else if Actor.ShapeType = stButton then
        begin
          // Button movement: Only move inward when pressed
          var BtnOffset: Single := 0.0;
          if Actor.IsPressed then
            BtnOffset := -0.03; // Move slightly inward on click

          // 1. Draw the outer frame (darker color)
          rlPushMatrix();
          rlScalef(Actor.Scale.x, Actor.Scale.y, Actor.Scale.z);
          var FrameCol: TColorB;
          FrameCol.r := Max(0, Round(Actor.BaseColor.r * 0.5));
          FrameCol.g := Max(0, Round(Actor.BaseColor.g * 0.5));
          FrameCol.b := Max(0, Round(Actor.BaseColor.b * 0.5));
          FrameCol.a := 255;

          DrawCube(Vector3Create(0, 0, -0.1), 1.0, 1.0, 1.0, FrameCol);
          rlPopMatrix();

          rlPushMatrix();
          rlTranslatef(0, 0, BtnOffset);
          rlScalef(Actor.Scale.x * 0.85, Actor.Scale.y * 0.85, Actor.Scale.z);

          if Actor.FVideoTexture.id > 0 then
            FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := Actor.FVideoTexture
          else if Actor.FButtonTexture.id > 0 then
            FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := Actor.FButtonTexture
          else
            FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;

          rlEnableBackfaceCulling();

          ModelMat := rlGetMatrixTransform();
          SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

          DrawModel(FBoxModel, Vector3Create(0, 0, 0), 1.0, Actor.ActColor);

          rlDisableBackfaceCulling();

          FBoxModel.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := FDefaultWhiteTex;

          DrawCubeWires(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, BLACK);
          rlPopMatrix();
        end;

        EndShaderMode();
      end;

      EndShaderMode();
      rlPopMatrix();
    end;
  end;

  // Selected Object
  if Assigned(FItemSelected) and FItemSelected.Visible then
  begin
    rlPushMatrix();

    // Translate to object position
    Pos := FItemSelected.Position;
    rlTranslatef(Pos.x, Pos.y, Pos.z);

    // Apply object rotation
    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if FItemSelected.Quaternion.w < 1.0 then
      QuaternionToAxisAngle(FItemSelected.Quaternion, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

    rlDrawRenderBatchActive();
    BeginShaderMode(FLightShader);

    // Fetch the model matrix and send it to the shader
    ModelMat := rlGetMatrixTransform();
    SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

    if FItemSelected.ShapeType = stModel then
    begin
      rlTranslatef(FItemSelected.FModelOffset.x, FItemSelected.FModelOffset.y, FItemSelected.FModelOffset.z);
      rlScalef(FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z);

      // Update model matrix for the model offset
      ModelMat := rlGetMatrixTransform();
      SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

      DrawModel(FItemSelected.FModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(FItemSelected));
      DrawCubeWires(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, YELLOW);
    end
    else
    begin
      // Apply scale and fetch matrix per shape to ensure correct normal calculations
      if FItemSelected.ShapeType = stSphere then
      begin
        var SelSphereScale: Single := Max(FItemSelected.Scale.x, Max(FItemSelected.Scale.y, FItemSelected.Scale.z)) * 0.5;

        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

        DrawModel(FSphereModel, Vector3Create(0, 0, 0), SelSphereScale, GetActorColor(FItemSelected));
        DrawSphereWires(Vector3Create(0, 0, 0), SelSphereScale, 16, 16, YELLOW);
      end
      else if FItemSelected.ShapeType = stBox then
      begin
        rlScalef(FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z);

        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

        DrawModel(FBoxModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(FItemSelected));
        DrawCubeWires(Vector3Create(0, 0, 0), 1.0, 1.0, 1.0, YELLOW);
      end
      else if FItemSelected.ShapeType = stCapsule then
      begin
        rlScalef(FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z);

        rlPushMatrix();

        // Shift down to align mesh bottom with physics bottom
        rlTranslatef(0.0, -0.5, 0.0);
        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

        // Offset Y position to lower mesh by half its height
        DrawModel(FCapsuleModel, Vector3Create(0, -0.5, 0), 1.0, GetActorColor(FItemSelected));

        DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, YELLOW);

        rlPopMatrix();
      end
      else if FItemSelected.ShapeType = stPyramid then
      begin
        rlScalef(FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z);

        rlPushMatrix();

        // Offset to align physics center of mass with visual mesh
        rlTranslatef(0.0, -0.25, 0.0);
        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);
        rlPushMatrix();
        rlRotatef(45.0, 0.0, 1.0, 0.0);
        DrawCylinderWiresEx(Vector3Create(0, 1, 0), Vector3Create(0, 0, 0), 0.0, 0.5, 4, YELLOW);
        rlPopMatrix();

        DrawModel(FPyramidModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(FItemSelected));

        rlPopMatrix();
      end
      else if FItemSelected.ShapeType = stPrism then
      begin
        rlScalef(FItemSelected.Scale.x, FItemSelected.Scale.y, FItemSelected.Scale.z);

        rlPushMatrix();
        rlTranslatef(0.0, -0.5, 0.0);

      // Update ModelMat for the mesh offset
        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

        DrawModel(FPrismModel, Vector3Create(0, 0, 0), 1.0, GetActorColor(FItemSelected));
        rlPopMatrix();

      // Re-update ModelMat for the wireframe
        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

      // Rotate the wireframe by 90 degrees on the Y axis to match the mesh
        rlPushMatrix();
        rlRotatef(90.0, 0.0, 1.0, 0.0);

      // Update ModelMat for the wireframe rotation
        ModelMat := rlGetMatrixTransform();
        SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

        DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 3, YELLOW);
        rlPopMatrix();
      end;
    end;

    EndShaderMode();
    rlPopMatrix();
  end;

  // --- GHOST PREVIEW ---
  if FIsBrushActive and FGhostVisible then
  begin
    rlPushMatrix();
    var SurfaceY: Single := FGhostPos.y;
    if (FBrushShape = stCapsule) or (FBrushShape = stPyramid) or (FBrushShape = stPrism) then
    begin
      if (FBrushShape = stPyramid) or (FBrushShape = stPrism) then
        SurfaceY := FGhostPos.y + (1.5 * 0.5)
      else
        SurfaceY := FGhostPos.y + (1.0 * 0.5);
    end
    else if FBrushShape = stModel then
    begin
      // Calculate exact Y-Offset for models based on their true bounding box height
      var GBBOX := GetModelBoundingBox(FCustomModel);
      var GMeshH: Single := GBBOX.max.y - GBBOX.min.y;
      var GMaxDim: Single := Max(GBBOX.max.x - GBBOX.min.x, Max(GMeshH, GBBOX.max.z - GBBOX.min.z));
      if GMaxDim <= 0 then
        GMaxDim := 1.0;
      var GUniformScale: Single := 1.0 / GMaxDim;

      // Half height of the model + half padding (0.05)
      SurfaceY := FGhostPos.y + ((GMeshH * GUniformScale) * 0.5) + 0.05;
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
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      DrawCylinderEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.5, 0), Vector3Create(0, -0.5, 0), 0.5, 0.5, 24, YELLOW);
    end
    else if FBrushShape = stPyramid then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      // Rotate 45 degrees so a flat face points forward, matching the spawned mesh!
      rlRotatef(45.0, 0.0, 1.0, 0.0);
      DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.0, 0.5, 4, YELLOW);
    end
    else if FBrushShape = stPrism then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      // Rotate 90 degrees for a 3-sided prism so it matches the spawned visual mesh
      rlRotatef(90.0, 0.0, 1.0, 0.0);
      DrawCylinderEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.5, 0.5, 3, Fade(WHITE, 0.4));
      DrawCylinderWiresEx(Vector3Create(0, 0.75, 0), Vector3Create(0, -0.75, 0), 0.5, 0.5, 3, YELLOW);
    end
    else if FBrushShape = stModel then
    begin
      rlTranslatef(FGhostPos.x, SurfaceY, FGhostPos.z);
      if FCustomModel.meshes <> nil then
      begin
        var GBBOX := GetModelBoundingBox(FCustomModel);
        var GMeshSize := Vector3Create(GBBOX.max.x - GBBOX.min.x, GBBOX.max.y - GBBOX.min.y, GBBOX.max.z - GBBOX.min.z);
        var GMaxDim: Single := Max(GMeshSize.x, Max(GMeshSize.y, GMeshSize.z));
        if GMaxDim <= 0 then
          GMaxDim := 1.0;
        var GUniformScale: Single := 1.0 / GMaxDim;

        // Calculate the center of the scaled mesh
        var GCenterX := ((GBBOX.max.x + GBBOX.min.x) / 2) * GUniformScale;
        var GCenterZ := ((GBBOX.max.z + GBBOX.min.z) / 2) * GUniformScale;
        var GMeshH: Single := GMeshSize.y * GUniformScale;

        rlTranslatef(-GCenterX, -GMeshH * 0.5, -GCenterZ);

        // CRITICAL: Temporarily reset the model's transform to identity (1.0 scale)
        // because the vertices are ALREADY scaled, and DrawModel would scale them again!
        var OldTransform: TMatrix := FCustomModel.transform;
        FCustomModel.transform := MatrixIdentity();
        DrawModel(FCustomModel, Vector3Create(0, 0, 0), 1.0, Fade(WHITE, 0.4));
        // Restore the original transform so we don't break the model for the actual spawn
        FCustomModel.transform := OldTransform;
      end;
      DrawCubeWires(Vector3Create(0, 0, 0), 1, 1, 1, YELLOW);
    end
    else if FBrushShape = stBomb then
    begin
      rlTranslatef(FGhostPos.x, FGhostPos.y + 0.5, FGhostPos.z);
      DrawSphere(Vector3Create(0, 0, 0), 0.5, Fade(RED, 0.5));
      DrawSphereWires(Vector3Create(0, 0, 0), 0.5, 16, 16, YELLOW);
    end;

    rlPopMatrix();
  end;

  if Assigned(FItemSelected) and not FIsBrushActive and (FGizmoMode <> gmNone) then
    DrawGizmo;

  // Draw projectiles
  for i := 0 to High(FProjectiles) do
  begin
    if FProjectiles[i] = nil then
      Continue;

    BeginShaderMode(FLightShader);

    rlPushMatrix();

    // Translate to the projectile's position with a small Y offset
    Pos := FProjectiles[i].Position;
    rlTranslatef(Pos.x, Pos.y + 0.3, Pos.z);

    // Apply the projectile's rotation for visual rolling
    var Quat := FProjectiles[i].Quaternion;
    Axis := Vector3Create(1, 1, 1);
    Angle := 0;
    if Quat.w < 1.0 then
      QuaternionToAxisAngle(Quat, @Axis, @Angle);
    rlRotatef(Angle * RAD2DEG, Axis.x, Axis.y, Axis.z);

    // Scale down to a small cannonball
    rlScalef(0.3, 0.3, 0.3);

    // Fetch the combined matrix and send it to the shader
    ModelMat := rlGetMatrixTransform();
    SetShaderValueMatrix(FLightShader, ModelMatLoc, ModelMat);

    // Draw the projectile sphere at local origin
    DrawModel(FSphereModel, Vector3Create(0, 0, 0), 1.0, SKYBLUE);

    rlPopMatrix();
    EndShaderMode();
  end;

  dt := GetFrameTime();
  // Pass scaled time to projectiles so their lifespan checks sync with slow motion
  UpdateProjectiles(dt * FTimeScale);

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
  BBox: TBoundingBox;
  PhysRadius: Single;
begin
  Pos := FItemSelected.Position;

  // Default gizmo length for primitives
  ScaleX := EnsureRange((FItemSelected.Scale.x * 0.5) + 1.0, 1.0, 100.0);
  ScaleY := EnsureRange((FItemSelected.Scale.y * 0.5) + 1.0, 1.0, 100.0);
  ScaleZ := EnsureRange((FItemSelected.Scale.z * 0.5) + 1.0, 1.0, 100.0);

  // FOR MODELS: Calculate the actual physical radius so the gizmo arms reach outside the mesh!
  if FItemSelected.ShapeType = stModel then
  begin
    BBox := GetModelBoundingBox(FItemSelected.FModel);

    // Calculate how big the model is after applying the model's internal transform and the Actor's scale
    PhysRadius := Max(BBox.max.x - BBox.min.x, Max(BBox.max.y - BBox.min.y, BBox.max.z - BBox.min.z)) * Max(FItemSelected.Scale.x, Max(FItemSelected.Scale.y, FItemSelected.Scale.z)) * 0.5;

    // Make the gizmo arms slightly larger than the object's physical radius
    ScaleX := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
    ScaleY := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
    ScaleZ := EnsureRange(PhysRadius + 1.5, 1.5, 150.0);
  end;

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
    else if I = 3 then
    begin
      DrawRectangle(Round(IconRect.x + 5), Round(IconRect.y + 5), 20, 20, ORANGE);
      DrawLine(Round(IconRect.x + 5), Round(IconRect.y + 5), Round(IconRect.x + 25), Round(IconRect.y + 25), BLACK);
      DrawLine(Round(IconRect.x + 25), Round(IconRect.y + 5), Round(IconRect.x + 5), Round(IconRect.y + 25), BLACK);
    end
    else if I = 4 then
    begin
      DrawTriangle(Vector2Create(IconRect.x + 5, IconRect.y + 25), Vector2Create(IconRect.x + 25, IconRect.y + 25), Vector2Create(IconRect.x + 15, IconRect.y + 5), COL_PRISM);
    end;
  end;
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
  DrawRectangle(10, 10 + YOffset, 214, 50, Fade(BLACK, 0.8));
  DrawRectangleLines(10, 10 + YOffset, 214, 50, RAYWHITE);
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
    else if I = 3 then
    begin
      DrawRectangle(Round(IconRect.x + 5), Round(IconRect.y + 5), 20, 20, Fade(PURPLE, 0.8));
      DrawLine(Round(IconRect.x + 5), Round(IconRect.y + 5), Round(IconRect.x + 25), Round(IconRect.y + 25), RAYWHITE);
      DrawLine(Round(IconRect.x + 25), Round(IconRect.y + 5), Round(IconRect.x + 5), Round(IconRect.y + 25), RAYWHITE);
    end
    else if I = 4 then
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
    gmDragAndThrow:
      ModeStr := 'Mode: Drag & Throw';
  else
    ModeStr := 'Mode: None (UI Interaction)';
  end;
  DrawText(PAnsiChar(ModeStr), 10, GetScreenHeight() - 90, 20, RAYWHITE);
end;

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
// ============================================================================
// NAVIGATION LOGIC
// Uses an internal absolute counter to cycle strictly through the FItems array.
// ============================================================================

procedure TRaylibSandbox.SelectNextObject;
var
  i: Integer;
  Actor: TA3DComponent;
begin
  // Abort if the scene is empty
  if Length(FItems) = 0 then
    Exit;

  // Strictly increment the internal navigation index and wrap around
  FNavIndex := FNavIndex + 1;
  if FNavIndex >= Length(FItems) then
    FNavIndex := 0;

  Actor := FItems[FNavIndex];
  if Assigned(Actor) then
  begin
    // Clear previous glow states
    for i := 0 to High(FItems) do
      if Assigned(FItems[i]) then
        FItems[i].CollisionHighlighting := False;

    // Apply new selection state
    Actor.CollisionHighlighting := True;
    FItemSelected := Actor; // Update engine state

    // Notify the VCL Form to update TreeView and Inspector
    DoObjectSelected(Actor);
  end;
end;

procedure TRaylibSandbox.SelectPrevObject;
var
  i: Integer;
  Actor: TA3DComponent;
begin
  // Abort if the scene is empty
  if Length(FItems) = 0 then
    Exit;

  // Strictly decrement the internal navigation index and wrap around
  FNavIndex := FNavIndex - 1;
  if FNavIndex < 0 then
    FNavIndex := High(FItems);

  Actor := FItems[FNavIndex];
  if Assigned(Actor) then
  begin
    // Clear previous glow states
    for i := 0 to High(FItems) do
      if Assigned(FItems[i]) then
        FItems[i].CollisionHighlighting := False;

    // Apply new selection state
    Actor.CollisionHighlighting := True;
    FItemSelected := Actor; // Update engine state

    // Notify the VCL Form to update TreeView and Inspector
    DoObjectSelected(Actor);
  end;
end;

procedure TRaylibSandbox.ProcessCustomSpawnQueue(dt: Single);
var
  Req: TSpawnRequest;
  oldLen: Integer;
  i: Integer;
  Data: PItemData;
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
  Obj: TA3DComponent;
  BombReq: TSpawnRequest;
begin
  if Length(FCustomSpawnQueue) = 0 then
    Exit;

  if FCustomSpawnTimer > 0 then
  begin
    FCustomSpawnTimer := FCustomSpawnTimer - dt;
    Exit;
  end;

  FLock.Enter;
  try
    Req := FCustomSpawnQueue[0];
    if Length(FCustomSpawnQueue) > 1 then
    begin
      for i := 0 to High(FCustomSpawnQueue) - 1 do
        FCustomSpawnQueue[i] := FCustomSpawnQueue[i + 1];
    end;
    SetLength(FCustomSpawnQueue, Length(FCustomSpawnQueue) - 1);
  finally
    FLock.Leave;
  end;

  // Faster spawn rate (0.05s) so the wall finishes before the bomb goes off!
  FCustomSpawnTimer := 0.05;

  // Check if this is the special Bomb Trigger
  if Req.Name = 'BOMB_TRIGGER' then
  begin
    // Spawn the last wall block first
    Req.Name := 'WallBlock_Final';
    // (We just let it fall through to the normal spawn code below for the last brick)

    // Now queue the actual bomb behind the wall
    BombReq.Shape := stSphere;
    BombReq.Size := Vector3Create(1, 1, 1);
    BombReq.IsStatic := False;
    BombReq.Color := RED;
    BombReq.Pos := Vector3Create(0, 2.0, -4.0); // 4 units behind the wall
    BombReq.Name := 'THE_BOMB';

    // Insert bomb at the front of the queue so it spawns immediately after the last brick
    FLock.Enter;
    try
      SetLength(FCustomSpawnQueue, Length(FCustomSpawnQueue) + 1);
      for i := High(FCustomSpawnQueue) downto 1 do
        FCustomSpawnQueue[i] := FCustomSpawnQueue[i - 1];
      FCustomSpawnQueue[0] := BombReq;
    finally
      FLock.Leave;
    end;
  end;

  oldLen := Length(FItems);
  SetLength(FItems, oldLen + 1);

  New(Data);
  FillChar(Data^, SizeOf(TItemData), 0);
  Data^.SpawnTime := GetTime();
  Data^.IsProjectile := False;
  Data^.Name := Req.Name;

  JPos.x := Req.Pos.x;
  JPos.y := Req.Pos.y;
  JPos.z := Req.Pos.z;
  JRot.x := 0;
  JRot.y := 0;
  JRot.z := 0;
  JRot.w := 1;

  Obj := TA3DComponent.Create('', FEngine, Req.Shape, Req.Size, Req.IsStatic, @JPos, @JRot);
  Obj.Name := Req.Name;
  Obj.Friction := 0.6;
  Obj.Restitution := 0.1;

  Obj.UserData := Data;
  Obj.Visible := True;
  if Req.Shape = stButton then
  begin
    Obj.Caption := Req.Caption;
    Obj.BaseColor := Req.BaseColor;
    Obj.HoverColor := Req.HoverColor;
    Obj.OnClick := Req.OnClick;

    var TxtSize: Integer := Round(Req.Size.x * 20.0);
    if TxtSize < 10 then
      TxtSize := 10;
    Obj.FButtonTexture := DrawTextToTexture(Req.Caption, TxtSize, BLACK, Req.BaseColor);
  end;

  Obj.TargetColor := Req.Color;
  Obj.ActColor := Req.Color;


  // If it's the bomb, set up the explosion timer
  if Req.Name = 'THE_BOMB' then
  begin
    FBombActor := Obj;
    FBombTimer := 2.0; // 2 seconds until boom!
    FBombExploded := False;
  end
  else
  // If requested, generate a unique test texture safely within the Raylib thread
    if Req.GenerateTestTexture then
  begin
    if (Req.Name = 'Screen_1') then
    begin
      // Initialize MPV Player on the fly when Screen 1 is spawned
      if not Assigned(FMPVPlayer) then
      begin
        try
          FMPVPlayer := TMPVPlayer.Create(640, 360);

          FMPVPlayer.LoadFile(ExtractFilePath(ParamStr(0)) + 'ressources\video\test.mp4');
          //FMPVPlayer.LoadFile( 'D:\test2.mp4');
        except
          on E: Exception do
          begin
            DoEngineException(E.Message, 'MPVInit');
            FMPVPlayer := nil;
          end;
        end;
      end;

      if Assigned(FMPVPlayer) then
        Obj.FVideoTexture := FMPVPlayer.Target.texture
      else
        // Fallback if MPV failed to load
        Obj.FVideoTexture := LoadTextureFromImage(GenImageColor(640, 360, RED));
    end
    else
    begin

    end;
  end;

  FItems[oldLen] := Obj;
  DoActorSpawned(Obj, oldLen);
end;

procedure TRaylibSandbox.UpdateBomb(dt: Single);
begin
  if not Assigned(FBombActor) or FBombExploded then
    Exit;

  FBombTimer := FBombTimer - dt;

  // Flashing effect: Blink faster as time runs out
  if FBombTimer < 0.5 then
  begin
    if Trunc(FBombTimer * 20) mod 2 = 0 then
      FBombActor.ActColor := RED
    else
      FBombActor.ActColor := WHITE;
  end;

  if FBombTimer <= 0 then
  begin
    ExplodeBomb;
  end;
end;

procedure TRaylibSandbox.ExplodeBomb;
var
  i: Integer;
  Actor: TA3DComponent;
  Dist: Single;
  Dir: TVector3;
  ForceMag: Single;
begin
  if not Assigned(FBombActor) then
    Exit;

  FBombExploded := True;

  PlayImpactSound;

  // Loop through all items and apply massive explosion force
  for i := 0 to High(FItems) do
  begin
    Actor := FItems[i];
    if Assigned(Actor) and (Actor <> FBombActor) and not Actor.FIsDead then
    begin
      // Only affect dynamic objects (our wall blocks)
      if not Actor.IsStatic then
      begin
        Dist := Vector3Distance(Actor.Position, FBombActor.Position);

        // Affect blocks within a 25 unit radius
        if Dist < 25.0 then
        begin
          Dir := Vector3Subtract(Actor.Position, FBombActor.Position);
          if Vector3Length(Dir) > 0.001 then
            Dir := Vector3Normalize(Dir)
          else
            Dir := Vector3Create(0, 1, 0); // Fallback if exactly inside

          // Force is stronger closer to the bomb (Massive magnitude!)
          ForceMag := (25.0 - Dist) * 5000.0;

          // CRITICAL: Wake up the body from Sleep Mode before applying force!
          Actor.ActivateBody;

          // Apply the explosive impulse
          Actor.ApplyImpulse(Vector3Scale(Dir, ForceMag));

          // Add a strong upward kick for dramatic effect
          Actor.ApplyImpulse(Vector3Create(0, ForceMag * 0.3, 0));
        end;
      end;
    end;
  end;

  // Hide the bomb actor (it's consumed)
  FBombActor.Visible := False;
  FBombActor.FIsDead := True;
  FBombActor := nil;
end;
// External accessor to toggle slow motion from VCL/UI

procedure TRaylibSandbox.SetSlowMotion(Active: Boolean);
begin
  FSlowMotionActive := Active;
end;

procedure TRaylibSandbox.ClearDynamicItemsOnly;
begin
  FLock.Enter;
  try
    FGizmoMode := gmNone;
    FDragging := False;
    FItemSelected := nil;
    FSpawnQueue := 0;
    // Stop and free MPV player when the scene is cleared!
    if Assigned(FMPVPlayer) then
      FreeAndNil(FMPVPlayer);
    // Only clear dynamic items, keep FFloorActor and Engine alive!
    var i: Integer;
    for i := High(FItems) downto 0 do
    begin
      if Assigned(FItems[i]) then
      begin
        if FItems[i].FButtonTexture.id > 0 then
          UnloadTexture(FItems[i].FButtonTexture);
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
    FBombActor := nil;
    FBombExploded := False;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.ReattachLoadedActor(Actor: TA3DComponent);
var
  JPos: JPH_RVec3;
  JRot: JPH_Quat;
begin
  if not Assigned(Actor) or not Assigned(FEngine) then
    Exit;
  // Reassign the engine pointer in case it was lost during serialization
  Actor.FEngine := FEngine;
  // Recreate the physics body based on loaded transform and scale
  JPos.x := Actor.Position.x;
  JPos.y := Actor.Position.y;
  JPos.z := Actor.Position.z;
  JRot.x := Actor.Quaternion.x;
  JRot.y := Actor.Quaternion.y;
  JRot.z := Actor.Quaternion.z;
  JRot.w := Actor.Quaternion.w;
  // Create the body in Jolt
  Actor.FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, JPH_BodyCreationSettings_Create3(Actor.FShape, @JPos, @JRot, JPH_MotionType_Dynamic, 0 // Default ObjectLayer, adjust if you save/load layers
  ), JPH_Activation_Activate);
  Actor.Visible := True;
end;
// ============================================================================
// SCENE SAVING & LOADING (Executed in main thread)
// ============================================================================

procedure TRaylibSandbox.SaveSceneToFile(const FileName: string);
begin
  FLock.Enter;
  try
    FQueuedSavePath := FileName;
    FSaveSceneQueued := True;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.LoadSceneFromFile(const FileName: string);
begin
  FLock.Enter;
  try
    FQueuedLoadPath := FileName;
    FLoadSceneQueued := True;
  finally
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.ExecuteSceneSave(const FileName: string);
var
  Stream: TFileStream;
  Writer: TWriter;
  i: Integer;
  Actor: TA3DComponent;
begin
  if not Assigned(FEngine) then
    Exit;

  Stream := TFileStream.Create(FileName, fmCreate);
  FLock.Enter;
  try
    Writer := TWriter.Create(Stream, 4096);
    try
      Writer.WriteInteger(Length(FItems));

      for i := 0 to High(FItems) do
      begin
        Actor := FItems[i];
        if Assigned(Actor) then
        begin
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

          // Save ModelPath if the actor is a model, otherwise -
          if Actor.ShapeType = stModel then
            Writer.WriteStr(Actor.ModelPath)
          else
            Writer.WriteStr('-');
        end;
      end;
      Writer.FlushBuffer;
    finally
      Writer.Free;
    end;
  finally
    Stream.Free;
    FLock.Leave;
  end;
end;

procedure TRaylibSandbox.ExecuteSceneLoad(const FileName: string);
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
  AName, ModelPath: string;
begin
  if not Assigned(FEngine) then
    Exit;

  if not System.SysUtils.FileExists(FileName) then
    Exit;

  // Soft reset the scene
  ClearDynamicItemsOnly;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead);
    try
      Reader := TReader.Create(Stream, 4096);
      try
        Count := Reader.ReadInteger;

        for i := 0 to Count - 1 do
        begin
          AName := Reader.ReadStr;
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

          // Read ModelPath ('-' if not a model)
          ModelPath := Reader.ReadStr;

          // Create the Actor natively
          Actor := TA3DComponent.Create('', FEngine, ShapeType, Size, False, @JPos, @JRot);
          Actor.Name := AName;
          Actor.Friction := Friction;
          Actor.Restitution := Restitution;
          Actor.ActColor := LoadColor;
          Actor.TargetColor := LoadColor;
          Actor.Visible := True;

          // Load model mesh if it's a model
          if (ShapeType = stModel) and (ModelPath <> '-') then
          begin
            Actor.ModelPath := ModelPath;
            var LoadedModel := LoadModel(PAnsiChar(AnsiString(ModelPath)));
            if LoadedModel.meshes <> nil then
            begin
              if (LoadedModel.materialCount > 0) and (LoadedModel.materials <> nil) then
              begin
                for var matIdx := 0 to LoadedModel.materialCount - 1 do
                  LoadedModel.materials[matIdx].shader := FLightShader;
              end;
              Actor.FModel := LoadedModel;
              var BBox := GetModelBoundingBox(LoadedModel);
              var MeshSize := Vector3Create(BBox.max.x - BBox.min.x, BBox.max.y - BBox.min.y, BBox.max.z - BBox.min.z);
              Actor.FMeshSize := MeshSize;
              Actor.FModelOffset := Vector3Create(-BBox.min.x * Size.x, -BBox.min.y * Size.y - 0.5, -BBox.min.z * Size.z);
            end;
          end
          else
            Actor.ModelPath := '';

          SetLength(FItems, Length(FItems) + 1);
          FItems[High(FItems)] := Actor;

          // Notify VCL Form about the spawned actor so it gets added to the TreeView
          DoActorSpawned(Actor, High(FItems));

          // Give Jolt Physics a tiny breather so Broadphase can catch up
          // This prevents bodies from spawning at 0,0,0
          Sleep(1);
        end;
      finally
        Reader.Free;
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
      DoEngineException(E.Message, 'LoadSceneFromFile');
  end;
end;

end.


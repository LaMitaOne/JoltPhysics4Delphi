unit ModelEngine;

{==============================================================================*
 *  ModelEngine v0.53 - Actor Layer combining Raylib rendering with Jolt Physics
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
 *  License: Follows the licensing of the original Jolt Physics project.
 *
 *  Description:
 *    Provides an Object-Oriented Delphi layer wrapping the native Jolt
 *    Physics C API. It bridges the physics simulation with Raylib rendering
 *    concepts. Designed for high performance, minimal memory overhead, and
 *    direct integration into custom threaded engines.
 *
 *  Architecture:
 *    - TModelEngine: Manages the Jolt PhysicsSystem, JobSystem, TempAllocator,
 *      and collision filters. It holds a list of actors and advances the
 *      simulation every frame.
 *    - TA3DComponent: Represents a single rigid body in the physics world.
 *      It wraps the creation of shapes (Box, Sphere, Capsule, Cylinder),
 *      manages properties (Mass, Friction, Restitution), and syncs the
 *      native physics transforms back to Delphi.
 *
 *  Editor & Physics Integration (v0.4):
 *    - Detach/Reattach System: To allow freeform editing without crashing
 *      Jolt's internal state, components can be completely detached from
 *      the physics simulation (DestroyBody) and re-attached later with
 *      updated transforms and shapes.
 *    - Dynamic SetScale: Rebuilds the native Jolt Shape safely. Includes
 *      an automatic fallback to a 0.0 convex radius if the scale drops
 *      below Jolt's safe threshold (0.2m), allowing paper-thin walls.
 *
 *  Memory Management:
 *    - TModelEngine creates all native Jolt resources in the constructor and
 *      must destroy them in the destructor.
 *    - TA3DComponent creates a native BodyID upon creation and MUST remove
 *      and destroy that body (or be safely detached) before the Delphi
 *      object is freed.
 *==============================================================================}

{$POINTERMATH ON}

interface

uses
  Winapi.Windows, System.Types, Raylib, rlgl, Classes, SysUtils, Contnrs,
  RayMath, Math, JoltPhysics, r3ddelphi, TypInfo;

type
  TShapeType = (stBox, stSphere, stCapsule, stPyramid, stPrism, stModel);

  TA3DComponent = class;

  TCollisionEvent = procedure(Sender: TA3DComponent; Other: TA3DComponent; const ContactPoint: TVector3; const Normal: TVector3) of object;

  TModelEngine = class
  private
    FActorList: TObjectList;
    FPhysicsSystem: JPH_PhysicsSystem;
    FBodyInterface: JPH_BodyInterface;
    FJobSystem: JPH_JobSystem;
    FTempAllocator: JPH_TempAllocator;
    FBroadPhaseLayerInterface: JPH_BroadPhaseLayerInterface;
    FObjectLayerPairFilter: JPH_ObjectLayerPairFilter;
    FObjectVsBroadPhaseLayerFilter: JPH_ObjectVsBroadPhaseLayerFilter;
    FCollideAllLayer: JPH_ObjectLayer;
    FBroadPhaseLayerFilter: JPH_BroadPhaseLayerFilter;
    FObjectLayerFilter: JPH_ObjectLayerFilter;
    FBodyFilter: JPH_BodyFilter;
    FShapeFilter: JPH_ShapeFilter;
    function GetCount: integer;
    function GetComponent(const Index: integer): TA3DComponent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Component: TA3DComponent);
    procedure Remove(const Component: TA3DComponent);
    procedure Update(DeltaTime: single);
    procedure Render;
    procedure Clear;
    function RayCast(const Origin, Direction: TVector3; out HitBodyID: JPH_BodyID; out HitPoint: TVector3): Boolean;
    property Items[const Index: integer]: TA3DComponent read GetComponent; default;
    property Count: integer read GetCount;
    property CollideAllLayer: JPH_ObjectLayer read FCollideAllLayer;
    property PhysicsSystem: JPH_PhysicsSystem read FPhysicsSystem;
    property BodyInterface: JPH_BodyInterface read FBodyInterface;
  end;

  TA3DComponent = class(TComponent)
  private
    FFriction: Single;
    FRestitution: Single;
    FMass: Single;
    procedure SetFriction(const Value: Single);
    procedure SetRestitution(const Value: Single);
    procedure SetMass(const Value: Single);
    procedure SetScale(const Value: TVector3);
  protected
    FEngine: TModelEngine;
    FBodyID: JPH_BodyID;
    FShape: JPH_Shape;
    FShapeType: TShapeType;
    FVisible: boolean;
    FPosition: TVector3;
    FScale: TVector3;
    FRotation: TVector3;
    FQuaternion: TQuaternion;
    FUserData: Pointer;
    FOnCollision: TCollisionEvent;
    FTealGlow: Boolean;
    FActColor: TColorB;
    FTargetColor: TColorB;
    FActAlpha: Single;
    FTargetAlpha: Single;
    FLerpSpeed: Single;
    procedure UpdateModelTransform;
    procedure UpdateLerp(DeltaTime: Single);
  public
    FModel: TModel;
    FModelOffset: TVector3;
    FMeshSize: TVector3;
    FIsDead: boolean;
    FModelTransform: TMatrix;
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType; ASize: TVector3; IsStatic: Boolean = False; APos: PJPH_RVec3 = nil; ARot: PJPH_Quat = nil); reintroduce; overload;
    destructor Destroy; override;
    procedure Update(DeltaTime: single); virtual;
    procedure Draw; virtual;
    procedure SetPosition(APosition: TVector3);
    procedure SetRotation(AQuaternion: TQuaternion);
    procedure SetLinearVelocity(AVelocity: TVector3);
    function GetLinearVelocity: TVector3;
    procedure SetAngularVelocity(AVelocity: TVector3);
    procedure SetMotionType(AMotionType: JPH_MotionType);
    function GetAngularVelocity: TVector3;
    procedure ApplyImpulse(AImpulse: TVector3);
    procedure AddForce(AForce: TVector3);
    procedure ActivateBody;
    procedure DeactivateBody;
    procedure DetachFromPhysics;
    procedure ReattachToPhysics;
    property BodyID: JPH_BodyID read FBodyID;
    property UserData: Pointer read FUserData write FUserData;
    property TealGlow: Boolean read FTealGlow write FTealGlow;
  published
    property ShapeType: TShapeType read FShapeType write FShapeType;
    property Position: TVector3 read FPosition write SetPosition;
    property Quaternion: TQuaternion read FQuaternion write SetRotation;
    property Scale: TVector3 read FScale write SetScale;
    property Rotation: TVector3 read FRotation write FRotation;
    property Mass: Single read FMass write SetMass;
    property Friction: Single read FFriction write SetFriction;
    property Restitution: Single read FRestitution write SetRestitution;
    property Visible: boolean read FVisible write FVisible;
    property ActColor: TColorB read FActColor write FActColor;
    property TargetColor: TColorB read FTargetColor write FTargetColor;
    property ActAlpha: Single read FActAlpha write FActAlpha;
    property TargetAlpha: Single read FTargetAlpha write FTargetAlpha;
    property LerpSpeed: Single read FLerpSpeed write FLerpSpeed;
    property OnCollision: TCollisionEvent read FOnCollision write FOnCollision;
  end;

implementation

{ TModelEngine }

constructor TModelEngine.Create;
var
  JobConfig: JobSystemThreadPoolConfig;
  GravVec: JPH_Vec3;
  Settings: JPH_PhysicsSystemSettings;
  BPLProcs: JPH_BroadPhaseLayerFilter_Procs;
  OLProcs: JPH_ObjectLayerFilter_Procs;
  BFProcs: JPH_BodyFilter_Procs;
  SFProcs: JPH_ShapeFilter_Procs;
begin
  FActorList := TObjectList.Create(False);
  JPH_Init;
  FBroadPhaseLayerInterface := JPH_BroadPhaseLayerInterfaceMask_Create(1);
  FObjectLayerPairFilter := JPH_ObjectLayerPairFilterMask_Create;
  FObjectVsBroadPhaseLayerFilter := JPH_ObjectVsBroadPhaseLayerFilterMask_Create(FBroadPhaseLayerInterface);
  FCollideAllLayer := JPH_ObjectLayerPairFilterMask_GetObjectLayer(1, $FFFFFFFF);
  FillChar(Settings, SizeOf(Settings), 0);
  Settings.maxBodies := 10240;
  Settings.numBodyMutexes := 2;
  Settings.maxBodyPairs := 65536;
  Settings.maxContactConstraints := 65536;
  Settings.broadPhaseLayerInterface := FBroadPhaseLayerInterface;
  Settings.objectLayerPairFilter := FObjectLayerPairFilter;
  Settings.objectVsBroadPhaseLayerFilter := FObjectVsBroadPhaseLayerFilter;
  FPhysicsSystem := JPH_PhysicsSystem_Create(@Settings);
  FBodyInterface := JPH_PhysicsSystem_GetBodyInterface(FPhysicsSystem);
  JobConfig.maxJobs := JPH_MAX_PHYSICS_JOBS;
  JobConfig.maxBarriers := JPH_MAX_PHYSICS_BARRIERS;
  JobConfig.numThreads := -1;
  FJobSystem := JPH_JobSystemThreadPool_Create(@JobConfig);
  FTempAllocator := JPH_TempAllocatorMalloc_Create;
  GravVec.x := 0;
  GravVec.y := -9.81;
  GravVec.z := 0;
  JPH_PhysicsSystem_SetGravity(FPhysicsSystem, @GravVec);
  FillChar(BPLProcs, SizeOf(BPLProcs), 0);
  FBroadPhaseLayerFilter := JPH_BroadPhaseLayerFilter_Create(nil, @BPLProcs);
  FillChar(OLProcs, SizeOf(OLProcs), 0);
  FObjectLayerFilter := JPH_ObjectLayerFilter_Create(nil, @OLProcs);
  FillChar(BFProcs, SizeOf(BFProcs), 0);
  FBodyFilter := JPH_BodyFilter_Create(nil, @BFProcs);
  FillChar(SFProcs, SizeOf(SFProcs), 0);
  FShapeFilter := JPH_ShapeFilter_Create(nil, @SFProcs);
end;

destructor TModelEngine.Destroy;
begin
  Clear;
  JPH_ShapeFilter_Destroy(FShapeFilter);
  JPH_BodyFilter_Destroy(FBodyFilter);
  JPH_ObjectLayerFilter_Destroy(FObjectLayerFilter);
  JPH_BroadPhaseLayerFilter_Destroy(FBroadPhaseLayerFilter);
  JPH_TempAllocator_Destroy(FTempAllocator);
  JPH_JobSystem_Destroy(FJobSystem);
  JPH_PhysicsSystem_Destroy(FPhysicsSystem);
  JPH_ObjectVsBroadPhaseLayerFilter_Destroy(FObjectVsBroadPhaseLayerFilter);
  JPH_ObjectLayerPairFilter_Destroy(FObjectLayerPairFilter);
  JPH_BroadPhaseLayerInterface_Destroy(FBroadPhaseLayerInterface);
  JPH_Shutdown;
  FActorList.Free;
  inherited;
end;

procedure TModelEngine.Add(const Component: TA3DComponent);
begin
  FActorList.Add(Component);
end;

procedure TModelEngine.Remove(const Component: TA3DComponent);
begin
  FActorList.Remove(Component);
end;

procedure TModelEngine.Update(DeltaTime: single);
var
  i: integer;
  Comp: TA3DComponent;
begin
  if FPhysicsSystem = nil then
    Exit;
  try
    JPH_PhysicsSystem_Update2(FPhysicsSystem, DeltaTime, 1, FTempAllocator, FJobSystem);
    for i := FActorList.Count - 1 downto 0 do
    begin
      try
        Comp := TA3DComponent(FActorList.Items[i]);
        if Assigned(Comp) and not Comp.FIsDead then
          Comp.Update(DeltaTime);
      except
        on E: Exception do
          OutputDebugString(PChar('Engine Update Actor Exception: ' + E.Message));
      end;
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('Engine Physics Update Exception: ' + E.Message));
  end;
end;

procedure TModelEngine.Render;
begin
end;

procedure TModelEngine.Clear;
begin
  FActorList.Clear;
end;

function TModelEngine.GetCount: integer;
begin
  Result := FActorList.Count;
end;

function TModelEngine.GetComponent(const Index: integer): TA3DComponent;
begin
  Result := TA3DComponent(FActorList[Index]);
end;

function TModelEngine.RayCast(const Origin, Direction: TVector3; out HitBodyID: JPH_BodyID; out HitPoint: TVector3): Boolean;
var
  Query: JPH_NarrowPhaseQuery;
  JOrigin, JDir: JPH_Vec3;
  HitResult: PJPH_RayCastResult;
  SafeSize: Cardinal;
  RetVal: Byte;
begin
  Result := False;
  HitBodyID := 0;
  HitPoint := Vector3Zero;
  if FPhysicsSystem = nil then
    Exit;
  Query := JPH_PhysicsSystem_GetNarrowPhaseQuery(FPhysicsSystem);
  if Query = nil then
    Exit;
  JOrigin.x := Origin.x;
  JOrigin.y := Origin.y;
  JOrigin.z := Origin.z;
  JDir.x := Direction.x;
  JDir.y := Direction.y;
  JDir.z := Direction.z;
  SafeSize := SizeOf(JPH_RayCastResult) + 32;
  GetMem(HitResult, SafeSize);
  try
    FillChar(HitResult^, SafeSize, 0);
    RetVal := JPH_NarrowPhaseQuery_CastRay(Query, @JOrigin, @JDir, HitResult, FBroadPhaseLayerFilter, FObjectLayerFilter, FBodyFilter, FShapeFilter);
    if RetVal <> 0 then
    begin
      Result := True;
      HitBodyID := HitResult^.bodyID;
      HitPoint.x := Origin.x + Direction.x * HitResult^.fraction;
      HitPoint.y := Origin.y + Direction.y * HitResult^.fraction;
      HitPoint.z := Origin.z + Direction.z * HitResult^.fraction;
    end;
  finally
    FreeMem(HitResult);
  end;
end;

{ TA3DComponent }

constructor TA3DComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFriction := 0.6;
  FRestitution := 0.3;
  FMass := 1.0;
  FLerpSpeed := 5.0;
  FActColor := WHITE;
  FTargetColor := WHITE;
  FActAlpha := 1.0;
  FTargetAlpha := 1.0;
  FVisible := True;
  FTealGlow := False;
  FModel.meshes := nil;
  FMeshSize := Vector3Create(1, 1, 1);
end;

constructor TA3DComponent.Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType; ASize: TVector3; IsStatic: Boolean; APos: PJPH_RVec3; ARot: PJPH_Quat);
var
  ShapeSettings: JPH_ShapeSettings;
  HalfExtents: JPH_Vec3;
  Pos: JPH_RVec3;
  Rot: JPH_Quat;
  MotionType: JPH_MotionType;
  CreationSettings: JPH_BodyCreationSettings;
begin
  Create(nil);
  FEngine := AParent;
  FPosition := Vector3Create(0, 0, 0);
  FScale := ASize;
  FQuaternion := QuaternionIdentity;
  FModelTransform := MatrixIdentity();
  FShapeType := AShapeType;
  if IsStatic then
    MotionType := JPH_MotionType_Static
  else
    MotionType := JPH_MotionType_Dynamic;
  case AShapeType of
    stSphere:
      begin
        // Use max axis for sphere radius to ensure it visually matches standard scale
        ShapeSettings := JPH_SphereShapeSettings_Create(Max(ASize.x, Max(ASize.y, ASize.z)) * 0.5);
        FShape := JPH_SphereShapeSettings_CreateShape(ShapeSettings);
      end;
    stCapsule:
      begin
        // Jolt Capsule: HalfHeightOfCylinderPart, Radius
        ShapeSettings := JPH_CapsuleShapeSettings_Create((FScale.y - FScale.x) * 0.5, FScale.x * 0.5);
        FShape := JPH_CapsuleShapeSettings_CreateShape(ShapeSettings);
        FScale := Vector3Create(ASize.x, ASize.y, ASize.z);
      end;
    stPyramid, stPrism:
      begin
        // Use cylinder shape with 4 sides for pyramid/prism. Top radius 0 for pyramid, >0 for prism
        ShapeSettings := JPH_CylinderShapeSettings_Create(ASize.y * 0.5, ASize.x * 0.5, JPH_DEFAULT_CONVEX_RADIUS);
        FShape := JPH_CylinderShapeSettings_CreateShape(ShapeSettings);
        FScale := Vector3Create(ASize.x, ASize.y, ASize.z);
      end;
    stModel:
      begin
        // Use a fixed 1x1x1 physics box for models. The visual mesh is
        // normalized to 1x1x1 world units via rlScalef(1/MeshSize) in the
        // render code, so a half-extent of 0.5 matches the visual exactly.
        HalfExtents.x := 0.5;
        HalfExtents.y := 0.5;
        HalfExtents.z := 0.5;
        ShapeSettings := JPH_BoxShapeSettings_Create(@HalfExtents, JPH_DEFAULT_CONVEX_RADIUS);
        FShape := JPH_BoxShapeSettings_CreateShape(ShapeSettings);
      end;
  else
    begin
      // Handle both standard boxes and models using a box shape
      HalfExtents.x := ASize.x * 0.5;
      HalfExtents.y := ASize.y * 0.5;
      HalfExtents.z := ASize.z * 0.5;
      ShapeSettings := JPH_BoxShapeSettings_Create(@HalfExtents, JPH_DEFAULT_CONVEX_RADIUS);
      FShape := JPH_BoxShapeSettings_CreateShape(ShapeSettings);
    end;
  end;
  if APos <> nil then
    Pos := APos^
  else
  begin
    Pos.x := 0;
    Pos.y := 0;
    Pos.z := 0;
  end;
  if ARot <> nil then
    Rot := ARot^
  else
  begin
    Rot.x := 0;
    Rot.y := 0;
    Rot.z := 0;
    Rot.w := 1;
  end;
  CreationSettings := JPH_BodyCreationSettings_Create3(FShape, @Pos, @Rot, MotionType, FEngine.CollideAllLayer);
  if IsStatic then
    FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, CreationSettings, JPH_Activation_DontActivate)
  else
    FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, CreationSettings, JPH_Activation_Activate);
  JPH_ShapeSettings_Destroy(ShapeSettings);
  JPH_BodyInterface_SetFriction(FEngine.BodyInterface, FBodyID, FFriction);
  JPH_BodyInterface_SetRestitution(FEngine.BodyInterface, FBodyID, FRestitution);
  if Assigned(FEngine) then
    FEngine.Add(Self);
end;

destructor TA3DComponent.Destroy;
begin
  // Unload the native Raylib model if one was assigned to this actor
  if FModel.meshes <> nil then
    UnloadModel(FModel);

  if Assigned(FEngine) and (FBodyID <> 0) then
  begin
    JPH_BodyInterface_RemoveAndDestroyBody(FEngine.BodyInterface, FBodyID);
    FBodyID := 0;
  end;
  inherited;
end;

procedure TA3DComponent.UpdateLerp(DeltaTime: Single);
var
  LerpFactor: Single;
begin
  LerpFactor := EnsureRange(DeltaTime * FLerpSpeed, 0.0, 1.0);
  FActColor.r := Round(FActColor.r + (FTargetColor.r - FActColor.r) * LerpFactor);
  FActColor.g := Round(FActColor.g + (FTargetColor.g - FActColor.g) * LerpFactor);
  FActColor.b := Round(FActColor.b + (FTargetColor.b - FActColor.b) * LerpFactor);
  FActColor.a := Round(FActColor.a + (FTargetColor.a - FActColor.a) * LerpFactor);
  FActAlpha := FActAlpha + (FTargetAlpha - FActAlpha) * LerpFactor;
end;

procedure TA3DComponent.Update(DeltaTime: single);
var
  JPos: JPH_Vec3;
  JRot: JPH_Quat;
begin
  UpdateLerp(DeltaTime);
  if FBodyID <> 0 then
  begin
    JPH_BodyInterface_GetCenterOfMassPosition(FEngine.BodyInterface, FBodyID, @JPos);
    FPosition.x := JPos.x;
    FPosition.y := JPos.y;
    FPosition.z := JPos.z;
    JPH_BodyInterface_GetRotation(FEngine.BodyInterface, FBodyID, @JRot);
    FQuaternion.x := JRot.x;
    FQuaternion.y := JRot.y;
    FQuaternion.z := JRot.z;
    FQuaternion.w := JRot.w;
    UpdateModelTransform;
  end;
end;

procedure TA3DComponent.UpdateModelTransform;
var
  ScaleMat, RotMat, TransMat: TMatrix;
begin
  ScaleMat := MatrixScale(FScale.x, FScale.y, FScale.z);
  RotMat := QuaternionToMatrix(FQuaternion);
  TransMat := MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  FModelTransform := MatrixMultiply(MatrixMultiply(ScaleMat, RotMat), TransMat);
end;

procedure TA3DComponent.SetPosition(APosition: TVector3);
var
  JPos: JPH_RVec3;
begin
  FPosition := APosition;
  if FBodyID <> 0 then
  begin
    JPos.x := APosition.x;
    JPos.y := APosition.y;
    JPos.z := APosition.z;
    JPH_BodyInterface_SetPosition(FEngine.BodyInterface, FBodyID, @JPos, JPH_Activation_Activate);
  end;
  UpdateModelTransform;
end;

procedure TA3DComponent.SetRotation(AQuaternion: TQuaternion);
var
  JRot: JPH_Quat;
begin
  FQuaternion := AQuaternion;
  if FBodyID <> 0 then
  begin
    JRot.x := AQuaternion.x;
    JRot.y := AQuaternion.y;
    JRot.z := AQuaternion.z;
    JRot.w := AQuaternion.w;
    JPH_BodyInterface_SetRotation(FEngine.BodyInterface, FBodyID, @JRot, JPH_Activation_Activate);
  end;
  UpdateModelTransform;
end;

procedure TA3DComponent.SetMotionType(AMotionType: JPH_MotionType);
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_SetMotionType(FEngine.BodyInterface, FBodyID, AMotionType, JPH_Activation_Activate);
end;

procedure TA3DComponent.SetLinearVelocity(AVelocity: TVector3);
var
  JVel: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JVel.x := AVelocity.x;
    JVel.y := AVelocity.y;
    JVel.z := AVelocity.z;
    JPH_BodyInterface_SetLinearVelocity(FEngine.BodyInterface, FBodyID, @JVel);
  end;
end;

function TA3DComponent.GetLinearVelocity: TVector3;
var
  JVel: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JPH_BodyInterface_GetLinearVelocity(FEngine.BodyInterface, FBodyID, @JVel);
    Result.x := JVel.x;
    Result.y := JVel.y;
    Result.z := JVel.z;
  end
  else
    Result := Vector3Zero;
end;

procedure TA3DComponent.SetAngularVelocity(AVelocity: TVector3);
var
  JVel: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JVel.x := AVelocity.x;
    JVel.y := AVelocity.y;
    JVel.z := AVelocity.z;
    JPH_BodyInterface_SetAngularVelocity(FEngine.BodyInterface, FBodyID, @JVel);
  end;
end;

function TA3DComponent.GetAngularVelocity: TVector3;
var
  JVel: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JPH_BodyInterface_GetAngularVelocity(FEngine.BodyInterface, FBodyID, @JVel);
    Result.x := JVel.x;
    Result.y := JVel.y;
    Result.z := JVel.z;
  end
  else
    Result := Vector3Zero;
end;

procedure TA3DComponent.SetMass(const Value: Single);
begin
  FMass := Value;
end;

procedure TA3DComponent.SetFriction(const Value: Single);
begin
  FFriction := Value;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetFriction(FEngine.BodyInterface, FBodyID, Value);
end;

procedure TA3DComponent.SetRestitution(const Value: Single);
begin
  FRestitution := Value;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetRestitution(FEngine.BodyInterface, FBodyID, Value);
end;

procedure TA3DComponent.DetachFromPhysics;
begin
  if (FBodyID <> 0) and Assigned(FEngine) then
  begin
    JPH_BodyInterface_RemoveAndDestroyBody(FEngine.BodyInterface, FBodyID);
    FBodyID := 0;
  end;
end;

procedure TA3DComponent.ReattachToPhysics;
var
  Pos: JPH_RVec3;
  Rot: JPH_Quat;
  CreationSettings: JPH_BodyCreationSettings;
begin
  if (FBodyID = 0) and Assigned(FEngine) then
  begin
    Pos.x := FPosition.x;
    Pos.y := FPosition.y;
    Pos.z := FPosition.z;
    Rot.x := FQuaternion.x;
    Rot.y := FQuaternion.y;
    Rot.z := FQuaternion.z;
    Rot.w := FQuaternion.w;
    CreationSettings := JPH_BodyCreationSettings_Create3(FShape, @Pos, @Rot, JPH_MotionType_Dynamic, FEngine.CollideAllLayer);
    FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, CreationSettings, JPH_Activation_Activate);
    JPH_BodyInterface_SetFriction(FEngine.BodyInterface, FBodyID, FFriction);
    JPH_BodyInterface_SetRestitution(FEngine.BodyInterface, FBodyID, FRestitution);
  end;
end;

procedure TA3DComponent.SetScale(const Value: TVector3);
var
  ShapeSettings: JPH_ShapeSettings;
  HalfExtents: JPH_Vec3;
  ConvexRadius: Single;
begin
  FScale := Value;

  // Clean up old shape
  if FShape <> nil then
    JPH_Shape_Destroy(FShape);

  // Determine safe convex radius to prevent Jolt crashes on tiny objects
  ConvexRadius := JPH_DEFAULT_CONVEX_RADIUS;
  if (FScale.x < 0.2) or (FScale.y < 0.2) or (FScale.z < 0.2) then
    ConvexRadius := 0.0;

  case FShapeType of
    stSphere:
      begin
        // Use max axis for sphere radius to ensure it visually matches standard scale
        ShapeSettings := JPH_SphereShapeSettings_Create(Max(FScale.x, Max(FScale.y, FScale.z)) * 0.5);
        FShape := JPH_SphereShapeSettings_CreateShape(ShapeSettings);
      end;
    stCapsule:
      begin
        ShapeSettings := JPH_CapsuleShapeSettings_Create((FScale.y - FScale.x) * 0.5, FScale.x * 0.5);
        FShape := JPH_CapsuleShapeSettings_CreateShape(ShapeSettings);
      end;
    stPyramid, stPrism:
      begin
        ShapeSettings := JPH_CylinderShapeSettings_Create(FScale.y * 0.5, FScale.x * 0.5, ConvexRadius);
        FShape := JPH_CylinderShapeSettings_CreateShape(ShapeSettings);
      end;
    stModel:
      begin
        // For models, compute physics box half-extents from the original
        // mesh dimensions multiplied by the current scale. This keeps the
        // physics body in sync with the visual mesh at all times, including
        // when the user resizes the actor via the gizmo.
        HalfExtents.x := FMeshSize.x * FScale.x * 0.5;
        HalfExtents.y := FMeshSize.y * FScale.y * 0.5;
        HalfExtents.z := FMeshSize.z * FScale.z * 0.5;
        ShapeSettings := JPH_BoxShapeSettings_Create(@HalfExtents, ConvexRadius);
        FShape := JPH_BoxShapeSettings_CreateShape(ShapeSettings);
      end;
  else
    begin
      HalfExtents.x := FScale.x * 0.5;
      HalfExtents.y := FScale.y * 0.5;
      HalfExtents.z := FScale.z * 0.5;
      ShapeSettings := JPH_BoxShapeSettings_Create(@HalfExtents, ConvexRadius);
      FShape := JPH_BoxShapeSettings_CreateShape(ShapeSettings);
    end;
  end;

  JPH_ShapeSettings_Destroy(ShapeSettings);
  UpdateModelTransform;
end;

procedure TA3DComponent.ApplyImpulse(AImpulse: TVector3);
var
  JImp: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JImp.x := AImpulse.x;
    JImp.y := AImpulse.y;
    JImp.z := AImpulse.z;
    JPH_BodyInterface_AddImpulse(FEngine.BodyInterface, FBodyID, @JImp);
  end;
end;

procedure TA3DComponent.AddForce(AForce: TVector3);
var
  JForce: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JForce.x := AForce.x;
    JForce.y := AForce.y;
    JForce.z := AForce.z;
    JPH_BodyInterface_AddForce(FEngine.BodyInterface, FBodyID, @JForce);
  end;
end;

procedure TA3DComponent.ActivateBody;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_ActivateBody(FEngine.BodyInterface, FBodyID);
end;

procedure TA3DComponent.DeactivateBody;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_DeactivateBody(FEngine.BodyInterface, FBodyID);
end;

procedure TA3DComponent.Draw;
begin
  // Rendering is handled externally
end;

end.


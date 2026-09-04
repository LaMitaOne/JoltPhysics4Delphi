unit ModelEngine;

{==============================================================================*
 *  ModelEngine - Actor Layer combining Raylib rendering with Jolt Physics
 *------------------------------------------------------------------------------
 *  Description:
 *    This unit provides an Object-Oriented Delphi layer wrapping the native
 *    Jolt Physics C API. It bridges the physics simulation with Raylib
 *    rendering concepts.
 *
 *  Architecture:
 *    - TModelEngine: Manages the Jolt PhysicsSystem, JobSystem, TempAllocator,
 *      and collision filters. It holds a list of actors and advances the
 *      simulation every frame.
 *    - TModelActor: Represents a single rigid body in the physics world.
 *      It wraps the creation of shapes (Box, Sphere, Capsule, Cylinder),
 *      manages properties (Mass, Friction, Restitution), and syncs the
 *      native physics transforms back to Delphi.
 *
 *  Memory Management:
 *    - TModelEngine creates all native Jolt resources in the constructor and
 *      must destroy them in the destructor.
 *    - TModelActor creates a native BodyID upon creation and MUST remove and
 *      destroy that body in its destructor before the Delphi object is freed.
 *==============================================================================}

{$POINTERMATH ON}

interface

uses
  Raylib, rlgl, Classes, SysUtils, Contnrs, RayMath, Math,
  JoltPhysics, r3ddelphi;

type
  /// <summary>
  /// Defines the primitive collision shape used by the physics engine.
  /// </summary>
  TShapeType = (stBox, stSphere, stCapsule, stCylinder);

  TModelActor = class;

  /// <summary>
  /// Callback signature for collision events between actors.
  /// </summary>
  TCollisionEvent = procedure(Sender: TModelActor; Other: TModelActor; const ContactPoint: TVector3; const Normal: TVector3) of object;

  { TModelEngine }
  /// <summary>
  /// Manages the physics world, systems, and all actors.
  /// </summary>
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
    function GetModelActor(const Index: integer): TModelActor;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ModelActor: TModelActor);
    procedure Remove(const ModelActor: TModelActor);
    procedure Update(DeltaTime: single);
    procedure Render;
    procedure Clear;

    /// <summary>
    /// Casts a ray into the physics world and returns the closest hit.
    /// </summary>
    function RayCast(const Origin, Direction: TVector3; out HitBodyID: JPH_BodyID; out HitPoint: TVector3): Boolean;

    property Items[const Index: integer]: TModelActor read GetModelActor; default;
    property Count: integer read GetCount;
    property CollideAllLayer: JPH_ObjectLayer read FCollideAllLayer;
    property PhysicsSystem: JPH_PhysicsSystem read FPhysicsSystem;
    property BodyInterface: JPH_BodyInterface read FBodyInterface;
  end;

  { TModelActor }
  /// <summary>
  /// Represents an individual physics body and its associated render model.
  /// </summary>
  TModelActor = class
  private
    FFriction: Single;
    FRestitution: Single;
    FMass: Single;
    procedure SetFriction(const Value: Single);
    procedure SetRestitution(const Value: Single);
    procedure SetMass(const Value: Single);
  protected
    FEngine: TModelEngine;
    FBodyID: JPH_BodyID;
    FShape: JPH_Shape;
    FShapeType: TShapeType;
    FModel: TR3D_Model;
    FVisible: boolean;
    FIsDead: boolean;
    FPosition: TVector3;
    FScale: TVector3;
    FRotation: TVector3;
    FQuaternion: TQuaternion;
    FModelOffset: TVector3;
    FModelTransform: TMatrix;
    FUserData: Pointer;
    FOnCollision: TCollisionEvent;

    /// <summary>
    /// Syncs the internal Delphi Matrix transform used for rendering
    /// with the Position and Quaternion from the physics body.
    /// </summary>
    procedure UpdateModelTransform;
  public
    constructor Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType;
      ASize: TVector3; IsStatic: Boolean = False);
    destructor Destroy; override;

    procedure Update(DeltaTime: single); virtual;
    procedure Draw; virtual;

    // Mutators & Accessors
    procedure SetPosition(APosition: TVector3);
    procedure SetRotation(AQuaternion: TQuaternion);
    procedure SetLinearVelocity(AVelocity: TVector3);
    function GetLinearVelocity: TVector3;
    procedure SetAngularVelocity(AVelocity: TVector3);
    function GetAngularVelocity: TVector3;
    procedure ApplyImpulse(AImpulse: TVector3);
    procedure AddForce(AForce: TVector3);
    procedure ActivateBody;

    property BodyID: JPH_BodyID read FBodyID;
    property ShapeType: TShapeType read FShapeType;
    property UserData: Pointer read FUserData write FUserData;
    property Position: TVector3 read FPosition write SetPosition;
    property Quaternion: TQuaternion read FQuaternion write SetRotation;
    property Mass: Single read FMass write SetMass;
    property Friction: Single read FFriction write SetFriction;
    property Restitution: Single read FRestitution write SetRestitution;
    property Visible: boolean read FVisible write FVisible;
    property OnCollision: TCollisionEvent read FOnCollision write FOnCollision;
  end;

  // Placeholder for the actual r3ddelphi record
  TR3D_Model = record Dummy: Integer; end;

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
  // We don't own the actors, so don't free them when list is cleared
  FActorList := TObjectList.Create(False);

  // 1. Initialize Core Physics Systems
  JPH_Init;

  // 2. Setup Broadphase Filters (Mask-based: everything collides with everything)
  FBroadPhaseLayerInterface := JPH_BroadPhaseLayerInterfaceMask_Create(1);
  FObjectLayerPairFilter := JPH_ObjectLayerPairFilterMask_Create;
  FObjectVsBroadPhaseLayerFilter := JPH_ObjectVsBroadPhaseLayerFilterMask_Create(FBroadPhaseLayerInterface);
  FCollideAllLayer := JPH_ObjectLayerPairFilterMask_GetObjectLayer(1, $FFFFFFFF);

  // 3. Setup PhysicsSystem Settings
  Settings.maxBodies := 10240;
  Settings.maxBodyPairs := 65536;
  Settings.maxContactConstraints := 10240;
  Settings.broadPhaseLayerInterface := FBroadPhaseLayerInterface;
  Settings.objectLayerPairFilter := FObjectLayerPairFilter;
  Settings.objectVsBroadPhaseLayerFilter := FObjectVsBroadPhaseLayerFilter;

  FPhysicsSystem := JPH_PhysicsSystem_Create(@Settings);
  FBodyInterface := JPH_PhysicsSystem_GetBodyInterface(FPhysicsSystem);

  // 4. Setup Threading & Memory Allocators
  JobConfig.maxJobs := JPH_MAX_PHYSICS_JOBS;
  JobConfig.maxBarriers := JPH_MAX_PHYSICS_BARRIERS;
  JobConfig.numThreads := -1; // -1 = auto-detect CPU cores
  FJobSystem := JPH_JobSystemThreadPool_Create(@JobConfig);
  FTempAllocator := JPH_TempAllocatorMalloc_Create;

  // 5. Set Gravity (-9.81 m/s^2 on Y axis)
  GravVec.x := 0; GravVec.y := -9.81; GravVec.z := 0;
  JPH_PhysicsSystem_SetGravity(FPhysicsSystem, @GravVec);

  // 6. Initialize Default Filters (Zeroed out structs mean "always allow")
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
  // Cleanup all native Jolt objects in reverse order of creation
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

procedure TModelEngine.Add(const ModelActor: TModelActor);
begin
  FActorList.Add(ModelActor);
end;

procedure TModelEngine.Remove(const ModelActor: TModelActor);
begin
  FActorList.Remove(ModelActor);
end;

procedure TModelEngine.Update(DeltaTime: single);
var
  i: integer;
  Actor: TModelActor;
begin
  // 1. Advance the Jolt Physics simulation by DeltaTime
  JPH_PhysicsSystem_Update2(FPhysicsSystem, DeltaTime, 1, FTempAllocator, FJobSystem);

  // 2. Iterate backwards to safely handle deletions during iteration
  for i := FActorList.Count - 1 downto 0 do
  begin
   try
    Actor := TModelActor(FActorList.Items[i]);
    if Assigned(Actor) and not Actor.FIsDead then
      Actor.Update(DeltaTime);
   except
     // Catch exceptions to prevent the thread from dying entirely
   end;
  end;
end;

procedure TModelEngine.Render;
begin
  // Rendering is currently handled externally by Raylib in the Sandbox
end;

procedure TModelEngine.Clear;
begin
  FActorList.Clear;
end;

function TModelEngine.GetCount: integer;
begin
  Result := FActorList.Count;
end;

function TModelEngine.GetModelActor(const Index: integer): TModelActor;
begin
  Result := TModelActor(FActorList[Index]);
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

  if FPhysicsSystem = nil then Exit;

  Query := JPH_PhysicsSystem_GetNarrowPhaseQuery(FPhysicsSystem);
  if Query = nil then Exit;

  // Map Delphi RayMath types to Jolt Physics types
  JOrigin.x := Origin.x; JOrigin.y := Origin.y; JOrigin.z := Origin.z;
  JDir.x := Direction.x; JDir.y := Direction.y; JDir.z := Direction.z;

  // Allocate memory for the hit result safely
  SafeSize := SizeOf(JPH_RayCastResult) + 32; // Add padding just to be safe against C API overruns
  GetMem(HitResult, SafeSize);
  try
    FillChar(HitResult^, SafeSize, 0);
    RetVal := JPH_NarrowPhaseQuery_CastRay(
      Query, @JOrigin, @JDir, HitResult,
      FBroadPhaseLayerFilter, FObjectLayerFilter, FBodyFilter, FShapeFilter);

    if RetVal <> 0 then
    begin
      Result := True;
      HitBodyID := HitResult^.bodyID;
      // Calculate world hit point: Origin + (Direction * Fraction)
      HitPoint.x := Origin.x + Direction.x * HitResult^.fraction;
      HitPoint.y := Origin.y + Direction.y * HitResult^.fraction;
      HitPoint.z := Origin.z + Direction.z * HitResult^.fraction;
    end;
  finally
    FreeMem(HitResult);
  end;
end;

{ TModelActor }

constructor TModelActor.Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType;
  ASize: TVector3; IsStatic: Boolean);
var
  ShapeSettings: JPH_ShapeSettings;
  HalfExtents: JPH_Vec3;
  Pos: JPH_RVec3;
  Rot: JPH_Quat;
  MotionType: JPH_MotionType;
  CreationSettings: JPH_BodyCreationSettings;
begin
  FEngine := AParent;
  // Default Delphi properties
  FPosition := Vector3Create(0, 0, 0);
  FScale := Vector3Create(1, 1, 1);
  FQuaternion := QuaternionIdentity;
  FModelTransform := MatrixIdentity();
  FUserData := nil;
  FFriction := 0.5;
  FRestitution := 0.2;
  FMass := 1.0;
  FShapeType := AShapeType;

  if IsStatic then
    MotionType := JPH_MotionType_Static
  else
    MotionType := JPH_MotionType_Dynamic;

  // 1. Create Jolt Shape Settings based on ShapeType
  case AShapeType of
    stSphere:
    begin
      ShapeSettings := JPH_SphereShapeSettings_Create(ASize.x);
      FShape := JPH_SphereShapeSettings_CreateShape(ShapeSettings);
    end;
    stCapsule:
    begin
      ShapeSettings := JPH_CapsuleShapeSettings_Create(ASize.y * 0.5, ASize.x);
      FShape := JPH_CapsuleShapeSettings_CreateShape(ShapeSettings);
    end;
    stCylinder:
    begin
      ShapeSettings := JPH_CylinderShapeSettings_Create(ASize.y * 0.5, ASize.x, JPH_DEFAULT_CONVEX_RADIUS);
      FShape := JPH_CylinderShapeSettings_CreateShape(ShapeSettings);
    end;
    else // stBox
    begin
      HalfExtents.x := ASize.x * 0.5;
      HalfExtents.y := ASize.y * 0.5;
      HalfExtents.z := ASize.z * 0.5;
      ShapeSettings := JPH_BoxShapeSettings_Create(@HalfExtents, JPH_DEFAULT_CONVEX_RADIUS);
      FShape := JPH_BoxShapeSettings_CreateShape(ShapeSettings);
    end;
  end;

  // 2. Initial Position and Rotation
  Pos.x := 0; Pos.y := 0; Pos.z := 0;
  Rot.x := 0; Rot.y := 0; Rot.z := 0; Rot.w := 1; // Identity quaternion

  // 3. Create the Body
  CreationSettings := JPH_BodyCreationSettings_Create3(FShape, @Pos, @Rot, MotionType, FEngine.CollideAllLayer);

  if IsStatic then
    FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, CreationSettings, JPH_Activation_DontActivate)
  else
    FBodyID := JPH_BodyInterface_CreateAndAddBody(FEngine.BodyInterface, CreationSettings, JPH_Activation_Activate);

  // 4. Clean up intermediate shape settings object
  JPH_ShapeSettings_Destroy(ShapeSettings);

  // 5. Apply default physical properties
  JPH_BodyInterface_SetFriction(FEngine.BodyInterface, FBodyID, FFriction);
  JPH_BodyInterface_SetRestitution(FEngine.BodyInterface, FBodyID, FRestitution);

  // 6. Register self with the Engine
  if Assigned(FEngine) then
    FEngine.Add(Self);
end;

destructor TModelActor.Destroy;
begin
  // CRITICAL: We must remove the native physics body from Jolt BEFORE
  // the Delphi object is torn down, otherwise Jolt will hold dangling pointers.
  if Assigned(FEngine) and (FBodyID <> 0) then
  begin
    JPH_BodyInterface_RemoveAndDestroyBody(FEngine.BodyInterface, FBodyID);
    FBodyID := 0; // Prevent double deletion
  end;

  inherited;
end;

procedure TModelActor.Update(DeltaTime: single);
begin
  // Poll the physics engine for the current transform and update Delphi vars
  if FBodyID <> 0 then
  begin
    JPH_BodyInterface_GetCenterOfMassPosition(FEngine.BodyInterface, FBodyID, @FPosition);
    JPH_BodyInterface_GetRotation(FEngine.BodyInterface, FBodyID, @FQuaternion);
    UpdateModelTransform;
  end;
end;

procedure TModelActor.UpdateModelTransform;
begin
  // Build render matrix: Translation * Rotation
  FModelTransform := MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  FModelTransform := MatrixMultiply(QuaternionToMatrix(FQuaternion), FModelTransform);
end;

procedure TModelActor.SetPosition(APosition: TVector3);
begin
  FPosition := APosition;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetPosition(FEngine.BodyInterface, FBodyID, @APosition, JPH_Activation_Activate);
  UpdateModelTransform;
end;

procedure TModelActor.SetRotation(AQuaternion: TQuaternion);
begin
  FQuaternion := AQuaternion;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetRotation(FEngine.BodyInterface, FBodyID, @AQuaternion, JPH_Activation_Activate);
  UpdateModelTransform;
end;

procedure TModelActor.SetLinearVelocity(AVelocity: TVector3);
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_SetLinearVelocity(FEngine.BodyInterface, FBodyID, @AVelocity);
end;

function TModelActor.GetLinearVelocity: TVector3;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_GetLinearVelocity(FEngine.BodyInterface, FBodyID, @Result)
  else
    Result := Vector3Zero;
end;

procedure TModelActor.SetAngularVelocity(AVelocity: TVector3);
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_SetAngularVelocity(FEngine.BodyInterface, FBodyID, @AVelocity);
end;

function TModelActor.GetAngularVelocity: TVector3;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_GetAngularVelocity(FEngine.BodyInterface, FBodyID, @Result)
  else
    Result := Vector3Zero;
end;

procedure TModelActor.SetMass(const Value: Single);
begin
  // NOTE: Setting mass dynamically in Jolt requires overriding mass properties
  // which is not fully wrapped in this version. Stored locally only.
  FMass := Value;
end;

procedure TModelActor.SetFriction(const Value: Single);
begin
  FFriction := Value;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetFriction(FEngine.BodyInterface, FBodyID, Value);
end;

procedure TModelActor.SetRestitution(const Value: Single);
begin
  FRestitution := Value;
  if FBodyID <> 0 then
    JPH_BodyInterface_SetRestitution(FEngine.BodyInterface, FBodyID, Value);
end;

procedure TModelActor.ApplyImpulse(AImpulse: TVector3);
begin
  if FBodyID <> 0 then
    // nil position means apply impulse at Center of Mass
    JPH_BodyInterface_AddImpulse(FEngine.BodyInterface, FBodyID, @AImpulse, nil);
end;

procedure TModelActor.AddForce(AForce: TVector3);
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_AddForce(FEngine.BodyInterface, FBodyID, @AForce);
end;

procedure TModelActor.ActivateBody;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_ActivateBody(FEngine.BodyInterface, FBodyID);
end;

procedure TModelActor.Draw;
begin
  // Hook for descendants to implement custom Raylib rendering
end;

end.

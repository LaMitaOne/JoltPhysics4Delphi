unit ModelEngine;

{==============================================================================*
 *  ModelEngine v0.2 - Actor Layer combining Raylib rendering with Jolt Physics
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
  Raylib, rlgl, Classes, SysUtils, Contnrs, RayMath, Math, JoltPhysics,
  r3ddelphi;

type
  TShapeType = (stBox, stSphere, stCapsule, stPyramid);

  TModelActor = class;

  TCollisionEvent = procedure(Sender: TModelActor; Other: TModelActor; const ContactPoint: TVector3; const Normal: TVector3) of object;

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

    function RayCast(const Origin, Direction: TVector3; out HitBodyID: JPH_BodyID; out HitPoint: TVector3): Boolean;

    property Items[const Index: integer]: TModelActor read GetModelActor; default;
    property Count: integer read GetCount;
    property CollideAllLayer: JPH_ObjectLayer read FCollideAllLayer;
    property PhysicsSystem: JPH_PhysicsSystem read FPhysicsSystem;
    property BodyInterface: JPH_BodyInterface read FBodyInterface;
  end;

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
    FUserData: Pointer;
    FOnCollision: TCollisionEvent;
    FTealGlow: Boolean;
    procedure UpdateModelTransform;
  public
    FModelTransform: TMatrix;
    constructor Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType; ASize: TVector3; IsStatic: Boolean = False; APos: PJPH_RVec3 = nil; ARot: PJPH_Quat = nil);
    destructor Destroy; override;

    procedure Update(DeltaTime: single); virtual;
    procedure Draw; virtual;

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
    property TealGlow: Boolean read FTealGlow write FTealGlow;
    property OnCollision: TCollisionEvent read FOnCollision write FOnCollision;
    property Scale: TVector3 read FScale;
  end;

  TR3D_Model = record
    Dummy: Integer;
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
  JPH_PhysicsSystem_Update2(FPhysicsSystem, DeltaTime, 1, FTempAllocator, FJobSystem);
  for i := FActorList.Count - 1 downto 0 do
  begin
    Actor := TModelActor(FActorList.Items[i]);
    if Assigned(Actor) and not Actor.FIsDead then
      Actor.Update(DeltaTime);
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

{ TModelActor }

constructor TModelActor.Create(const AModelPath: string; AParent: TModelEngine; AShapeType: TShapeType; ASize: TVector3; IsStatic: Boolean; APos: PJPH_RVec3; ARot: PJPH_Quat);
var
  ShapeSettings: JPH_ShapeSettings;
  HalfExtents: JPH_Vec3;
  Pos: JPH_RVec3;
  Rot: JPH_Quat;
  MotionType: JPH_MotionType;
  CreationSettings: JPH_BodyCreationSettings;
begin
  FEngine := AParent;
  FPosition := Vector3Create(0, 0, 0);
  FScale := ASize;
  FQuaternion := QuaternionIdentity;
  FModelTransform := MatrixIdentity();
  FUserData := nil;
  FFriction := 0.5;
  FRestitution := 0.2;
  FMass := 1.0;
  FShapeType := AShapeType;
  FVisible := True;
  FTealGlow := False;

  if IsStatic then
    MotionType := JPH_MotionType_Static
  else
    MotionType := JPH_MotionType_Dynamic;

  case AShapeType of
    stSphere:
      begin
        ShapeSettings := JPH_SphereShapeSettings_Create(ASize.x * 0.5);
        FShape := JPH_SphereShapeSettings_CreateShape(ShapeSettings);
      end;
    stCapsule:
      begin
        ShapeSettings := JPH_CapsuleShapeSettings_Create(ASize.y * 0.5, ASize.x);
        FShape := JPH_CapsuleShapeSettings_CreateShape(ShapeSettings);
      end;
    stPyramid:
      begin
      // Jolt has no direct pyramid type, but we can use a cylinder
        ShapeSettings := JPH_CylinderShapeSettings_Create(0.75, ASize.x, JPH_DEFAULT_CONVEX_RADIUS);
        FShape := JPH_CylinderShapeSettings_CreateShape(ShapeSettings);
      // Adjust scale so Y and Z are swapped
        FScale := Vector3Create(ASize.x, ASize.z, ASize.y);
      end;
  else
    begin
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

destructor TModelActor.Destroy;
begin
  if Assigned(FEngine) and (FBodyID <> 0) then
  begin
    JPH_BodyInterface_RemoveAndDestroyBody(FEngine.BodyInterface, FBodyID);
    FBodyID := 0;
  end;
  inherited;
end;

procedure TModelActor.Update(DeltaTime: single);
var
  JPos: JPH_Vec3;
  JRot: JPH_Quat;
begin
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

procedure TModelActor.UpdateModelTransform;
var
  ScaleMat, RotMat, TransMat: TMatrix;
begin
  ScaleMat := MatrixScale(FScale.x, FScale.y, FScale.z);
  RotMat := QuaternionToMatrix(FQuaternion);
  TransMat := MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);

  // Standard DirectX/OpenGL order: Scale -> Rotation -> Translation
  FModelTransform := MatrixMultiply(MatrixMultiply(ScaleMat, RotMat), TransMat);
end;

procedure TModelActor.SetPosition(APosition: TVector3);
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

procedure TModelActor.SetRotation(AQuaternion: TQuaternion);
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

procedure TModelActor.SetLinearVelocity(AVelocity: TVector3);
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

function TModelActor.GetLinearVelocity: TVector3;
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

procedure TModelActor.SetAngularVelocity(AVelocity: TVector3);
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

function TModelActor.GetAngularVelocity: TVector3;
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

procedure TModelActor.SetMass(const Value: Single);
begin
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
var
  JImp: JPH_Vec3;
begin
  if FBodyID <> 0 then
  begin
    JImp.x := AImpulse.x;
    JImp.y := AImpulse.y;
    JImp.z := AImpulse.z;
    JPH_BodyInterface_AddImpulse(FEngine.BodyInterface, FBodyID, @JImp, nil);
  end;
end;

procedure TModelActor.AddForce(AForce: TVector3);
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

procedure TModelActor.ActivateBody;
begin
  if FBodyID <> 0 then
    JPH_BodyInterface_ActivateBody(FEngine.BodyInterface, FBodyID);
end;

procedure TModelActor.Draw;
begin
//--
end;

end.


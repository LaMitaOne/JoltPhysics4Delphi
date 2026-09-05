unit JoltPhysics;

{==============================================================================*
 *  JoltPhysics v0.2 - Delphi Wrapper for Jolt Physics C API
 *------------------------------------------------------------------------------
    Author:  Lara Miriam Tamy Reschke / LamitaOne
 *  Description:
 *    This unit provides Delphi bindings for the Jolt Physics C API (JoltC.dll).
 *    Jolt Physics is a fast, multi-threaded physics engine originally written
 *    in C++ by Jorrit Rouwe. The C API allows usage from other languages.
 *
 *  Status:
 *    This wrapper is a work-in-progress. The core functionality (world setup,
 *    body creation, shape creation, ray casting, transforms, forces/impulses)
 *    is implemented and usable. Some advanced features are still missing and
 *    may be added in future revisions. Contributions are welcome.
 *
 *  Usage:
 *    1. Call JPH_Init() once at startup.
 *    2. Create a BroadPhaseLayerInterface, ObjectLayerPairFilter and
 *       ObjectVsBroadPhaseLayerFilter.
 *    3. Create a PhysicsSystem using JPH_PhysicsSystem_Create.
 *    4. Create a TempAllocator and a JobSystemThreadPool.
 *    5. Add bodies via the BodyInterface and run JPH_PhysicsSystem_Update2
 *       every frame.
 *    6. Call JPH_Shutdown() on program exit.
 *
 *  Notes:
 *    - All handles are opaque pointers; do not dereference them in Delphi.
 *    - Records passed to the API by pointer must not be moved/rellocated
 *      while the C side holds a reference.
 *    - The DLL must match the architecture (x86/x64) of the host application.
 *
 *  License:
 *    Follow the licensing of the original Jolt Physics project.
 *    See: https://github.com/jrouwe/JoltPhysics
 *==============================================================================}
interface
{$MINENUMSIZE 4}

uses
  SysUtils;

const
  // Name of the native library loaded at runtime.
  JOLT_LIB = 'JoltC.dll';

  // Default tolerances and radii used by Jolt for collision shapes.
  JPH_DEFAULT_COLLISION_TOLERANCE = 1.0e-4;
  JPH_DEFAULT_PENETRATION_TOLERANCE = 1.0e-4;
  JPH_DEFAULT_CONVEX_RADIUS = 0.05;
  JPH_CAPSULE_PROJECTION_SLOP = 0.02;

  // Upper bounds for the internal job system allocation pools.
  JPH_MAX_PHYSICS_JOBS = 2048;
  JPH_MAX_PHYSICS_BARRIERS = 8;

  // Invalid IDs used to represent "no group" or "no subgroup".
  JPH_INVALID_COLLISION_GROUP_ID = $FFFFFFFF;
  JPH_INVALID_COLLISION_SUBGROUP_ID = $FFFFFFFF;

type
  // --- Primitive Typen ---
  // 32-bit boolean (C _Bool / int)
  JPH_Bool = UInt32;
  // Unique identifier for a body

  JPH_BodyID = UInt32;
  // Identifies a sub-part of a compound shape

  JPH_SubShapeID = UInt32;
  // User-defined collision layer

  JPH_ObjectLayer = UInt32;
  // Broad-phase bucket a layer belongs to

  JPH_BroadPhaseLayer = Byte;
  // Collision group id

  JPH_CollisionGroupID = UInt32;
  // Collision sub group id

  JPH_CollisionSubGroupID = UInt32;
  // Virtual character id

  JPH_CharacterID = UInt32;
  // Debug-rendering color (0xRRGGBBAA)

  JPH_Color = UInt32;

  // --- Opaque Handles (Pointer) ---
  // They are declared as distinct types so the compiler can distinguish them.
  JPH_BroadPhaseLayerInterface = type Pointer;

  JPH_ObjectVsBroadPhaseLayerFilter = type Pointer;

  JPH_ObjectLayerPairFilter = type Pointer;

  JPH_BroadPhaseLayerFilter = type Pointer;

  JPH_ObjectLayerFilter = type Pointer;

  JPH_BodyFilter = type Pointer;

  JPH_ShapeFilter = type Pointer;

  JPH_SimShapeFilter = type Pointer;

  JPH_PhysicsStepListener = type Pointer;

  JPH_PhysicsSystem = type Pointer;

  JPH_PhysicsMaterial = type Pointer;

  JPH_LinearCurve = type Pointer;

  JPH_ShapeSettings = type Pointer;

  JPH_ConvexShapeSettings = type Pointer;

  JPH_SphereShapeSettings = type Pointer;

  JPH_BoxShapeSettings = type Pointer;

  JPH_PlaneShapeSettings = type Pointer;

  JPH_TriangleShapeSettings = type Pointer;

  JPH_CapsuleShapeSettings = type Pointer;

  JPH_TaperedCapsuleShapeSettings = type Pointer;

  JPH_CylinderShapeSettings = type Pointer;

  JPH_TaperedCylinderShapeSettings = type Pointer;

  JPH_ConvexHullShapeSettings = type Pointer;

  JPH_CompoundShapeSettings = type Pointer;

  JPH_StaticCompoundShapeSettings = type Pointer;

  JPH_MutableCompoundShapeSettings = type Pointer;

  JPH_MeshShapeSettings = type Pointer;

  JPH_HeightFieldShapeSettings = type Pointer;

  JPH_RotatedTranslatedShapeSettings = type Pointer;

  JPH_ScaledShapeSettings = type Pointer;

  JPH_OffsetCenterOfMassShapeSettings = type Pointer;

  JPH_EmptyShapeSettings = type Pointer;

  JPH_Shape = type Pointer;

  JPH_ConvexShape = type Pointer;

  JPH_SphereShape = type Pointer;

  JPH_BoxShape = type Pointer;

  JPH_PlaneShape = type Pointer;

  JPH_CapsuleShape = type Pointer;

  JPH_CylinderShape = type Pointer;

  JPH_TaperedCylinderShape = type Pointer;

  JPH_TriangleShape = type Pointer;

  JPH_TaperedCapsuleShape = type Pointer;

  JPH_ConvexHullShape = type Pointer;

  JPH_CompoundShape = type Pointer;

  JPH_StaticCompoundShape = type Pointer;

  JPH_MutableCompoundShape = type Pointer;

  JPH_MeshShape = type Pointer;

  JPH_HeightFieldShape = type Pointer;

  JPH_DecoratedShape = type Pointer;

  JPH_RotatedTranslatedShape = type Pointer;

  JPH_ScaledShape = type Pointer;

  JPH_OffsetCenterOfMassShape = type Pointer;

  JPH_EmptyShape = type Pointer;

  JPH_BodyCreationSettings = type Pointer;

  JPH_SoftBodyCreationSettings = type Pointer;

  JPH_SoftBodySharedSettings = type Pointer;

  JPH_BodyInterface = type Pointer;

  JPH_BodyLockInterface = type Pointer;

  JPH_BroadPhaseQuery = type Pointer;

  JPH_NarrowPhaseQuery = type Pointer;

  JPH_MotionProperties = type Pointer;

  JPH_Body = type Pointer;

  JPH_CollideShapeResult = type Pointer;

  JPH_ContactListener = type Pointer;

  JPH_ContactManifold = type Pointer;

  JPH_GroupFilter = type Pointer;

  JPH_GroupFilterTable = type Pointer;

  JPH_BodyActivationListener = type Pointer;

  JPH_BodyDrawFilter = type Pointer;

  JPH_SharedMutex = type Pointer;

  JPH_DebugRenderer = type Pointer;

  JPH_Constraint = type Pointer;

  JPH_TwoBodyConstraint = type Pointer;

  JPH_FixedConstraint = type Pointer;

  JPH_DistanceConstraint = type Pointer;

  JPH_PointConstraint = type Pointer;

  JPH_HingeConstraint = type Pointer;

  JPH_SliderConstraint = type Pointer;

  JPH_ConeConstraint = type Pointer;

  JPH_SwingTwistConstraint = type Pointer;

  JPH_SixDOFConstraint = type Pointer;

  JPH_GearConstraint = type Pointer;

  JPH_CharacterBase = type Pointer;

  JPH_Character = type Pointer;

  JPH_CharacterVirtual = type Pointer;

  JPH_CharacterContactListener = type Pointer;

  JPH_CharacterVsCharacterCollision = type Pointer;

  JPH_Skeleton = type Pointer;

  JPH_SkeletonPose = type Pointer;

  JPH_SkeletalAnimation = type Pointer;

  JPH_SkeletonMapper = type Pointer;

  JPH_RagdollSettings = type Pointer;

  JPH_Ragdoll = type Pointer;

  JPH_VehicleConstraint = type Pointer;

  JPH_VehicleController = type Pointer;

  JPH_VehicleControllerSettings = type Pointer;

  JPH_WheeledVehicleController = type Pointer;

  JPH_WheeledVehicleControllerSettings = type Pointer;

  JPH_TrackedVehicleController = type Pointer;

  JPH_TrackedVehicleControllerSettings = type Pointer;

  JPH_MotorcycleController = type Pointer;

  JPH_MotorcycleControllerSettings = type Pointer;

  JPH_Wheel = type Pointer;

  JPH_WheelSettings = type Pointer;

  JPH_WheelWV = type Pointer;

  JPH_WheelSettingsWV = type Pointer;

  JPH_WheelTV = type Pointer;

  JPH_WheelSettingsTV = type Pointer;

  JPH_VehicleEngine = type Pointer;

  JPH_VehicleTransmission = type Pointer;

  JPH_VehicleTransmissionSettings = type Pointer;

  JPH_VehicleCollisionTester = type Pointer;

  JPH_VehicleCollisionTesterRay = type Pointer;

  JPH_VehicleCollisionTesterCastSphere = type Pointer;

  JPH_VehicleCollisionTesterCastCylinder = type Pointer;

  JPH_TempAllocator = type Pointer;

  JPH_JobSystem = type Pointer;

  // --- Math Types (Records must match the C struct layout exactly) ---
  JPH_Vec3 = record
    x, y, z: Single;
  end;

  PJPH_Vec3 = ^JPH_Vec3;

  JPH_Vec4 = record
    x, y, z, w: Single;
  end;

  PJPH_Vec4 = ^JPH_Vec4;

  JPH_Quat = record
    x, y, z, w: Single;
  end;

  PJPH_Quat = ^JPH_Quat;

  JPH_Plane = record
    normal: JPH_Vec3;
    distance: Single;
  end;

  PJPH_Plane = ^JPH_Plane;

  JPH_Mat44 = record
    column: array[0..3] of JPH_Vec4;
  end;

  PJPH_Mat44 = ^JPH_Mat44;

  // Double-precision Vec3 - here aliased to single precision. If you need
  // real double-precision coordinates enable the corresponding Jolt build.
  JPH_RVec3 = JPH_Vec3;

  PJPH_RVec3 = ^JPH_RVec3;

  JPH_RMat44 = JPH_Mat44;

  PJPH_RMat44 = ^JPH_RMat44;

  JPH_Point = record
    x, y: Single;
  end;

  PJPH_Point = ^JPH_Point;

  JPH_AABox = record
    min, max: JPH_Vec3;
  end;

  PJPH_AABox = ^JPH_AABox;

  JPH_Triangle = record
    v1, v2, v3: JPH_Vec3;
    materialIndex: UInt32;
  end;

  PJPH_Triangle = ^JPH_Triangle;

  JPH_IndexedTriangle = record
    i1, i2, i3, materialIndex, userData: UInt32;
  end;

  PJPH_IndexedTriangle = ^JPH_IndexedTriangle;

  JPH_MassProperties = record
    mass: Single;
    inertia: JPH_Mat44;
  end;

  PJPH_MassProperties = ^JPH_MassProperties;

  // Result of a successful ray cast.
  PJPH_RayCastResult = ^JPH_RayCastResult;

  JPH_RayCastResult = record
    bodyID: JPH_BodyID;
    fraction: Single;
    subShapeID2: JPH_SubShapeID;
  end;

  // Result of a broad-phase cast (raycast or shape cast).
  PJPH_BroadPhaseCastResult = ^JPH_BroadPhaseCastResult;

  JPH_BroadPhaseCastResult = record
    bodyID: JPH_BodyID;
    fraction: Single;
  end;

  // Result of a point collision query.
  PJPH_CollidePointResult = ^JPH_CollidePointResult;

  JPH_CollidePointResult = record
    bodyID: JPH_BodyID;
    subShapeID2: JPH_SubShapeID;
  end;

  // Identifies a pair of sub-shapes that are colliding.
  PJPH_SubShapeIDPair = ^JPH_SubShapeIDPair;

  JPH_SubShapeIDPair = record
    Body1ID: JPH_BodyID;
    subShapeID1: JPH_SubShapeID;
    Body2ID: JPH_BodyID;
    subShapeID2: JPH_SubShapeID;
  end;

  // Soft body vertex data (position, velocity, inverse mass).
  PJPH_SoftVertex = ^JPH_SoftVertex;

  JPH_SoftVertex = record
    position, velocity: JPH_Vec3;
    invMass: Single;
  end;

  // Soft body face data (vertex indices and material).
  PJPH_SoftFace = ^JPH_SoftFace;

  JPH_SoftFace = record
    vertex1, vertex2, vertex3, materialIndex: UInt32;
  end;

  // --- Enums (Declared early so records can use them) ---
  // Result code returned by JPH_PhysicsSystem_Update2.
  JPH_PhysicsUpdateError = type UInt32;
  // Type of a body (Rigid or Soft)

  JPH_BodyType = type UInt32;
  // Motion properties of a body (Static, Kinematic, Dynamic)

  JPH_MotionType = type UInt32;
  // Activation mode used when adding/moving bodies

  JPH_Activation = type UInt32;
  // Validation result for body creation

  JPH_ValidateResult = type UInt32;
  // Shape type (Sphere, Box, Mesh, etc.)

  JPH_ShapeType = type UInt32;
  // Shape sub-type for more specific casting

  JPH_ShapeSubType = type UInt32;
  // Quality of motion (Discrete or LinearCast)

  JPH_MotionQuality = type UInt32;
  // How to handle mass properties when creating a body

  JPH_OverrideMassProperties = type UInt32;
  // Degrees of freedom allowed for a body

  JPH_AllowedDOFs = type UInt32;
  // State of a character's contact with the ground

  JPH_GroundState = type UInt32;
  // Whether to collide with back faces

  JPH_BackFaceMode = type UInt32;
  // How to handle active edges in meshes

  JPH_ActiveEdgeMode = type UInt32;
  // Whether to collect faces during collision

  JPH_CollectFacesMode = type UInt32;
  // State of a constraint motor (Off, Velocity, Position)

  JPH_MotorState = type UInt32;
  // Type of collision collector

  JPH_CollisionCollectorType = type UInt32;
  // Type of swing constraint

  JPH_SwingType = type UInt32;
  // Type of constraint

  JPH_ConstraintType = type UInt32;
  // Sub-type of constraint

  JPH_ConstraintSubType = type UInt32;
  // Space in which a constraint operates

  JPH_ConstraintSpace = type UInt32;
  // Mode for spring settings

  JPH_SpringMode = type UInt32;
  // Mode for vehicle transmission

  JPH_TransmissionMode = type UInt32;
  // Color mode for soft body constraints

  JPH_SoftBodyConstraintColor = type UInt32;
  // Bend type for soft body

  JPH_SoftBodyBendType = type UInt32;
  // Color mode for body shapes in debug rendering

  JPH_BodyManager_ShapeColor = type UInt32;
  // Shadow casting mode in debug renderer

  JPH_DebugRenderer_CastShadow = type UInt32;
  // Draw mode in debug renderer

  JPH_DebugRenderer_DrawMode = type UInt32;
  // Build quality for mesh shapes

  JPH_Mesh_Shape_BuildQuality = type UInt32;
  // Side of a tracked vehicle track

  JPH_TrackSide = type UInt32;
  // Axis for a 6DOF constraint

  JPH_SixDOFConstraintAxis = type UInt32;

const
  // 0 means no error, any combination of the bits below indicates a problem
  JPH_PhysicsUpdateError_None = 0;

  // Motion types: Static (never moves), Kinematic (moved by user), Dynamic (simulated)
  JPH_MotionType_Static = 0;
  JPH_MotionType_Kinematic = 1;
  JPH_MotionType_Dynamic = 2;

  // Activation modes: Activate or DontActivate
  JPH_Activation_Activate = 0;
  JPH_Activation_DontActivate = 1;

  // Spring modes: Frequency/Damping or Stiffness/Damping
  JPH_SpringMode_FrequencyAndDamping = 0;
  JPH_SpringMode_StiffnessAndDamping = 1;

type
  // Settings passed to a contact listener to modify contact properties
  PJPH_ContactSettings = ^JPH_ContactSettings;

  JPH_ContactSettings = record
    combinedFriction: Single;
    combinedRestitution: Single;
    invMassScale1: Single;
    invInertiaScale1: Single;
    invMassScale2: Single;
    invInertiaScale2: Single;
    isSensor: JPH_Bool;
    relativeLinearSurfaceVelocity: JPH_Vec3;
    relativeAngularSurfaceVelocity: JPH_Vec3;
  end;

  // Configuration record for the thread-pool based job system.
  PJobSystemThreadPoolConfig = ^JobSystemThreadPoolConfig;

  JobSystemThreadPoolConfig = record
    maxJobs: UInt32;      // Maximum number of concurrent jobs allowed
    maxBarriers: UInt32;  // Maximum number of barriers allowed
    numThreads: Int32;    // Number of worker threads (-1 = auto-detect)
  end;

  // Settings used to construct a JPH_PhysicsSystem instance.
  PJPH_PhysicsSystemSettings = ^JPH_PhysicsSystemSettings;

  JPH_PhysicsSystemSettings = record
    maxBodies: UInt32;                  // Maximum number of bodies allowed
    numBodyMutexes: UInt32;             // Number of body mutexes (use a power of 2)
    maxBodyPairs: UInt32;               // Maximum simultaneously active body pairs
    maxContactConstraints: UInt32;      // Maximum simultaneously active contact constraints
    _padding: UInt32;                   // Explicit alignment padding
    broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface;     // User-provided BP layer interface
    objectLayerPairFilter: JPH_ObjectLayerPairFilter;          // User-provided layer pair filter
    objectVsBroadPhaseLayerFilter: JPH_ObjectVsBroadPhaseLayerFilter; // User-provided BP-vs-object filter
  end;

  // General physics simulation settings.
  PJPH_PhysicsSettings = ^JPH_PhysicsSettings;

  JPH_PhysicsSettings = record
    maxInFlightBodyPairs: Int32;
    stepListenersBatchSize: Int32;
    stepListenerBatchesPerJob: Int32;
    baumgarte: Single;
    speculativeContactDistance: Single;
    penetrationSlop: Single;
    linearCastThreshold: Single;
    linearCastMaxPenetration: Single;
    manifoldTolerance: Single;
    maxPenetrationDistance: Single;
    bodyPairCacheMaxDeltaPositionSq: Single;
    bodyPairCacheCosMaxDeltaRotationDiv2: Single;
    contactNormalCosMaxDeltaRotation: Single;
    contactPointPreserveLambdaMaxDistSq: Single;
    numVelocitySteps: UInt32;
    numPositionSteps: UInt32;
    minVelocityForRestitution: Single;
    timeBeforeSleep: Single;
    pointVelocitySleepThreshold: Single;
    deterministicSimulation: JPH_Bool;
    constraintWarmStart: JPH_Bool;
    useBodyPairContactCache: JPH_Bool;
    useManifoldReduction: JPH_Bool;
    useLargeIslandSplitter: JPH_Bool;
    allowSleeping: JPH_Bool;
    checkActiveEdges: JPH_Bool;
  end;

  // Collision group settings for a body
  PJPH_CollisionGroup = ^JPH_CollisionGroup;

  JPH_CollisionGroup = record
    groupFilter: JPH_GroupFilter;
    groupID: JPH_CollisionGroupID;
    subGroupID: JPH_CollisionSubGroupID;
  end;

  // Spring settings used by motors and constraints
  PJPH_SpringSettings = ^JPH_SpringSettings;

  JPH_SpringSettings = record
    mode: JPH_SpringMode;
    frequencyOrStiffness: Single;
    damping: Single;
  end;

  // Motor settings used by constraints
  PJPH_MotorSettings = ^JPH_MotorSettings;

  JPH_MotorSettings = record
    springSettings: JPH_SpringSettings;
    minForceLimit, maxForceLimit, minTorqueLimit, maxTorqueLimit: Single;
  end;

  // ---------------------------------------------------------------------------
  //  Callback vtables - these are struct-of-function-pointers matching the
  //  C API. Each field must point to a cdecl callback.
  // ---------------------------------------------------------------------------
  PJPH_BroadPhaseLayerFilter_Procs = ^JPH_BroadPhaseLayerFilter_Procs;

  JPH_BroadPhaseLayerFilter_Procs = record
    ShouldCollide: Pointer;
  end;

  PJPH_ObjectLayerFilter_Procs = ^JPH_ObjectLayerFilter_Procs;

  JPH_ObjectLayerFilter_Procs = record
    ShouldCollide: Pointer;
  end;

  PJPH_BodyFilter_Procs = ^JPH_BodyFilter_Procs;

  JPH_BodyFilter_Procs = record
    ShouldCollide: Pointer;
    ShouldCollideLocked: Pointer;
  end;

  PJPH_ShapeFilter_Procs = ^JPH_ShapeFilter_Procs;

  JPH_ShapeFilter_Procs = record
    ShouldCollide: Pointer;
    ShouldCollide2: Pointer;
  end;

  // === API FUNCTIONS ===
  // All functions are cdecl and imported from JoltC.dll.
  // Ownership rules:
  //   - Every *_Create call that returns a heap-allocated handle must be paired
  //     with the matching *_Destroy call to avoid leaks.
  //   - Shapes returned by *_CreateShape are reference-counted by the engine.
  // =============================================================================

  // -- Lifecycle ---------------------------------------------------------------
function JPH_Init: JPH_Bool; cdecl; external JOLT_LIB;

procedure JPH_Shutdown; cdecl; external JOLT_LIB;

  // -- BroadPhaseLayerInterface (mask-based default implementation) -------------
function JPH_BroadPhaseLayerInterfaceMask_Create(numBroadPhaseLayers: UInt32): JPH_BroadPhaseLayerInterface; cdecl; external JOLT_LIB;

procedure JPH_BroadPhaseLayerInterface_Destroy(bpInterface: JPH_BroadPhaseLayerInterface); cdecl; external JOLT_LIB;

  // -- ObjectLayerPairFilter (mask-based default implementation) ---------------
function JPH_ObjectLayerPairFilterMask_Create: JPH_ObjectLayerPairFilter; cdecl; external JOLT_LIB;

procedure JPH_ObjectLayerPairFilter_Destroy(filter: JPH_ObjectLayerPairFilter); cdecl; external JOLT_LIB;
  // Helper to build an ObjectLayer value from a (group, mask) pair.

function JPH_ObjectLayerPairFilterMask_GetObjectLayer(group: UInt32; mask: UInt32): JPH_ObjectLayer; cdecl; external JOLT_LIB;

  // -- ObjectVsBroadPhaseLayerFilter (mask-based default implementation) --------
function JPH_ObjectVsBroadPhaseLayerFilterMask_Create(broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface): JPH_ObjectVsBroadPhaseLayerFilter; cdecl; external JOLT_LIB;

procedure JPH_ObjectVsBroadPhaseLayerFilter_Destroy(filter: JPH_ObjectVsBroadPhaseLayerFilter); cdecl; external JOLT_LIB;

  // -- Custom filter wrappers (callback-based) ----------------------------------
  //  Each Create() takes a userData pointer and a vtable of callbacks.
function JPH_BroadPhaseLayerFilter_Create(userData: Pointer; procs: PJPH_BroadPhaseLayerFilter_Procs): JPH_BroadPhaseLayerFilter; cdecl; external JOLT_LIB;

procedure JPH_BroadPhaseLayerFilter_Destroy(filter: JPH_BroadPhaseLayerFilter); cdecl; external JOLT_LIB;

function JPH_ObjectLayerFilter_Create(userData: Pointer; procs: PJPH_ObjectLayerFilter_Procs): JPH_ObjectLayerFilter; cdecl; external JOLT_LIB;

procedure JPH_ObjectLayerFilter_Destroy(filter: JPH_ObjectLayerFilter); cdecl; external JOLT_LIB;

function JPH_BodyFilter_Create(userData: Pointer; procs: PJPH_BodyFilter_Procs): JPH_BodyFilter; cdecl; external JOLT_LIB;

procedure JPH_BodyFilter_Destroy(filter: JPH_BodyFilter); cdecl; external JOLT_LIB;

function JPH_ShapeFilter_Create(userData: Pointer; procs: PJPH_ShapeFilter_Procs): JPH_ShapeFilter; cdecl; external JOLT_LIB;

procedure JPH_ShapeFilter_Destroy(filter: JPH_ShapeFilter); cdecl; external JOLT_LIB;

  // -- PhysicsSystem -----------------------------------------------------------
function JPH_PhysicsSystem_Create(settings: PJPH_PhysicsSystemSettings): JPH_PhysicsSystem; cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_Destroy(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetPhysicsSettings(system: JPH_PhysicsSystem; settings: PJPH_PhysicsSettings); cdecl; external JOLT_LIB;

  // Rebuilds the broad-phase structures. Call after adding/removing many bodies.
procedure JPH_PhysicsSystem_OptimizeBroadPhase(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

  // Advance the simulation by deltaTime seconds.
function JPH_PhysicsSystem_Update2(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Int32; tempAllocator: JPH_TempAllocator; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetGravity(system: JPH_PhysicsSystem; value: PJPH_Vec3); cdecl; external JOLT_LIB;

  // Returns the non-locking body interface.
function JPH_PhysicsSystem_GetBodyInterface(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_GetNarrowPhaseQuery(system: JPH_PhysicsSystem): JPH_NarrowPhaseQuery; cdecl; external JOLT_LIB;

  // -- JobSystem / TempAllocator ------------------------------------------------
function JPH_JobSystemThreadPool_Create(config: PJobSystemThreadPoolConfig): JPH_JobSystem; cdecl; external JOLT_LIB;

procedure JPH_JobSystem_Destroy(jobSystem: JPH_JobSystem); cdecl; external JOLT_LIB;

  // Uses malloc internally.
function JPH_TempAllocator_Create(size: UInt32): JPH_TempAllocator; cdecl; external JOLT_LIB;

function JPH_TempAllocatorMalloc_Create: JPH_TempAllocator; cdecl; external JOLT_LIB;

procedure JPH_TempAllocator_Destroy(allocator: JPH_TempAllocator); cdecl; external JOLT_LIB;

  // -- Body creation -----------------------------------------------------------
  // Create3 builds a JPH_BodyCreationSettings from a shape, transform and motion type.
function JPH_BodyCreationSettings_Create3(shape: JPH_Shape; position: PJPH_RVec3; rotation: PJPH_Quat; motionType: JPH_MotionType; objectLayer: JPH_ObjectLayer): JPH_BodyCreationSettings; cdecl; external JOLT_LIB;
  // Returns the BodyID of the newly added body.

function JPH_BodyInterface_CreateAndAddBody(bodyInterface: JPH_BodyInterface; settings: JPH_BodyCreationSettings; activationMode: JPH_Activation): JPH_BodyID; cdecl; external JOLT_LIB;
  // Removes the body from the world and destroys the underlying body object.

procedure JPH_BodyInterface_RemoveAndDestroyBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

  // -- Body transform ----------------------------------------------------------
procedure JPH_BodyInterface_SetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetCenterOfMassPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetWorldTransform(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RMat44); cdecl; external JOLT_LIB;

  // -- Body velocity ------------------------------------------------------------
procedure JPH_BodyInterface_SetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

  // -- Forces / impulses --------------------------------------------------------
  //  AddImpulse: optional world-space position; if nil, applies at the center of mass.
  //  AddForce:   continuous force, applied during the next simulation step only.
procedure JPH_BodyInterface_AddImpulse(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; impulse: PJPH_Vec3; position: PJPH_RVec3 = nil); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddForce(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; force: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_ActivateBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

  // -- Surface properties -------------------------------------------------------
procedure JPH_BodyInterface_SetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; friction: Single); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; restitution: Single); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;

  // -- Ray casting --------------------------------------------------------------
  //  Casts a ray from `origin` in `direction` (not necessarily normalized).
  //  Returns 1 if a hit was found and writes the result to `hit`, otherwise 0.
function JPH_NarrowPhaseQuery_CastRay(query: JPH_NarrowPhaseQuery; origin: PJPH_RVec3; direction: PJPH_Vec3; hit: PJPH_RayCastResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): Byte; cdecl; external JOLT_LIB;

  // -- Shape settings (builders for convex shapes) -----------------------------
  //  Each *ShapeSettings_Create returns a settings object. Call the corresponding
  //  *_CreateShape to obtain the actual JPH_Shape, then destroy the settings object.
function JPH_BoxShapeSettings_Create(halfExtent: PJPH_Vec3; convexRadius: Single): JPH_BoxShapeSettings; cdecl; external JOLT_LIB;

function JPH_SphereShapeSettings_Create(radius: Single): JPH_SphereShapeSettings; cdecl; external JOLT_LIB;

function JPH_CapsuleShapeSettings_Create(halfHeightOfCylinder: Single; radius: Single): JPH_CapsuleShapeSettings; cdecl; external JOLT_LIB;

function JPH_CylinderShapeSettings_Create(halfHeight: Single; radius: Single; convexRadius: Single): JPH_CylinderShapeSettings; cdecl; external JOLT_LIB;

function JPH_BoxShapeSettings_CreateShape(settings: JPH_BoxShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_SphereShapeSettings_CreateShape(settings: JPH_SphereShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CapsuleShapeSettings_CreateShape(settings: JPH_CapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CylinderShapeSettings_CreateShape(settings: JPH_CylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

procedure JPH_ShapeSettings_Destroy(settings: JPH_ShapeSettings); cdecl; external JOLT_LIB;

implementation

end.


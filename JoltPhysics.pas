unit JoltPhysics;

{==============================================================================*
 *  JoltPhysics v0.3 - Delphi Wrapper for Jolt Physics C API
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
 *    is implemented and usable. Advanced features (constraints, characters,
 *    math helpers, and contact listeners) have been added.
 *    Some highly complex features (like vehicles and ragdolls) are still
 *    missing and may be added in future revisions.
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


 Latest changes:

  v0.3:
     Expanded Structs & Records: Added necessary records for advanced queries, including JPH_CollideShapeResult, JPH_ShapeCastResult, JPH_CollideShapeSettings, JPH_ShapeCastSettings, and JPH_RayCastSettings.
     Constraint System: Implemented base structs (JPH_ConstraintSettings) and specific settings for Fixed, Point, Distance, Hinge, and Slider constraints. Added corresponding API functions for creation, destruction, and control (e.g., JPH_HingeConstraint_SetMotorState).
     Complete Enum Constants: Added all missing enum values as constants (e.g., JPH_BodyType, JPH_ShapeSubType, JPH_AllowedDOFs, JPH_GroundState, JPH_MotorState, JPH_ConstraintSubType, etc.).
     Listeners & Callbacks: Added vtable structs and API functions for JPH_ContactListener (collision events) and JPH_BodyActivationListener (sleep/wake events).
     Extended Body Interface: Integrated many missing functions such as AddTorque, AddForce2 (with position parameter), AddAngularImpulse, combined getters/setters for velocities, and queries for Active-state, ObjectLayer, and UserData.
     Additional Shapes: Added settings and creation functions for TaperedCapsule, TaperedCylinder, ConvexHull, StaticCompound, and MeshShape. Also added JPH_CompoundShapeSettings_AddShape for grouping shapes.
     Math Helpers: Wrapped useful C-API math functions (JPH_Vec3_Cross, JPH_Vec3_Normalize, JPH_Quat_Rotate, JPH_Mat44_RotationTranslation, etc.).
     Material System: Added functions to create and destroy JPH_PhysicsMaterial.
     Miscellaneous: Added JPH_PhysicsSystem_Update (without TempAllocator) .

 *==============================================================================}
interface
{$MINENUMSIZE 4}
{$A+} // Ensure default alignment to match C/C++ structs

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

  // ShapeSettings
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

  // Shapes
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

  // Other Handles
  JPH_BodyCreationSettings = type Pointer;

  JPH_SoftBodyCreationSettings = type Pointer;

  JPH_SoftBodySharedSettings = type Pointer;

  JPH_BodyInterface = type Pointer;

  JPH_BodyLockInterface = type Pointer;

  JPH_BroadPhaseQuery = type Pointer;

  JPH_NarrowPhaseQuery = type Pointer;

  JPH_MotionProperties = type Pointer;

  JPH_Body = type Pointer;

  JPH_ContactListener = type Pointer;

  JPH_ContactManifold = type Pointer;

  JPH_GroupFilter = type Pointer;

  JPH_GroupFilterTable = type Pointer;

  JPH_BodyActivationListener = type Pointer;

  JPH_BodyDrawFilter = type Pointer;

  JPH_SharedMutex = type Pointer;

  JPH_DebugRenderer = type Pointer;

  // Constraints
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

  // Characters
  JPH_CharacterBase = type Pointer;

  JPH_Character = type Pointer;

  JPH_CharacterVirtual = type Pointer;

  JPH_CharacterContactListener = type Pointer;

  JPH_CharacterVsCharacterCollision = type Pointer;

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
  // Axis for a 6DOF constraint

  JPH_SixDOFConstraintAxis = type UInt32;

const
  // 0 means no error, any combination of the bits below indicates a problem
  JPH_PhysicsUpdateError_None = 0;
  JPH_PhysicsUpdateError_ManifoldCacheFull = 1 shl 0;
  JPH_PhysicsUpdateError_BodyPairCacheFull = 1 shl 1;
  JPH_PhysicsUpdateError_ContactConstraintsFull = 1 shl 2;

  // Motion types: Static (never moves), Kinematic (moved by user), Dynamic (simulated)
  JPH_MotionType_Static = 0;
  JPH_MotionType_Kinematic = 1;
  JPH_MotionType_Dynamic = 2;

  // Body types: Rigid (solid) or Soft (deformable)
  JPH_BodyType_Rigid = 0;
  JPH_BodyType_Soft = 1;

  // Activation modes: Activate or DontActivate
  JPH_Activation_Activate = 0;
  JPH_Activation_DontActivate = 1;

  // Validation results for contact listeners
  JPH_ValidateResult_AcceptAllContactsForThisBodyPair = 0;
  JPH_ValidateResult_AcceptContact = 1;
  JPH_ValidateResult_RejectContact = 2;
  JPH_ValidateResult_RejectAllContactsForThisBodyPair = 3;

  // Shape types: Defines the fundamental category of a shape
  JPH_ShapeType_Convex = 0;
  JPH_ShapeType_Compound = 1;
  JPH_ShapeType_Decorated = 2;
  JPH_ShapeType_Mesh = 3;
  JPH_ShapeType_HeightField = 4;
  JPH_ShapeType_SoftBody = 5;
  JPH_ShapeType_User1 = 6;
  JPH_ShapeType_User2 = 7;
  JPH_ShapeType_User3 = 8;
  JPH_ShapeType_User4 = 9;

  // Shape sub-types: Specific implementations of shape types
  JPH_ShapeSubType_Sphere = 0;
  JPH_ShapeSubType_Box = 1;
  JPH_ShapeSubType_Triangle = 2;
  JPH_ShapeSubType_Capsule = 3;
  JPH_ShapeSubType_TaperedCapsule = 4;
  JPH_ShapeSubType_Cylinder = 5;
  JPH_ShapeSubType_ConvexHull = 6;
  JPH_ShapeSubType_StaticCompound = 7;
  JPH_ShapeSubType_MutableCompound = 8;
  JPH_ShapeSubType_RotatedTranslated = 9;
  JPH_ShapeSubType_Scaled = 10;
  JPH_ShapeSubType_OffsetCenterOfMass = 11;
  JPH_ShapeSubType_Mesh = 12;
  JPH_ShapeSubType_HeightField = 13;
  JPH_ShapeSubType_SoftBody = 14;

  // Motion qualities: Discrete (default, fast objects might tunnel) or LinearCast (prevents tunneling at high speeds)
  JPH_MotionQuality_Discrete = 0;
  JPH_MotionQuality_LinearCast = 1;

  // Mass properties override modes for body creation
  JPH_OverrideMassProperties_CalculateMassAndInertia = 0;
  JPH_OverrideMassProperties_CalculateInertia = 1;
  JPH_OverrideMassProperties_MassAndInertiaProvided = 2;

  // Allowed Degrees of Freedom (bitflags)
  JPH_AllowedDOFs_All = $3F;
  JPH_AllowedDOFs_TranslationX = $01;
  JPH_AllowedDOFs_TranslationY = $02;
  JPH_AllowedDOFs_TranslationZ = $04;
  JPH_AllowedDOFs_RotationX = $08;
  JPH_AllowedDOFs_RotationY = $10;
  JPH_AllowedDOFs_RotationZ = $20;
  JPH_AllowedDOFs_Plane2D = JPH_AllowedDOFs_TranslationX or JPH_AllowedDOFs_TranslationY or JPH_AllowedDOFs_RotationZ;

  // Ground states for characters
  JPH_GroundState_OnGround = 0;
  JPH_GroundState_OnSteepGround = 1;
  JPH_GroundState_NotSupported = 2;
  JPH_GroundState_InAir = 3;

  // Back face modes for ray/shape casting
  JPH_BackFaceMode_IgnoreBackFaces = 0;
  JPH_BackFaceMode_CollideWithBackFaces = 1;

  // Active edge modes for meshes
  JPH_ActiveEdgeMode_CollideOnlyWithActive = 0;
  JPH_ActiveEdgeMode_CollideWithAll = 1;

  // Collect faces modes for shape collisions
  JPH_CollectFacesMode_CollectFaces = 0;
  JPH_CollectFacesMode_NoFaces = 1;

  // Motor states for constraints
  JPH_MotorState_Off = 0;
  JPH_MotorState_Velocity = 1;
  JPH_MotorState_Position = 2;

  // Collision collector types
  JPH_CollisionCollectorType_AllHit = 0;
  JPH_CollisionCollectorType_AllHitSorted = 1;
  JPH_CollisionCollectorType_ClosestHit = 2;
  JPH_CollisionCollectorType_AnyHit = 3;

  // Swing types for constraints
  JPH_SwingType_Cone = 0;
  JPH_SwingType_Pyramid = 1;

  // Constraint types
  JPH_ConstraintType_Constraint = 0;
  JPH_ConstraintType_TwoBodyConstraint = 1;

  // Constraint sub-types
  JPH_ConstraintSubType_Fixed = 0;
  JPH_ConstraintSubType_Point = 1;
  JPH_ConstraintSubType_Hinge = 2;
  JPH_ConstraintSubType_Slider = 3;
  JPH_ConstraintSubType_Distance = 4;
  JPH_ConstraintSubType_Cone = 5;
  JPH_ConstraintSubType_SwingTwist = 6;
  JPH_ConstraintSubType_SixDOF = 7;
  JPH_ConstraintSubType_Path = 8;
  JPH_ConstraintSubType_Vehicle = 9;
  JPH_ConstraintSubType_RackAndPinion = 10;
  JPH_ConstraintSubType_Gear = 11;
  JPH_ConstraintSubType_Pulley = 12;
  JPH_ConstraintSubType_User1 = 13;
  JPH_ConstraintSubType_User2 = 14;
  JPH_ConstraintSubType_User3 = 15;
  JPH_ConstraintSubType_User4 = 16;

  // Constraint spaces
  JPH_ConstraintSpace_LocalToBodyCOM = 0;
  JPH_ConstraintSpace_WorldSpace = 1;

  // Spring modes: Frequency/Damping or Stiffness/Damping
  JPH_SpringMode_FrequencyAndDamping = 0;
  JPH_SpringMode_StiffnessAndDamping = 1;

  // Transmission modes for vehicles
  JPH_TransmissionMode_Auto = 0;
  JPH_TransmissionMode_Manual = 1;

  // 6DOF constraint axes
  JPH_SixDOFConstraintAxis_TranslationX = 0;
  JPH_SixDOFConstraintAxis_TranslationY = 1;
  JPH_SixDOFConstraintAxis_TranslationZ = 2;
  JPH_SixDOFConstraintAxis_RotationX = 3;
  JPH_SixDOFConstraintAxis_RotationY = 4;
  JPH_SixDOFConstraintAxis_RotationZ = 5;
  JPH_SixDOFConstraintAxis_Num = 6;
  JPH_SixDOFConstraintAxis_NumTranslation = 3;

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

  // Result of a shape-vs-shape collision query.
  PJPH_CollideShapeResult = ^JPH_CollideShapeResult;

  JPH_CollideShapeResult = record
    contactPointOn1: JPH_Vec3;
    contactPointOn2: JPH_Vec3;
    penetrationAxis: JPH_Vec3;
    penetrationDepth: Single;
    subShapeID1: JPH_SubShapeID;
    subShapeID2: JPH_SubShapeID;
    bodyID2: JPH_BodyID;
    shape1FaceCount: UInt32;
    shape1Faces: PJPH_Vec3;
    shape2FaceCount: UInt32;
    shape2Faces: PJPH_Vec3;
  end;

  // Result of a shape cast (sweep test).
  PJPH_ShapeCastResult = ^JPH_ShapeCastResult;

  JPH_ShapeCastResult = record
    contactPointOn1: JPH_Vec3;
    contactPointOn2: JPH_Vec3;
    penetrationAxis: JPH_Vec3;
    penetrationDepth: Single;
    subShapeID1: JPH_SubShapeID;
    subShapeID2: JPH_SubShapeID;
    bodyID2: JPH_BodyID;
    fraction: Single;
    isBackFaceHit: JPH_Bool;
  end;

  // Base settings for shape collision queries.
  PJPH_CollideSettingsBase = ^JPH_CollideSettingsBase;

  JPH_CollideSettingsBase = record
    activeEdgeMode: JPH_ActiveEdgeMode;
    collectFacesMode: JPH_CollectFacesMode;
    collisionTolerance: Single;
    penetrationTolerance: Single;
    activeEdgeMovementDirection: JPH_Vec3;
  end;

  // Settings for shape collision queries.
  PJPH_CollideShapeSettings = ^JPH_CollideShapeSettings;

  JPH_CollideShapeSettings = record
    base: JPH_CollideSettingsBase;
    maxSeparationDistance: Single;
    backFaceMode: JPH_BackFaceMode;
  end;

  // Settings for shape casting (sweep tests).
  PJPH_ShapeCastSettings = ^JPH_ShapeCastSettings;

  JPH_ShapeCastSettings = record
    base: JPH_CollideSettingsBase;
    backFaceModeTriangles: JPH_BackFaceMode;
    backFaceModeConvex: JPH_BackFaceMode;
    useShrunkenShapeAndConvexRadius: JPH_Bool;
    returnDeepestPoint: JPH_Bool;
  end;

  // Settings for ray casts.
  PJPH_RayCastSettings = ^JPH_RayCastSettings;

  JPH_RayCastSettings = record
    backFaceModeTriangles: JPH_BackFaceMode;
    backFaceModeConvex: JPH_BackFaceMode;
    treatConvexAsSolid: JPH_Bool;
  end;

  // Base settings for all constraints.
  PJPH_ConstraintSettings = ^JPH_ConstraintSettings;

  JPH_ConstraintSettings = record
    enabled: JPH_Bool;
    constraintPriority: UInt32;
    numVelocityStepsOverride: UInt32;
    numPositionStepsOverride: UInt32;
    drawConstraintSize: Single;
    userData: UInt64;
  end;

  // Settings for a fixed constraint (welds two bodies together).
  PJPH_FixedConstraintSettings = ^JPH_FixedConstraintSettings;

  JPH_FixedConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    autoDetectPoint: JPH_Bool;
    point1: JPH_RVec3;
    axisX1: JPH_Vec3;
    axisY1: JPH_Vec3;
    point2: JPH_RVec3;
    axisX2: JPH_Vec3;
    axisY2: JPH_Vec3;
  end;

  // Settings for a point constraint (ball joint).
  PJPH_PointConstraintSettings = ^JPH_PointConstraintSettings;

  JPH_PointConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    point1: JPH_RVec3;
    point2: JPH_RVec3;
  end;

  // Settings for a distance constraint (keeps bodies at a fixed distance).
  PJPH_DistanceConstraintSettings = ^JPH_DistanceConstraintSettings;

  JPH_DistanceConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    point1: JPH_RVec3;
    point2: JPH_RVec3;
    minDistance: Single;
    maxDistance: Single;
    limitsSpringSettings: JPH_SpringSettings;
  end;

  // Settings for a hinge constraint (door joint).
  PJPH_HingeConstraintSettings = ^JPH_HingeConstraintSettings;

  JPH_HingeConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    point1: JPH_RVec3;
    hingeAxis1: JPH_Vec3;
    normalAxis1: JPH_Vec3;
    point2: JPH_RVec3;
    hingeAxis2: JPH_Vec3;
    normalAxis2: JPH_Vec3;
    limitsMin: Single;
    limitsMax: Single;
    limitsSpringSettings: JPH_SpringSettings;
    maxFrictionTorque: Single;
    motorSettings: JPH_MotorSettings;
  end;

  // Settings for a slider constraint (prismatic joint).
  PJPH_SliderConstraintSettings = ^JPH_SliderConstraintSettings;

  JPH_SliderConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    autoDetectPoint: JPH_Bool;
    point1: JPH_RVec3;
    sliderAxis1: JPH_Vec3;
    normalAxis1: JPH_Vec3;
    point2: JPH_RVec3;
    sliderAxis2: JPH_Vec3;
    normalAxis2: JPH_Vec3;
    limitsMin: Single;
    limitsMax: Single;
    limitsSpringSettings: JPH_SpringSettings;
    maxFrictionForce: Single;
    motorSettings: JPH_MotorSettings;
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

  // Contact listener callbacks for collision events.
  PJPH_ContactListener_Procs = ^JPH_ContactListener_Procs;

  JPH_ContactListener_Procs = record
    OnContactValidate: Pointer;
    OnContactAdded: Pointer;
    OnContactPersisted: Pointer;
    OnContactRemoved: Pointer;
  end;

  // Body activation listener callbacks for sleeping/waking events.
  PJPH_BodyActivationListener_Procs = ^JPH_BodyActivationListener_Procs;

  JPH_BodyActivationListener_Procs = record
    OnBodyActivated: Pointer;
    OnBodyDeactivated: Pointer;
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

procedure JPH_BroadPhaseLayerInterfaceMask_ConfigureLayer(bpInterface: JPH_BroadPhaseLayerInterface; broadPhaseLayer: JPH_BroadPhaseLayer; groupsToInclude: UInt32; groupsToExclude: UInt32); cdecl; external JOLT_LIB;

  // -- ObjectLayerPairFilter (mask-based default implementation) ---------------

function JPH_ObjectLayerPairFilterMask_Create: JPH_ObjectLayerPairFilter; cdecl; external JOLT_LIB;

procedure JPH_ObjectLayerPairFilter_Destroy(filter: JPH_ObjectLayerPairFilter); cdecl; external JOLT_LIB;

  // Helper to build an ObjectLayer value from a (group, mask) pair.
function JPH_ObjectLayerPairFilterMask_GetObjectLayer(group: UInt32; mask: UInt32): JPH_ObjectLayer; cdecl; external JOLT_LIB;

function JPH_ObjectLayerPairFilterMask_GetGroup(layer: JPH_ObjectLayer): UInt32; cdecl; external JOLT_LIB;

function JPH_ObjectLayerPairFilterMask_GetMask(layer: JPH_ObjectLayer): UInt32; cdecl; external JOLT_LIB;

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

  // -- Contact & Activation Listeners ------------------------------------------

function JPH_ContactListener_Create(userData: Pointer; procs: PJPH_ContactListener_Procs): JPH_ContactListener; cdecl; external JOLT_LIB;

procedure JPH_ContactListener_Destroy(listener: JPH_ContactListener); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetContactListener(system: JPH_PhysicsSystem; listener: JPH_ContactListener); cdecl; external JOLT_LIB;

function JPH_BodyActivationListener_Create(userData: Pointer; procs: PJPH_BodyActivationListener_Procs): JPH_BodyActivationListener; cdecl; external JOLT_LIB;

procedure JPH_BodyActivationListener_Destroy(listener: JPH_BodyActivationListener); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetBodyActivationListener(system: JPH_PhysicsSystem; listener: JPH_BodyActivationListener); cdecl; external JOLT_LIB;

  // -- PhysicsSystem -----------------------------------------------------------

function JPH_PhysicsSystem_Create(settings: PJPH_PhysicsSystemSettings): JPH_PhysicsSystem; cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_Destroy(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetPhysicsSettings(system: JPH_PhysicsSystem; settings: PJPH_PhysicsSettings); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_GetPhysicsSettings(system: JPH_PhysicsSystem; settings: PJPH_PhysicsSettings); cdecl; external JOLT_LIB;

  // Rebuilds the broad-phase structures. Call after adding/removing many bodies.
procedure JPH_PhysicsSystem_OptimizeBroadPhase(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

  // Advance the simulation by deltaTime seconds.
function JPH_PhysicsSystem_Update(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Int32; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_Update2(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Int32; tempAllocator: JPH_TempAllocator; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetGravity(system: JPH_PhysicsSystem; value: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_GetGravity(system: JPH_PhysicsSystem; result: PJPH_Vec3); cdecl; external JOLT_LIB;

  // Returns the non-locking body interface.
function JPH_PhysicsSystem_GetBodyInterface(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_GetBodyInterfaceNoLock(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_GetNarrowPhaseQuery(system: JPH_PhysicsSystem): JPH_NarrowPhaseQuery; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_GetNumBodies(system: JPH_PhysicsSystem): UInt32; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_GetMaxBodies(system: JPH_PhysicsSystem): UInt32; cdecl; external JOLT_LIB;

function JPH_PhysicsSystem_WereBodiesInContact(system: JPH_PhysicsSystem; body1: JPH_BodyID; body2: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;

  // -- JobSystem / TempAllocator ------------------------------------------------

function JPH_JobSystemThreadPool_Create(config: PJobSystemThreadPoolConfig): JPH_JobSystem; cdecl; external JOLT_LIB;

procedure JPH_JobSystem_Destroy(jobSystem: JPH_JobSystem); cdecl; external JOLT_LIB;

  // Uses malloc internally.
function JPH_TempAllocator_Create(size: UInt32): JPH_TempAllocator; cdecl; external JOLT_LIB;

function JPH_TempAllocatorMalloc_Create: JPH_TempAllocator; cdecl; external JOLT_LIB;

procedure JPH_TempAllocator_Destroy(allocator: JPH_TempAllocator); cdecl; external JOLT_LIB;

  // -- Body creation & Transforms ----------------------------------------------
  // Create3 builds a JPH_BodyCreationSettings from a shape, transform and motion type.

function JPH_BodyCreationSettings_Create3(shape: JPH_Shape; position: PJPH_RVec3; rotation: PJPH_Quat; motionType: JPH_MotionType; objectLayer: JPH_ObjectLayer): JPH_BodyCreationSettings; cdecl; external JOLT_LIB;

procedure JPH_BodyCreationSettings_Destroy(settings: JPH_BodyCreationSettings); cdecl; external JOLT_LIB;

  // Returns the BodyID of the newly added body.
function JPH_BodyInterface_CreateAndAddBody(bodyInterface: JPH_BodyInterface; settings: JPH_BodyCreationSettings; activationMode: JPH_Activation): JPH_BodyID; cdecl; external JOLT_LIB;
  // Removes the body from the world and destroys the underlying body object.

procedure JPH_BodyInterface_RemoveAndDestroyBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;
  // Removes the body from the world but does not destroy it.

procedure JPH_BodyInterface_RemoveBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

function JPH_BodyInterface_IsAdded(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RVec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_Quat); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetPositionAndRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetPositionAndRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; rotation: PJPH_Quat); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetCenterOfMassPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetWorldTransform(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RMat44); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetCenterOfMassTransform(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RMat44); cdecl; external JOLT_LIB;

  // -- Body Velocity & Forces --------------------------------------------------

procedure JPH_BodyInterface_SetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetLinearAndAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3; angularVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_GetLinearAndAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3; angularVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;

  //  AddImpulse: optional world-space position; if nil, applies at the center of mass.
  //  AddForce:   continuous force, applied during the next simulation step only.
procedure JPH_BodyInterface_AddImpulse(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; impulse: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddImpulse2(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; impulse: PJPH_Vec3; point: PJPH_RVec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddAngularImpulse(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; angularImpulse: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddForce(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; force: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddForce2(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; force: PJPH_Vec3; point: PJPH_RVec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_AddTorque(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; torque: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_ActivateBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_DeactivateBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

function JPH_BodyInterface_IsActive(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;

  // -- Body Properties ---------------------------------------------------------

procedure JPH_BodyInterface_SetMotionType(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; motionType: JPH_MotionType; activationMode: JPH_Activation); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetMotionType(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_MotionType; cdecl; external JOLT_LIB;

  // Set motion quality (Discrete or LinearCast). LinearCast prevents fast moving objects from tunneling through walls.
procedure JPH_BodyInterface_SetMotionQuality(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; quality: JPH_MotionQuality); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetMotionQuality(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_MotionQuality; cdecl; external JOLT_LIB;

  // -- Surface properties -------------------------------------------------------

procedure JPH_BodyInterface_SetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; friction: Single); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; restitution: Single); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;

  // -- Object Layer & User Data ------------------------------------------------

procedure JPH_BodyInterface_SetObjectLayer(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; layer: JPH_ObjectLayer); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetObjectLayer(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_ObjectLayer; cdecl; external JOLT_LIB;

procedure JPH_BodyInterface_SetUserData(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; userData: UInt64); cdecl; external JOLT_LIB;

function JPH_BodyInterface_GetUserData(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): UInt64; cdecl; external JOLT_LIB;

  // -- Ray casting & Collisions ------------------------------------------------
  //  Casts a ray from `origin` in `direction` (not necessarily normalized).
  //  Returns 1 if a hit was found and writes the result to `hit`, otherwise 0.

function JPH_NarrowPhaseQuery_CastRay(query: JPH_NarrowPhaseQuery; origin: PJPH_RVec3; direction: PJPH_Vec3; hit: PJPH_RayCastResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;

function JPH_NarrowPhaseQuery_CollidePoint(query: JPH_NarrowPhaseQuery; point: PJPH_RVec3; hit: PJPH_CollidePointResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;

  // -- Shape settings (builders for convex shapes) -----------------------------
  //  Each *ShapeSettings_Create returns a settings object. Call the corresponding
  //  *_CreateShape to obtain the actual JPH_Shape, then destroy the settings object.

function JPH_BoxShapeSettings_Create(halfExtent: PJPH_Vec3; convexRadius: Single): JPH_BoxShapeSettings; cdecl; external JOLT_LIB;

function JPH_SphereShapeSettings_Create(radius: Single): JPH_SphereShapeSettings; cdecl; external JOLT_LIB;

function JPH_CapsuleShapeSettings_Create(halfHeightOfCylinder: Single; radius: Single): JPH_CapsuleShapeSettings; cdecl; external JOLT_LIB;

function JPH_CylinderShapeSettings_Create(halfHeight: Single; radius: Single; convexRadius: Single): JPH_CylinderShapeSettings; cdecl; external JOLT_LIB;

function JPH_TaperedCapsuleShapeSettings_Create(halfHeightOfTaperedCylinder: Single; topRadius: Single; bottomRadius: Single): JPH_TaperedCapsuleShapeSettings; cdecl; external JOLT_LIB;

function JPH_TaperedCylinderShapeSettings_Create(halfHeightOfTaperedCylinder: Single; topRadius: Single; bottomRadius: Single; convexRadius: Single): JPH_TaperedCylinderShapeSettings; cdecl; external JOLT_LIB;

function JPH_ConvexHullShapeSettings_Create(points: PJPH_Vec3; pointsCount: UInt32; maxConvexRadius: Single): JPH_ConvexHullShapeSettings; cdecl; external JOLT_LIB;

function JPH_StaticCompoundShapeSettings_Create: JPH_StaticCompoundShapeSettings; cdecl; external JOLT_LIB;

function JPH_MeshShapeSettings_Create(triangles: PJPH_Triangle; triangleCount: UInt32): JPH_MeshShapeSettings; cdecl; external JOLT_LIB;

function JPH_BoxShapeSettings_CreateShape(settings: JPH_BoxShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_SphereShapeSettings_CreateShape(settings: JPH_SphereShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CapsuleShapeSettings_CreateShape(settings: JPH_CapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CylinderShapeSettings_CreateShape(settings: JPH_CylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_TaperedCapsuleShapeSettings_CreateShape(settings: JPH_TaperedCapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_TaperedCylinderShapeSettings_CreateShape(settings: JPH_TaperedCylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_ConvexHullShapeSettings_CreateShape(settings: JPH_ConvexHullShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_StaticCompoundShapeSettings_CreateShape(settings: JPH_StaticCompoundShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_MeshShapeSettings_CreateShape(settings: JPH_MeshShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

  // Adds a child shape to a compound shape settings object.
procedure JPH_CompoundShapeSettings_AddShape(settings: JPH_CompoundShapeSettings; position: PJPH_Vec3; rotation: PJPH_Quat; shapeSettings: JPH_ShapeSettings; userData: UInt32); cdecl; external JOLT_LIB;

procedure JPH_ShapeSettings_Destroy(settings: JPH_ShapeSettings); cdecl; external JOLT_LIB;

procedure JPH_Shape_Destroy(shape: JPH_Shape); cdecl; external JOLT_LIB;

  // -- Constraints -------------------------------------------------------------
  //  Create joints between bodies. Settings must be initialized before creation.

procedure JPH_FixedConstraintSettings_Init(settings: PJPH_FixedConstraintSettings); cdecl; external JOLT_LIB;

function JPH_FixedConstraint_Create(settings: PJPH_FixedConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_FixedConstraint; cdecl; external JOLT_LIB;

procedure JPH_PointConstraintSettings_Init(settings: PJPH_PointConstraintSettings); cdecl; external JOLT_LIB;

function JPH_PointConstraint_Create(settings: PJPH_PointConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_PointConstraint; cdecl; external JOLT_LIB;

procedure JPH_DistanceConstraintSettings_Init(settings: PJPH_DistanceConstraintSettings); cdecl; external JOLT_LIB;

function JPH_DistanceConstraint_Create(settings: PJPH_DistanceConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_DistanceConstraint; cdecl; external JOLT_LIB;

procedure JPH_HingeConstraintSettings_Init(settings: PJPH_HingeConstraintSettings); cdecl; external JOLT_LIB;

function JPH_HingeConstraint_Create(settings: PJPH_HingeConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_HingeConstraint; cdecl; external JOLT_LIB;

procedure JPH_HingeConstraint_SetTargetAngularVelocity(constraint: JPH_HingeConstraint; angularVelocity: Single); cdecl; external JOLT_LIB;

procedure JPH_HingeConstraint_SetTargetAngle(constraint: JPH_HingeConstraint; angle: Single); cdecl; external JOLT_LIB;

procedure JPH_HingeConstraint_SetMotorState(constraint: JPH_HingeConstraint; state: JPH_MotorState); cdecl; external JOLT_LIB;

procedure JPH_SliderConstraintSettings_Init(settings: PJPH_SliderConstraintSettings); cdecl; external JOLT_LIB;

function JPH_SliderConstraint_Create(settings: PJPH_SliderConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_SliderConstraint; cdecl; external JOLT_LIB;

procedure JPH_Constraint_Destroy(constraint: JPH_Constraint); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_AddConstraint(system: JPH_PhysicsSystem; constraint: JPH_Constraint); cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_RemoveConstraint(system: JPH_PhysicsSystem; constraint: JPH_Constraint); cdecl; external JOLT_LIB;

  // -- Math Helpers ------------------------------------------------------------
  //  Utility functions provided by the C API for vector and matrix math.

procedure JPH_Vec3_Normalize(v: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;

function JPH_Vec3_Length(v: PJPH_Vec3): Single; cdecl; external JOLT_LIB;

function JPH_Vec3_LengthSquared(v: PJPH_Vec3): Single; cdecl; external JOLT_LIB;

procedure JPH_Vec3_Cross(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_Vec3_DotProduct(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PSingle); cdecl; external JOLT_LIB;

procedure JPH_Quat_Multiply(q1: PJPH_Quat; q2: PJPH_Quat; result: PJPH_Quat); cdecl; external JOLT_LIB;

procedure JPH_Quat_Rotate(quat: PJPH_Quat; vec: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;

procedure JPH_Quat_Inversed(quat: PJPH_Quat; result: PJPH_Quat); cdecl; external JOLT_LIB;

procedure JPH_Mat44_Identity(result: PJPH_Mat44); cdecl; external JOLT_LIB;

procedure JPH_Mat44_RotationTranslation(result: PJPH_Mat44; rotation: PJPH_Quat; translation: PJPH_Vec3); cdecl; external JOLT_LIB;

  // -- Materials ---------------------------------------------------------------
  //  Custom materials can be assigned to shape sub-parts for per-face friction/restitution.

function JPH_PhysicsMaterial_Create(name: PAnsiChar; color: UInt32): JPH_PhysicsMaterial; cdecl; external JOLT_LIB;

procedure JPH_PhysicsMaterial_Destroy(material: JPH_PhysicsMaterial); cdecl; external JOLT_LIB;

implementation

end.


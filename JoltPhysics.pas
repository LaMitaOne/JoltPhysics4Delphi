unit JoltPhysics;

{==============================================================================*
 *  JoltPhysics v0.60 - Delphi Wrapper for Jolt Physics C API
 *------------------------------------------------------------------------------
    Author:  Lara Miriam Tamy Reschke / LamitaOne
 *  Description:
 *    This unit provides Delphi bindings for the Jolt Physics C API (JoltC.dll).
 *    Jolt Physics is a fast, multi-threaded physics engine originally written
 *    in C++ by Jorrit Rouwe. The C API allows usage from other languages.
 *
 *  IMPORTANT NOTE FOR GITHUB USERS:
 *    This is the FIRST EVER Delphi wrapper for Jolt Physics!
 *    It allows Delphi developers to use this high-performance physics engine
 *    natively via the C API. Please report any issues or contribute!
 *
 *  Status:
 *    This wrapper is a work-in-progress. The core functionality (world setup,
 *    body creation, shape creation, ray casting, transforms, forces/impulses)
 *    is implemented and usable. Advanced features (constraints, characters,
 *    math helpers, and contact listeners) have been added.
 *    Complex features (like vehicles, ragdolls, and soft bodies) are now
 *    partially integrated.
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
  v0.6:
     Implemented Advanced Collision Queries (CastShape/CollideShape) and Sweep tests.
     Added full Ragdoll/Skeleton configuration (joint mapping, group filters, activation).
     Exposed Soft Body creation APIs (adding vertices/edges, SoftBodyCreationSettings).
     Expanded Vehicle system (engines, transmissions, tracks, anti-roll bars, driver inputs).
     Added remaining constraints (Cone, SwingTwist, SixDOF, Gear).
     Implemented Table-based BroadPhase/Layer filters and Collision Group management.
     Extended Body Interface (MoveKinematic, PointVelocity, InverseInertia).
     Added PhysicsStepListener vtables and expanded Debug Renderer bindings (DrawSettings).
  v0.5:
     Added missing handles, records, and API calls for SoftBodies, Skeletons/Ragdolls,
     Vehicles, and advanced Debug Rendering.
     Extended constraints (Cone, SwingTwist, SixDOF, Gear).
     Extended character virtual implementation and contact listeners.
     Added table-based BroadPhase and GroupFilter implementations.
  v0.4:
     Added missing JPH_BodyInterface_GetShape JPH_BodyInterface_SetShape
  v0.3:
     Expanded Structs & Records: Added necessary records for advanced queries, including JPH_CollideShapeResult, JPH_ShapeCastResult, JPH_CollideShapeSettings, JPH_ShapeCastSettings, and JPH_RayCastSettings.
     Constraint System: Implemented base structs (JPH_ConstraintSettings) and specific settings for Fixed, Point, Distance, Hinge, and Slider constraints. Added corresponding API functions for creation, destruction, and control (e.g., JPH_HingeConstraint_SetMotorState).
     Complete Enum Constants: Added all missing enum values as constants (e.g., JPH_BodyType, JPH_ShapeSubType, JPH_AllowedDOFs, JPH_GroundState, JPH_MotorState, JPH_ConstraintSubType, etc.).
     Listeners & Callbacks: Added vtable structs and API functions for JPH_ContactListener (collision events) and JPH_BodyActivationListener (sleep/wake events).
     Extended Body Interface: Integrated many missing functions such as AddTorque, AddForce2 (with position parameter), AddAngularImpulse, combined getters/setters for velocities, and queries for Active-state, ObjectLayer, and UserData.
     Additional Shapes: Added settings and creation functions for TaperedCapsule, TaperedCylinder, ConvexHull, StaticCompound, and MeshShape. Also added JPH_CompoundShapeSettings_AddShape for grouping shapes.
     Math Helpers: Wrapped useful C-API math functions (JPH_Vec3_Cross, JPH_Vec3_Normalize, JPH_Quat_Rotate, JPH_Mat4_RotationTranslation, etc.).
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
  // JPH_SixDOFConstraintAxis_Num is already defined (6)
  JPH_M_PI = 3.14159265358979323846;
  // Color modes for visualizing soft body constraints (debug rendering)
  JPH_SoftBodyConstraintColor_ConstraintType = 0;
  JPH_SoftBodyConstraintColor_ConstraintGroup = 1;
  JPH_SoftBodyConstraintColor_ConstraintOrder = 2;
  // Types of bend constraints for soft bodies
  JPH_SoftBodyBendType_None = 0;
  JPH_SoftBodyBendType_Distance = 1;
  JPH_SoftBodyBendType_Dihedral = 2;
  // Color modes for body shapes in the debug renderer
  JPH_BodyManager_ShapeColor_InstanceColor = 0;
  JPH_BodyManager_ShapeColor_ShapeTypeColor = 1;
  JPH_BodyManager_ShapeColor_MotionTypeColor = 2;
  JPH_BodyManager_ShapeColor_SleepColor = 3;
  JPH_BodyManager_ShapeColor_IslandColor = 4;
  JPH_BodyManager_ShapeColor_MaterialColor = 5;
  // Debug renderer shadow modes
  JPH_DebugRenderer_CastShadow_On = 0;
  JPH_DebugRenderer_CastShadow_Off = 1;
  // Debug renderer draw modes (Solid vs Wireframe)
  JPH_DebugRenderer_DrawMode_Solid = 0;
  JPH_DebugRenderer_DrawMode_Wireframe = 1;
  // Build quality preference for Mesh Shapes (performance vs. build speed)
  JPH_Mesh_Shape_BuildQuality_FavorRuntimePerformance = 0;
  JPH_Mesh_Shape_BuildQuality_FavorBuildSpeed = 1;
  // Side of a vehicle track (left or right)
  JPH_TrackSide_Left = 0;
  JPH_TrackSide_Right = 1;

type
  // --- Primitive Types ---
  // 32-bit boolean (C _Bool / int) matching the C API standard.
  JPH_Bool = UInt32;
  // Unique identifier for a physics body in the world.
  JPH_BodyID = UInt32;
  // Identifies a sub-part of a compound shape (e.g., a specific child shape in a mesh).
  JPH_SubShapeID = UInt32;
  // User-defined collision layer (e.g., Player, Enemy, Wall) for filtering collisions.
  JPH_ObjectLayer = UInt32;
  // Broad-phase bucket a layer belongs to (coarser collision filtering).
  JPH_BroadPhaseLayer = Byte;
  // Collision group id (for grouping bodies that should collide/ignore each other).
  JPH_CollisionGroupID = UInt32;
  // Collision sub group id.
  JPH_CollisionSubGroupID = UInt32;
  // Unique identifier for a virtual character (Kinematic/Virtual Character Controller).
  JPH_CharacterID = UInt32;
  // Debug-rendering color represented as an unsigned 32-bit integer (0xRRGGBBAA).
  JPH_Color = UInt32;
  // --- Math Types (Records must match the C struct layout exactly) ---
  // 3D Vector (Single precision float)
  JPH_Vec3 = record
    x, y, z: Single;
  end;

  PJPH_Vec3 = ^JPH_Vec3;
  // 4D Vector (Single precision float)
  JPH_Vec4 = record
    x, y, z, w: Single;
  end;

  PJPH_Vec4 = ^JPH_Vec4;
  // Quaternion for 3D rotations
  JPH_Quat = record
    x, y, z, w: Single;
  end;

  PJPH_Quat = ^JPH_Quat;
  // Mathematical plane defined by a normal and distance
  JPH_Plane = record
    normal: JPH_Vec3;
    distance: Single;
  end;

  PJPH_Plane = ^JPH_Plane;
  // 4x4 Transformation Matrix (Single precision)
  JPH_Mat4 = record
    column: array[0..3] of JPH_Vec4;
  end;

  PJPH_Mat4 = ^JPH_Mat4;
  // Double-precision Vec3 - here aliased to single precision.
  // If you need real double-precision coordinates, enable the corresponding Jolt build.
  JPH_RVec3 = JPH_Vec3;

  PJPH_RVec3 = ^JPH_RVec3;
  // Double-precision Mat4 - aliased to single precision.
  JPH_RMat4 = JPH_Mat4;

  PJPH_RMat4 = ^JPH_RMat4;
  // 2D Point (Single precision)
  JPH_Point = record
    x, y: Single;
  end;

  PJPH_Point = ^JPH_Point;
  // Axis-Aligned Bounding Box (AABB)
  JPH_AABox = record
    min, max: JPH_Vec3;
  end;

  PJPH_AABox = ^JPH_AABox;
  // Basic triangle defined by 3 vertices and a material index
  JPH_Triangle = record
    v1, v2, v3: JPH_Vec3;
    materialIndex: UInt32;
  end;

  PJPH_Triangle = ^JPH_Triangle;
  // Indexed triangle (uses integer indices instead of full vertices)
  JPH_IndexedTriangle = record
    i1, i2, i3, materialIndex, userData: UInt32;
  end;

  PJPH_IndexedTriangle = ^JPH_IndexedTriangle;
  // Mass properties of a body (mass and inertia tensor matrix)
  JPH_MassProperties = record
    mass: Single;
    inertia: JPH_Mat4;
  end;

  PJPH_MassProperties = ^JPH_MassProperties;
  // --- Enums (Declared early so records can use them) ---
  // Result code returned by JPH_PhysicsSystem_Update2 (e.g., if caches are full).
  JPH_PhysicsUpdateError = type UInt32;
  // Type of a body: Rigid (solid) or Soft (deformable).
  JPH_BodyType = type UInt32;
  // Motion properties of a body: Static (never moves), Kinematic (moved by code), Dynamic (simulated by physics).
  JPH_MotionType = type UInt32;
  // Activation mode used when adding/moving bodies (Activate or DontActivate).
  JPH_Activation = type UInt32;
  // Validation result for body creation (used in contact listeners to accept/reject collisions).
  JPH_ValidateResult = type UInt32;
  // Shape type (Sphere, Box, Mesh, etc.).
  JPH_ShapeType = type UInt32;
  // Shape sub-type for more specific casting.
  JPH_ShapeSubType = type UInt32;
  // Quality of motion: Discrete (fast objects might tunnel) or LinearCast (prevents tunneling).
  JPH_MotionQuality = type UInt32;
  // How to handle mass properties when creating a body.
  JPH_OverrideMassProperties = type UInt32;
  // Degrees of freedom allowed for a body (e.g., restrict to 2D plane).
  JPH_AllowedDOFs = type UInt32;
  // State of a character's contact with the ground (OnGround, InAir, etc.).
  JPH_GroundState = type UInt32;
  // Whether to collide with back faces during ray/shape casting.
  JPH_BackFaceMode = type UInt32;
  // How to handle active edges in meshes (edges that should collide).
  JPH_ActiveEdgeMode = type UInt32;
  // Whether to collect faces during collision queries.
  JPH_CollectFacesMode = type UInt32;
  // State of a constraint motor (Off, Velocity, Position).
  JPH_MotorState = type UInt32;
  // Type of collision collector (Closest hit, All hits, etc.).
  JPH_CollisionCollectorType = type UInt32;
  // Type of swing constraint (Cone or Pyramid).
  JPH_SwingType = type UInt32;
  // Base type of a constraint.
  JPH_ConstraintType = type UInt32;
  // Sub-type of a constraint (Hinge, Slider, Point, etc.).
  JPH_ConstraintSubType = type UInt32;
  // Space in which a constraint operates (Local space or World space).
  JPH_ConstraintSpace = type UInt32;
  // Mode for spring settings (Frequency/Damping or Stiffness/Damping).
  JPH_SpringMode = type UInt32;
  // Mode for vehicle transmission (Auto or Manual).
  JPH_TransmissionMode = type UInt32;
  // Axis index for a 6DOF constraint (0-2 Translation, 3-5 Rotation).
  JPH_SixDOFConstraintAxis = type UInt32;
  // Additional Enums for Extended Features
  JPH_SoftBodyConstraintColor = type UInt32;

  JPH_SoftBodyBendType = type UInt32;

  JPH_BodyManager_ShapeColor = type UInt32;

  JPH_DebugRenderer_CastShadow = type UInt32;

  JPH_DebugRenderer_DrawMode = type UInt32;

  JPH_Mesh_Shape_BuildQuality = type UInt32;

  JPH_TrackSide = type UInt32;

const
  // 0 means no error, any combination of the bits below indicates a problem during update
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
  // Allowed Degrees of Freedom (bitflags) to restrict body movement
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
  // === OPAQUE HANDLES (Pointers) ===
  // These are declared as distinct types so the Delphi compiler can distinguish them.
  // They represent pointers to C++ objects managed entirely by the JoltC.dll.

  // BroadPhase / Layers
  JPH_BroadPhaseLayerInterface = type Pointer;

  JPH_ObjectVsBroadPhaseLayerFilter = type Pointer;

  JPH_ObjectLayerPairFilter = type Pointer;

  JPH_BroadPhaseLayerFilter = type Pointer;

  JPH_ObjectLayerFilter = type Pointer;

  JPH_BodyFilter = type Pointer;

  JPH_ShapeFilter = type Pointer;

  JPH_SimShapeFilter = type Pointer;

  JPH_PhysicsStepListener = type Pointer;
  // Core Systems
  JPH_PhysicsSystem = type Pointer;

  JPH_PhysicsMaterial = type Pointer;

  JPH_LinearCurve = type Pointer;
  // ShapeSettings (Used to construct shapes)
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
  // Shapes (Actual instances, usually reference-counted by the engine)
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
  // Bodies and Interfaces
  JPH_BodyCreationSettings = type Pointer;

  JPH_SoftBodyCreationSettings = type Pointer;

  JPH_SoftBodySharedSettings = type Pointer;

  JPH_BodyLockRead = type Pointer;

  JPH_BodyLockWrite = type Pointer;

  JPH_BodyLockMultiRead = type Pointer;

  JPH_BodyLockMultiWrite = type Pointer;

  JPH_BodyInterface = type Pointer;

  JPH_BodyLockInterface = type Pointer;

  JPH_BroadPhaseQuery = type Pointer;

  JPH_NarrowPhaseQuery = type Pointer;

  JPH_MotionProperties = type Pointer;

  JPH_Body = type Pointer;
  // Listeners & Filters
  JPH_ContactListener = type Pointer;

  JPH_ContactManifold = type Pointer;

  JPH_GroupFilter = type Pointer;

  JPH_GroupFilterTable = type Pointer;

  JPH_BodyActivationListener = type Pointer;

  JPH_BodyDrawFilter = type Pointer;

  JPH_SharedMutex = type Pointer;

  JPH_DebugRenderer = type Pointer;
  // Constraints (Joints between bodies)
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
  // Characters (Kinematic/Virtual Character Controllers)
  JPH_CharacterBase = type Pointer;

  JPH_Character = type Pointer;

  JPH_CharacterVirtual = type Pointer;

  JPH_CharacterContactListener = type Pointer;

  JPH_CharacterVsCharacterCollision = type Pointer;
  // Skeleton/Ragdoll (Bone hierarchies and joint limits)
  JPH_Skeleton = type Pointer;

  JPH_SkeletonPose = type Pointer;

  JPH_SkeletalAnimation = type Pointer;

  JPH_SkeletonMapper = type Pointer;

  JPH_RagdollSettings = type Pointer;

  JPH_Ragdoll = type Pointer;
  // Vehicles (Wheeled and Tracked vehicle physics)
  JPH_WheelSettings = type Pointer;

  JPH_WheelSettingsWV = type Pointer;

  JPH_WheelSettingsTV = type Pointer;

  JPH_Wheel = type Pointer;

  JPH_WheelWV = type Pointer;

  JPH_WheelTV = type Pointer;

  JPH_VehicleEngine = type Pointer;

  JPH_VehicleTransmission = type Pointer;

  JPH_VehicleTransmissionSettings = type Pointer;

  JPH_VehicleCollisionTester = type Pointer;

  JPH_VehicleCollisionTesterRay = type Pointer;

  JPH_VehicleCollisionTesterCastSphere = type Pointer;

  JPH_VehicleCollisionTesterCastCylinder = type Pointer;

  JPH_VehicleConstraint = type Pointer;

  JPH_VehicleControllerSettings = type Pointer;

  JPH_WheeledVehicleControllerSettings = type Pointer;

  JPH_MotorcycleControllerSettings = type Pointer;

  JPH_TrackedVehicleControllerSettings = type Pointer;

  JPH_WheeledVehicleController = type Pointer;

  JPH_MotorcycleController = type Pointer;

  JPH_TrackedVehicleController = type Pointer;

  JPH_VehicleController = type Pointer;

  JPH_VehicleTrack = type Pointer;

  JPH_VehicleTrackSettings = type Pointer;
  // Threading/Memory
  JPH_TempAllocator = type Pointer;

  JPH_JobSystem = type Pointer;
  // === RECORDS (Structs) ===
  // Settings passed to a contact listener to modify contact properties dynamically
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
    maxJobs: UInt32;
    maxBarriers: UInt32;
    numThreads: Int32;
  end;
  // Settings used to construct a JPH_PhysicsSystem instance (limits and interfaces).
  PJPH_PhysicsSystemSettings = ^JPH_PhysicsSystemSettings;

  JPH_PhysicsSystemSettings = record
    maxBodies: UInt32;
    numBodyMutexes: UInt32;
    maxBodyPairs: UInt32;
    maxContactConstraints: UInt32;
    _padding: UInt32;
    broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface;
    objectLayerPairFilter: JPH_ObjectLayerPairFilter;
    objectVsBroadPhaseLayerFilter: JPH_ObjectVsBroadPhaseLayerFilter;
  end;
  // General physics simulation settings (gravity, sleep, tolerances).
  PJPH_PhysicsSettings = ^JPH_PhysicsSettings;

  JPH_PhysicsSettings = record
    maxInFlightBodyPairs: Int32;
    stepListenersBatchSize: Int32;
    stepListenerBatchesPerJob: Int32;
    baumgarte: Single;             // Baumgarte stabilization factor (position correction)
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
    numVelocitySteps: UInt32;     // Solver iterations for velocity
    numPositionSteps: UInt32;     // Solver iterations for position
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
  // Collision group settings for a body (allows fine-grained group-based filtering)
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
  // Motor settings used by constraints (force limits and spring behavior)
  PJPH_MotorSettings = ^JPH_MotorSettings;

  JPH_MotorSettings = record
    springSettings: JPH_SpringSettings;
    minForceLimit, maxForceLimit, minTorqueLimit, maxTorqueLimit: Single;
  end;
  // Result of a successful ray cast.
  PJPH_RayCastResult = ^JPH_RayCastResult;

  JPH_RayCastResult = record
    bodyID: JPH_BodyID;
    fraction: Single;        // Distance from 0 to 1 along the ray
    subShapeID2: JPH_SubShapeID;
  end;
  // Result of a broad-phase cast (raycast or shape cast).
  PJPH_BroadPhaseCastResult = ^JPH_BroadPhaseCastResult;

  JPH_BroadPhaseCastResult = record
    bodyID: JPH_BodyID;
    fraction: Single;
  end;
  // Result of a point collision query (e.g. what is under the mouse cursor).
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
  // Result of a shape-vs-shape collision query (detailed contact info).
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
 // Advanced Collision Queries
  PJPH_CollideShapeResultPair = ^JPH_CollideShapeResultPair; // Helper for array of results
  JPH_CollideShapeResultPair = record
    results: PJPH_CollideShapeResult;
    count: UInt32;
  end;
  // Ragdoll Settings Configuration
  PJPH_RagdollSubPartSettings = ^JPH_RagdollSubPartSettings;
  JPH_RagdollSubPartSettings = record
    toParent: JPH_RMat4;
    constraintSettings: JPH_ConstraintSettings; // Base, can be Hinge, SwingTwist, etc.
  end;
  // Soft Body Configuration
  PJPH_SoftBodySharedSettingsVertex = ^JPH_SoftBodySharedSettingsVertex;
  JPH_SoftBodySharedSettingsVertex = record
    position: JPH_Vec3;
    velocity: JPH_Vec3;
    invMass: Single;
  end;
  PJPH_SoftBodySharedSettingsEdge = ^JPH_SoftBodySharedSettingsEdge;
  JPH_SoftBodySharedSettingsEdge = record
    vertex1: UInt32;
    vertex2: UInt32;
    restLength: Single;
  end;
  PJPH_SoftBodyCreationSettingsRecord = ^JPH_SoftBodyCreationSettingsRecord;
  JPH_SoftBodyCreationSettingsRecord = record
    settings: JPH_SoftBodySharedSettings;
    position: JPH_RVec3;
    rotation: JPH_Quat;
    objectLayer: JPH_ObjectLayer;
    userData: UInt64;
    motionType: JPH_MotionType;
    allowedDOFs: JPH_AllowedDOFs;
    collisionGroup: JPH_CollisionGroup;
  end;
  // Extended Records (SoftBody, Characters, Vehicles, etc.)
  PJPH_SoftVertex = ^JPH_SoftVertex;

  JPH_SoftVertex = record
    position: JPH_Vec3;
    velocity: JPH_Vec3;
    invMass: Single;
  end;

  PJPH_SoftFace = ^JPH_SoftFace;

  JPH_SoftFace = record
    vertex1: UInt32;
    vertex2: UInt32;
    vertex3: UInt32;
    materialIndex: UInt32;
  end;

  PJPH_SupportingFace = ^JPH_SupportingFace;

  JPH_SupportingFace = record
    count: UInt32;
    vertices: array[0..31] of JPH_Vec3;
  end;

  PJPH_CollisionEstimationResult = ^JPH_CollisionEstimationResult;

  JPH_CollisionEstimationResult = record
    linearVelocity1: JPH_Vec3;
    angularVelocity1: JPH_Vec3;
    linearVelocity2: JPH_Vec3;
    angularVelocity2: JPH_Vec3;
    frictionPoint: JPH_Vec3;
    tangent1: JPH_Vec3;
    tangent2: JPH_Vec3;
    frictionImpulse1: Single;
    frictionImpulse2: Single;
    angularFrictionImpulse: Single;
    contactImpulseCount: UInt32;
    contactImpulses: PSingle;
  end;

  PJPH_PhysicsStepListenerContext = ^JPH_PhysicsStepListenerContext;

  JPH_PhysicsStepListenerContext = record
    deltaTime: Single;
    isFirstStep: JPH_Bool;
    isLastStep: JPH_Bool;
    physicsSystem: JPH_PhysicsSystem;
  end;
  // Settings for character stair walking and floor sticking
  PJPH_ExtendedUpdateSettings = ^JPH_ExtendedUpdateSettings;

  JPH_ExtendedUpdateSettings = record
    stickToFloorStepDown: JPH_Vec3;
    walkStairsStepUp: JPH_Vec3;
    walkStairsMinStepForward: Single;
    walkStairsStepForwardTest: Single;
    walkStairsCosAngleForwardContact: Single;
    walkStairsStepDownExtra: JPH_Vec3;
  end;
  // Base settings for Characters (virtual and rigid)
  PJPH_CharacterBaseSettings = ^JPH_CharacterBaseSettings;

  JPH_CharacterBaseSettings = record
    up: JPH_Vec3;
    supportingVolume: JPH_Plane;
    maxSlopeAngle: Single;
    enhancedInternalEdgeRemoval: JPH_Bool;
    shape: JPH_Shape;
  end;

  PJPH_CharacterSettings = ^JPH_CharacterSettings;

  JPH_CharacterSettings = record
    base: JPH_CharacterBaseSettings;
    layer: JPH_ObjectLayer;
    mass: Single;
    friction: Single;
    gravityFactor: Single;
    allowedDOFs: JPH_AllowedDOFs;
  end;

  PJPH_CharacterVirtualSettings = ^JPH_CharacterVirtualSettings;

  JPH_CharacterVirtualSettings = record
    base: JPH_CharacterBaseSettings;
    ID: JPH_CharacterID;
    mass: Single;
    maxStrength: Single;
    shapeOffset: JPH_Vec3;
    backFaceMode: JPH_BackFaceMode;
    predictiveContactDistance: Single;
    maxCollisionIterations: UInt32;
    maxConstraintIterations: UInt32;
    minTimeRemaining: Single;
    collisionTolerance: Single;
    characterPadding: Single;
    maxNumHits: UInt32;
    hitReductionCosMaxAngle: Single;
    penetrationRecoverySpeed: Single;
    innerBodyShape: JPH_Shape;
    innerBodyIDOverride: JPH_BodyID;
    innerBodyLayer: JPH_ObjectLayer;
  end;

  PJPH_CharacterContactSettings = ^JPH_CharacterContactSettings;

  JPH_CharacterContactSettings = record
    canPushCharacter: JPH_Bool;
    canReceiveImpulses: JPH_Bool;
  end;
  // Contact info specifically for Character controllers
  PJPH_CharacterContact = ^JPH_CharacterContact;

  JPH_CharacterContact = record
    hash: UInt64;
    bodyB: JPH_BodyID;
    characterIDB: JPH_CharacterID;
    subShapeIDB: JPH_SubShapeID;
    position: JPH_RVec3;
    linearVelocity: JPH_Vec3;
    contactNormal: JPH_Vec3;
    surfaceNormal: JPH_Vec3;
    distance: Single;
    fraction: Single;
    motionTypeB: JPH_MotionType;
    isSensorB: JPH_Bool;
    characterB: JPH_CharacterVirtual;
    userData: UInt64;
    material: JPH_PhysicsMaterial;
    hadCollision: JPH_Bool;
    wasDiscarded: JPH_Bool;
    canPushCharacter: JPH_Bool;
    isBackFacingContact: JPH_Bool;
  end;
  // Debug rendering draw settings
  PJPH_DrawSettings = ^JPH_DrawSettings;

  JPH_DrawSettings = record
    drawGetSupportFunction: JPH_Bool;
    drawSupportDirection: JPH_Bool;
    drawGetSupportingFace: JPH_Bool;
    drawShape: JPH_Bool;
    drawShapeWireframe: JPH_Bool;
    drawShapeColor: JPH_BodyManager_ShapeColor;
    drawBoundingBox: JPH_Bool;
    drawCenterOfMassTransform: JPH_Bool;
    drawWorldTransform: JPH_Bool;
    drawVelocity: JPH_Bool;
    drawMassAndInertia: JPH_Bool;
    drawSleepStats: JPH_Bool;
    drawSoftBodyVertices: JPH_Bool;
    drawSoftBodyVertexVelocities: JPH_Bool;
    drawSoftBodyEdgeConstraints: JPH_Bool;
    drawSoftBodyBendConstraints: JPH_Bool;
    drawSoftBodyVolumeConstraints: JPH_Bool;
    drawSoftBodySkinConstraints: JPH_Bool;
    drawSoftBodyLRAConstraints: JPH_Bool;
    drawSoftBodyPredictedBounds: JPH_Bool;
    drawSoftBodyConstraintColor: JPH_SoftBodyConstraintColor;
  end;
  // Cone Constraint Settings (Limits rotation to a cone shape)
  PJPH_ConeConstraintSettings = ^JPH_ConeConstraintSettings;

  JPH_ConeConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    point1: JPH_RVec3;
    twistAxis1: JPH_Vec3;
    point2: JPH_RVec3;
    twistAxis2: JPH_Vec3;
    halfConeAngle: Single;
  end;
  // SwingTwist Constraint Settings (Common for character ragdoll shoulders/hips)
  PJPH_SwingTwistConstraintSettings = ^JPH_SwingTwistConstraintSettings;

  JPH_SwingTwistConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    position1: JPH_RVec3;
    twistAxis1: JPH_Vec3;
    planeAxis1: JPH_Vec3;
    position2: JPH_RVec3;
    twistAxis2: JPH_Vec3;
    planeAxis2: JPH_Vec3;
    swingType: JPH_SwingType;
    normalHalfConeAngle: Single;
    planeHalfConeAngle: Single;
    twistMinAngle: Single;
    twistMaxAngle: Single;
    maxFrictionTorque: Single;
    swingMotorSettings: JPH_MotorSettings;
    twistMotorSettings: JPH_MotorSettings;
  end;
  // 6 Degrees of Freedom Constraint Settings
  PJPH_SixDOFConstraintSettings = ^JPH_SixDOFConstraintSettings;

  JPH_SixDOFConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    position1: JPH_RVec3;
    axisX1: JPH_Vec3;
    axisY1: JPH_Vec3;
    position2: JPH_RVec3;
    axisX2: JPH_Vec3;
    axisY2: JPH_Vec3;
    maxFriction: array[0..5] of Single;
    swingType: JPH_SwingType;
    limitMin: array[0..5] of Single;
    limitMax: array[0..5] of Single;
    limitsSpringSettings: array[0..2] of JPH_SpringSettings;
    motorSettings: array[0..5] of JPH_MotorSettings;
  end;
  // Gear Constraint Settings (Links rotation of two bodies like a gear)
  PJPH_GearConstraintSettings = ^JPH_GearConstraintSettings;

  JPH_GearConstraintSettings = record
    base: JPH_ConstraintSettings;
    space: JPH_ConstraintSpace;
    hingeAxis1: JPH_Vec3;
    hingeAxis2: JPH_Vec3;
    ratio: Single;
  end;
  // Skeleton Joint definition
  PJPH_SkeletonJoint = ^JPH_SkeletonJoint;

  JPH_SkeletonJoint = record
    name: PAnsiChar;
    parentName: PAnsiChar;
    parentJointIndex: Int32;
  end;
  // Vehicle anti-roll bar settings
  PJPH_VehicleAntiRollBar = ^JPH_VehicleAntiRollBar;

  JPH_VehicleAntiRollBar = record
    leftWheel: Int32;
    rightWheel: Int32;
    stiffness: Single;
  end;
  // Vehicle Constraint Settings
  PJPH_VehicleConstraintSettings = ^JPH_VehicleConstraintSettings;

  JPH_VehicleConstraintSettings = record
    base: JPH_ConstraintSettings;
    up: JPH_Vec3;
    forward: JPH_Vec3;
    maxPitchRollAngle: Single;
    wheelsCount: UInt32;
    wheels: array of JPH_WheelSettings;
    antiRollBarsCount: UInt32;
    antiRollBars: PJPH_VehicleAntiRollBar;
    controller: JPH_VehicleControllerSettings;
  end;
  // Vehicle Engine Settings
  PJPH_VehicleEngineSettings = ^JPH_VehicleEngineSettings;

  JPH_VehicleEngineSettings = record
    maxTorque: Single;
    minRPM: Single;
    maxRPM: Single;
    normalizedTorque: JPH_LinearCurve;
    inertia: Single;
    angularDamping: Single;
  end;
  // Vehicle Differential Settings
  PJPH_VehicleDifferentialSettings = ^JPH_VehicleDifferentialSettings;

  JPH_VehicleDifferentialSettings = record
    leftWheel: Int32;
    rightWheel: Int32;
    differentialRatio: Single;
    leftRightSplit: Single;
    limitedSlipRatio: Single;
    engineTorqueRatio: Single;
  end;
  // Vehicle Track Settings (for tracked vehicles like tanks)
  PJPH_VehicleTrackSettingsRecord = ^JPH_VehicleTrackSettingsRecord;

  JPH_VehicleTrackSettingsRecord = record
    drivenWheel: UInt32;
    wheels: PUInt32;
    wheelsCount: UInt32;
    inertia: Single;
    angularDamping: Single;
    maxBrakeTorque: Single;
    differentialRatio: Single;
  end;
  // ---------------------------------------------------------------------------
  //  Callback vtables - these are struct-of-function-pointers matching the
  //  C API. Each field must point to a cdecl callback.
  // ---------------------------------------------------------------------------

  // BroadPhase / Object / Body / Shape filters for custom collision rules
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
  // Extended Callback VTables
  PJPH_PhysicsStepListener_Procs = ^JPH_PhysicsStepListener_Procs;

  JPH_PhysicsStepListener_Procs = record
    OnStep: Pointer;
  end;

  PJPH_SimShapeFilter_Procs = ^JPH_SimShapeFilter_Procs;

  JPH_SimShapeFilter_Procs = record
    ShouldCollide: Pointer;
  end;

  PJPH_BodyDrawFilter_Procs = ^JPH_BodyDrawFilter_Procs;

  JPH_BodyDrawFilter_Procs = record
    ShouldDraw: Pointer;
  end;
  // Character contact listeners
  PJPH_CharacterContactListener_Procs = ^JPH_CharacterContactListener_Procs;

  JPH_CharacterContactListener_Procs = record
    OnAdjustBodyVelocity: Pointer;
    OnContactValidate: Pointer;
    OnCharacterContactValidate: Pointer;
    OnContactAdded: Pointer;
    OnContactPersisted: Pointer;
    OnContactRemoved: Pointer;
    OnCharacterContactAdded: Pointer;
    OnCharacterContactPersisted: Pointer;
    OnCharacterContactRemoved: Pointer;
    OnContactSolve: Pointer;
    OnCharacterContactSolve: Pointer;
  end;
  // Character vs Character collision callbacks
  PJPH_CharacterVsCharacterCollision_Procs = ^JPH_CharacterVsCharacterCollision_Procs;

  JPH_CharacterVsCharacterCollision_Procs = record
    CollideCharacter: Pointer;
    CastCharacter: Pointer;
  end;
  // Debug Renderer callbacks to draw lines, triangles, and text in your engine
  PJPH_DebugRenderer_Procs = ^JPH_DebugRenderer_Procs;

  JPH_DebugRenderer_Procs = record
    DrawLine: Pointer;
    DrawTriangle: Pointer;
    DrawText3D: Pointer;
  end;
  // === API FUNCTIONS ===
  // All functions are cdecl and imported from JoltC.dll.
  // Ownership rules:
  //   - Every *_Create call that returns a heap-allocated handle must be paired
  //     with the matching *_Destroy call to avoid leaks.
  //   - Shapes returned by *_CreateShape are reference-counted by the engine.
  // =============================================================================

  // -- Lifecycle ---------------------------------------------------------------
  { Initializes the Jolt Physics library. Must be called once at startup. }
function JPH_Init: JPH_Bool; cdecl; external JOLT_LIB;
  { Shuts down the Jolt Physics library and frees global memory. }

procedure JPH_Shutdown; cdecl; external JOLT_LIB;
  { Sets a custom trace handler for logging messages from the physics engine. }

procedure JPH_SetTraceHandler(handler: Pointer); cdecl; external JOLT_LIB;
  { Sets a custom handler for assertion failures in the physics engine. }

procedure JPH_SetAssertFailureHandler(handler: Pointer); cdecl; external JOLT_LIB;
  // -- BroadPhase / Layers (Mask Variants) -------------
  { Creates a BroadPhaseLayerInterface using bit masks for collision filtering. }
function JPH_BroadPhaseLayerInterfaceMask_Create(numBroadPhaseLayers: UInt32): JPH_BroadPhaseLayerInterface; cdecl; external JOLT_LIB;
  { Destroys a BroadPhaseLayerInterface handle. }

procedure JPH_BroadPhaseLayerInterface_Destroy(bpInterface: JPH_BroadPhaseLayerInterface); cdecl; external JOLT_LIB;
  { Configures which groups are included/excluded for a specific broadphase layer. }

procedure JPH_BroadPhaseLayerInterfaceMask_ConfigureLayer(bpInterface: JPH_BroadPhaseLayerInterface; broadPhaseLayer: JPH_BroadPhaseLayer; groupsToInclude: UInt32; groupsToExclude: UInt32); cdecl; external JOLT_LIB;
  { Creates an ObjectLayerPairFilter using bit masks. }
function JPH_ObjectLayerPairFilterMask_Create: JPH_ObjectLayerPairFilter; cdecl; external JOLT_LIB;
  { Destroys an ObjectLayerPairFilter. }

procedure JPH_ObjectLayerPairFilter_Destroy(filter: JPH_ObjectLayerPairFilter); cdecl; external JOLT_LIB;
  { Calculates an ObjectLayer from a group and a mask. }

function JPH_ObjectLayerPairFilterMask_GetObjectLayer(group: UInt32; mask: UInt32): JPH_ObjectLayer; cdecl; external JOLT_LIB;
  { Extracts the group from an ObjectLayer. }

function JPH_ObjectLayerPairFilterMask_GetGroup(layer: JPH_ObjectLayer): UInt32; cdecl; external JOLT_LIB;
  { Extracts the mask from an ObjectLayer. }

function JPH_ObjectLayerPairFilterMask_GetMask(layer: JPH_ObjectLayer): UInt32; cdecl; external JOLT_LIB;
  { Creates an ObjectVsBroadPhaseLayerFilter using masks. }
function JPH_ObjectVsBroadPhaseLayerFilterMask_Create(broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface): JPH_ObjectVsBroadPhaseLayerFilter; cdecl; external JOLT_LIB;
  { Destroys an ObjectVsBroadPhaseLayerFilter. }

procedure JPH_ObjectVsBroadPhaseLayerFilter_Destroy(filter: JPH_ObjectVsBroadPhaseLayerFilter); cdecl; external JOLT_LIB;
  // -- BroadPhase / Layers (Table Variants) --
  { Creates a BroadPhaseLayerInterface using a table mapping (ObjectLayer -> BroadPhaseLayer). }
function JPH_BroadPhaseLayerInterfaceTable_Create(numObjectLayers: UInt32; numBroadPhaseLayers: UInt32): JPH_BroadPhaseLayerInterface; cdecl; external JOLT_LIB;
  { Maps a specific ObjectLayer to a BroadPhaseLayer. }

procedure JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(bpInterface: JPH_BroadPhaseLayerInterface; objectLayer: JPH_ObjectLayer; broadPhaseLayer: JPH_BroadPhaseLayer); cdecl; external JOLT_LIB;
  { Creates an ObjectLayerPairFilter using a table to enable/disable collisions. }
function JPH_ObjectLayerPairFilterTable_Create(numObjectLayers: UInt32): JPH_ObjectLayerPairFilter; cdecl; external JOLT_LIB;
  { Disables collision between two specific ObjectLayers. }

procedure JPH_ObjectLayerPairFilterTable_DisableCollision(objectFilter: JPH_ObjectLayerPairFilter; layer1: JPH_ObjectLayer; layer2: JPH_ObjectLayer); cdecl; external JOLT_LIB;
  { Enables collision between two specific ObjectLayers. }

procedure JPH_ObjectLayerPairFilterTable_EnableCollision(objectFilter: JPH_ObjectLayerPairFilter; layer1: JPH_ObjectLayer; layer2: JPH_ObjectLayer); cdecl; external JOLT_LIB;
  { Checks if collision is enabled between two ObjectLayers. }

function JPH_ObjectLayerPairFilterTable_ShouldCollide(objectFilter: JPH_ObjectLayerPairFilter; layer1: JPH_ObjectLayer; layer2: JPH_ObjectLayer): JPH_Bool; cdecl; external JOLT_LIB;
  { Creates an ObjectVsBroadPhaseLayerFilter using a table. }
function JPH_ObjectVsBroadPhaseLayerFilterTable_Create(broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface; numBroadPhaseLayers: UInt32; objectLayerPairFilter: JPH_ObjectLayerPairFilter; numObjectLayers: UInt32): JPH_ObjectVsBroadPhaseLayerFilter; cdecl; external JOLT_LIB;
  // -- Custom filter wrappers (callback-based) ----------------------------------
  { Creates a custom BroadPhaseLayerFilter using Delphi callbacks. }
function JPH_BroadPhaseLayerFilter_Create(userData: Pointer; procs: PJPH_BroadPhaseLayerFilter_Procs): JPH_BroadPhaseLayerFilter; cdecl; external JOLT_LIB;
  { Destroys a custom BroadPhaseLayerFilter. }

procedure JPH_BroadPhaseLayerFilter_Destroy(filter: JPH_BroadPhaseLayerFilter); cdecl; external JOLT_LIB;
  { Creates a custom ObjectLayerFilter using Delphi callbacks. }

function JPH_ObjectLayerFilter_Create(userData: Pointer; procs: PJPH_ObjectLayerFilter_Procs): JPH_ObjectLayerFilter; cdecl; external JOLT_LIB;
  { Destroys a custom ObjectLayerFilter. }

procedure JPH_ObjectLayerFilter_Destroy(filter: JPH_ObjectLayerFilter); cdecl; external JOLT_LIB;
  { Creates a custom BodyFilter using Delphi callbacks (used for queries like raycasts). }

function JPH_BodyFilter_Create(userData: Pointer; procs: PJPH_BodyFilter_Procs): JPH_BodyFilter; cdecl; external JOLT_LIB;
  { Destroys a custom BodyFilter. }

procedure JPH_BodyFilter_Destroy(filter: JPH_BodyFilter); cdecl; external JOLT_LIB;
  { Creates a custom ShapeFilter using Delphi callbacks. }

function JPH_ShapeFilter_Create(userData: Pointer; procs: PJPH_ShapeFilter_Procs): JPH_ShapeFilter; cdecl; external JOLT_LIB;
  { Destroys a custom ShapeFilter. }

procedure JPH_ShapeFilter_Destroy(filter: JPH_ShapeFilter); cdecl; external JOLT_LIB;
// -- Advanced Shape Casting (Sweep Tests) --
  // Casts a shape from 'from' to 'to' and returns hit results.
function JPH_NarrowPhaseQuery_CastShape(query: JPH_NarrowPhaseQuery; shapeCast: PJPH_ShapeCastSettings; shape: JPH_Shape; scale: PJPH_Vec3; from: PJPH_RMat4; xto: PJPH_RMat4; baseOffset: PJPH_RVec3; hit: PJPH_ShapeCastResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;
  // Collides a shape against the world without moving it.
function JPH_NarrowPhaseQuery_CollideShape(query: JPH_NarrowPhaseQuery; shape: JPH_Shape; scale: PJPH_Vec3; centerOfMassTransform: PJPH_RMat4; collShapeSettings: PJPH_CollideShapeSettings; baseOffset: PJPH_RVec3; hit: PJPH_CollideShapeResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;
  // -- Ragdoll Setup & Control --
procedure JPH_RagdollSettings_SetSkeleton(settings: JPH_RagdollSettings; skeleton: JPH_Skeleton); cdecl; external JOLT_LIB;
function JPH_RagdollSettings_GetJoint(settings: JPH_RagdollSettings; index: UInt32): JPH_Constraint; cdecl; external JOLT_LIB;
procedure JPH_RagdollSettings_SetGroupFilter(settings: JPH_RagdollSettings; filter: JPH_GroupFilter); cdecl; external JOLT_LIB;
procedure JPH_Ragdoll_SetGroupFilter(ragdoll: JPH_Ragdoll; filter: JPH_GroupFilter); cdecl; external JOLT_LIB;
procedure JPH_Ragdoll_Activate(ragdoll: JPH_Ragdoll); cdecl; external JOLT_LIB;
procedure JPH_Ragdoll_Deactivate(ragdoll: JPH_Ragdoll); cdecl; external JOLT_LIB;
function JPH_Ragdoll_GetBodyID(ragdoll: JPH_Ragdoll; index: UInt32): JPH_BodyID; cdecl; external JOLT_LIB;
  // -- Soft Body Setup & Manipulation --
function JPH_SoftBodySharedSettings_Create: JPH_SoftBodySharedSettings; cdecl; external JOLT_LIB;
procedure JPH_SoftBodySharedSettings_Destroy(settings: JPH_SoftBodySharedSettings); cdecl; external JOLT_LIB;
procedure JPH_SoftBodySharedSettings_AddVertex(settings: JPH_SoftBodySharedSettings; vertex: PJPH_SoftBodySharedSettingsVertex); cdecl; external JOLT_LIB;
procedure JPH_SoftBodySharedSettings_AddEdge(settings: JPH_SoftBodySharedSettings; edge: PJPH_SoftBodySharedSettingsEdge); cdecl; external JOLT_LIB;
procedure JPH_SoftBodySharedSettings_Optimize(settings: JPH_SoftBodySharedSettings); cdecl; external JOLT_LIB;
function JPH_SoftBodyCreationSettings_Create(settings: JPH_SoftBodySharedSettings; position: PJPH_RVec3; rotation: PJPH_Quat; objectLayer: JPH_ObjectLayer): JPH_SoftBodyCreationSettings; cdecl; external JOLT_LIB;
procedure JPH_SoftBodyCreationSettings_Destroy(settings: JPH_SoftBodyCreationSettings); cdecl; external JOLT_LIB;
function JPH_BodyInterface_CreateAndAddSoftBody(bodyInterface: JPH_BodyInterface; settings: JPH_SoftBodyCreationSettings; activationMode: JPH_Activation): JPH_BodyID; cdecl; external JOLT_LIB;
  // Get/Set vertex velocities directly for soft body manipulation
procedure JPH_SoftBody_GetVertices(softBody: JPH_Body; outVertices: PJPH_SoftBodySharedSettingsVertex; count: UInt32); cdecl; external JOLT_LIB;
  // -- Collision Groups API --
procedure JPH_BodyInterface_SetCollisionGroup(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; group: JPH_CollisionGroup); cdecl; external JOLT_LIB;
procedure JPH_BodyInterface_GetCollisionGroup(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; outGroup: PJPH_CollisionGroup); cdecl; external JOLT_LIB;
  // -- Body Interface Extended --
function JPH_BodyInterface_GetMotionProperties(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_MotionProperties; cdecl; external JOLT_LIB;
  // -- Math Extensions --
procedure JPH_Vec3_Add(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;
procedure JPH_Vec3_Sub(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;
procedure JPH_Vec3_Mul(v: PJPH_Vec3; scale: Single; result: PJPH_Vec3); cdecl; external JOLT_LIB;
  // -- Contact & Activation Listeners ------------------------------------------
  { Creates a ContactListener using Delphi callbacks for collision events. }
function JPH_ContactListener_Create(userData: Pointer; procs: PJPH_ContactListener_Procs): JPH_ContactListener; cdecl; external JOLT_LIB;
  { Destroys a ContactListener. }

procedure JPH_ContactListener_Destroy(listener: JPH_ContactListener); cdecl; external JOLT_LIB;
  { Sets the global ContactListener callbacks. }

procedure JPH_ContactListener_SetProcs(procs: PJPH_ContactListener_Procs); cdecl; external JOLT_LIB;
  { Assigns a ContactListener to the PhysicsSystem. }

procedure JPH_PhysicsSystem_SetContactListener(system: JPH_PhysicsSystem; listener: JPH_ContactListener); cdecl; external JOLT_LIB;
  { Creates a BodyActivationListener using Delphi callbacks for sleep/wake events. }
function JPH_BodyActivationListener_Create(userData: Pointer; procs: PJPH_BodyActivationListener_Procs): JPH_BodyActivationListener; cdecl; external JOLT_LIB;
  { Destroys a BodyActivationListener. }

procedure JPH_BodyActivationListener_Destroy(listener: JPH_BodyActivationListener); cdecl; external JOLT_LIB;
  { Sets the global BodyActivationListener callbacks. }

procedure JPH_BodyActivationListener_SetProcs(procs: PJPH_BodyActivationListener_Procs); cdecl; external JOLT_LIB;
  { Assigns a BodyActivationListener to the PhysicsSystem. }

procedure JPH_PhysicsSystem_SetBodyActivationListener(system: JPH_PhysicsSystem; listener: JPH_BodyActivationListener); cdecl; external JOLT_LIB;
  // -- PhysicsSystem -----------------------------------------------------------
  { Creates the main PhysicsSystem. }
function JPH_PhysicsSystem_Create(settings: PJPH_PhysicsSystemSettings): JPH_PhysicsSystem; cdecl; external JOLT_LIB;
  { Destroys the PhysicsSystem and all contained bodies/constraints. }

procedure JPH_PhysicsSystem_Destroy(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;
  { Overrides the default physics settings (gravity, sleep, tolerances). }

procedure JPH_PhysicsSystem_SetPhysicsSettings(system: JPH_PhysicsSystem; settings: PJPH_PhysicsSettings); cdecl; external JOLT_LIB;
  { Retrieves the current physics settings. }

procedure JPH_PhysicsSystem_GetPhysicsSettings(system: JPH_PhysicsSystem; settings: PJPH_PhysicsSettings); cdecl; external JOLT_LIB;
  { Optimizes the broadphase tree. Call after adding many bodies initially. }

procedure JPH_PhysicsSystem_OptimizeBroadPhase(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;
  { Steps the simulation forward by deltaTime. (Without TempAllocator) }

function JPH_PhysicsSystem_Update(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Int32; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;
  { Steps the simulation forward by deltaTime using a TempAllocator (recommended). }

function JPH_PhysicsSystem_Update2(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Int32; tempAllocator: JPH_TempAllocator; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;
  { Sets the global gravity vector. }

procedure JPH_PhysicsSystem_SetGravity(system: JPH_PhysicsSystem; value: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the global gravity vector. }

procedure JPH_PhysicsSystem_GetGravity(system: JPH_PhysicsSystem; result: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the thread-safe BodyInterface for adding/removing bodies. }

function JPH_PhysicsSystem_GetBodyInterface(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;
  { Gets the non-thread-safe BodyInterface (faster, use only when not multi-threading). }

function JPH_PhysicsSystem_GetBodyInterfaceNoLock(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;
  { Gets the BodyLockInterface for locking bodies before reading/writing directly. }

function JPH_PhysicsSystem_GetBodyLockInterface(system: JPH_PhysicsSystem): JPH_BodyLockInterface; cdecl; external JOLT_LIB;
  { Gets the non-locking BodyLockInterface. }

function JPH_PhysicsSystem_GetBodyLockInterfaceNoLock(system: JPH_PhysicsSystem): JPH_BodyLockInterface; cdecl; external JOLT_LIB;
  { Gets the BroadPhaseQuery interface for broadphase raycasts/casts. }

function JPH_PhysicsSystem_GetBroadPhaseQuery(system: JPH_PhysicsSystem): JPH_BroadPhaseQuery; cdecl; external JOLT_LIB;
  { Gets the NarrowPhaseQuery interface for precise collision queries. }

function JPH_PhysicsSystem_GetNarrowPhaseQuery(system: JPH_PhysicsSystem): JPH_NarrowPhaseQuery; cdecl; external JOLT_LIB;
  { Gets the NarrowPhaseQuery interface without locking. }

function JPH_PhysicsSystem_GetNarrowPhaseQueryNoLock(system: JPH_PhysicsSystem): JPH_NarrowPhaseQuery; cdecl; external JOLT_LIB;
  { Sets a filter to ignore certain shape collisions during simulation. }

procedure JPH_PhysicsSystem_SetSimShapeFilter(system: JPH_PhysicsSystem; filter: JPH_SimShapeFilter); cdecl; external JOLT_LIB;
  { Returns the current number of bodies in the system. }

function JPH_PhysicsSystem_GetNumBodies(system: JPH_PhysicsSystem): UInt32; cdecl; external JOLT_LIB;
  { Returns the maximum number of bodies allowed. }

function JPH_PhysicsSystem_GetMaxBodies(system: JPH_PhysicsSystem): UInt32; cdecl; external JOLT_LIB;
  { Returns the number of active (non-sleeping) bodies. }

function JPH_PhysicsSystem_GetNumActiveBodies(system: JPH_PhysicsSystem; bodyType: JPH_BodyType): UInt32; cdecl; external JOLT_LIB;
  { Returns the number of constraints in the system. }

function JPH_PhysicsSystem_GetNumConstraints(system: JPH_PhysicsSystem): UInt32; cdecl; external JOLT_LIB;
  { Checks if two specific bodies were in contact during the last simulation step. }

function JPH_PhysicsSystem_WereBodiesInContact(system: JPH_PhysicsSystem; body1: JPH_BodyID; body2: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;
  // Constraint Management
  { Adds a constraint (joint) to the simulation. }
procedure JPH_PhysicsSystem_AddConstraint(system: JPH_PhysicsSystem; constraint: JPH_Constraint); cdecl; external JOLT_LIB;
  { Removes a constraint from the simulation. }

procedure JPH_PhysicsSystem_RemoveConstraint(system: JPH_PhysicsSystem; constraint: JPH_Constraint); cdecl; external JOLT_LIB;
  { Adds multiple constraints to the simulation at once. }

procedure JPH_PhysicsSystem_AddConstraints(system: JPH_PhysicsSystem; constraints: Pointer; count: UInt32); cdecl; external JOLT_LIB;
  { Removes multiple constraints from the simulation at once. }

procedure JPH_PhysicsSystem_RemoveConstraints(system: JPH_PhysicsSystem; constraints: Pointer; count: UInt32); cdecl; external JOLT_LIB;
  // Step Listeners
  { Adds a listener that triggers before every physics step. }
procedure JPH_PhysicsSystem_AddStepListener(system: JPH_PhysicsSystem; listener: JPH_PhysicsStepListener); cdecl; external JOLT_LIB;
  { Removes a step listener. }

procedure JPH_PhysicsSystem_RemoveStepListener(system: JPH_PhysicsSystem; listener: JPH_PhysicsStepListener); cdecl; external JOLT_LIB;
  { Sets the global callbacks for PhysicsStepListener. }

procedure JPH_PhysicsStepListener_SetProcs(procs: PJPH_PhysicsStepListener_Procs); cdecl; external JOLT_LIB;
  { Creates a PhysicsStepListener. }

function JPH_PhysicsStepListener_Create(userData: Pointer): JPH_PhysicsStepListener; cdecl; external JOLT_LIB;
  { Destroys a PhysicsStepListener. }

procedure JPH_PhysicsStepListener_Destroy(listener: JPH_PhysicsStepListener); cdecl; external JOLT_LIB;
  // GroupFilter
  { Creates a GroupFilterTable to manage collision groups. }
function JPH_GroupFilterTable_Create(numSubGroups: UInt32): JPH_GroupFilterTable; cdecl; external JOLT_LIB;
  { Disables collision between two subgroups. }

procedure JPH_GroupFilterTable_DisableCollision(table: JPH_GroupFilterTable; subGroup1: JPH_CollisionSubGroupID; subGroup2: JPH_CollisionSubGroupID); cdecl; external JOLT_LIB;
  { Enables collision between two subgroups. }

procedure JPH_GroupFilterTable_EnableCollision(table: JPH_GroupFilterTable; subGroup1: JPH_CollisionSubGroupID; subGroup2: JPH_CollisionSubGroupID); cdecl; external JOLT_LIB;
  { Checks if collision is enabled between two subgroups. }

function JPH_GroupFilterTable_IsCollisionEnabled(table: JPH_GroupFilterTable; subGroup1: JPH_CollisionSubGroupID; subGroup2: JPH_CollisionSubGroupID): JPH_Bool; cdecl; external JOLT_LIB;
  // -- Body Debug Rendering --
  { Draws all bodies to a custom DebugRenderer using the given settings. }
procedure JPH_PhysicsSystem_DrawBodies(system: JPH_PhysicsSystem; settings: PJPH_DrawSettings; renderer: JPH_DebugRenderer; bodyFilter: JPH_BodyDrawFilter); cdecl; external JOLT_LIB;
  // -- JobSystem / TempAllocator ------------------------------------------------
  { Creates a thread pool for executing physics jobs (multi-threading). }
function JPH_JobSystemThreadPool_Create(config: PJobSystemThreadPoolConfig): JPH_JobSystem; cdecl; external JOLT_LIB;
  { Destroys the job system thread pool. }

procedure JPH_JobSystem_Destroy(jobSystem: JPH_JobSystem); cdecl; external JOLT_LIB;
  { Creates a temporary allocator with a fixed block size. }

function JPH_TempAllocator_Create(size: UInt32): JPH_TempAllocator; cdecl; external JOLT_LIB;
  { Creates a temporary allocator that falls back to malloc (slower, but no size limit). }

function JPH_TempAllocatorMalloc_Create: JPH_TempAllocator; cdecl; external JOLT_LIB;
  { Destroys a temporary allocator. }

procedure JPH_TempAllocator_Destroy(allocator: JPH_TempAllocator); cdecl; external JOLT_LIB;
  // -- Body creation & Transforms ----------------------------------------------
  { Creates settings for a new body with basic parameters. }
function JPH_BodyCreationSettings_Create3(shape: JPH_Shape; position: PJPH_RVec3; rotation: PJPH_Quat; motionType: JPH_MotionType; objectLayer: JPH_ObjectLayer): JPH_BodyCreationSettings; cdecl; external JOLT_LIB;
  { Destroys body creation settings. }

procedure JPH_BodyCreationSettings_Destroy(settings: JPH_BodyCreationSettings); cdecl; external JOLT_LIB;
  { Creates a body from settings and immediately adds it to the world. Returns the BodyID. }

function JPH_BodyInterface_CreateAndAddBody(bodyInterface: JPH_BodyInterface; settings: JPH_BodyCreationSettings; activationMode: JPH_Activation): JPH_BodyID; cdecl; external JOLT_LIB;
  { Removes a body from the world and destroys it. }

procedure JPH_BodyInterface_RemoveAndDestroyBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;
  { Removes a body from the world without destroying the shape. }

procedure JPH_BodyInterface_RemoveBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;
  { Checks if a body is currently added to the world. }

function JPH_BodyInterface_IsAdded(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;
  { Sets the world position of a body. }

procedure JPH_BodyInterface_SetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
  { Gets the world position of a body. }

procedure JPH_BodyInterface_GetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RVec3); cdecl; external JOLT_LIB;
  { Sets the world rotation of a body. }

procedure JPH_BodyInterface_SetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
  { Gets the world rotation of a body. }

procedure JPH_BodyInterface_GetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_Quat); cdecl; external JOLT_LIB;
  { Sets position and rotation simultaneously (more efficient than calling both separately). }

procedure JPH_BodyInterface_SetPositionAndRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
  { Gets position and rotation simultaneously. }

procedure JPH_BodyInterface_GetPositionAndRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; rotation: PJPH_Quat); cdecl; external JOLT_LIB;
  { Gets the world position of the body's center of mass. }

procedure JPH_BodyInterface_GetCenterOfMassPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3); cdecl; external JOLT_LIB;
  { Gets the full world transform matrix of the body. }

procedure JPH_BodyInterface_GetWorldTransform(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RMat4); cdecl; external JOLT_LIB;
  { Gets the transform matrix relative to the center of mass. }

procedure JPH_BodyInterface_GetCenterOfMassTransform(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_RMat4); cdecl; external JOLT_LIB;
  // -- Body Velocity & Forces --------------------------------------------------
  { Sets the linear velocity of a body. }
procedure JPH_BodyInterface_SetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the linear velocity of a body. }

procedure JPH_BodyInterface_GetLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Sets the angular velocity of a body. }

procedure JPH_BodyInterface_SetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the angular velocity of a body. }

procedure JPH_BodyInterface_GetAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Sets both linear and angular velocity simultaneously. }

procedure JPH_BodyInterface_SetLinearAndAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3; angularVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets both linear and angular velocity simultaneously. }

procedure JPH_BodyInterface_GetLinearAndAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3; angularVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Calculates the velocity of a specific point on a body (including angular motion). }

procedure JPH_BodyInterface_GetPointVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; point: PJPH_RVec3; velocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Adds a delta linear velocity to a body. }

procedure JPH_BodyInterface_AddLinearVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Adds delta linear and angular velocity simultaneously. }

procedure JPH_BodyInterface_AddLinearAndAngularVelocity(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; linearVelocity: PJPH_Vec3; angularVelocity: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Applies an impulse to the center of mass. }

procedure JPH_BodyInterface_AddImpulse(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; impulse: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Applies an impulse at a specific world position. }

procedure JPH_BodyInterface_AddImpulse2(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; impulse: PJPH_Vec3; point: PJPH_RVec3); cdecl; external JOLT_LIB;
  { Applies an angular impulse (torque over time). }

procedure JPH_BodyInterface_AddAngularImpulse(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; angularImpulse: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Applies a continuous force to the center of mass. }

procedure JPH_BodyInterface_AddForce(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; force: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Applies a continuous force at a specific world position. }

procedure JPH_BodyInterface_AddForce2(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; force: PJPH_Vec3; point: PJPH_RVec3); cdecl; external JOLT_LIB;
  { Applies a continuous torque. }

procedure JPH_BodyInterface_AddTorque(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; torque: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Wakes a body up (makes it active). }

procedure JPH_BodyInterface_ActivateBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;
  { Forces a body to sleep (makes it inactive). }

procedure JPH_BodyInterface_DeactivateBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;
  { Checks if a body is active. }

function JPH_BodyInterface_IsActive(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_Bool; cdecl; external JOLT_LIB;
  { Gets the shape attached to a body. }

function JPH_BodyInterface_GetShape(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_Shape; cdecl; external JOLT_LIB;
  { Replaces the shape of a body. Can optionally update mass properties. }

procedure JPH_BodyInterface_SetShape(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; shape: JPH_Shape; updateMassProperties: JPH_Bool; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
  // -- Body Properties ---------------------------------------------------------
  { Changes the motion type (Static, Kinematic, Dynamic). }
procedure JPH_BodyInterface_SetMotionType(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; motionType: JPH_MotionType; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
  { Gets the current motion type. }

function JPH_BodyInterface_GetMotionType(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_MotionType; cdecl; external JOLT_LIB;
  { Gets the body type (Rigid or Soft). }

function JPH_BodyInterface_GetBodyType(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_BodyType; cdecl; external JOLT_LIB;
  { Sets the motion quality (Discrete or LinearCast). }

procedure JPH_BodyInterface_SetMotionQuality(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; quality: JPH_MotionQuality); cdecl; external JOLT_LIB;
  { Gets the motion quality. }

function JPH_BodyInterface_GetMotionQuality(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_MotionQuality; cdecl; external JOLT_LIB;
  { Gets the inverse inertia tensor (matrix) of a body. }

procedure JPH_BodyInterface_GetInverseInertia(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; result: PJPH_Mat4); cdecl; external JOLT_LIB;
  { Sets a multiplier for gravity affecting this body. }

procedure JPH_BodyInterface_SetGravityFactor(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; value: Single); cdecl; external JOLT_LIB;
  { Gets the current gravity factor. }

function JPH_BodyInterface_GetGravityFactor(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;
  { Smoothly moves a kinematic body towards a target position/rotation. }

procedure JPH_BodyInterface_MoveKinematic(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; targetPosition: PJPH_RVec3; targetRotation: PJPH_Quat; deltaTime: Single); cdecl; external JOLT_LIB;
  // -- Surface properties -------------------------------------------------------
  { Sets the friction coefficient. }
procedure JPH_BodyInterface_SetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; friction: Single); cdecl; external JOLT_LIB;
  { Gets the friction coefficient. }

function JPH_BodyInterface_GetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;
  { Sets the restitution (bounciness). }

procedure JPH_BodyInterface_SetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; restitution: Single); cdecl; external JOLT_LIB;
  { Gets the restitution. }

function JPH_BodyInterface_GetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;
  // -- Object Layer & User Data ------------------------------------------------
  { Changes the ObjectLayer (collision group) of the body. }
procedure JPH_BodyInterface_SetObjectLayer(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; layer: JPH_ObjectLayer); cdecl; external JOLT_LIB;
  { Gets the ObjectLayer. }

function JPH_BodyInterface_GetObjectLayer(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): JPH_ObjectLayer; cdecl; external JOLT_LIB;
  { Sets a user-defined 64-bit integer pointer for custom data. }

procedure JPH_BodyInterface_SetUserData(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; userData: UInt64); cdecl; external JOLT_LIB;
  { Gets the user data pointer. }

function JPH_BodyInterface_GetUserData(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): UInt64; cdecl; external JOLT_LIB;
  // -- Ray casting & Collisions ------------------------------------------------
  { Casts a ray and returns the closest hit. }
function JPH_NarrowPhaseQuery_CastRay(query: JPH_NarrowPhaseQuery; origin: PJPH_RVec3; direction: PJPH_Vec3; hit: PJPH_RayCastResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;
  { Checks if a point is inside any shape and returns the hit. }

function JPH_NarrowPhaseQuery_CollidePoint(query: JPH_NarrowPhaseQuery; point: PJPH_RVec3; hit: PJPH_CollidePointResult; broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter): JPH_Bool; cdecl; external JOLT_LIB;
  // -- Shape settings ----------------------------------------------------------
  { Creates settings for a Box shape. }
function JPH_BoxShapeSettings_Create(halfExtent: PJPH_Vec3; convexRadius: Single): JPH_BoxShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Sphere shape. }

function JPH_SphereShapeSettings_Create(radius: Single): JPH_SphereShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Capsule shape. }

function JPH_CapsuleShapeSettings_Create(halfHeightOfCylinder: Single; radius: Single): JPH_CapsuleShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Cylinder shape. }

function JPH_CylinderShapeSettings_Create(halfHeight: Single; radius: Single; convexRadius: Single): JPH_CylinderShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a TaperedCapsule shape. }

function JPH_TaperedCapsuleShapeSettings_Create(halfHeightOfTaperedCylinder: Single; topRadius: Single; bottomRadius: Single): JPH_TaperedCapsuleShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a TaperedCylinder shape. }

function JPH_TaperedCylinderShapeSettings_Create(halfHeightOfTaperedCylinder: Single; topRadius: Single; bottomRadius: Single; convexRadius: Single): JPH_TaperedCylinderShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a ConvexHull shape from a point cloud. }

function JPH_ConvexHullShapeSettings_Create(points: PJPH_Vec3; pointsCount: UInt32; maxConvexRadius: Single): JPH_ConvexHullShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a static compound shape (can group multiple shapes). }

function JPH_StaticCompoundShapeSettings_Create: JPH_StaticCompoundShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Mesh shape from triangles. }

function JPH_MeshShapeSettings_Create(triangles: PJPH_Triangle; triangleCount: UInt32): JPH_MeshShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a single Triangle shape. }

function JPH_TriangleShapeSettings_Create(v1: PJPH_Vec3; v2: PJPH_Vec3; v3: PJPH_Vec3; convexRadius: Single): JPH_TriangleShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for an infinite Plane shape. }

function JPH_PlaneShapeSettings_Create(plane: PJPH_Plane; material: JPH_PhysicsMaterial; halfExtent: Single): JPH_PlaneShapeSettings; cdecl; external JOLT_LIB;
  { Creates settings for a HeightField shape (terrain). }

function JPH_HeightFieldShapeSettings_Create(samples: PSingle; offset: PJPH_Vec3; scale: PJPH_Vec3; sampleCount: UInt32; materialIndices: PByte): JPH_HeightFieldShapeSettings; cdecl; external JOLT_LIB;
  // Functions to finalize settings into actual reference-counted Shapes
function JPH_BoxShapeSettings_CreateShape(settings: JPH_BoxShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_SphereShapeSettings_CreateShape(settings: JPH_SphereShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CapsuleShapeSettings_CreateShape(settings: JPH_CapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_CylinderShapeSettings_CreateShape(settings: JPH_CylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_TaperedCapsuleShapeSettings_CreateShape(settings: JPH_TaperedCapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_TaperedCylinderShapeSettings_CreateShape(settings: JPH_TaperedCylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_ConvexHullShapeSettings_CreateShape(settings: JPH_ConvexHullShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_StaticCompoundShapeSettings_CreateShape(settings: JPH_StaticCompoundShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_MeshShapeSettings_CreateShape(settings: JPH_MeshShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_TriangleShapeSettings_CreateShape(settings: JPH_TriangleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_PlaneShapeSettings_CreateShape(settings: JPH_PlaneShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

function JPH_HeightFieldShapeSettings_CreateShape(settings: JPH_HeightFieldShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;
  { Adds a child shape to a compound shape settings. }
procedure JPH_CompoundShapeSettings_AddShape(settings: JPH_CompoundShapeSettings; position: PJPH_Vec3; rotation: PJPH_Quat; shapeSettings: JPH_ShapeSettings; userData: UInt32); cdecl; external JOLT_LIB;
  { Destroys shape settings (safe to call after CreateShape). }

procedure JPH_ShapeSettings_Destroy(settings: JPH_ShapeSettings); cdecl; external JOLT_LIB;
  { Decrements the reference count of a shape, destroying it if it reaches 0. }

procedure JPH_Shape_Destroy(shape: JPH_Shape); cdecl; external JOLT_LIB;
  // -- Shapes extended --
  { Gets the top-level type of a shape. }
function JPH_Shape_GetType(shape: JPH_Shape): JPH_ShapeType; cdecl; external JOLT_LIB;
  { Gets the sub-type of a shape. }

function JPH_Shape_GetSubType(shape: JPH_Shape): JPH_ShapeSubType; cdecl; external JOLT_LIB;
  { Gets the local bounding box of a shape. }

procedure JPH_Shape_GetLocalBounds(shape: JPH_Shape; result: PJPH_AABox); cdecl; external JOLT_LIB;
  { Gets the inner radius of a shape (largest sphere that fits inside). }

function JPH_Shape_GetInnerRadius(shape: JPH_Shape): Single; cdecl; external JOLT_LIB;
  { Calculates the mass properties if this shape were used for a body. }

procedure JPH_Shape_GetMassProperties(shape: JPH_Shape; result: PJPH_MassProperties); cdecl; external JOLT_LIB;
  { Casts a ray against this specific shape directly. }

function JPH_Shape_CastRay(shape: JPH_Shape; origin: PJPH_Vec3; direction: PJPH_Vec3; hit: PJPH_RayCastResult): JPH_Bool; cdecl; external JOLT_LIB;
  // -- Constraints (Joints) ----------------------------------------------------
  { Initializes FixedConstraintSettings to default values. }
procedure JPH_FixedConstraintSettings_Init(settings: PJPH_FixedConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a FixedConstraint (welds bodies together). }

function JPH_FixedConstraint_Create(settings: PJPH_FixedConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_FixedConstraint; cdecl; external JOLT_LIB;
  { Initializes PointConstraintSettings (ball joint). }
procedure JPH_PointConstraintSettings_Init(settings: PJPH_PointConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a PointConstraint. }

function JPH_PointConstraint_Create(settings: PJPH_PointConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_PointConstraint; cdecl; external JOLT_LIB;
  { Initializes DistanceConstraintSettings. }
procedure JPH_DistanceConstraintSettings_Init(settings: PJPH_DistanceConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a DistanceConstraint. }

function JPH_DistanceConstraint_Create(settings: PJPH_DistanceConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_DistanceConstraint; cdecl; external JOLT_LIB;
  { Initializes HingeConstraintSettings. }
procedure JPH_HingeConstraintSettings_Init(settings: PJPH_HingeConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a HingeConstraint. }

function JPH_HingeConstraint_Create(settings: PJPH_HingeConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_HingeConstraint; cdecl; external JOLT_LIB;
  { Sets the target angular velocity for the hinge motor. }

procedure JPH_HingeConstraint_SetTargetAngularVelocity(constraint: JPH_HingeConstraint; angularVelocity: Single); cdecl; external JOLT_LIB;
  { Sets the target angle for the hinge motor. }

procedure JPH_HingeConstraint_SetTargetAngle(constraint: JPH_HingeConstraint; angle: Single); cdecl; external JOLT_LIB;
  { Enables/disables the hinge motor or sets it to velocity/position mode. }

procedure JPH_HingeConstraint_SetMotorState(constraint: JPH_HingeConstraint; state: JPH_MotorState); cdecl; external JOLT_LIB;
  { Initializes SliderConstraintSettings. }
procedure JPH_SliderConstraintSettings_Init(settings: PJPH_SliderConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a SliderConstraint. }

function JPH_SliderConstraint_Create(settings: PJPH_SliderConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_SliderConstraint; cdecl; external JOLT_LIB;
  { Initializes ConeConstraintSettings. }
procedure JPH_ConeConstraintSettings_Init(settings: PJPH_ConeConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a ConeConstraint. }

function JPH_ConeConstraint_Create(settings: PJPH_ConeConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_ConeConstraint; cdecl; external JOLT_LIB;
  { Initializes SwingTwistConstraintSettings (used for ragdoll joints). }
procedure JPH_SwingTwistConstraintSettings_Init(settings: PJPH_SwingTwistConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a SwingTwistConstraint. }

function JPH_SwingTwistConstraint_Create(settings: PJPH_SwingTwistConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_SwingTwistConstraint; cdecl; external JOLT_LIB;
  { Initializes SixDOFConstraintSettings. }
procedure JPH_SixDOFConstraintSettings_Init(settings: PJPH_SixDOFConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a SixDOFConstraint. }

function JPH_SixDOFConstraint_Create(settings: PJPH_SixDOFConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_SixDOFConstraint; cdecl; external JOLT_LIB;
  { Initializes GearConstraintSettings. }
procedure JPH_GearConstraintSettings_Init(settings: PJPH_GearConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a GearConstraint. }

function JPH_GearConstraint_Create(settings: PJPH_GearConstraintSettings; body1: JPH_Body; body2: JPH_Body): JPH_GearConstraint; cdecl; external JOLT_LIB;
  { Destroys a constraint and frees its memory. }
procedure JPH_Constraint_Destroy(constraint: JPH_Constraint); cdecl; external JOLT_LIB;
  // -- Characters (Kinematic Character Controllers) --
  { Initializes settings for a rigid Character. }
procedure JPH_CharacterSettings_Init(settings: PJPH_CharacterSettings); cdecl; external JOLT_LIB;
  { Creates a rigid Character. }

function JPH_Character_Create(settings: PJPH_CharacterSettings; position: PJPH_RVec3; rotation: PJPH_Quat; userData: UInt64; system: JPH_PhysicsSystem): JPH_Character; cdecl; external JOLT_LIB;
  { Adds the character to the world. }

procedure JPH_Character_AddToPhysicsSystem(character: JPH_Character; activationMode: JPH_Activation; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Removes the character from the world. }

procedure JPH_Character_RemoveFromPhysicsSystem(character: JPH_Character; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Updates character state after simulation (checks ground, etc.). Call after PhysicsSystem_Update. }

procedure JPH_Character_PostSimulation(character: JPH_Character; maxSeparationDistance: Single; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Gets the character position. }

procedure JPH_Character_GetPosition(character: JPH_Character; position: PJPH_RVec3; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Sets the character position. }

procedure JPH_Character_SetPosition(character: JPH_Character; position: PJPH_RVec3; activationMode: JPH_Activation; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Gets the character rotation. }

procedure JPH_Character_GetRotation(character: JPH_Character; rotation: PJPH_Quat; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Sets the character rotation. }

procedure JPH_Character_SetRotation(character: JPH_Character; rotation: PJPH_Quat; activationMode: JPH_Activation; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  { Initializes settings for a Virtual Character (does not push bodies by default). }
procedure JPH_CharacterVirtualSettings_Init(settings: PJPH_CharacterVirtualSettings); cdecl; external JOLT_LIB;
  { Creates a Virtual Character. }

function JPH_CharacterVirtual_Create(settings: PJPH_CharacterVirtualSettings; position: PJPH_RVec3; rotation: PJPH_Quat; userData: UInt64; system: JPH_PhysicsSystem): JPH_CharacterVirtual; cdecl; external JOLT_LIB;
  { Updates the Virtual Character, resolving collisions. }

procedure JPH_CharacterVirtual_Update(character: JPH_CharacterVirtual; deltaTime: Single; layer: JPH_ObjectLayer; system: JPH_PhysicsSystem; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter); cdecl; external JOLT_LIB;
  { Extended update for Virtual Character with stair walking and floor sticking. }

procedure JPH_CharacterVirtual_ExtendedUpdate(character: JPH_CharacterVirtual; deltaTime: Single; settings: PJPH_ExtendedUpdateSettings; layer: JPH_ObjectLayer; system: JPH_PhysicsSystem; bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter); cdecl; external JOLT_LIB;
  // -- Skeleton & Ragdoll --
  { Creates a Skeleton (hierarchy of joints for ragdolls). }
function JPH_Skeleton_Create: JPH_Skeleton; cdecl; external JOLT_LIB;
  { Destroys a Skeleton. }

procedure JPH_Skeleton_Destroy(skeleton: JPH_Skeleton); cdecl; external JOLT_LIB;
  { Adds a joint to the skeleton. }

function JPH_Skeleton_AddJoint(skeleton: JPH_Skeleton; name: PAnsiChar): UInt32; cdecl; external JOLT_LIB;
  { Creates a SkeletonPose to store current joint transformations. }

function JPH_SkeletonPose_Create: JPH_SkeletonPose; cdecl; external JOLT_LIB;
  { Links a Skeleton to a SkeletonPose. }

procedure JPH_SkeletonPose_SetSkeleton(pose: JPH_SkeletonPose; skeleton: JPH_Skeleton); cdecl; external JOLT_LIB;
  { Gets the local matrix of a specific joint. }

procedure JPH_SkeletonPose_GetJointMatrix(pose: JPH_SkeletonPose; index: Int32; result: PJPH_Mat4); cdecl; external JOLT_LIB;
  { Creates settings for a Ragdoll. }

function JPH_RagdollSettings_Create: JPH_RagdollSettings; cdecl; external JOLT_LIB;
  { Instantiates a Ragdoll from settings and adds it to the world. }

function JPH_RagdollSettings_CreateRagdoll(settings: JPH_RagdollSettings; system: JPH_PhysicsSystem; collisionGroup: JPH_CollisionGroupID; userData: UInt64): JPH_Ragdoll; cdecl; external JOLT_LIB;
  { Adds a Ragdoll to the physics system. }

procedure JPH_Ragdoll_AddToPhysicsSystem(ragdoll: JPH_Ragdoll; activationMode: JPH_Activation; lockBodies: JPH_Bool); cdecl; external JOLT_LIB;
  // -- Vehicle System --
  { Initializes VehicleConstraintSettings. }
procedure JPH_VehicleConstraintSettings_Init(settings: PJPH_VehicleConstraintSettings); cdecl; external JOLT_LIB;
  { Creates a VehicleConstraint (attaches to a body to make it a vehicle). }

function JPH_VehicleConstraint_Create(body: JPH_Body; settings: PJPH_VehicleConstraintSettings): JPH_VehicleConstraint; cdecl; external JOLT_LIB;
  { Sets the collision tester for vehicle wheels. }

procedure JPH_VehicleConstraint_SetVehicleCollisionTester(constraint: JPH_VehicleConstraint; tester: JPH_VehicleCollisionTester); cdecl; external JOLT_LIB;
  { Creates a Ray-based collision tester for wheels. }

function JPH_VehicleCollisionTesterRay_Create(layer: JPH_ObjectLayer; up: PJPH_Vec3; maxSlopeAngle: Single): JPH_VehicleCollisionTesterRay; cdecl; external JOLT_LIB;
  { Creates settings for a Wheeled Vehicle Controller. }

function JPH_WheeledVehicleControllerSettings_Create: JPH_WheeledVehicleControllerSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Tracked Vehicle Controller (tanks). }

function JPH_TrackedVehicleControllerSettings_Create: JPH_TrackedVehicleControllerSettings; cdecl; external JOLT_LIB;
  { Creates settings for a Motorcycle Controller. }

function JPH_MotorcycleControllerSettings_Create: JPH_MotorcycleControllerSettings; cdecl; external JOLT_LIB;
  { Sets driver input for a wheeled vehicle (forward, right, brake, handbrake). }

procedure JPH_WheeledVehicleController_SetDriverInput(controller: JPH_WheeledVehicleController; forward: Single; right: Single; brake: Single; handBrake: Single); cdecl; external JOLT_LIB;
  { Sets driver input for a tracked vehicle (forward, left track ratio, right track ratio, brake). }

procedure JPH_TrackedVehicleController_SetDriverInput(controller: JPH_TrackedVehicleController; forward: Single; leftRatio: Single; rightRatio: Single; brake: Single); cdecl; external JOLT_LIB;
  // -- Debug Renderer --
  { Sets global callbacks for the Debug Renderer. }
procedure JPH_DebugRenderer_SetProcs(procs: PJPH_DebugRenderer_Procs); cdecl; external JOLT_LIB;
  { Creates a Debug Renderer instance. }

function JPH_DebugRenderer_Create(userData: Pointer): JPH_DebugRenderer; cdecl; external JOLT_LIB;
  { Destroys the Debug Renderer. }

procedure JPH_DebugRenderer_Destroy(renderer: JPH_DebugRenderer); cdecl; external JOLT_LIB;
  { Draws a line. }

procedure JPH_DebugRenderer_DrawLine(renderer: JPH_DebugRenderer; fromPt: PJPH_RVec3; toPt: PJPH_RVec3; color: JPH_Color); cdecl; external JOLT_LIB;
  { Draws a wireframe box. }

procedure JPH_DebugRenderer_DrawWireBox(renderer: JPH_DebugRenderer; box: PJPH_AABox; color: JPH_Color); cdecl; external JOLT_LIB;
  { Draws a marker (cross) at a position. }

procedure JPH_DebugRenderer_DrawMarker(renderer: JPH_DebugRenderer; position: PJPH_RVec3; color: JPH_Color; size: Single); cdecl; external JOLT_LIB;
  // -- Math Helpers ------------------------------------------------------------
  { Normalizes a 3D Vector. }
procedure JPH_Vec3_Normalize(v: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the length of a 3D Vector. }

function JPH_Vec3_Length(v: PJPH_Vec3): Single; cdecl; external JOLT_LIB;
  { Gets the squared length of a 3D Vector (faster than Length). }

function JPH_Vec3_LengthSquared(v: PJPH_Vec3): Single; cdecl; external JOLT_LIB;
  { Calculates the cross product of two 3D Vectors. }

procedure JPH_Vec3_Cross(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Calculates the dot product of two 3D Vectors. }

procedure JPH_Vec3_DotProduct(v1: PJPH_Vec3; v2: PJPH_Vec3; result: PSingle); cdecl; external JOLT_LIB;
  { Multiplies two Quaternions. }

procedure JPH_Quat_Multiply(q1: PJPH_Quat; q2: PJPH_Quat; result: PJPH_Quat); cdecl; external JOLT_LIB;
  { Rotates a vector by a quaternion. }

procedure JPH_Quat_Rotate(quat: PJPH_Quat; vec: PJPH_Vec3; result: PJPH_Vec3); cdecl; external JOLT_LIB;
  { Gets the inverse of a quaternion. }

procedure JPH_Quat_Inversed(quat: PJPH_Quat; result: PJPH_Quat); cdecl; external JOLT_LIB;
  { Sets a 4x4 matrix to identity. }

procedure JPH_Mat4_Identity(result: PJPH_Mat4); cdecl; external JOLT_LIB;
  { Creates a 4x4 matrix from a rotation and translation. }

procedure JPH_Mat4_RotationTranslation(result: PJPH_Mat4; rotation: PJPH_Quat; translation: PJPH_Vec3); cdecl; external JOLT_LIB;
  // -- Materials ---------------------------------------------------------------
  { Creates a physics material with a name and debug color. }
function JPH_PhysicsMaterial_Create(name: PAnsiChar; color: UInt32): JPH_PhysicsMaterial; cdecl; external JOLT_LIB;
  { Destroys a physics material. }

procedure JPH_PhysicsMaterial_Destroy(material: JPH_PhysicsMaterial); cdecl; external JOLT_LIB;

implementation

end.


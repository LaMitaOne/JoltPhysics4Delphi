unit JoltPhysics;

{==============================================================================*
 *  JoltPhysics - Delphi Wrapper for Jolt Physics C API
 *------------------------------------------------------------------------------
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

  // Default convex radius used by Jolt for collision shapes.
  JPH_DEFAULT_CONVEX_RADIUS = 0.05;

  // Upper bounds for the internal job system allocation pools.
  JPH_MAX_PHYSICS_JOBS    = 2048;
  JPH_MAX_PHYSICS_BARRIERS = 8;

type
  // ---------------------------------------------------------------------------
  //  Primitive typedefs mirroring the C API
  // ---------------------------------------------------------------------------
  JPH_Bool               = UInt32;   // 32-bit boolean (C _Bool / int)
  JPH_BodyID             = UInt32;   // Unique identifier for a body
  JPH_SubShapeID         = UInt32;   // Identifies a sub-part of a compound shape
  JPH_ObjectLayer        = UInt32;   // User-defined collision layer
  JPH_BroadPhaseLayer    = Byte;     // Broad-phase bucket a layer belongs to
  JPH_CollisionGroupID   = UInt32;   // Collision group id
  JPH_CollisionSubGroupID = UInt32;  // Collision sub group id
  JPH_CharacterID        = UInt32;   // Virtual character id
  JPH_Color              = UInt32;   // Debug-rendering color (0xRRGGBBAA)

  // ---------------------------------------------------------------------------
  //  Opaque handle types - all are plain pointers on the Delphi side.
  //  They are declared as distinct types so the compiler can distinguish them.
  // ---------------------------------------------------------------------------
  JPH_PhysicsSystem               = type Pointer;
  JPH_BodyInterface               = type Pointer;
  JPH_Body                        = type Pointer;
  JPH_BodyLockInterface           = type Pointer;
  JPH_JobSystem                   = type Pointer;
  JPH_TempAllocator               = type Pointer;
  JPH_BroadPhaseLayerInterface    = type Pointer;
  JPH_ObjectLayerPairFilter      = type Pointer;
  JPH_ObjectVsBroadPhaseLayerFilter = type Pointer;
  JPH_NarrowPhaseQuery            = type Pointer;
  JPH_Shape                       = type Pointer;
  JPH_ShapeSettings               = type Pointer;
  JPH_BoxShapeSettings            = type Pointer;
  JPH_SphereShapeSettings         = type Pointer;
  JPH_CapsuleShapeSettings        = type Pointer;
  JPH_CylinderShapeSettings       = type Pointer;
  JPH_BodyCreationSettings        = type Pointer;
  JPH_BroadPhaseLayerFilter       = type Pointer;
  JPH_ObjectLayerFilter           = type Pointer;
  JPH_BodyFilter                  = type Pointer;
  JPH_ShapeFilter                 = type Pointer;

  // ---------------------------------------------------------------------------
  //  Math types - must match the memory layout of the C structs exactly.
  //  All of them are plain-value records and can be passed by pointer.
  // ---------------------------------------------------------------------------
  PJPH_Vec3 = ^JPH_Vec3;
  JPH_Vec3 = record
    x, y, z: Single;
  end;

  PJPH_Vec4 = ^JPH_Vec4;
  JPH_Vec4 = record
    x, y, z, w: Single;
  end;

  PJPH_Quat = ^JPH_Quat;
  JPH_Quat = record
    x, y, z, w: Single;
  end;

  PJPH_Mat44 = ^JPH_Mat44;
  JPH_Mat44 = record
    column: array[0..3] of JPH_Vec4;
  end;

  // Double-precision Vec3 - here aliased to single precision. If you need
  // real double-precision coordinates enable the corresponding Jolt build
  // and replace Single with Double in JPH_RVec3 / JPH_Vec3.
  JPH_RVec3  = JPH_Vec3;
  PJPH_RVec3 = ^JPH_RVec3;

  // ---------------------------------------------------------------------------
  //  Callback vtables - these are struct-of-function-pointers matching the
  //  C API. Each field must point to a cdecl callback whose signature is
  //  compatible with the corresponding C function pointer.
  //  Implement these in Delphi using `cdecl` and assign them before passing
  //  the struct to the *_Create calls.
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

  // Result code returned by JPH_PhysicsSystem_Update2.
  // 0 means no error, any combination of the bits below indicates a problem
  // during the physics step (see JoltPhysics.h for exact semantics).
  JPH_PhysicsUpdateError = type UInt32;

const
  JPH_PhysicsUpdateError_None = 0;

type
  // Motion properties of a body. Determines how the body is integrated.
  //   Static    - never moves, infinite mass
  //   Kinematic - moved explicitly by the user, unaffected by forces
  //   Dynamic   - fully simulated by the physics solver
  JPH_MotionType = type UInt32;

const
  JPH_MotionType_Static    = 0;
  JPH_MotionType_Kinematic = 1;
  JPH_MotionType_Dynamic   = 2;

type
  // Activation mode used when adding/moving bodies.
  JPH_Activation = type UInt32;

const
  JPH_Activation_Activate     = 0;
  JPH_Activation_DontActivate = 1;

type
  // How to handle mass properties when creating a body.
  JPH_OverrideMassProperties = type UInt32;

const
  JPH_OverrideMassProperties_CalculateMassAndInertia = 0;

type
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

  // Result of a successful ray cast.
  PJPH_RayCastResult = ^JPH_RayCastResult;
  JPH_RayCastResult = record
    bodyID: JPH_BodyID;       // Body that was hit
    fraction: Single;         // Distance along the ray as a fraction [0..1]
    subShapeID2: JPH_SubShapeID; // Sub-shape of the body that was hit
  end;

// =============================================================================
//  API Functions
//  All functions are cdecl and imported from JoltC.dll.
//  Ownership rules:
//    - Every *_Create call that returns a heap-allocated handle must be paired
//      with the matching *_Destroy call to avoid leaks.
//    - Shapes returned by *_CreateShape are reference-counted by the engine;
//      do not free them manually unless you also call the corresponding
//      Release function (not yet wrapped here).
// =============================================================================

// -- Lifecycle ---------------------------------------------------------------
function  JPH_Init: JPH_Bool; cdecl; external JOLT_LIB;
procedure JPH_Shutdown; cdecl; external JOLT_LIB;

// -- BroadPhaseLayerInterface (mask-based default implementation) -------------
function  JPH_BroadPhaseLayerInterfaceMask_Create(numBroadPhaseLayers: UInt32): JPH_BroadPhaseLayerInterface; cdecl; external JOLT_LIB;
procedure JPH_BroadPhaseLayerInterface_Destroy(bpInterface: JPH_BroadPhaseLayerInterface); cdecl; external JOLT_LIB;

// -- ObjectLayerPairFilter (mask-based default implementation) ---------------
function  JPH_ObjectLayerPairFilterMask_Create: JPH_ObjectLayerPairFilter; cdecl; external JOLT_LIB;
procedure JPH_ObjectLayerPairFilter_Destroy(filter: JPH_ObjectLayerPairFilter); cdecl; external JOLT_LIB;

// Helper to build an ObjectLayer value from a (group, mask) pair.
function  JPH_ObjectLayerPairFilterMask_GetObjectLayer(group: UInt32; mask: UInt32): JPH_ObjectLayer; cdecl; external JOLT_LIB;

// -- ObjectVsBroadPhaseLayerFilter (mask-based default implementation) --------
function  JPH_ObjectVsBroadPhaseLayerFilterMask_Create(broadPhaseLayerInterface: JPH_BroadPhaseLayerInterface): JPH_ObjectVsBroadPhaseLayerFilter; cdecl; external JOLT_LIB;
procedure JPH_ObjectVsBroadPhaseLayerFilter_Destroy(filter: JPH_ObjectVsBroadPhaseLayerFilter); cdecl; external JOLT_LIB;

// -- Custom filter wrappers (callback-based) ----------------------------------
//  Each Create() takes a userData pointer and a vtable of callbacks.
//  The userData pointer is forwarded to every callback invocation.
function  JPH_BroadPhaseLayerFilter_Create(userData: Pointer; procs: PJPH_BroadPhaseLayerFilter_Procs): JPH_BroadPhaseLayerFilter; cdecl; external JOLT_LIB;
procedure JPH_BroadPhaseLayerFilter_Destroy(filter: JPH_BroadPhaseLayerFilter); cdecl; external JOLT_LIB;

function  JPH_ObjectLayerFilter_Create(userData: Pointer; procs: PJPH_ObjectLayerFilter_Procs): JPH_ObjectLayerFilter; cdecl; external JOLT_LIB;
procedure JPH_ObjectLayerFilter_Destroy(filter: JPH_ObjectLayerFilter); cdecl; external JOLT_LIB;

function  JPH_BodyFilter_Create(userData: Pointer; procs: PJPH_BodyFilter_Procs): JPH_BodyFilter; cdecl; external JOLT_LIB;
procedure JPH_BodyFilter_Destroy(filter: JPH_BodyFilter); cdecl; external JOLT_LIB;

function  JPH_ShapeFilter_Create(userData: Pointer; procs: PJPH_ShapeFilter_Procs): JPH_ShapeFilter; cdecl; external JOLT_LIB;
procedure JPH_ShapeFilter_Destroy(filter: JPH_ShapeFilter); cdecl; external JOLT_LIB;

// -- PhysicsSystem -----------------------------------------------------------
function  JPH_PhysicsSystem_Create(settings: PJPH_PhysicsSystemSettings): JPH_PhysicsSystem; cdecl; external JOLT_LIB;
procedure JPH_PhysicsSystem_Destroy(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

// Rebuilds the broad-phase structures. Call after adding/removing many bodies
// at once or after a large batch of body additions.
procedure JPH_PhysicsSystem_OptimizeBroadPhase(system: JPH_PhysicsSystem); cdecl; external JOLT_LIB;

// Advance the simulation by deltaTime seconds.
//  deltaTime        : step length in seconds (e.g. 1/60)
//  collisionSteps   : number of discrete collision sub-steps (>=1)
//  tempAllocator    : allocator used for transient memory during the step
//  jobSystem        : thread-pool used for parallel simulation
function  JPH_PhysicsSystem_Update2(system: JPH_PhysicsSystem; deltaTime: Single; collisionSteps: Integer; tempAllocator: JPH_TempAllocator; jobSystem: JPH_JobSystem): JPH_PhysicsUpdateError; cdecl; external JOLT_LIB;

procedure JPH_PhysicsSystem_SetGravity(system: JPH_PhysicsSystem; value: PJPH_Vec3); cdecl; external JOLT_LIB;

// Returns the non-locking body interface. For multi-threaded access use the
// locking variant (not yet wrapped here).
function  JPH_PhysicsSystem_GetBodyInterface(system: JPH_PhysicsSystem): JPH_BodyInterface; cdecl; external JOLT_LIB;
function  JPH_PhysicsSystem_GetNarrowPhaseQuery(system: JPH_PhysicsSystem): JPH_NarrowPhaseQuery; cdecl; external JOLT_LIB;

// -- JobSystem / TempAllocator ------------------------------------------------
function  JPH_JobSystemThreadPool_Create(config: PJobSystemThreadPoolConfig): JPH_JobSystem; cdecl; external JOLT_LIB;
procedure JPH_JobSystem_Destroy(jobSystem: JPH_JobSystem); cdecl; external JOLT_LIB;

// Uses malloc internally. For production use a JPH_TempAllocatorImpl with a
// pre-allocated block (not yet wrapped here) for better performance.
function  JPH_TempAllocatorMalloc_Create: JPH_TempAllocator; cdecl; external JOLT_LIB;
procedure JPH_TempAllocator_Destroy(allocator: JPH_TempAllocator); cdecl; external JOLT_LIB;

// -- Body creation -----------------------------------------------------------
// Create3 builds a JPH_BodyCreationSettings from a shape, transform and
// motion type. Pass the result to JPH_BodyInterface_CreateAndAddBody to add
// the body to the world.
function  JPH_BodyCreationSettings_Create3(shape: JPH_Shape; position: PJPH_RVec3; rotation: PJPH_Quat; motionType: JPH_MotionType; objectLayer: JPH_ObjectLayer): JPH_BodyCreationSettings; cdecl; external JOLT_LIB;

// Returns the BodyID of the newly added body. Store it for later lookups.
function  JPH_BodyInterface_CreateAndAddBody(bodyInterface: JPH_BodyInterface; settings: JPH_BodyCreationSettings; activationMode: JPH_Activation): JPH_BodyID; cdecl; external JOLT_LIB;

// Removes the body from the world and destroys the underlying body object.
procedure JPH_BodyInterface_RemoveAndDestroyBody(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID); cdecl; external JOLT_LIB;

// -- Body transform ----------------------------------------------------------
procedure JPH_BodyInterface_SetPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_RVec3; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
procedure JPH_BodyInterface_GetCenterOfMassPosition(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; position: PJPH_Vec3); cdecl; external JOLT_LIB;
procedure JPH_BodyInterface_SetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat; activationMode: JPH_Activation); cdecl; external JOLT_LIB;
procedure JPH_BodyInterface_GetRotation(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; rotation: PJPH_Quat); cdecl; external JOLT_LIB;

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
function  JPH_BodyInterface_GetFriction(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;
procedure JPH_BodyInterface_SetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID; restitution: Single); cdecl; external JOLT_LIB;
function  JPH_BodyInterface_GetRestitution(bodyInterface: JPH_BodyInterface; bodyID: JPH_BodyID): Single; cdecl; external JOLT_LIB;

// -- Ray casting --------------------------------------------------------------
//  Casts a ray from `origin` in `direction` (not necessarily normalized).
//  Returns 1 if a hit was found and writes the result to `hit`, otherwise 0.
//  Filters can be set to nil to use the default "everything passes" filters.
function  JPH_NarrowPhaseQuery_CastRay(
  query: JPH_NarrowPhaseQuery; origin: PJPH_RVec3; direction: PJPH_Vec3; hit: PJPH_RayCastResult;
  broadPhaseLayerFilter: JPH_BroadPhaseLayerFilter; objectLayerFilter: JPH_ObjectLayerFilter;
  bodyFilter: JPH_BodyFilter; shapeFilter: JPH_ShapeFilter
): Byte; cdecl; external JOLT_LIB;

// -- Shape settings (builders for convex shapes) -----------------------------
//  Each *ShapeSettings_Create returns a settings object that owns internal
//  validation data. Call the corresponding *_CreateShape to obtain the actual
//  JPH_Shape, then destroy the settings object with JPH_ShapeSettings_Destroy.
//  Shapes themselves are reference-counted inside Jolt.
function  JPH_BoxShapeSettings_Create(halfExtent: PJPH_Vec3; convexRadius: Single): JPH_BoxShapeSettings; cdecl; external JOLT_LIB;
function  JPH_SphereShapeSettings_Create(radius: Single): JPH_SphereShapeSettings; cdecl; external JOLT_LIB;
function  JPH_CapsuleShapeSettings_Create(halfHeightOfCylinder: Single; radius: Single): JPH_CapsuleShapeSettings; cdecl; external JOLT_LIB;
function  JPH_CylinderShapeSettings_Create(halfHeight: Single; radius: Single; convexRadius: Single): JPH_CylinderShapeSettings; cdecl; external JOLT_LIB;

function  JPH_BoxShapeSettings_CreateShape(settings: JPH_BoxShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;
function  JPH_SphereShapeSettings_CreateShape(settings: JPH_SphereShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;
function  JPH_CapsuleShapeSettings_CreateShape(settings: JPH_CapsuleShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;
function  JPH_CylinderShapeSettings_CreateShape(settings: JPH_CylinderShapeSettings): JPH_Shape; cdecl; external JOLT_LIB;

procedure JPH_ShapeSettings_Destroy(settings: JPH_ShapeSettings); cdecl; external JOLT_LIB;

implementation

end.

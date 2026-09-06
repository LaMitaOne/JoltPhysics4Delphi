# JoltPhysics4Delphi
A Delphi wrapper and object-oriented binding layer for the Jolt Physics high-performance rigid body physics engine. 
    
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/JoltPhysics4Delphi)    
     
<img width="1920" height="1080" alt="Unbenannt" src="https://github.com/user-attachments/assets/52e374ae-b7a0-47a3-8f95-42426f21bf20" />
       
This project provides a clean VCL-friendly implementation that bridges the native Jolt Physics C API with Raylib for 3D rendering. It allows you to run a fully multi-threaded physics simulation directly inside a Delphi application. 
           
   Status: Work in Progress (Alpha v0.3)     
   The original Jolt Physics C API contains over 3,000 lines of definitions. This wrapper currently covers a few hundred of the most essential lines. While not feature-complete, the core functionality is fully usable and highly stable.     
      
✨ Features    
    
     Core Physics System: World creation, gravity setup, broadphase optimization.
     Rigid Bodies: Static and Dynamic actors with full transform syncing (Position & Rotation).
     Collision Shapes: Box, Sphere, Capsule, and Cylinder primitives.
     Physics Interactions: Apply forces, impulses, and set linear/angular velocities.
     Raycasting: Built-in 3D raycasting from screen coordinates to the physics world.
     Optimization: Frustum & Distance Culling   
     Multi-threading: Utilizes Jolt's built-in thread pool and job system for maximum performance.
     VCL Integration: Includes a TRaylibSandbox component that embeds a Raylib 3D window inside a standard Delphi VCL form, running smoothly in a background thread.
     Shooting mechanic: Fire persistent blue cannonball projectiles using Spacebar with a cooldown to knock objects away.   
     Custom GLSL Lighting System implementing basic ambient and diffuse shading for the floor, walls, and actors.
     Dynamic Fake Shadows: Flat shadows drawn under objects that scale in size and opacity based on the object's height.
      
  Controls:    
      
   Left click drag and throw items    
   Right click camera rotation    
   WASD move camera
   Space shoot
   Mouse Wheel zoom in out     
      
📦 Project Structure    
    
The repository consists of three main units:    
    
    JoltPhysics.pas - The low-level header translation mapping the JoltC.dll C API to Delphi types and records.
    ModelEngine.pas - The Object-Oriented Delphi layer (TModelEngine, TModelActor) that manages the physics world and actors.
    RaylibSandbox.pas - A VCL TWinControl that runs a threaded Raylib window, handling 3D rendering, camera input, and user interaction (dragging bodies with the mouse).
        
🛠️ What's Missing? (Roadmap)     
      
Since the original C API is massive, there is still a lot to cover. Here is what is currently missing but planned for future updates:    
    
     Complete locking BodyInterface for safe multi-threaded access.
     Advanced Joint/Constraint systems (Hinges, Distance, etc.).
     Compound shapes (Mesh shapes, Convex Hulls).
     Collision callback events in Delphi.
     Custom memory allocators (currently using JPH_TempAllocatorMalloc).
     Character virtual controllers.

  Exe and sample project included    

  Latest Changes:    
      
  v0.3:     
  
  JoltPhysics:   
     
     Expanded Structs & Records: Added necessary records for advanced queries, including JPH_CollideShapeResult, JPH_ShapeCastResult, JPH_CollideShapeSettings, JPH_ShapeCastSettings, and JPH_RayCastSettings.    
     Constraint System: Implemented base structs (JPH_ConstraintSettings) and specific settings for Fixed, Point, Distance, Hinge, and Slider constraints. Added corresponding API functions for creation, destruction, and control (e.g., JPH_HingeConstraint_SetMotorState).     
     Complete Enum Constants: Added all missing enum values as constants (e.g., JPH_BodyType, JPH_ShapeSubType, JPH_AllowedDOFs, JPH_GroundState, JPH_MotorState, JPH_ConstraintSubType, etc.).     
     Listeners & Callbacks: Added vtable structs and API functions for JPH_ContactListener (collision events) and JPH_BodyActivationListener (sleep/wake events).     
     Extended Body Interface: Integrated many missing functions such as AddTorque, AddForce2 (with position parameter), AddAngularImpulse, combined getters/setters for velocities, and queries for Active-state, ObjectLayer, and UserData.     
     Additional Shapes: Added settings and creation functions for TaperedCapsule, TaperedCylinder, ConvexHull, StaticCompound, and MeshShape. Also added JPH_CompoundShapeSettings_AddShape for grouping shapes.    
     Math Helpers: Wrapped useful C-API math functions (JPH_Vec3_Cross, JPH_Vec3_Normalize, JPH_Quat_Rotate, JPH_Mat44_RotationTranslation, etc.).
     Material System: Added functions to create and destroy JPH_PhysicsMaterial.    
     Miscellaneous: Added JPH_PhysicsSystem_Update (without TempAllocator) and included the {$A+} compiler directive to ensure exact C/C++ struct alignment.   

 RaylibSandbox:     
     
     Shooting Mechanic (Projectiles): Added the ability to shoot dynamic physics spheres by pressing SPACE. Projectiles use a 250ms cooldown to prevent machine-gun fire.     
     Dynamic Fake Shadows: Implemented custom flat shadows (DrawFlatShadow / DrawCylinderEx) for the floor, walls, and all actors. Shadow radius and alpha opacity scale dynamically based on the object's Y-height to simulate realistic light scattering.    
     Camera Panning & Bounds: Added WASD and Arrow Key panning. Camera movement is now clamped to world bounds (-80 to +80) to prevent the user from scrolling infinitely into the void.    
     Custom Lighting System: Implemented a custom GLSL shader for basic ambient and diffuse lighting that affects the floor, walls, and objects, giving the scene proper depth.     
     CCD (Continuous Collision Detection): Projectiles use JPH_MotionQuality_LinearCast to prevent fast-moving spheres from tunneling through walls or objects.    
     Z-Fighting Fix: Enabled rlEnableDepthTest() for custom shadow drawing to prevent them from flickering or being hidden behind the wallpaper texture.   
     Sphere Clipping Fix: Applied a manual Y-offset (+0.3 for spheres) during rendering to visually lift them out of the floor, bypassing Jolt's internal convex radius penetration.   
     Raylib DrawSphere Workaround: Implemented manual matrix scaling (rlScalef) because Raylib's DrawSphere ignores the radius parameter when drawing inside a manually pushed rotation matrix.    
     Memory Initialization: Used FillChar for TItemData upon spawn to prevent random memory garbage from causing projectiles to render incorrectly.    
      
  v0.2:     
  
     True 3D Rotation: Implemented proper quaternion-based rotation and transform matrices (Scale * Rotation * Translation) so objects now visually roll and tumble correctly.
     Pyramid Shape: Added stPyramid (simulated via a 4-sided Jolt cylinder) with a slight spawn offset to prevent perfect balancing.
     Frustum & Distance Culling: Optimized the 3D renderer to skip drawing objects that are out of camera view or beyond a set distance limit.
     Custom Spawn Transforms: TModelActor.Create now accepts optional initial position (APos) and rotation (ARot) parameters for dynamic spawning.
     Dynamic Glow State: Moved collision glow logic into a TealGlow property on the actor, triggered by velocity thresholds for cleaner rendering logic.
     Selection Highlighting: Dynamically selected objects are now rendered with a yellow wireframe overlay for clear visual feedback.
     Code Cleanup: Renamed cube-specific variables to generic item names (FItems, PItemData) to reflect support for multiple shape types.    
       
 Based on JoltC from https://github.com/amerkoleci/joltc    
    
 ModelEngine based on  https://github.com/GuvaCode/raylib-TPS-prototype    
     

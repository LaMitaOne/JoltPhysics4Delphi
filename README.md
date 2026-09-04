# JoltPhysics4Delphi
A Delphi wrapper and object-oriented binding layer for the Jolt Physics high-performance rigid body physics engine. 
    
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/JoltPhysics4Delphi)    
     
<img width="1920" height="1080" alt="Unbenannt" src="https://github.com/user-attachments/assets/cd5949ff-cd02-4d50-b4f9-7ff2aefe2313" />
Hundreds in movement sometimes and still almost cant get it under 60fps on ryzen4500u igpu vega...    
    
This project provides a clean VCL-friendly implementation that bridges the native Jolt Physics C API with Raylib for 3D rendering. It allows you to run a fully multi-threaded physics simulation directly inside a Delphi application. 
           
   Status: Work in Progress (Alpha)     
   The original Jolt Physics C API contains over 3,000 lines of definitions. This wrapper currently covers a few hundred of the most essential lines. While not feature-complete, the core functionality is fully usable and highly stable.     
      
✨ Features    
    
     Core Physics System: World creation, gravity setup, broadphase optimization.
     Rigid Bodies: Static and Dynamic actors with full transform syncing (Position & Rotation).
     Collision Shapes: Box, Sphere, Capsule, and Cylinder primitives.
     Physics Interactions: Apply forces, impulses, and set linear/angular velocities.
     Raycasting: Built-in 3D raycasting from screen coordinates to the physics world.
     Multi-threading: Utilizes Jolt's built-in thread pool and job system for maximum performance.
     VCL Integration: Includes a TRaylibSandbox component that embeds a Raylib 3D window inside a standard Delphi VCL form, running smoothly in a background thread.
    
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
   
 Based on JoltC from https://github.com/amerkoleci/joltc    
    
 ModelEngine based on  https://github.com/GuvaCode/raylib-TPS-prototype    
     

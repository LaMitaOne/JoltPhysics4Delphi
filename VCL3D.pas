unit VCL3D;

{==============================================================================*
 *  VCL3D v0.60 - High-Level Spawning Utilities for TRaylibSandbox
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
 *
 *  Description:
 *    Provides high-level, ready-to-use spawning routines for the 3D Engine.
 *    This unit acts as a bridge between the VCL UI controls and the thread-safe
 *    spawn queue inside TRaylibSandbox, preventing race conditions with Jolt.
 *==============================================================================}

interface

uses
  System.SysUtils, System.Classes, Raylib, RaylibSandbox, ModelEngine;

type
  TVCL3D = class
  private
  public
    { Spawns 4 solid, static walls to create a closed sandbox environment }
    class procedure SpawnSandbox(Sandbox: TRaylibSandbox);

    { Spawns a grid of blocks sequentially to build a realistic wall }
    class procedure SpawnDynamicWall(Sandbox: TRaylibSandbox; Width, Height: Integer; SpawnFalling: Boolean = True; SpawnBomb: Boolean = False);

    { Spawns a 3D UI Button with OnClick Event }
    class procedure SpawnButton(Sandbox: TRaylibSandbox; const ACaption: string; APos, ASize: TVector3; AOnClick: TNotifyEvent);
  end;

implementation
{ TVCL3D }


class procedure TVCL3D.SpawnSandbox(Sandbox: TRaylibSandbox);
var
  Req: TSpawnRequest;
begin
  if not Assigned(Sandbox) then
    Exit;

  // Prevent spawning the sandbox multiple times
  if Sandbox.FSandboxSpawned then
    Exit;

  Sandbox.FSandboxSpawned := True;

  // Configure the request for solid, static walls
  Req.Shape := stBox;
  Req.IsStatic := True; // Static bodies won't fall over or be affected by physics
  Req.Color := Fade(DARKGRAY, 0.9);

  // Back Wall
  Req.Size := Vector3Create(100, 20, 1);
  Req.Pos := Vector3Create(0, 10, -50);
  Req.Name := 'Sandbox_Wall_Back';
  Sandbox.QueueCustomSpawn(Req);

  // Front Wall
  Req.Pos := Vector3Create(0, 10, 50);
  Req.Name := 'Sandbox_Wall_Front';
  Sandbox.QueueCustomSpawn(Req);

  // Left Wall
  Req.Size := Vector3Create(1, 20, 100);
  Req.Pos := Vector3Create(-50, 10, 0);
  Req.Name := 'Sandbox_Wall_Left';
  Sandbox.QueueCustomSpawn(Req);

  // Right Wall
  Req.Pos := Vector3Create(50, 10, 0);
  Req.Name := 'Sandbox_Wall_Right';
  Sandbox.QueueCustomSpawn(Req);
end;

class procedure TVCL3D.SpawnDynamicWall(Sandbox: TRaylibSandbox; Width, Height: Integer; SpawnFalling: Boolean = True; SpawnBomb: Boolean = False);
var
  Req: TSpawnRequest;
  x, y: Integer;
  BrickSize, HalfWidth, SpawnHeight: Single;
  RandX, RandZ, RandY: Single;
begin
  if not Assigned(Sandbox) then
    Exit;
  if Width < 1 then
    Width := 1;
  if Height < 1 then
    Height := 1;

  BrickSize := 2.0; // 2x2x2 blocks
  HalfWidth := (Width - 1) * BrickSize * 0.5;

  // If static, we don't need a spawn height, they can just be placed directly
  if not SpawnFalling then
    SpawnHeight := 0.0
  else
    SpawnHeight := 15.0; // Height from which they fall

  Req.Shape := stBox;
  Req.Size := Vector3Create(BrickSize, BrickSize, BrickSize);
  Req.IsStatic := False; // Always dynamic so the bomb can destroy them!
  Req.Color := MAROON;

  // Strict sequential order: Left to Right, Bottom to Top (like a real bricklayer)
  for y := 0 to Height - 1 do
  begin
    for x := 0 to Width - 1 do
    begin
      if SpawnFalling then
      begin
        RandX := (System.Random - 0.5) * 0.4;
        RandZ := (System.Random - 0.5) * 0.4;
        RandY := System.Random * 2.0;
      end
      else
      begin
        // Perfect placement: RandY=1.0 so the bottom row sits exactly on the ground (Y=0)
        RandX := 0.0;
        RandY := 1.0;
        RandZ := 0.0;
      end;

      Req.Pos := Vector3Create(-HalfWidth + (x * BrickSize) + RandX, (y * BrickSize) + SpawnHeight + RandY, 0 + RandZ);

      // Set timer: The last block gets the bomb!
      if SpawnBomb and (y = Height - 1) and (x = Width - 1) then
        Req.Name := 'BOMB_TRIGGER'
      else
        Req.Name := 'WallBlock_' + IntToStr(x) + '_' + IntToStr(y);

      Sandbox.QueueCustomSpawn(Req);
    end;
  end;
end;

class procedure TVCL3D.SpawnButton(Sandbox: TRaylibSandbox; const ACaption: string; APos, ASize: TVector3; AOnClick: TNotifyEvent);
var
  Req: TSpawnRequest;
begin
  if not Assigned(Sandbox) then
    Exit;

  // Configure the spawn request for a static UI button
  Req.Shape := stButton;
  Req.Pos := APos;
  Req.Size := ASize;
  Req.IsStatic := True; // Buttons shouldn't fall via gravity
  Req.Name := 'UI_Button_' + ACaption;

  // Default Colors (Standard VCL Blue-ish)
  Req.Color := BLUE;
  Req.BaseColor := GRAY;
  Req.HoverColor := SKYBLUE;

  Req.Caption := ACaption;
  Req.OnClick := AOnClick;

  Sandbox.QueueCustomSpawn(Req);
end;

end.


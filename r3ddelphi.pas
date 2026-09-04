unit r3ddelphi;
{==============================================================================*
 *  r3d version 0.9 - Pascal header for Delphi / RAD Studio                     *
 *  Combined from ray4laz-FPC-Header (2025-2026 Gunko Vadim @guvacode)          *
 *  Original C code r3d by Le Juez Victor:  https://github.com/Bigfoot71/r3d    *
 *                                                                              *
 *  This software is provided "as-is", without any express or implied warranty. *
 *  In no event will the authors be held liable for any damages arising from    *
 *  the use of this software.                                                   *
 *                                                                              *
 *  Permission is granted to anyone to use this software for any purpose,       *
 *  including commercial applications, and to alter it and redistribute it      *
 *  freely, subject to the following restrictions:                              *
 *   1. The origin of this software must not be misrepresented; you must not    *
 *      claim that you wrote the original software. If you use this software    *
 *      in a product, an acknowledgment in the product documentation would be   *
 *      appreciated but is not required.                                        *
 *   2. Altered source versions must be plainly marked as such, and must not    *
 *      be misrepresented as being the original software.                       *
 *   3. This notice may not be removed or altered from any source distribution. *
 *                                                                              *
 *==============================================================================}

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$MINENUMSIZE 4}

interface

uses
  SysUtils, Math, Raylib;

const
  {$IFDEF MSWINDOWS}
  R3D_DLLNAME = 'libr3d.dll';        // <-- Adjust to your DLL name if different!
  {$ENDIF}
  {$IFDEF LINUX}
  R3D_DLLNAME = 'libr3d.so';
  {$ENDIF}
  {$IFDEF MACOS}
  R3D_DLLNAME = 'libr3d.dylib';
  {$ENDIF}

{ Uncomment if the DLL exports the visibility functions
  (in the original FPC module this was disabled): }
{.$DEFINE R3D_INCLUDE_VISIBILITY}

type
  PUInt32 = ^UInt32;

// ============================== r3d_core.inc ==============================

type
  TR3D_Hint = (
    R3D_HINT_MESH_VERTEX_BUFFER_CAPACITY,
    R3D_HINT_MESH_INDEX_BUFFER_CAPACITY,
    R3D_HINT_MESH_STREAMING_CAPACITY,
    R3D_HINT_DRAW_CALL_CAPACITY,
    R3D_HINT_FORWARD_LIGHT_PER_MESH,
    R3D_HINT_PROBE_MAX_ACTIVE,
    R3D_HINT_PROBE_CAPTURE_SIZE,
    R3D_HINT_SHADOW_DIR_SIZE,
    R3D_HINT_SHADOW_SPOT_SIZE,
    R3D_HINT_SHADOW_OMNI_SIZE,
    R3D_HINT_IBL_IRRADIANCE_SIZE,
    R3D_HINT_IBL_PREFILTER_SIZE,
    R3D_HINT_COUNT
  );

  TR3D_AntiAliasingMode = (R3D_ANTI_ALIASING_MODE_NONE, R3D_ANTI_ALIASING_MODE_FXAA, R3D_ANTI_ALIASING_MODE_SMAA);
  TR3D_AntiAliasingPreset = (R3D_ANTI_ALIASING_PRESET_LOW, R3D_ANTI_ALIASING_PRESET_MEDIUM, R3D_ANTI_ALIASING_PRESET_HIGH, R3D_ANTI_ALIASING_PRESET_ULTRA, R3D_ANTI_ALIASING_PRESET_COUNT);
  TR3D_AspectMode = (R3D_ASPECT_EXPAND, R3D_ASPECT_KEEP);
  TR3D_UpscaleMode = (R3D_UPSCALE_NEAREST, R3D_UPSCALE_LINEAR, R3D_UPSCALE_BICUBIC, R3D_UPSCALE_LANCZOS);
  TR3D_DownscaleMode = (R3D_DOWNSCALE_NEAREST, R3D_DOWNSCALE_LINEAR, R3D_DOWNSCALE_RGSS, R3D_DOWNSCALE_PDSS);
  TR3D_OutputMode = (R3D_OUTPUT_SCENE, R3D_OUTPUT_ALBEDO, R3D_OUTPUT_NORMAL, R3D_OUTPUT_ORM, R3D_OUTPUT_DIFFUSE,
    R3D_OUTPUT_SPECULAR, R3D_OUTPUT_SSAO, R3D_OUTPUT_SSIL, R3D_OUTPUT_SSGI, R3D_OUTPUT_SSR, R3D_OUTPUT_BLOOM, R3D_OUTPUT_DOF);
  TR3D_ColorSpace = (R3D_COLORSPACE_LINEAR, R3D_COLORSPACE_SRGB);

procedure R3D_SetHint(hint: TR3D_Hint; value: Integer); cdecl; external R3D_DLLNAME name 'R3D_SetHint';
function R3D_GetHint(hint: TR3D_Hint): Integer; cdecl; external R3D_DLLNAME name 'R3D_GetHint';
function R3D_Init(resWidth, resHeight: Integer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_Init';
procedure R3D_Close; cdecl; external R3D_DLLNAME name 'R3D_Close';
procedure R3D_GetResolution(width, height: PInteger); cdecl; external R3D_DLLNAME name 'R3D_GetResolution';
procedure R3D_SetResolution(width, height: Integer); cdecl; external R3D_DLLNAME name 'R3D_SetResolution';
function R3D_GetAntiAliasingMode: TR3D_AntiAliasingMode; cdecl; external R3D_DLLNAME name 'R3D_GetAntiAliasingMode';
procedure R3D_SetAntiAliasingMode(mode: TR3D_AntiAliasingMode); cdecl; external R3D_DLLNAME name 'R3D_SetAntiAliasingMode';
function R3D_GetAntiAliasingPreset: TR3D_AntiAliasingPreset; cdecl; external R3D_DLLNAME name 'R3D_GetAntiAliasingPreset';
procedure R3D_SetAntiAliasingPreset(preset: TR3D_AntiAliasingPreset); cdecl; external R3D_DLLNAME name 'R3D_SetAntiAliasingPreset';
function R3D_GetAspectMode: TR3D_AspectMode; cdecl; external R3D_DLLNAME name 'R3D_GetAspectMode';
procedure R3D_SetAspectMode(mode: TR3D_AspectMode); cdecl; external R3D_DLLNAME name 'R3D_SetAspectMode';
function R3D_GetUpscaleMode: TR3D_UpscaleMode; cdecl; external R3D_DLLNAME name 'R3D_GetUpscaleMode';
procedure R3D_SetUpscaleMode(mode: TR3D_UpscaleMode); cdecl; external R3D_DLLNAME name 'R3D_SetUpscaleMode';
function R3D_GetDownscaleMode: TR3D_DownscaleMode; cdecl; external R3D_DLLNAME name 'R3D_GetDownscaleMode';
procedure R3D_SetDownscaleMode(mode: TR3D_DownscaleMode); cdecl; external R3D_DLLNAME name 'R3D_SetDownscaleMode';
function R3D_GetOutputMode: TR3D_OutputMode; cdecl; external R3D_DLLNAME name 'R3D_GetOutputMode';
procedure R3D_SetOutputMode(mode: TR3D_OutputMode); cdecl; external R3D_DLLNAME name 'R3D_SetOutputMode';
procedure R3D_SetTextureFilter(filter: TTextureFilter); cdecl; external R3D_DLLNAME name 'R3D_SetTextureFilter';
procedure R3D_SetTextureWrap(wrap: TTextureWrap); cdecl; external R3D_DLLNAME name 'R3D_SetTextureWrap';
procedure R3D_SetColorSpace(space: TR3D_ColorSpace); cdecl; external R3D_DLLNAME name 'R3D_SetColorSpace';

// ============================== r3d_camera.inc ==============================

type
  TR3D_Projection = (R3D_PROJECTION_PERSPECTIVE, R3D_PROJECTION_ORTHOGRAPHIC);
  TR3D_Layer = UInt32;

const
  R3D_LAYER_01 = 1 shl 0;
  R3D_LAYER_02 = 1 shl 1;
  R3D_LAYER_03 = 1 shl 2;
  R3D_LAYER_04 = 1 shl 3;
  R3D_LAYER_05 = 1 shl 4;
  R3D_LAYER_06 = 1 shl 5;
  R3D_LAYER_07 = 1 shl 6;
  R3D_LAYER_08 = 1 shl 7;
  R3D_LAYER_09 = 1 shl 8;
  R3D_LAYER_10 = 1 shl 9;
  R3D_LAYER_11 = 1 shl 10;
  R3D_LAYER_12 = 1 shl 11;
  R3D_LAYER_13 = 1 shl 12;
  R3D_LAYER_14 = 1 shl 13;
  R3D_LAYER_15 = 1 shl 14;
  R3D_LAYER_16 = 1 shl 15;
  R3D_LAYER_ALL = $FFFFFFFF;

type
  PR3D_Camera = ^TR3D_Camera;
  TR3D_Camera = record
    position: TVector3;
    rotation: TQuaternion;
    fovy: Double;
    nearPlane: Double;
    farPlane: Double;
    cullMask: TR3D_Layer;
    projection: TR3D_Projection;
  end;

function R3D_CameraFromRL(camera: TCamera3D): TR3D_Camera; cdecl; external R3D_DLLNAME name 'R3D_CameraFromRL';
function R3D_CameraToRL(camera: TR3D_Camera): TCamera3D; cdecl; external R3D_DLLNAME name 'R3D_CameraToRL';
procedure R3D_CameraLookAt(camera: PR3D_Camera; target: TVector3; up: TVector3); cdecl; external R3D_DLLNAME name 'R3D_CameraLookAt';
function R3D_GetCameraForward(camera: TR3D_Camera): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetCameraForward';
function R3D_GetCameraRight(camera: TR3D_Camera): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetCameraRight';
function R3D_GetCameraUp(camera: TR3D_Camera): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetCameraUp';
function R3D_GetCameraView(camera: TR3D_Camera): TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetCameraView';
function R3D_GetCameraProj(camera: TR3D_Camera; aspect: Double): TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetCameraProj';
function R3D_GetCameraViewProj(camera: TR3D_Camera; aspect: Double): TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetCameraViewProj';
procedure R3D_MoveCamera(camera: PR3D_Camera; delta: TVector3); cdecl; external R3D_DLLNAME name 'R3D_MoveCamera';
procedure R3D_MoveCameraLocal(camera: PR3D_Camera; delta: TVector3); cdecl; external R3D_DLLNAME name 'R3D_MoveCameraLocal';
procedure R3D_CameraRotate(camera: PR3D_Camera; rotation: TQuaternion); cdecl; external R3D_DLLNAME name 'R3D_CameraRotate';
procedure R3D_CameraPitch(camera: PR3D_Camera; angle: Single); cdecl; external R3D_DLLNAME name 'R3D_CameraPitch';
procedure R3D_CameraYaw(camera: PR3D_Camera; angle: Single); cdecl; external R3D_DLLNAME name 'R3D_CameraYaw';
procedure R3D_CameraRoll(camera: PR3D_Camera; angle: Single); cdecl; external R3D_DLLNAME name 'R3D_CameraRoll';
procedure R3D_SetCameraCullMask(camera: PR3D_Camera; cullMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_SetCameraCullMask';
procedure R3D_EnableCameraCullLayers(camera: PR3D_Camera; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_EnableCameraCullLayers';
procedure R3D_DisableCameraCullLayers(camera: PR3D_Camera; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_DisableCameraCullLayers';
procedure R3D_ToggleCameraCullLayers(camera: PR3D_Camera; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_ToggleCameraCullLayers';
function R3D_IsCameraLayerVisible(camera: TR3D_Camera; layerMask: TR3D_Layer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsCameraLayerVisible';

// ============================ r3d_screen_shader.inc ============================

type
  TR3D_ScreenShader = record end;
  PR3D_ScreenShader = ^TR3D_ScreenShader;
  PPR3D_ScreenShader = ^PR3D_ScreenShader;
  TR3D_ScreenShaderStage = (R3D_SCREEN_SHADER_STAGE_SCENE, R3D_SCREEN_SHADER_STAGE_POST,
    R3D_SCREEN_SHADER_STAGE_OUTPUT, R3D_SCREEN_SHADER_STAGE_FINAL, R3D_SCREEN_SHADER_STAGE_COUNT);

function R3D_LoadScreenShader(const filePath: PAnsiChar): PR3D_ScreenShader; cdecl; external R3D_DLLNAME name 'R3D_LoadScreenShader';
function R3D_LoadScreenShaderFromMemory(const code: PAnsiChar): PR3D_ScreenShader; cdecl; external R3D_DLLNAME name 'R3D_LoadScreenShaderFromMemory';
function R3D_LoadScreenShaderAlias(shader: PR3D_ScreenShader): PR3D_ScreenShader; cdecl; external R3D_DLLNAME name 'R3D_LoadScreenShaderAlias';
procedure R3D_UnloadScreenShader(shader: PR3D_ScreenShader); cdecl; external R3D_DLLNAME name 'R3D_UnloadScreenShader';
procedure R3D_SetScreenShaderUniform(shader: PR3D_ScreenShader; const name: PAnsiChar; const value: Pointer); cdecl; external R3D_DLLNAME name 'R3D_SetScreenShaderUniform';
procedure R3D_SetScreenShaderSampler(shader: PR3D_ScreenShader; const name: PAnsiChar; texture: TTexture); cdecl; external R3D_DLLNAME name 'R3D_SetScreenShaderSampler';
procedure R3D_SetScreenShaderChain(stage: TR3D_ScreenShaderStage; shaders: PPR3D_ScreenShader; count: Integer); cdecl; external R3D_DLLNAME name 'R3D_SetScreenShaderChain';

// ============================== r3d_pack.inc ==============================

function R3D_PackFloat16(x: Single): UInt16; cdecl; external R3D_DLLNAME name 'R3D_PackFloat16';
function R3D_PackUnorm16(x: Single): UInt16; cdecl; external R3D_DLLNAME name 'R3D_PackUnorm16';
function R3D_PackSnorm16(x: Single): Int16; cdecl; external R3D_DLLNAME name 'R3D_PackSnorm16';
function R3D_PackUnorm8(x: Single): UInt8; cdecl; external R3D_DLLNAME name 'R3D_PackUnorm8';
function R3D_PackSnorm8(x: Single): Int8; cdecl; external R3D_DLLNAME name 'R3D_PackSnorm8';
function R3D_UnpackFloat16(x: UInt16): Single; cdecl; external R3D_DLLNAME name 'R3D_UnpackFloat16';
function R3D_UnpackUnorm16(x: UInt16): Single; cdecl; external R3D_DLLNAME name 'R3D_UnpackUnorm16';
function R3D_UnpackSnorm16(x: Int16): Single; cdecl; external R3D_DLLNAME name 'R3D_UnpackSnorm16';
function R3D_UnpackUnorm8(x: UInt8): Single; cdecl; external R3D_DLLNAME name 'R3D_UnpackUnorm8';
function R3D_UnpackSnorm8(x: Int8): Single; cdecl; external R3D_DLLNAME name 'R3D_UnpackSnorm8';

// ============================= r3d_cubemap.inc =============================

type
  TR3D_CubemapLayout = (
    R3D_CUBEMAP_LAYOUT_AUTO_DETECT = 0,
    R3D_CUBEMAP_LAYOUT_LINE_VERTICAL,
    R3D_CUBEMAP_LAYOUT_LINE_HORIZONTAL,
    R3D_CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR,
    R3D_CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE,
    R3D_CUBEMAP_LAYOUT_PANORAMA
  );

  PR3D_Cubemap = ^TR3D_Cubemap;
  TR3D_Cubemap = record
    texture: UInt32;
    fbo: UInt32;
    size: Integer;
  end;

function R3D_LoadCubemap(fileName: PAnsiChar; layout: TR3D_CubemapLayout): TR3D_Cubemap; cdecl; external R3D_DLLNAME name 'R3D_LoadCubemap';
function R3D_LoadCubemapFromImage(image: TImage; layout: TR3D_CubemapLayout): TR3D_Cubemap; cdecl; external R3D_DLLNAME name 'R3D_LoadCubemapFromImage';
procedure R3D_UnloadCubemap(cubemap: TR3D_Cubemap); cdecl; external R3D_DLLNAME name 'R3D_UnloadCubemap';

// ============================ r3d_ambient_map.inc ============================

type
  TR3D_AmbientFlags = UInt32;

const
  R3D_AMBIENT_ILLUMINATION = 1 shl 0;
  R3D_AMBIENT_REFLECTION   = 1 shl 1;

type
  PR3D_AmbientMap = ^TR3D_AmbientMap;
  TR3D_AmbientMap = record
    flags: TR3D_AmbientFlags;
    irradiance: UInt32;
    prefilter: UInt32;
  end;

function R3D_LoadAmbientMap(const fileName: PAnsiChar; layout: TR3D_CubemapLayout; flag: TR3D_AmbientFlags): TR3D_AmbientMap; cdecl; external R3D_DLLNAME name 'R3D_LoadAmbientMap';
function R3D_LoadAmbientMapFromImage(image: TImage; layout: TR3D_CubemapLayout; flag: TR3D_AmbientFlags): TR3D_AmbientMap; cdecl; external R3D_DLLNAME name 'R3D_LoadAmbientMapFromImage';
function R3D_GenAmbientMap(cubemap: TR3D_Cubemap; flags: TR3D_AmbientFlags): TR3D_AmbientMap; cdecl; external R3D_DLLNAME name 'R3D_GenAmbientMap';
procedure R3D_UnloadAmbientMap(ambientMap: TR3D_AmbientMap); cdecl; external R3D_DLLNAME name 'R3D_UnloadAmbientMap';
procedure R3D_UpdateAmbientMap(ambientMap: TR3D_AmbientMap; cubemap: TR3D_Cubemap); cdecl; external R3D_DLLNAME name 'R3D_UpdateAmbientMap';

// ============================= r3d_importer.inc =============================

type
  R3D_ImportFlags = UInt32;

const
  R3D_IMPORT_RETAIN_MESH_DATA  = 1 shl 0;
  R3D_IMPORT_RETAIN_MESH_NAMES = 1 shl 1;
  R3D_IMPORT_SMOOTH_NORMALS    = 1 shl 2;
  R3D_IMPORT_OPTIMIZE_MESH     = 1 shl 3;
  R3D_IMPORT_VALIDATE_DATA     = 1 shl 4;
  R3D_IMPORT_QUALITY = R3D_IMPORT_SMOOTH_NORMALS or R3D_IMPORT_OPTIMIZE_MESH or R3D_IMPORT_VALIDATE_DATA;

type
  PR3D_Importer = ^TR3D_Importer;
  TR3D_Importer = record end;

function R3D_LoadImporter(const filePath: PAnsiChar; flags: R3D_ImportFlags): PR3D_Importer; cdecl; external R3D_DLLNAME name 'R3D_LoadImporter';
function R3D_LoadImporterFromMemory(const data: Pointer; size: Cardinal; const hint: PAnsiChar; flags: R3D_ImportFlags): PR3D_Importer; cdecl; external R3D_DLLNAME name 'R3D_LoadImporterFromMemory';
procedure R3D_UnloadImporter(importer: PR3D_Importer); cdecl; external R3D_DLLNAME name 'R3D_UnloadImporter';

// =============================== r3d_probe.inc ===============================

type
  TR3D_ProbeFlags = UInt32;

const
  R3D_PROBE_ILLUMINATION = 1 shl 0;
  R3D_PROBE_REFLECTION   = 1 shl 1;

type
  TR3D_ProbeUpdateMode = (R3D_PROBE_UPDATE_ONCE, R3D_PROBE_UPDATE_ALWAYS);
  TR3D_Probe = UInt32;

const
  R3D_INVALID_PROBE: TR3D_Probe = 0;

function R3D_CreateProbe(flags: TR3D_ProbeFlags): TR3D_Probe; cdecl; external R3D_DLLNAME name 'R3D_CreateProbe';
procedure R3D_DestroyProbe(id: TR3D_Probe); cdecl; external R3D_DLLNAME name 'R3D_DestroyProbe';
function R3D_IsProbeValid(id: TR3D_Probe): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsProbeValid';
function R3D_GetProbeFlags(id: TR3D_Probe): TR3D_ProbeFlags; cdecl; external R3D_DLLNAME name 'R3D_GetProbeFlags';
function R3D_IsProbeEnabled(id: TR3D_Probe): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsProbeEnabled';
procedure R3D_ToggleProbe(id: TR3D_Probe); cdecl; external R3D_DLLNAME name 'R3D_ToggleProbe';
procedure R3D_EnableProbe(id: TR3D_Probe); cdecl; external R3D_DLLNAME name 'R3D_EnableProbe';
procedure R3D_DisableProbe(id: TR3D_Probe); cdecl; external R3D_DLLNAME name 'R3D_DisableProbe';
function R3D_GetProbeUpdateMode(id: TR3D_Probe): TR3D_ProbeUpdateMode; cdecl; external R3D_DLLNAME name 'R3D_GetProbeUpdateMode';
procedure R3D_SetProbeUpdateMode(id: TR3D_Probe; mode: TR3D_ProbeUpdateMode); cdecl; external R3D_DLLNAME name 'R3D_SetProbeUpdateMode';
function R3D_GetProbeInterior(id: TR3D_Probe): Boolean; cdecl; external R3D_DLLNAME name 'R3D_GetProbeInterior';
procedure R3D_SetProbeInterior(id: TR3D_Probe; active: Boolean); cdecl; external R3D_DLLNAME name 'R3D_SetProbeInterior';
function R3D_GetProbeShadows(id: TR3D_Probe): Boolean; cdecl; external R3D_DLLNAME name 'R3D_GetProbeShadows';
procedure R3D_SetProbeShadows(id: TR3D_Probe; active: Boolean); cdecl; external R3D_DLLNAME name 'R3D_SetProbeShadows';
function R3D_GetProbePosition(id: TR3D_Probe): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetProbePosition';
procedure R3D_SetProbePosition(id: TR3D_Probe; position: TVector3); cdecl; external R3D_DLLNAME name 'R3D_SetProbePosition';
function R3D_GetProbeRange(id: TR3D_Probe): Single; cdecl; external R3D_DLLNAME name 'R3D_GetProbeRange';
procedure R3D_SetProbeRange(id: TR3D_Probe; range: Single); cdecl; external R3D_DLLNAME name 'R3D_SetProbeRange';
function R3D_GetProbeFalloff(id: TR3D_Probe): Single; cdecl; external R3D_DLLNAME name 'R3D_GetProbeFalloff';
procedure R3D_SetProbeFalloff(id: TR3D_Probe; falloff: Single); cdecl; external R3D_DLLNAME name 'R3D_SetProbeFalloff';

// =========================== r3d_environment.inc ===========================

type
  TR3D_Bloom = (R3D_BLOOM_DISABLED, R3D_BLOOM_MIX, R3D_BLOOM_ADDITIVE, R3D_BLOOM_SCREEN);
  TR3D_Fog = (R3D_FOG_DISABLED, R3D_FOG_LINEAR, R3D_FOG_EXP2, R3D_FOG_EXP);
  TR3D_DoF = (R3D_DOF_DISABLED, R3D_DOF_ENABLED);
  TR3D_Tonemap = (R3D_TONEMAP_LINEAR, R3D_TONEMAP_REINHARD, R3D_TONEMAP_FILMIC, R3D_TONEMAP_ACES, R3D_TONEMAP_AGX, R3D_TONEMAP_COUNT);

  PR3D_EnvBackground = ^TR3D_EnvBackground;
  TR3D_EnvBackground = record
    color: TColor;
    energy: Single;
    skyBlur: Single;
    sky: TR3D_Cubemap;
    rotation: TQuaternion;
  end;

  PR3D_EnvAmbient = ^TR3D_EnvAmbient;
  TR3D_EnvAmbient = record
    color: TColor;
    energy: Single;
    map: TR3D_AmbientMap;
  end;

  PR3D_EnvSSAO = ^TR3D_EnvSSAO;
  TR3D_EnvSSAO = record
    sampleCount: Integer;
    intensity: Single;
    power: Single;
    maxRadius: Single;
    radius: Single;
    bias: Single;
    enabled: Boolean;
  end;

  PR3D_EnvSSIL = ^TR3D_EnvSSIL;
  TR3D_EnvSSIL = record
    sampleCount: Integer;
    giIntensity: Single;
    aoIntensity: Single;
    aoPower: Single;
    maxRadius: Single;
    radius: Single;
    bias: Single;
    enabled: Boolean;
  end;

  PR3D_EnvSSGI = ^TR3D_EnvSSGI;
  TR3D_EnvSSGI = record
    sliceCount: Integer;
    edgeFade: Single;
    distanceFalloff: Single;
    normalRejection: Single;
    intensity: Single;
    denoiseSteps: Integer;
    enabled: Boolean;
  end;

  PR3D_EnvSSR = ^TR3D_EnvSSR;
  TR3D_EnvSSR = record
    maxRaySteps: Integer;
    binarySteps: Integer;
    stepSize: Single;
    thickness: Single;
    maxDistance: Single;
    edgeFade: Single;
    enabled: Boolean;
  end;

  PR3D_EnvFog = ^TR3D_EnvFog;
  TR3D_EnvFog = record
    mode: TR3D_Fog;
    color: TColor;
    start: Single;
    end_: Single;
    density: Single;
    skyAffect: Single;
  end;

  PR3D_VolumetricFog = ^TR3D_VolumetricFog;
  TR3D_VolumetricFog = record
    scatteringDensity: Single;
    absortionDensity: Single;
    scatteringColor: TColorB;
    anisotropy: Single;
    emissionColor: TColorB;
    emissionEnergy: Single;
    skyAffect: Single;
    length: Single;
    stepSize: Single;
    enabled: Boolean;
  end;

  PR3D_EnvDoF = ^TR3D_EnvDoF;
  TR3D_EnvDoF = record
    mode: TR3D_DoF;
    focusPoint: Single;
    focusScale: Single;
    nearScale: Single;
    maxBlurSize: Single;
  end;

  PR3D_EnvBloom = ^TR3D_EnvBloom;
  TR3D_EnvBloom = record
    mode: TR3D_Bloom;
    levels: Single;
    intensity: Single;
    threshold: Single;
    softThreshold: Single;
    filterRadius: Single;
  end;

  PR3D_EnvAutoExposure = ^TR3D_EnvAutoExposure;
  TR3D_EnvAutoExposure = record
    minEV: Single;
    maxEV: Single;
    exposureCompensation: Single;
    adaptationToBright: Single;
    adaptationToDark: Single;
    enabled: Boolean;
  end;

  PR3D_EnvTonemap = ^TR3D_EnvTonemap;
  TR3D_EnvTonemap = record
    mode: TR3D_Tonemap;
    exposure: Single;
    white: Single;
  end;

  PR3D_EnvColor = ^TR3D_EnvColor;
  TR3D_EnvColor = record
    brightness: Single;
    contrast: Single;
    saturation: Single;
  end;

  PR3D_Environment = ^TR3D_Environment;
  TR3D_Environment = record
    background: TR3D_EnvBackground;
    ambient: TR3D_EnvAmbient;
    ssao: TR3D_EnvSSAO;
    ssil: TR3D_EnvSSIL;
    ssgi: TR3D_EnvSSGI;
    ssr: TR3D_EnvSSR;
    fog: TR3D_EnvFog;
    volumetricFog: TR3D_VolumetricFog;
    dof: TR3D_EnvDoF;
    bloom: TR3D_EnvBloom;
    autoExposure: TR3D_EnvAutoExposure;
    tonemap: TR3D_EnvTonemap;
    color: TR3D_EnvColor;
  end;

function R3D_GetEnvironment: PR3D_Environment; cdecl; external R3D_DLLNAME name 'R3D_GetEnvironment';
procedure R3D_SetEnvironment(env: PR3D_Environment); cdecl; external R3D_DLLNAME name 'R3D_SetEnvironment';

function R3D_ENVIRONMENT_BASE: TR3D_Environment;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Single); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Integer); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Boolean); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TColor); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Cubemap); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_AmbientMap); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TQuaternion); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Bloom); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Fog); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_DoF); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Tonemap); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_EnvBackground); overload;
procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_EnvAmbient); overload;

// ============================== r3d_lighting.inc ==============================

type
  TR3D_ShadowUpdateMode = (
    R3D_SHADOW_UPDATE_MANUAL,     ///< Shadow maps update only when explicitly requested.
    R3D_SHADOW_UPDATE_INTERVAL,   ///< Shadow maps update at defined time intervals.
    R3D_SHADOW_UPDATE_CONTINUOUS  ///< Shadow maps update every frame for real-time accuracy.
  );

  // NOTE: TR3D_LightType was missing in the original paste (probably located above
  // the copied snippet). This definition matches the original C code.
  // If this type already exists elsewhere in the unit -> delete the duplicate!
  TR3D_LightType = (R3D_LIGHT_DIR = 0, R3D_LIGHT_SPOT, R3D_LIGHT_OMNI);

  TR3D_Light = UInt32;

const
  R3D_INVALID_LIGHT: TR3D_Light = 0;

{ ---------------------------------------- }
{ LIGHTS CONFIG                             }
{ ---------------------------------------- }

function R3D_CreateLight(typ: TR3D_LightType): TR3D_Light; cdecl; external R3D_DLLNAME name 'R3D_CreateLight';
procedure R3D_DestroyLight(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_DestroyLight';
function R3D_IsLightValid(id: TR3D_Light): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsLightValid';
function R3D_GetLightType(id: TR3D_Light): TR3D_LightType; cdecl; external R3D_DLLNAME name 'R3D_GetLightType';
function R3D_IsLightEnabled(id: TR3D_Light): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsLightEnabled';
procedure R3D_ToggleLight(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_ToggleLight';
procedure R3D_EnableLight(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_EnableLight';
procedure R3D_DisableLight(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_DisableLight';

{ ---------------------------------------- }
{ LIGHT COLOR                               }
{ ---------------------------------------- }

function R3D_GetLightColor(id: TR3D_Light): TColor; cdecl; external R3D_DLLNAME name 'R3D_GetLightColor';
procedure R3D_SetLightColor(id: TR3D_Light; color: TColor); cdecl; external R3D_DLLNAME name 'R3D_SetLightColor';
function R3D_GetLightColorLinear(id: TR3D_Light): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetLightColorLinear';
procedure R3D_SetLightColorLinear(id: TR3D_Light; color: TVector3); cdecl; external R3D_DLLNAME name 'R3D_SetLightColorLinear';
procedure R3D_SetLightTemperature(id: TR3D_Light; kelvin: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightTemperature';

{ ---------------------------------------- }
{ LIGHT POSITION & DIRECTION                }
{ ---------------------------------------- }

function R3D_GetLightPosition(id: TR3D_Light): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetLightPosition';
procedure R3D_SetLightPosition(id: TR3D_Light; position: TVector3); cdecl; external R3D_DLLNAME name 'R3D_SetLightPosition';
function R3D_GetLightDirection(id: TR3D_Light): TVector3; cdecl; external R3D_DLLNAME name 'R3D_GetLightDirection';
procedure R3D_SetLightDirection(id: TR3D_Light; direction: TVector3); cdecl; external R3D_DLLNAME name 'R3D_SetLightDirection';
procedure R3D_SetLightTarget(id: TR3D_Light; position: TVector3; target: TVector3); cdecl; external R3D_DLLNAME name 'R3D_SetLightTarget';

{ ---------------------------------------- }
{ LIGHT ENERGY & SPECULAR                   }
{ ---------------------------------------- }

function R3D_GetLightEnergy(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightEnergy';
procedure R3D_SetLightEnergy(id: TR3D_Light; energy: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightEnergy';
function R3D_GetLightLumen(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightLumen';
procedure R3D_SetLightLumen(id: TR3D_Light; lumens: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightLumen';
function R3D_GetLightSpecular(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightSpecular';
procedure R3D_SetLightSpecular(id: TR3D_Light; specular: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightSpecular';

{ ---------------------------------------- }
{ LIGHT RANGE & FALLOFF                     }
{ ---------------------------------------- }

function R3D_GetLightRange(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightRange';
procedure R3D_SetLightRange(id: TR3D_Light; range: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightRange';
function R3D_GetLightFalloff(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightFalloff';
procedure R3D_SetLightFalloff(id: TR3D_Light; falloff: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightFalloff';

{ ---------------------------------------- }
{ LIGHT CONE ANGLES (Spot)                  }
{ ---------------------------------------- }

procedure R3D_GetLightAngle(id: TR3D_Light; inner: PSingle; outer: PSingle); cdecl; external R3D_DLLNAME name 'R3D_GetLightAngle';
procedure R3D_SetLightAngle(id: TR3D_Light; inner: Single; outer: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightAngle';

{ ---------------------------------------- }
{ LIGHT VOLUMETRIC FOG                      }
{ ---------------------------------------- }

function R3D_GetLightFogEnergy(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetLightFogEnergy';
procedure R3D_SetLightFogEnergy(id: TR3D_Light; energy: Single); cdecl; external R3D_DLLNAME name 'R3D_SetLightFogEnergy';

{ ---------------------------------------- }
{ SHADOW CONFIG                             }
{ ---------------------------------------- }

procedure R3D_EnableShadow(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_EnableShadow';
procedure R3D_DisableShadow(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_DisableShadow';
function R3D_IsShadowEnabled(id: TR3D_Light): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsShadowEnabled';
function R3D_GetShadowUpdateMode(id: TR3D_Light): TR3D_ShadowUpdateMode; cdecl; external R3D_DLLNAME name 'R3D_GetShadowUpdateMode';
procedure R3D_SetShadowUpdateMode(id: TR3D_Light; mode: TR3D_ShadowUpdateMode); cdecl; external R3D_DLLNAME name 'R3D_SetShadowUpdateMode';
function R3D_GetShadowUpdateInterval(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetShadowUpdateInterval';
procedure R3D_SetShadowUpdateInterval(id: TR3D_Light; seconds: Single); cdecl; external R3D_DLLNAME name 'R3D_SetShadowUpdateInterval';
procedure R3D_UpdateShadowMap(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_UpdateShadowMap';
function R3D_GetShadowSoftness(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetShadowSoftness';
procedure R3D_SetShadowSoftness(id: TR3D_Light; softness: Single); cdecl; external R3D_DLLNAME name 'R3D_SetShadowSoftness';
function R3D_GetShadowOpacity(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetShadowOpacity';
procedure R3D_SetShadowOpacity(id: TR3D_Light; opacity: Single); cdecl; external R3D_DLLNAME name 'R3D_SetShadowOpacity';
function R3D_GetShadowDepthBias(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetShadowDepthBias';
procedure R3D_SetShadowDepthBias(id: TR3D_Light; value: Single); cdecl; external R3D_DLLNAME name 'R3D_SetShadowDepthBias';
function R3D_GetShadowSlopeBias(id: TR3D_Light): Single; cdecl; external R3D_DLLNAME name 'R3D_GetShadowSlopeBias';
procedure R3D_SetShadowSlopeBias(id: TR3D_Light; value: Single); cdecl; external R3D_DLLNAME name 'R3D_SetShadowSlopeBias';
function R3D_GetShadowCasterMask(id: TR3D_Light): TR3D_Layer; cdecl; external R3D_DLLNAME name 'R3D_GetShadowCasterMask';
procedure R3D_SetShadowCasterMask(id: TR3D_Light; cullMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_SetShadowCasterMask';
procedure R3D_EnableShadowCasterLayers(id: TR3D_Light; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_EnableShadowCasterLayers';
procedure R3D_DisableShadowCasterLayers(id: TR3D_Light; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_DisableShadowCasterLayers';
procedure R3D_ToggleShadowCasterLayers(id: TR3D_Light; layerMask: TR3D_Layer); cdecl; external R3D_DLLNAME name 'R3D_ToggleShadowCasterLayers';
function R3D_IsShadowCasterLayerVisible(id: TR3D_Light; layerMask: TR3D_Layer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsShadowCasterLayerVisible';

{ ---------------------------------------- }
{ LIGHT HELPERS & MATH                      }
{ ---------------------------------------- }

function R3D_GetLightBoundingBox(light: TR3D_Light): TBoundingBox; cdecl; external R3D_DLLNAME name 'R3D_GetLightBoundingBox';
procedure R3D_DrawLightDebug(id: TR3D_Light); cdecl; external R3D_DLLNAME name 'R3D_DrawLightDebug';
function R3D_LumensToEnergy(lumens: Single; referenceDistance: Single): Single; cdecl; external R3D_DLLNAME name 'R3D_LumensToEnergy';
function R3D_EnergyToLumens(energy: Single; referenceDistance: Single): Single; cdecl; external R3D_DLLNAME name 'R3D_EnergyToLumens';
// ============================= r3d_sky_shader.inc =============================

type
  PR3D_SkyShader = ^TR3D_SkyShader;
  TR3D_SkyShader = record end;

function R3D_LoadSkyShader(const filePath: PAnsiChar): PR3D_SkyShader; cdecl; external R3D_DLLNAME name 'R3D_LoadSkyShader';
function R3D_LoadSkyShaderFromMemory(const code: PAnsiChar): PR3D_SkyShader; cdecl; external R3D_DLLNAME name 'R3D_LoadSkyShaderFromMemory';
procedure R3D_UnloadSkyShader(shader: PR3D_SkyShader); cdecl; external R3D_DLLNAME name 'R3D_UnloadSkyShader';
procedure R3D_SetSkyShaderUniform(shader: PR3D_SkyShader; const name: PAnsiChar; const value: Pointer); cdecl; external R3D_DLLNAME name 'R3D_SetSkyShaderUniform';
procedure R3D_SetSkyShaderSampler(shader: PR3D_SkyShader; const name: PAnsiChar; texture: TTexture); cdecl; external R3D_DLLNAME name 'R3D_SetSkyShaderSampler';

// =============================== r3d_sky.inc ===============================

type
  PR3D_ProceduralSky = ^TR3D_ProceduralSky;
  TR3D_ProceduralSky = record
    skyTopColor: TColorB;
    skyHorizonColor: TColorB;
    skyHorizonCurve: Single;
    skyEnergy: Single;
    groundBottomColor: TColorB;
    groundHorizonColor: TColorB;
    groundHorizonCurve: Single;
    groundEnergy: Single;
    sunDirection: TVector3;
    sunColor: TColorB;
    sunSize: Single;
    sunCurve: Single;
    sunEnergy: Single;
  end;

function R3D_GenProceduralSky(size: Integer; params: TR3D_ProceduralSky): TR3D_Cubemap; cdecl; external R3D_DLLNAME name 'R3D_GenProceduralSky';
function R3D_GenCustomSky(size: Integer; shader: PR3D_SkyShader): TR3D_Cubemap; cdecl; external R3D_DLLNAME name 'R3D_GenCustomSky';
procedure R3D_UpdateProceduralSky(cubemap: PR3D_Cubemap; params: TR3D_ProceduralSky); cdecl; external R3D_DLLNAME name 'R3D_UpdateProceduralSky';
procedure R3D_UpdateCustomSky(cubemap: PR3D_Cubemap; shader: PR3D_SkyShader); cdecl; external R3D_DLLNAME name 'R3D_UpdateCustomSky';

function R3D_PROCEDURAL_SKY_BASE: TR3D_ProceduralSky;

// =========================== r3d_surface_shader.inc ===========================

type
  TR3D_SurfaceShader = record end;
  PR3D_SurfaceShader = ^TR3D_SurfaceShader;

function R3D_LoadSurfaceShader(const filePath: PAnsiChar): PR3D_SurfaceShader; cdecl; external R3D_DLLNAME name 'R3D_LoadSurfaceShader';
function R3D_LoadSurfaceShaderFromMemory(const code: PAnsiChar): PR3D_SurfaceShader; cdecl; external R3D_DLLNAME name 'R3D_LoadSurfaceShaderFromMemory';
function R3D_LoadSurfaceShaderAlias(shader: PR3D_SurfaceShader): PR3D_SurfaceShader; cdecl; external R3D_DLLNAME name 'R3D_LoadSurfaceShaderAlias';
procedure R3D_UnloadSurfaceShader(shader: PR3D_SurfaceShader); cdecl; external R3D_DLLNAME name 'R3D_UnloadSurfaceShader';
procedure R3D_SetSurfaceShaderUniform(shader: PR3D_SurfaceShader; const name: PAnsiChar; const value: Pointer); cdecl; external R3D_DLLNAME name 'R3D_SetSurfaceShaderUniform';
procedure R3D_SetSurfaceShaderSampler(shader: PR3D_SurfaceShader; const name: PAnsiChar; texture: TTexture); cdecl; external R3D_DLLNAME name 'R3D_SetSurfaceShaderSampler';

// ============================ r3d_material.inc ============================

type
  TR3D_TransparencyMode = (R3D_TRANSPARENCY_DISABLED, R3D_TRANSPARENCY_PREPASS, R3D_TRANSPARENCY_ALPHA);
  TR3D_BillboardMode = (R3D_BILLBOARD_DISABLED, R3D_BILLBOARD_FRONT, R3D_BILLBOARD_Y_AXIS);
  TR3D_BlendMode = (R3D_BLEND_MIX, R3D_BLEND_ADDITIVE, R3D_BLEND_MULTIPLY, R3D_BLEND_PREMULTIPLIED_ALPHA);
  TR3D_CompareMode = (R3D_COMPARE_LESS, R3D_COMPARE_LEQUAL, R3D_COMPARE_EQUAL, R3D_COMPARE_GREATER,
    R3D_COMPARE_GEQUAL, R3D_COMPARE_NOTEQUAL, R3D_COMPARE_ALWAYS, R3D_COMPARE_NEVER);
  TR3D_StencilOp = (R3D_STENCIL_KEEP, R3D_STENCIL_ZERO, R3D_STENCIL_REPLACE, R3D_STENCIL_INCR, R3D_STENCIL_DECR);
  TR3D_CullMode = (R3D_CULL_NONE, R3D_CULL_BACK, R3D_CULL_FRONT);

  TR3D_AlbedoMap = record
    texture: TTexture2D;
    color: TColor;
  end;

  TR3D_EmissionMap = record
    texture: TTexture2D;
    color: TColor;
    energy: Single;
  end;

  TR3D_NormalMap = record
    texture: TTexture2D;
    scale: Single;
  end;

  TR3D_OrmMap = record
    texture: TTexture2D;
    occlusion: Single;
    roughness: Single;
    metalness: Single;
    specular: Single;
  end;

  TR3D_DepthState = record
    mode: TR3D_CompareMode;
    offsetFactor: Single;
    offsetUnits: Single;
    rangeNear: Single;
    rangeFar: Single;
  end;

  TR3D_StencilState = record
    mode: TR3D_CompareMode;
    ref: Byte;
    mask: Byte;
    opFail: TR3D_StencilOp;
    opZFail: TR3D_StencilOp;
    opPass: TR3D_StencilOp;
  end;

  PR3D_Material = ^TR3D_Material;
  TR3D_Material = record
    albedo: TR3D_AlbedoMap;
    emission: TR3D_EmissionMap;
    normal: TR3D_NormalMap;
    orm: TR3D_OrmMap;
    uvOffset: TVector2;
    uvScale: TVector2;
    alphaCutoff: Single;
    depth: TR3D_DepthState;
    stencil: TR3D_StencilState;
    transparencyMode: TR3D_TransparencyMode;
    billboardMode: TR3D_BillboardMode;
    blendMode: TR3D_BlendMode;
    cullMode: TR3D_CullMode;
    unlit: Boolean;
    priority: Integer;
    shader: PR3D_SurfaceShader;
  end;

function R3D_GetDefaultMaterial: TR3D_Material; cdecl; external R3D_DLLNAME name 'R3D_GetDefaultMaterial';
procedure R3D_SetDefaultMaterial(material: TR3D_Material); cdecl; external R3D_DLLNAME name 'R3D_SetDefaultMaterial';
function R3D_LoadMaterials(const filePath: PAnsiChar; materialCount: PInteger): PR3D_Material; cdecl; external R3D_DLLNAME name 'R3D_LoadMaterials';
function R3D_LoadMaterialsFromMemory(const data: Pointer; size: LongWord; const hint: PAnsiChar; materialCount: PInteger): PR3D_Material; cdecl; external R3D_DLLNAME name 'R3D_LoadMaterialsFromMemory';
function R3D_LoadMaterialsFromImporter(const importer: PR3D_Importer; materialCount: PInteger): PR3D_Material; cdecl; external R3D_DLLNAME name 'R3D_LoadMaterialsFromImporter';
procedure R3D_UnloadMaterial(material: TR3D_Material); cdecl; external R3D_DLLNAME name 'R3D_UnloadMaterial';
function R3D_LoadAlbedoMap(const fileName: PAnsiChar; color: TColor): TR3D_AlbedoMap; cdecl; external R3D_DLLNAME name 'R3D_LoadAlbedoMap';
function R3D_LoadAlbedoMapFromMemory(fileType: PAnsiChar; fileData: Pointer; dataSize: Integer; color: TColor): TR3D_AlbedoMap; cdecl; external R3D_DLLNAME name 'R3D_LoadAlbedoMapFromMemory';
procedure R3D_UnloadAlbedoMap(map: TR3D_AlbedoMap); cdecl; external R3D_DLLNAME name 'R3D_UnloadAlbedoMap';
function R3D_LoadEmissionMap(fileName: PAnsiChar; color: TColor; energy: Single): TR3D_EmissionMap; cdecl; external R3D_DLLNAME name 'R3D_LoadEmissionMap';
function R3D_LoadEmissionMapFromMemory(fileType: PAnsiChar; fileData: Pointer; dataSize: Integer; color: TColor; energy: Single): TR3D_EmissionMap; cdecl; external R3D_DLLNAME name 'R3D_LoadEmissionMapFromMemory';
procedure R3D_UnloadEmissionMap(map: TR3D_EmissionMap); cdecl; external R3D_DLLNAME name 'R3D_UnloadEmissionMap';
function R3D_LoadNormalMap(fileName: PAnsiChar; scale: Single): TR3D_NormalMap; cdecl; external R3D_DLLNAME name 'R3D_LoadNormalMap';
function R3D_LoadNormalMapFromMemory(fileType: PAnsiChar; fileData: Pointer; dataSize: Integer; scale: Single): TR3D_NormalMap; cdecl; external R3D_DLLNAME name 'R3D_LoadNormalMapFromMemory';
procedure R3D_UnloadNormalMap(map: TR3D_NormalMap); cdecl; external R3D_DLLNAME name 'R3D_UnloadNormalMap';
function R3D_LoadOrmMap(fileName: PAnsiChar; occlusion, roughness, metalness, specular: Single): TR3D_OrmMap; cdecl; external R3D_DLLNAME name 'R3D_LoadOrmMap';
function R3D_LoadOrmMapFromMemory(fileType: PAnsiChar; fileData: Pointer; dataSize: Integer; occlusion, roughness, metalness, specular: Single): TR3D_OrmMap; cdecl; external R3D_DLLNAME name 'R3D_LoadOrmMapFromMemory';
procedure R3D_UnloadOrmMap(map: TR3D_OrmMap); cdecl; external R3D_DLLNAME name 'R3D_UnloadOrmMap';

function R3D_MATERIAL_BASE: TR3D_Material;

// ============================== r3d_color.inc ==============================

function R3D_ColorSrgbToLinear(color: TColor): TVector4; cdecl; external R3D_DLLNAME name 'R3D_ColorSrgbToLinear';
function R3D_ColorSrgbToLinearVector3(color: TColor): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ColorSrgbToLinearVector3';
function R3D_ColorLinearToSrgb(color: TVector4): TColor; cdecl; external R3D_DLLNAME name 'R3D_ColorLinearToSrgb';
function R3D_ColorFromCurrentSpace(color: TColor): TVector4; cdecl; external R3D_DLLNAME name 'R3D_ColorFromCurrentSpace';
function R3D_ColorFromCurrentSpaceVector3(color: TColor): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ColorFromCurrentSpaceVector3';
function R3D_ColorFromTemperature(kelvin: Single): TColorB; cdecl; external R3D_DLLNAME name 'R3D_ColorFromTemperature';

// ============================= r3d_texture.inc =============================

function R3D_LoadTexture(const fileName: PAnsiChar; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTexture';
function R3D_LoadTextureEx(const fileName: PAnsiChar; wrap: TTextureWrap; filter: TTextureFilter; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTextureEx';
function R3D_LoadTextureFromImage(image: TImage; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTextureFromImage';
function R3D_LoadTextureFromImageEx(image: TImage; wrap: TTextureWrap; filter: TTextureFilter; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTextureFromImageEx';
function R3D_LoadTextureFromMemory(const fileType: PAnsiChar; const fileData: Pointer; dataSize: Integer; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTextureFromMemory';
function R3D_LoadTextureFromMemoryEx(const fileType: PAnsiChar; const fileData: Pointer; dataSize: Integer; wrap: TTextureWrap; filter: TTextureFilter; isColor: Boolean): TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_LoadTextureFromMemoryEx';
procedure R3D_UnloadTexture(texture: TTexture2D); cdecl; external R3D_DLLNAME name 'R3D_UnloadTexture';

// ============================== r3d_decal.inc ==============================

type
  PR3D_Decal = ^TR3D_Decal;
  TR3D_Decal = record
    albedo: TR3D_AlbedoMap;
    emission: TR3D_EmissionMap;
    normal: TR3D_NormalMap;
    orm: TR3D_OrmMap;
    uvOffset: TVector2;
    uvScale: TVector2;
    alphaCutoff: Single;
    normalThreshold: Single;
    fadeWidth: Single;
    applyColor: Boolean;
    shader: PR3D_SurfaceShader;
  end;

procedure R3D_UnloadDecalMaps(decal: TR3D_Decal); cdecl; external R3D_DLLNAME name 'R3D_UnloadDecalMaps';

function R3D_DECAL_BASE: TR3D_Decal;

// ============================ r3d_skeleton.inc ============================

type
  PR3D_BoneInfo = ^TR3D_BoneInfo;
  TR3D_BoneInfo = record
    name: array[0..31] of AnsiChar;
    parent: Integer;
  end;

  PR3D_Skeleton = ^TR3D_Skeleton;
  TR3D_Skeleton = record
    bones: PR3D_BoneInfo;
    boneCount: Integer;
    localBind: PMatrix;
    modelBind: PMatrix;
    invBind: PMatrix;
    rootBind: TMatrix;
    skinTexture: LongWord;
  end;

function R3D_LoadSkeleton(const filePath: PAnsiChar): TR3D_Skeleton; cdecl; external R3D_DLLNAME name 'R3D_LoadSkeleton';
function R3D_LoadSkeletonFromMemory(const data: Pointer; size: LongWord; const hint: PAnsiChar): TR3D_Skeleton; cdecl; external R3D_DLLNAME name 'R3D_LoadSkeletonFromMemory';
function R3D_LoadSkeletonFromImporter(const importer: PR3D_Importer): TR3D_Skeleton; cdecl; external R3D_DLLNAME name 'R3D_LoadSkeletonFromImporter';
procedure R3D_UnloadSkeleton(skeleton: TR3D_Skeleton); cdecl; external R3D_DLLNAME name 'R3D_UnloadSkeleton';
function R3D_IsSkeletonValid(const skeleton: TR3D_Skeleton): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsSkeletonValid';
function R3D_GetSkeletonBoneIndex(skeleton: TR3D_Skeleton; const boneName: PAnsiChar): Integer; cdecl; external R3D_DLLNAME name 'R3D_GetSkeletonBoneIndex';
function R3D_GetSkeletonBone(skeleton: TR3D_Skeleton; const boneName: PAnsiChar): PR3D_BoneInfo; cdecl; external R3D_DLLNAME name 'R3D_GetSkeletonBone';

// ============================ r3d_animation.inc ============================

type
  PR3D_AnimationTrack = ^TR3D_AnimationTrack;
  TR3D_AnimationTrack = record
    times: PSingle;
    values: Pointer;
    count: Integer;
  end;

  PR3D_AnimationChannel = ^TR3D_AnimationChannel;
  TR3D_AnimationChannel = record
    translation: TR3D_AnimationTrack;
    rotation: TR3D_AnimationTrack;
    scale: TR3D_AnimationTrack;
    boneIndex: Integer;
  end;

  PR3D_Animation = ^TR3D_Animation;
  TR3D_Animation = record
    channels: PR3D_AnimationChannel;
    channelCount: Integer;
    ticksPerSecond: Single;
    duration: Single;
    boneCount: Integer;
    name: array[0..31] of AnsiChar;
  end;

  PR3D_AnimationLib = ^TR3D_AnimationLib;
  TR3D_AnimationLib = record
    animations: PR3D_Animation;
    count: Integer;
  end;

function R3D_LoadAnimationLib(const filePath: PAnsiChar): TR3D_AnimationLib; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationLib';
function R3D_LoadAnimationLibFromMemory(const data: Pointer; size: LongWord; const hint: PAnsiChar): TR3D_AnimationLib; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationLibFromMemory';
function R3D_LoadAnimationLibFromImporter(const importer: PR3D_Importer): TR3D_AnimationLib; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationLibFromImporter';
procedure R3D_UnloadAnimationLib(animLib: TR3D_AnimationLib); cdecl; external R3D_DLLNAME name 'R3D_UnloadAnimationLib';
function R3D_GetAnimationIndex(animLib: TR3D_AnimationLib; const name: PAnsiChar): Integer; cdecl; external R3D_DLLNAME name 'R3D_GetAnimationIndex';
function R3D_GetAnimation(animLib: TR3D_AnimationLib; const name: PAnsiChar): PR3D_Animation; cdecl; external R3D_DLLNAME name 'R3D_GetAnimation';

// ========================= r3d_animation_player.inc =========================

type
  TR3D_AnimationEvent = (R3D_ANIM_EVENT_FINISHED, R3D_ANIM_EVENT_LOOPED);

  PR3D_AnimationState = ^TR3D_AnimationState;
  TR3D_AnimationState = record
    currentTime: Single;
    speed: Single;
    play: Boolean;
    loop: Boolean;
  end;

  PR3D_AnimationPlayer = ^TR3D_AnimationPlayer;
  R3D_AnimationEventCallback = procedure(
    player: PR3D_AnimationPlayer;
    eventType: TR3D_AnimationEvent;
    animIndex: Integer;
    userData: Pointer
  ); cdecl;

  TR3D_AnimationPlayer = record
    animLib: TR3D_AnimationLib;
    skeleton: TR3D_Skeleton;
    states: PR3D_AnimationState;
    activeAnimIndex: Integer;
    localPose: PMatrix;
    modelPose: PMatrix;
    skinBuffer: PMatrix;
    skinTexture: UInt32;
    eventCallback: R3D_AnimationEventCallback;
    eventUserData: Pointer;
  end;

function R3D_LoadAnimationPlayer(skeleton: TR3D_Skeleton; animLib: TR3D_AnimationLib): TR3D_AnimationPlayer; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationPlayer';
procedure R3D_UnloadAnimationPlayer(player: TR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_UnloadAnimationPlayer';
function R3D_IsAnimationPlayerValid(player: TR3D_AnimationPlayer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsAnimationPlayerValid';
function R3D_IsAnimationPlaying(player: TR3D_AnimationPlayer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsAnimationPlaying';
procedure R3D_PlayAnimation(player: PR3D_AnimationPlayer; animIndex: Integer); cdecl; external R3D_DLLNAME name 'R3D_PlayAnimation';
procedure R3D_PauseAnimation(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_PauseAnimation';
procedure R3D_StopAnimation(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_StopAnimation';
procedure R3D_RewindAnimation(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_RewindAnimation';
function R3D_GetAnimationTime(player: TR3D_AnimationPlayer; animIndex: Integer): Single; cdecl; external R3D_DLLNAME name 'R3D_GetAnimationTime';
procedure R3D_SetAnimationTime(player: PR3D_AnimationPlayer; animIndex: Integer; time: Single); cdecl; external R3D_DLLNAME name 'R3D_SetAnimationTime';
function R3D_GetAnimationSpeed(player: TR3D_AnimationPlayer; animIndex: Integer): Single; cdecl; external R3D_DLLNAME name 'R3D_GetAnimationSpeed';
procedure R3D_SetAnimationSpeed(player: PR3D_AnimationPlayer; animIndex: Integer; speed: Single); cdecl; external R3D_DLLNAME name 'R3D_SetAnimationSpeed';
function R3D_GetAnimationLoop(player: TR3D_AnimationPlayer; animIndex: Integer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_GetAnimationLoop';
procedure R3D_SetAnimationLoop(player: PR3D_AnimationPlayer; animIndex: Integer; loop: Boolean); cdecl; external R3D_DLLNAME name 'R3D_SetAnimationLoop';
procedure R3D_AdvanceAnimationTime(player: PR3D_AnimationPlayer; dt: Single); cdecl; external R3D_DLLNAME name 'R3D_AdvanceAnimationTime';
procedure R3D_ComputeAnimationLocalPose(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_ComputeAnimationLocalPose';
procedure R3D_ComputeAnimationModelPose(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_ComputeAnimationModelPose';
procedure R3D_ComputeAnimationPose(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_ComputeAnimationPose';
procedure R3D_UploadAnimationPose(player: PR3D_AnimationPlayer); cdecl; external R3D_DLLNAME name 'R3D_UploadAnimationPose';
procedure R3D_UpdateAnimationPlayer(player: PR3D_AnimationPlayer; dt: Single); cdecl; external R3D_DLLNAME name 'R3D_UpdateAnimationPlayer';

// ========================== r3d_animation_tree.inc ==========================

type
  PR3D_AnimationTreeNode = ^TR3D_AnimationTreeNode;
  TR3D_AnimationTreeNode = record end;

  R3D_AnimationStmIndex = Integer;

  TR3D_AnimationNodeCallback = procedure(const animation: PR3D_Animation; state: TR3D_AnimationState;
    boneIndex: Integer; outTransform: PTransform; userData: Pointer); cdecl;

  TR3D_AnimationTreeCallback = procedure(const player: PR3D_AnimationPlayer; boneIndex: Integer;
    outTransform: PTransform; userData: Pointer); cdecl;

  TR3D_StmEdgeMode = (R3D_STM_EDGE_INSTANT = 0, R3D_STM_EDGE_ONDONE);
  TR3D_StmEdgeStatus = (R3D_STM_EDGE_ON = 0, R3D_STM_EDGE_AUTO, R3D_STM_EDGE_ONCE, R3D_STM_EDGE_OFF);

  PR3D_BoneMask = ^TR3D_BoneMask;
  TR3D_BoneMask = record
    mask: array[0..7] of Int32;
    boneCount: Integer;
  end;

  PR3D_AnimationNodeParams = ^TR3D_AnimationNodeParams;
  TR3D_AnimationNodeParams = record
    name: array[0..31] of AnsiChar;
    state: TR3D_AnimationState;
    looper: Boolean;
    evalCallback: TR3D_AnimationNodeCallback;
    evalUserData: Pointer;
  end;

  PR3D_Blend2NodeParams = ^TR3D_Blend2NodeParams;
  TR3D_Blend2NodeParams = record
    boneMask: PR3D_BoneMask;
    blend: Single;
  end;

  PR3D_Add2NodeParams = ^TR3D_Add2NodeParams;
  TR3D_Add2NodeParams = record
    boneMask: PR3D_BoneMask;
    weight: Single;
  end;

  PR3D_SwitchNodeParams = ^TR3D_SwitchNodeParams;
  TR3D_SwitchNodeParams = record
    synced: Boolean;
    activeInput: Integer;
    xFadeTime: Single;
  end;

  PR3D_StmEdgeParams = ^TR3D_StmEdgeParams;
  TR3D_StmEdgeParams = record
    mode: TR3D_StmEdgeMode;
    status: TR3D_StmEdgeStatus;
    nextStatus: TR3D_StmEdgeStatus;
    xFadeTime: Single;
  end;

  PR3D_AnimationTree = ^TR3D_AnimationTree;
  TR3D_AnimationTree = record
    player: TR3D_AnimationPlayer;
    rootNode: PR3D_AnimationTreeNode;
    nodePool: PR3D_AnimationTreeNode;
    nodePoolSize: Integer;
    nodePoolMaxSize: Integer;
    rootBone: Integer;
    updateCallback: TR3D_AnimationTreeCallback;
    updateUserData: Pointer;
  end;

function R3D_LoadAnimationTree(player: TR3D_AnimationPlayer; maxSize: Integer): TR3D_AnimationTree; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationTree';
function R3D_LoadAnimationTreeEx(player: TR3D_AnimationPlayer; maxSize: Integer; rootBone: Integer): TR3D_AnimationTree; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationTreeEx';
function R3D_LoadAnimationTreePro(player: TR3D_AnimationPlayer; maxSize: Integer; rootBone: Integer;
  updateCallback: TR3D_AnimationTreeCallback; updateUserData: Pointer): TR3D_AnimationTree; cdecl; external R3D_DLLNAME name 'R3D_LoadAnimationTreePro';
procedure R3D_UnloadAnimationTree(tree: TR3D_AnimationTree); cdecl; external R3D_DLLNAME name 'R3D_UnloadAnimationTree';
procedure R3D_UpdateAnimationTree(tree: PR3D_AnimationTree; dt: Single); cdecl; external R3D_DLLNAME name 'R3D_UpdateAnimationTree';
procedure R3D_UpdateAnimationTreeEx(tree: PR3D_AnimationTree; dt: Single; rootMotion: PTransform; rootDistance: PTransform); cdecl; external R3D_DLLNAME name 'R3D_UpdateAnimationTreeEx';
procedure R3D_AddRootAnimationNode(tree: PR3D_AnimationTree; node: PR3D_AnimationTreeNode); cdecl; external R3D_DLLNAME name 'R3D_AddRootAnimationNode';
function R3D_AddAnimationNode(parent: PR3D_AnimationTreeNode; node: PR3D_AnimationTreeNode; inputIndex: Integer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_AddAnimationNode';
function R3D_CreateAnimationNode(tree: PR3D_AnimationTree; params: TR3D_AnimationNodeParams): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateAnimationNode';
function R3D_CreateAnimationNodeEx(tree: PR3D_AnimationTree; params: TR3D_AnimationNodeParams; setTime: Boolean): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateAnimationNodeEx';
function R3D_CreateBlend2Node(tree: PR3D_AnimationTree; params: TR3D_Blend2NodeParams): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateBlend2Node';
function R3D_CreateAdd2Node(tree: PR3D_AnimationTree; params: TR3D_Add2NodeParams): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateAdd2Node';
function R3D_CreateSwitchNode(tree: PR3D_AnimationTree; inputCount: Integer; params: TR3D_SwitchNodeParams): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateSwitchNode';
function R3D_CreateStmNode(tree: PR3D_AnimationTree; statesCount, edgesCount: Integer): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateStmNode';
function R3D_CreateStmNodeEx(tree: PR3D_AnimationTree; statesCount, edgesCount: Integer; enableTravel: Boolean): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateStmNodeEx';
function R3D_CreateStmXNode(tree: PR3D_AnimationTree; nestedNode: PR3D_AnimationTreeNode): PR3D_AnimationTreeNode; cdecl; external R3D_DLLNAME name 'R3D_CreateStmXNode';
function R3D_CreateStmNodeState(stmNode: PR3D_AnimationTreeNode; stateNode: PR3D_AnimationTreeNode; outEdgesCount: Integer): R3D_AnimationStmIndex; cdecl; external R3D_DLLNAME name 'R3D_CreateStmNodeState';
function R3D_CreateStmNodeEdge(stmNode: PR3D_AnimationTreeNode; beginStateIndex, endStateIndex: R3D_AnimationStmIndex;
  params: TR3D_StmEdgeParams): R3D_AnimationStmIndex; cdecl; external R3D_DLLNAME name 'R3D_CreateStmNodeEdge';
procedure R3D_SetAnimationNodeParams(node: PR3D_AnimationTreeNode; params: TR3D_AnimationNodeParams); cdecl; external R3D_DLLNAME name 'R3D_SetAnimationNodeParams';
function R3D_GetAnimationNodeParams(node: PR3D_AnimationTreeNode): TR3D_AnimationNodeParams; cdecl; external R3D_DLLNAME name 'R3D_GetAnimationNodeParams';
procedure R3D_SetBlend2NodeParams(node: PR3D_AnimationTreeNode; params: TR3D_Blend2NodeParams); cdecl; external R3D_DLLNAME name 'R3D_SetBlend2NodeParams';
function R3D_GetBlend2NodeParams(node: PR3D_AnimationTreeNode): TR3D_Blend2NodeParams; cdecl; external R3D_DLLNAME name 'R3D_GetBlend2NodeParams';
procedure R3D_SetAdd2NodeParams(node: PR3D_AnimationTreeNode; params: TR3D_Add2NodeParams); cdecl; external R3D_DLLNAME name 'R3D_SetAdd2NodeParams';
function R3D_GetAdd2NodeParams(node: PR3D_AnimationTreeNode): TR3D_Add2NodeParams; cdecl; external R3D_DLLNAME name 'R3D_GetAdd2NodeParams';
procedure R3D_SetSwitchNodeParams(node: PR3D_AnimationTreeNode; params: TR3D_SwitchNodeParams); cdecl; external R3D_DLLNAME name 'R3D_SetSwitchNodeParams';
function R3D_GetSwitchNodeParams(node: PR3D_AnimationTreeNode): TR3D_SwitchNodeParams; cdecl; external R3D_DLLNAME name 'R3D_GetSwitchNodeParams';
procedure R3D_SetStmNodeEdgeParams(node: PR3D_AnimationTreeNode; edgeIndex: R3D_AnimationStmIndex; params: TR3D_StmEdgeParams); cdecl; external R3D_DLLNAME name 'R3D_SetStmNodeEdgeParams';
function R3D_GetStmNodeEdgeParams(node: PR3D_AnimationTreeNode; edgeIndex: R3D_AnimationStmIndex): TR3D_StmEdgeParams; cdecl; external R3D_DLLNAME name 'R3D_GetStmNodeEdgeParams';
function R3D_GetStmStateActiveIndex(node: PR3D_AnimationTreeNode): R3D_AnimationStmIndex; cdecl; external R3D_DLLNAME name 'R3D_GetStmStateActiveIndex';
procedure R3D_TravelToStmState(node: PR3D_AnimationTreeNode; targetStateIndex: R3D_AnimationStmIndex); cdecl; external R3D_DLLNAME name 'R3D_TravelToStmState';
function R3D_ComputeBoneMask(const skeleton: PR3D_Skeleton; boneNames: PPAnsiChar; boneNameCount: Integer): TR3D_BoneMask; cdecl; external R3D_DLLNAME name 'R3D_ComputeBoneMask';

// ============================== r3d_vertex.inc ==============================

type
  PR3D_Vertex = ^TR3D_Vertex;
  TR3D_Vertex = record
    position: TVector3;
    texcoord: array[0..1] of UInt16;
    normal: array[0..3] of Int8;
    tangent: array[0..3] of Int8;
    color: TColorB;
    boneIndices: array[0..3] of UInt8;
    boneWeights: array[0..3] of UInt8;
  end;

function R3D_MakeVertex(position: TVector3; texcoord: TVector2; normal: TVector3; tangent: TVector4; color: TColorB): TR3D_Vertex; cdecl; external R3D_DLLNAME name 'R3D_MakeVertex';
procedure R3D_PackTexCoord(dst: PWord; src: TVector2); cdecl; external R3D_DLLNAME name 'R3D_PackTexCoord';
function R3D_UnpackTexCoord(src: PWord): TVector2; cdecl; external R3D_DLLNAME name 'R3D_UnpackTexCoord';
procedure R3D_PackNormal(dst: PShortInt; src: TVector3); cdecl; external R3D_DLLNAME name 'R3D_PackNormal';
function R3D_UnpackNormal(src: PShortInt): TVector3; cdecl; external R3D_DLLNAME name 'R3D_UnpackNormal';
procedure R3D_PackTangent(dst: PShortInt; src: TVector4); cdecl; external R3D_DLLNAME name 'R3D_PackTangent';
function R3D_UnpackTangent(src: PShortInt): TVector4; cdecl; external R3D_DLLNAME name 'R3D_UnpackTangent';

// ============================ r3d_mesh_data.inc ============================

type
  TR3D_PrimitiveType = (
    R3D_PRIMITIVE_POINTS,
    R3D_PRIMITIVE_LINES,
    R3D_PRIMITIVE_LINE_STRIP,
    R3D_PRIMITIVE_LINE_LOOP,
    R3D_PRIMITIVE_TRIANGLES,
    R3D_PRIMITIVE_TRIANGLE_STRIP,
    R3D_PRIMITIVE_TRIANGLE_FAN
  );

  PR3D_MeshData = ^TR3D_MeshData;
  TR3D_MeshData = record
    vertices: PR3D_Vertex;
    indices: PUInt32;
    vertexCapacity: Integer;
    indexCapacity: Integer;
    vertexCount: Integer;
    indexCount: Integer;
  end;

function R3D_LoadMeshData(vertexCount, indexCount: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_LoadMeshData';
procedure R3D_UnloadMeshData(meshData: TR3D_MeshData); cdecl; external R3D_DLLNAME name 'R3D_UnloadMeshData';
function R3D_IsMeshDataValid(meshData: TR3D_MeshData): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsMeshDataValid';
function R3D_GenMeshDataQuad(width, length: Single; resX, resZ: Integer; frontDir: TVector3): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataQuad';
function R3D_GenMeshDataPlane(width, length: Single; resX, resZ: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataPlane';
function R3D_GenMeshDataPoly(sides: Integer; radius: Single; frontDir: TVector3): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataPoly';
function R3D_GenMeshDataCube(width, height, length: Single): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCube';
function R3D_GenMeshDataCubeEx(width, height, length: Single; resX, resY, resZ: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCubeEx';
function R3D_GenMeshDataSlope(width, height, length: Single; slopeNormal: TVector3): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataSlope';
function R3D_GenMeshDataSphere(radius: Single; rings, slices: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataSphere';
function R3D_GenMeshDataHemiSphere(radius: Single; rings, slices: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataHemiSphere';
function R3D_GenMeshDataCylinder(radius, height: Single; slices: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCylinder';
function R3D_GenMeshDataCylinderEx(bottomRadius, topRadius, height: Single; slices, stacks: Integer; bottomCap, topCap: Boolean): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCylinderEx';
function R3D_GenMeshDataCapsule(radius, height: Single; rings, slices: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCapsule';
function R3D_GenMeshDataTorus(radius, size: Single; radSeg, sides: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataTorus';
function R3D_GenMeshDataKnot(radius, size: Single; radSeg, sides: Integer): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataKnot';
function R3D_GenMeshDataHeightmap(heightmap: TImage; size: TVector3): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataHeightmap';
function R3D_GenMeshDataCubicmap(cubicmap: TImage; cubeSize: TVector3): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataCubicmap';
procedure R3D_ReserveMeshData(meshData: PR3D_MeshData; vertexCount, indexCount: Integer); cdecl; external R3D_DLLNAME name 'R3D_ReserveMeshData';
procedure R3D_ShrinkMeshData(meshData: PR3D_MeshData); cdecl; external R3D_DLLNAME name 'R3D_ShrinkMeshData';
procedure R3D_ResetMeshData(meshData: PR3D_MeshData); cdecl; external R3D_DLLNAME name 'R3D_ResetMeshData';
function R3D_CopyMeshData(meshData: TR3D_MeshData): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_CopyMeshData';
function R3D_MergeMeshData(a, b: TR3D_MeshData): TR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_MergeMeshData';
procedure R3D_AppendMeshData(meshData: PR3D_MeshData; vertices: PR3D_Vertex; vertexCount: Integer; indices: PUInt32; indexCount: Integer); cdecl; external R3D_DLLNAME name 'R3D_AppendMeshData';
procedure R3D_TransformMeshData(meshData: PR3D_MeshData; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_TransformMeshData';
procedure R3D_TranslateMeshData(meshData: PR3D_MeshData; translation: TVector3); cdecl; external R3D_DLLNAME name 'R3D_TranslateMeshData';
procedure R3D_RotateMeshData(meshData: PR3D_MeshData; rotation: TQuaternion); cdecl; external R3D_DLLNAME name 'R3D_RotateMeshData';
procedure R3D_ScaleMeshData(meshData: PR3D_MeshData; scale: TVector3); cdecl; external R3D_DLLNAME name 'R3D_ScaleMeshData';
procedure R3D_GenMeshDataUVsPlanar(meshData: PR3D_MeshData; uvScale: TVector2; axis: TVector3); cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataUVsPlanar';
procedure R3D_GenMeshDataUVsSpherical(meshData: PR3D_MeshData); cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataUVsSpherical';
procedure R3D_GenMeshDataUVsCylindrical(meshData: PR3D_MeshData); cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataUVsCylindrical';
procedure R3D_GenMeshDataNormals(meshData: PR3D_MeshData; primitiveType: TR3D_PrimitiveType); cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataNormals';
procedure R3D_GenMeshDataTangents(meshData: PR3D_MeshData; primitiveType: TR3D_PrimitiveType); cdecl; external R3D_DLLNAME name 'R3D_GenMeshDataTangents';
function R3D_CalculateMeshDataBoundingBox(meshData: TR3D_MeshData): TBoundingBox; cdecl; external R3D_DLLNAME name 'R3D_CalculateMeshDataBoundingBox';

// ============================== r3d_mesh.inc ==============================

type
  TR3D_ShadowCastMode = (
    R3D_SHADOW_CAST_ON_AUTO,
    R3D_SHADOW_CAST_ON_DOUBLE_SIDED,
    R3D_SHADOW_CAST_ON_FRONT_SIDE,
    R3D_SHADOW_CAST_ON_BACK_SIDE,
    R3D_SHADOW_CAST_ONLY_AUTO,
    R3D_SHADOW_CAST_ONLY_DOUBLE_SIDED,
    R3D_SHADOW_CAST_ONLY_FRONT_SIDE,
    R3D_SHADOW_CAST_ONLY_BACK_SIDE,
    R3D_SHADOW_CAST_DISABLED
  );

  PR3D_Mesh = ^TR3D_Mesh;
  TR3D_Mesh = record
    vertexOffset: Integer;
    vertexCapacity: Integer;
    vertexCount: Integer;
    indexOffset: Integer;
    indexCapacity: Integer;
    indexCount: Integer;
    shadowCastMode: TR3D_ShadowCastMode;
    primitiveType: TR3D_PrimitiveType;
    layerMask: TR3D_Layer;
    aabb: TBoundingBox;
  end;

function R3D_LoadMesh(PrimitiveType: TR3D_PrimitiveType; data: TR3D_MeshData; const aabb: PBoundingBox): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_LoadMesh';   // C-Param: "type"
procedure R3D_UnloadMesh(mesh: TR3D_Mesh); cdecl; external R3D_DLLNAME name 'R3D_UnloadMesh';
function R3D_IsMeshValid(const mesh: TR3D_Mesh): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsMeshValid';
function R3D_GenMeshQuad(width, length: Single; resX, resZ: Integer; frontDir: TVector3): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshQuad';
function R3D_GenMeshPlane(width, length: Single; resX, resZ: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshPlane';
function R3D_GenMeshPoly(sides: Integer; radius: Single; frontDir: TVector3): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshPoly';
function R3D_GenMeshCube(width, height, length: Single): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCube';
function R3D_GenMeshCubeEx(width, height, length: Single; resX, resY, resZ: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCubeEx';
function R3D_GenMeshSlope(width, height, length: Single; slopeNormal: TVector3): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshSlope';
function R3D_GenMeshSphere(radius: Single; rings, slices: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshSphere';
function R3D_GenMeshHemiSphere(radius: Single; rings, slices: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshHemiSphere';
function R3D_GenMeshCylinder(radius, height: Single; slices: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCylinder';
function R3D_GenMeshCylinderEx(bottomRadius, topRadius, height: Single; slices, stacks: Integer; bottomCap, topCap: Boolean): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCylinderEx';
function R3D_GenMeshCapsule(radius, height: Single; rings, slices: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCapsule';
function R3D_GenMeshTorus(radius, size: Single; radSeg, sides: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshTorus';
function R3D_GenMeshKnot(radius, size: Single; radSeg, sides: Integer): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshKnot';
function R3D_GenMeshHeightmap(heightmap: TImage; size: TVector3): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshHeightmap';
function R3D_GenMeshCubicmap(cubicmap: TImage; cubeSize: TVector3): TR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GenMeshCubicmap';
function R3D_UpdateMesh(mesh: PR3D_Mesh; data: TR3D_MeshData; const aabb: PBoundingBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_UpdateMesh';

// ============================== r3d_model.inc ==============================

type
  TR3D_MeshName = array[0..31] of AnsiChar;
  PR3D_MeshName = ^TR3D_MeshName;

  PR3D_Model = ^TR3D_Model;
  TR3D_Model = record
    meshes: PR3D_Mesh;
    meshData: PR3D_MeshData;
    meshNames: PR3D_MeshName;
    materials: PR3D_Material;
    meshMaterials: PInteger;
    meshCount: Integer;
    materialCount: Integer;
    aabb: TBoundingBox;
    skeleton: TR3D_Skeleton;
  end;

function R3D_LoadModel(const filePath: PAnsiChar): TR3D_Model; cdecl; external R3D_DLLNAME name 'R3D_LoadModel';
function R3D_LoadModelEx(const filePath: PAnsiChar; flags: R3D_ImportFlags): TR3D_Model; cdecl; external R3D_DLLNAME name 'R3D_LoadModelEx';
function R3D_LoadModelFromMemory(const data: Pointer; size: LongWord; const hint: PAnsiChar): TR3D_Model; cdecl; external R3D_DLLNAME name 'R3D_LoadModelFromMemory';
function R3D_LoadModelFromMemoryEx(const data: Pointer; size: LongWord; const hint: PAnsiChar; flags: R3D_ImportFlags): TR3D_Model; cdecl; external R3D_DLLNAME name 'R3D_LoadModelFromMemoryEx';
function R3D_LoadModelFromImporter(const importer: PR3D_Importer): TR3D_Model; cdecl; external R3D_DLLNAME name 'R3D_LoadModelFromImporter';
procedure R3D_UnloadModel(model: TR3D_Model; unloadMaterials: Boolean); cdecl; external R3D_DLLNAME name 'R3D_UnloadModel';
function R3D_GetModelMeshIndex(model: TR3D_Model; const meshName: PAnsiChar): Integer; cdecl; external R3D_DLLNAME name 'R3D_GetModelMeshIndex';
function R3D_GetModelMesh(model: TR3D_Model; const meshName: PAnsiChar): PR3D_Mesh; cdecl; external R3D_DLLNAME name 'R3D_GetModelMesh';
function R3D_GetModelMeshData(model: TR3D_Model; const meshName: PAnsiChar): PR3D_MeshData; cdecl; external R3D_DLLNAME name 'R3D_GetModelMeshData';

// ============================== r3d_shape.inc ==============================

type
  TR3D_BoundingBox = TBoundingBox;

  PR3D_OrientedBox = ^TR3D_OrientedBox;
  TR3D_OrientedBox = record
    center: TVector3;
    axisX: TVector3;
    axisY: TVector3;
    axisZ: TVector3;
    halfExtents: TVector3;
  end;

  PR3D_Capsule = ^TR3D_Capsule;
  TR3D_Capsule = record
    start: TVector3;
    end_: TVector3;
    radius: Single;
  end;

  PR3D_Penetration = ^TR3D_Penetration;
  TR3D_Penetration = record
    collides: Boolean;
    depth: Single;
    normal: TVector3;
    mtv: TVector3;
  end;

function R3D_GetBoundingBox(center, halfExtents: TVector3): TR3D_BoundingBox; cdecl; external R3D_DLLNAME name 'R3D_GetBoundingBox';
function R3D_GetOrientedBox(aabb: TR3D_BoundingBox; transform: TMatrix): TR3D_OrientedBox; cdecl; external R3D_DLLNAME name 'R3D_GetOrientedBox';
function R3D_CheckCollisionBoundingBoxes(box1, box2: TR3D_BoundingBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionBoundingBoxes';
function R3D_CheckCollisionBoundingBoxSphere(box: TR3D_BoundingBox; center: TVector3; radius: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionBoundingBoxSphere';
function R3D_CheckCollisionOrientedBoxes(box1, box2: TR3D_OrientedBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionOrientedBoxes';
function R3D_CheckCollisionOrientedBoxSphere(box: TR3D_OrientedBox; center: TVector3; radius: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionOrientedBoxSphere';
function R3D_CheckCollisionSpheres(center1: TVector3; radius1: Single; center2: TVector3; radius2: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionSpheres';
function R3D_CheckCollisionCapsuleBoundingBox(capsule: TR3D_Capsule; box: TR3D_BoundingBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionCapsuleBoundingBox';
function R3D_CheckCollisionCapsuleOrientedBox(capsule: TR3D_Capsule; box: TR3D_OrientedBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionCapsuleOrientedBox';
function R3D_CheckCollisionCapsuleSphere(capsule: TR3D_Capsule; center: TVector3; radius: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionCapsuleSphere';
function R3D_CheckCollisionCapsules(a, b: TR3D_Capsule): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionCapsules';
function R3D_CheckCollisionCapsuleMesh(capsule: TR3D_Capsule; mesh: TR3D_MeshData; transform: TMatrix): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCollisionCapsuleMesh';
function R3D_CheckPenetrationBoundingBoxes(box1, box2: TR3D_BoundingBox): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationBoundingBoxes';
function R3D_CheckPenetrationBoundingBoxSphere(box: TR3D_BoundingBox; center: TVector3; radius: Single): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationBoundingBoxSphere';
function R3D_CheckPenetrationOrientedBoxes(box1, box2: TR3D_OrientedBox): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationOrientedBoxes';
function R3D_CheckPenetrationOrientedBoxSphere(box: TR3D_OrientedBox; center: TVector3; radius: Single): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationOrientedBoxSphere';
function R3D_CheckPenetrationSpheres(center1: TVector3; radius1: Single; center2: TVector3; radius2: Single): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationSpheres';
function R3D_CheckPenetrationCapsuleBoundingBox(capsule: TR3D_Capsule; box: TR3D_BoundingBox): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationCapsuleBoundingBox';
function R3D_CheckPenetrationCapsuleOrientedBox(capsule: TR3D_Capsule; box: TR3D_OrientedBox): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationCapsuleOrientedBox';
function R3D_CheckPenetrationCapsuleSphere(capsule: TR3D_Capsule; center: TVector3; radius: Single): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationCapsuleSphere';
function R3D_CheckPenetrationCapsules(a, b: TR3D_Capsule): TR3D_Penetration; cdecl; external R3D_DLLNAME name 'R3D_CheckPenetrationCapsules';
function R3D_RaycastTriangle(ray: TRay; p1, p2, p3: TVector3): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastTriangle';
function R3D_RaycastQuad(ray: TRay; p1, p2, p3, p4: TVector3): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastQuad';
function R3D_RaycastBoundingBox(ray: TRay; box: TR3D_BoundingBox): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastBoundingBox';
function R3D_RaycastOrientedBox(ray: TRay; box: TR3D_OrientedBox): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastOrientedBox';
function R3D_RaycastSphere(ray: TRay; center: TVector3; radius: Single): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastSphere';
function R3D_RaycastCapsule(ray: TRay; capsule: TR3D_Capsule): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastCapsule';
function R3D_RaycastMesh(ray: TRay; mesh: TR3D_MeshData; transform: TMatrix): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastMesh';
function R3D_RaycastModel(ray: TRay; model: TR3D_Model; transform: TMatrix): TRayCollision; cdecl; external R3D_DLLNAME name 'R3D_RaycastModel';
function R3D_ClosestPointOnSegment(point, start, end_: TVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ClosestPointOnSegment';
function R3D_ClosestPointOnTriangle(p, a, b, c: TVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ClosestPointOnTriangle';
function R3D_ClosestPointOnBox(point: TVector3; box: TR3D_BoundingBox): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ClosestPointOnBox';

// ============================ r3d_kinematics.inc ============================

type
  PR3D_SweepCollision = ^TR3D_SweepCollision;
  TR3D_SweepCollision = record
    hit: Boolean;
    time: Single;
    point: TVector3;
    normal: TVector3;
  end;

function R3D_ClipVelocity(velocity, normal: TVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ClipVelocity';
function R3D_ReflectVelocity(velocity, normal: TVector3; bounciness: Single): TVector3; cdecl; external R3D_DLLNAME name 'R3D_ReflectVelocity';
function R3D_SlideVelocity(velocity: TVector3; collision: TR3D_SweepCollision; outNormal: PVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_SlideVelocity';
function R3D_SlideSphereBoundingBox(center: TVector3; radius: Single; velocity: TVector3; box: TR3D_BoundingBox; outNormal: PVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_SlideSphereBoundingBox';
function R3D_SlideSphereMesh(center: TVector3; radius: Single; velocity: TVector3; mesh: TR3D_MeshData; transform: TMatrix; outNormal: PVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_SlideSphereMesh';
function R3D_SlideCapsuleBoundingBox(capsule: TR3D_Capsule; velocity: TVector3; box: TR3D_BoundingBox; outNormal: PVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_SlideCapsuleBoundingBox';
function R3D_SlideCapsuleMesh(capsule: TR3D_Capsule; velocity: TVector3; mesh: TR3D_MeshData; transform: TMatrix; outNormal: PVector3): TVector3; cdecl; external R3D_DLLNAME name 'R3D_SlideCapsuleMesh';
function R3D_DepenetrateSphereBoundingBox(var center: TVector3; radius: Single; box: TR3D_BoundingBox; outPenetration: PSingle): Boolean; cdecl; external R3D_DLLNAME name 'R3D_DepenetrateSphereBoundingBox';
function R3D_DepenetrateCapsuleBoundingBox(var capsule: TR3D_Capsule; box: TR3D_BoundingBox; outPenetration: PSingle): Boolean; cdecl; external R3D_DLLNAME name 'R3D_DepenetrateCapsuleBoundingBox';
function R3D_CheckSphereSupportBoundingBox(center: TVector3; radius: Single; direction: TVector3; distance: Single; box: TR3D_BoundingBox; outHit: PRayCollision): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckSphereSupportBoundingBox';
function R3D_CheckSphereSupportMesh(center: TVector3; radius: Single; direction: TVector3; distance: Single; mesh: TR3D_MeshData; transform: TMatrix; outHit: PRayCollision): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckSphereSupportMesh';
function R3D_CheckCapsuleSupportBoundingBox(capsule: TR3D_Capsule; direction: TVector3; distance: Single; box: TR3D_BoundingBox; outHit: PRayCollision): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCapsuleSupportBoundingBox';
function R3D_CheckCapsuleSupportMesh(capsule: TR3D_Capsule; direction: TVector3; distance: Single; mesh: TR3D_MeshData; transform: TMatrix; outHit: PRayCollision): Boolean; cdecl; external R3D_DLLNAME name 'R3D_CheckCapsuleSupportMesh';
function R3D_SweepSpherePoint(center: TVector3; radius: Single; velocity: TVector3; point: TVector3): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSpherePoint';
function R3D_SweepSphereSegment(center: TVector3; radius: Single; velocity: TVector3; a, b: TVector3): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSphereSegment';
function R3D_SweepSphereTrianglePlane(center: TVector3; radius: Single; velocity: TVector3; a, b, c: TVector3): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSphereTrianglePlane';
function R3D_SweepSphereTriangle(center: TVector3; radius: Single; velocity: TVector3; a, b, c: TVector3): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSphereTriangle';
function R3D_SweepSphereBoundingBox(center: TVector3; radius: Single; velocity: TVector3; box: TR3D_BoundingBox): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSphereBoundingBox';
function R3D_SweepSphereMesh(center: TVector3; radius: Single; velocity: TVector3; mesh: TR3D_MeshData; transform: TMatrix): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepSphereMesh';
function R3D_SweepCapsuleBoundingBox(capsule: TR3D_Capsule; velocity: TVector3; box: TR3D_BoundingBox): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepCapsuleBoundingBox';
function R3D_SweepCapsuleMesh(capsule: TR3D_Capsule; velocity: TVector3; mesh: TR3D_MeshData; transform: TMatrix): TR3D_SweepCollision; cdecl; external R3D_DLLNAME name 'R3D_SweepCapsuleMesh';

// ============================= r3d_frustum.inc =============================

type
  R3D_FrustumPlane = (R3D_PLANE_BACK, R3D_PLANE_FRONT, R3D_PLANE_BOTTOM, R3D_PLANE_TOP, R3D_PLANE_RIGHT, R3D_PLANE_LEFT);

const
  R3D_PLANE_COUNT = 6;

type
  PR3D_Frustum = ^TR3D_Frustum;
  TR3D_Frustum = record
    planes: array[0..R3D_PLANE_COUNT - 1] of TVector4;
  end;

function R3D_GetFrustum: TR3D_Frustum; cdecl; external R3D_DLLNAME name 'R3D_GetFrustum';
function R3D_ComputeFrustum(viewProj: TMatrix): TR3D_Frustum; cdecl; external R3D_DLLNAME name 'R3D_ComputeFrustum';
function R3D_ComputeFrustumBoundingBox(invViewProj: TMatrix): TBoundingBox; cdecl; external R3D_DLLNAME name 'R3D_ComputeFrustumBoundingBox';
// ATTENTION (Bugfix compared to FPC version): no more "var array of" (ABI), instead
// pointer to at least 8 TVector3:  var pts: array[0..7] of TVector3;
// R3D_ComputeFrustumCorners(mat, @pts[0]);
procedure R3D_ComputeFrustumCorners(invViewProj: TMatrix; corners: PVector3); cdecl; external R3D_DLLNAME name 'R3D_ComputeFrustumCorners';
function R3D_FrustumContainsPoint(const frustum: PR3D_Frustum; position: TVector3): Boolean; cdecl; external R3D_DLLNAME name 'R3D_FrustumContainsPoint';
function R3D_FrustumContainsAnyPoint(const frustum: PR3D_Frustum; const positions: PVector3; count: Integer): Boolean; cdecl; external R3D_DLLNAME name 'R3D_FrustumContainsAnyPoint';
function R3D_FrustumIntersectsSphere(const frustum: PR3D_Frustum; position: TVector3; radius: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_FrustumIntersectsSphere';
function R3D_FrustumIntersectsBoundingBox(const frustum: PR3D_Frustum; aabb: TBoundingBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_FrustumIntersectsBoundingBox';
function R3D_FrustumIntersectsOrientedBox(const frustum: PR3D_Frustum; obb: TR3D_OrientedBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_FrustumIntersectsOrientedBox';

// ============================== r3d_utils.inc ==============================

function R3D_GetWhiteTexture: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetWhiteTexture';
function R3D_GetBlackTexture: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetBlackTexture';
function R3D_GetNormalTexture: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetNormalTexture';
function R3D_GetBufferColor: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetBufferColor';
function R3D_GetBufferNormal: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetBufferNormal';
function R3D_GetBufferDepth: TTexture2D; cdecl; external R3D_DLLNAME name 'R3D_GetBufferDepth';
function R3D_GetMatrixView: TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetMatrixView';
function R3D_GetMatrixInvView: TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetMatrixInvView';
function R3D_GetMatrixProjection: TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetMatrixProjection';
function R3D_GetMatrixInvProjection: TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetMatrixInvProjection';
function R3D_GetMatrixViewProjection: TMatrix; cdecl; external R3D_DLLNAME name 'R3D_GetMatrixViewProjection';

// ============================= r3d_instance.inc =============================

const
  R3D_INSTANCE_ATTRIBUTE_COUNT = 5;
  R3D_INSTANCE_POSITION = 1 shl 0;
  R3D_INSTANCE_ROTATION = 1 shl 1;
  R3D_INSTANCE_SCALE    = 1 shl 2;
  R3D_INSTANCE_COLOR    = 1 shl 3;
  R3D_INSTANCE_CUSTOM   = 1 shl 4;

type
  TR3D_InstanceFlags = UInt32;
  TR3D_InstanceFormat = (R3D_INSTANCE_FORMAT_FLOAT32, R3D_INSTANCE_FORMAT_FLOAT16, R3D_INSTANCE_FORMAT_UNORM16,
    R3D_INSTANCE_FORMAT_SNORM16, R3D_INSTANCE_FORMAT_UNORM8, R3D_INSTANCE_FORMAT_SNORM8, R3D_INSTANCE_FORMAT_COUNT);

  PR3D_InstanceLayout = ^TR3D_InstanceLayout;
  TR3D_InstanceLayout = record
    formats: array[0..R3D_INSTANCE_ATTRIBUTE_COUNT - 1] of TR3D_InstanceFormat;
    flags: TR3D_InstanceFlags;
  end;

  PR3D_InstanceBuffer = ^TR3D_InstanceBuffer;
  TR3D_InstanceBuffer = record
    buffers: array[0..R3D_INSTANCE_ATTRIBUTE_COUNT - 1] of UInt32;
    layout: TR3D_InstanceLayout;
    capacity: Integer;
  end;

function R3D_LoadInstanceBuffer(capacity: Integer; flags: TR3D_InstanceFlags): TR3D_InstanceBuffer; cdecl; external R3D_DLLNAME name 'R3D_LoadInstanceBuffer';
function R3D_LoadInstanceBufferEx(capacity: Integer; layout: TR3D_InstanceLayout): TR3D_InstanceBuffer; cdecl; external R3D_DLLNAME name 'R3D_LoadInstanceBufferEx';
procedure R3D_UnloadInstanceBuffer(buffer: TR3D_InstanceBuffer); cdecl; external R3D_DLLNAME name 'R3D_UnloadInstanceBuffer';
procedure R3D_ResizeInstanceBuffer(buffer: PR3D_InstanceBuffer; newCapacity: Integer; keepData: Boolean); cdecl; external R3D_DLLNAME name 'R3D_ResizeInstanceBuffer';
procedure R3D_UploadInstances(buffer: TR3D_InstanceBuffer; flag: TR3D_InstanceFlags; offset: Integer; count: Integer; data: Pointer; discard: Boolean); cdecl; external R3D_DLLNAME name 'R3D_UploadInstances';
function R3D_MapInstances(buffer: TR3D_InstanceBuffer; flag: TR3D_InstanceFlags; discard: Boolean): Pointer; cdecl; external R3D_DLLNAME name 'R3D_MapInstances';
function R3D_MapInstancesEx(buffer: TR3D_InstanceBuffer; flag: TR3D_InstanceFlags; offset: Integer; count: Integer; discard: Boolean): Pointer; cdecl; external R3D_DLLNAME name 'R3D_MapInstancesEx';
procedure R3D_UnmapInstances(buffer: TR3D_InstanceBuffer; flags: TR3D_InstanceFlags); cdecl; external R3D_DLLNAME name 'R3D_UnmapInstances';
procedure R3D_SetInstanceFormat(layout: PR3D_InstanceLayout; attribute: TR3D_InstanceFlags; format: TR3D_InstanceFormat); cdecl; external R3D_DLLNAME name 'R3D_SetInstanceFormat';
function R3D_GetInstanceFormat(layout: TR3D_InstanceLayout; attribute: TR3D_InstanceFlags): TR3D_InstanceFormat; cdecl; external R3D_DLLNAME name 'R3D_GetInstanceFormat';

// ============================== r3d_draw.inc ==============================

type
  PR3D_View = ^TR3D_View;
  TR3D_View = record
    camera: TR3D_Camera;
    target: TRenderTexture;
    viewport: TRectangle;
  end;

procedure R3D_Begin(camera: TCamera3D); cdecl; external R3D_DLLNAME name 'R3D_Begin';
procedure R3D_BeginEx(camera: TR3D_Camera); cdecl; external R3D_DLLNAME name 'R3D_BeginEx';
procedure R3D_BeginPro(view: TR3D_View); cdecl; external R3D_DLLNAME name 'R3D_BeginPro';
procedure R3D_End; cdecl; external R3D_DLLNAME name 'R3D_End';
procedure R3D_BeginCluster(aabb: TBoundingBox); cdecl; external R3D_DLLNAME name 'R3D_BeginCluster';
procedure R3D_EndCluster; cdecl; external R3D_DLLNAME name 'R3D_EndCluster';
procedure R3D_DrawMesh(mesh: TR3D_Mesh; material: TR3D_Material; position: TVector3; scale: Single); cdecl; external R3D_DLLNAME name 'R3D_DrawMesh';
procedure R3D_DrawMeshEx(mesh: TR3D_Mesh; material: TR3D_Material; position: TVector3; rotation: TQuaternion; scale: TVector3); cdecl; external R3D_DLLNAME name 'R3D_DrawMeshEx';
procedure R3D_DrawMeshPro(mesh: TR3D_Mesh; material: TR3D_Material; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawMeshPro';
procedure R3D_DrawMeshInstanced(mesh: TR3D_Mesh; material: TR3D_Material; instances: TR3D_InstanceBuffer; count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawMeshInstanced';
procedure R3D_DrawMeshInstancedEx(mesh: TR3D_Mesh; material: TR3D_Material; instances: TR3D_InstanceBuffer; offset, count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawMeshInstancedEx';
procedure R3D_DrawMeshInstancedPro(mesh: TR3D_Mesh; material: TR3D_Material; instances: TR3D_InstanceBuffer; offset, count: Integer; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawMeshInstancedPro';
procedure R3D_DrawModel(model: TR3D_Model; position: TVector3; scale: Single); cdecl; external R3D_DLLNAME name 'R3D_DrawModel';
procedure R3D_DrawModelEx(model: TR3D_Model; position: TVector3; rotation: TQuaternion; scale: TVector3); cdecl; external R3D_DLLNAME name 'R3D_DrawModelEx';
procedure R3D_DrawModelPro(model: TR3D_Model; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawModelPro';
procedure R3D_DrawModelInstanced(model: TR3D_Model; instances: TR3D_InstanceBuffer; count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawModelInstanced';
procedure R3D_DrawModelInstancedEx(model: TR3D_Model; instances: TR3D_InstanceBuffer; offset, count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawModelInstancedEx';
procedure R3D_DrawModelInstancedPro(model: TR3D_Model; instances: TR3D_InstanceBuffer; offset, count: Integer; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawModelInstancedPro';
procedure R3D_DrawAnimatedModel(model: TR3D_Model; player: TR3D_AnimationPlayer; position: TVector3; scale: Single); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModel';
procedure R3D_DrawAnimatedModelEx(model: TR3D_Model; player: TR3D_AnimationPlayer; position: TVector3; rotation: TQuaternion; scale: TVector3); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModelEx';
procedure R3D_DrawAnimatedModelPro(model: TR3D_Model; player: TR3D_AnimationPlayer; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModelPro';
procedure R3D_DrawAnimatedModelInstanced(model: TR3D_Model; player: TR3D_AnimationPlayer; instances: TR3D_InstanceBuffer; count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModelInstanced';
procedure R3D_DrawAnimatedModelInstancedEx(model: TR3D_Model; player: TR3D_AnimationPlayer; instances: TR3D_InstanceBuffer; offset, count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModelInstancedEx';
procedure R3D_DrawAnimatedModelInstancedPro(model: TR3D_Model; player: TR3D_AnimationPlayer; instances: TR3D_InstanceBuffer; offset, count: Integer; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawAnimatedModelInstancedPro';
procedure R3D_DrawDecal(decal: TR3D_Decal; position: TVector3; scale: Single); cdecl; external R3D_DLLNAME name 'R3D_DrawDecal';
procedure R3D_DrawDecalEx(decal: TR3D_Decal; position: TVector3; rotation: TQuaternion; scale: TVector3); cdecl; external R3D_DLLNAME name 'R3D_DrawDecalEx';
procedure R3D_DrawDecalPro(decal: TR3D_Decal; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawDecalPro';
procedure R3D_DrawDecalInstanced(decal: TR3D_Decal; instances: TR3D_InstanceBuffer; count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawDecalInstanced';
procedure R3D_DrawDecalInstancedEx(decal: TR3D_Decal; instances: TR3D_InstanceBuffer; offset, count: Integer); cdecl; external R3D_DLLNAME name 'R3D_DrawDecalInstancedEx';
procedure R3D_DrawDecalInstancedPro(decal: TR3D_Decal; instances: TR3D_InstanceBuffer; offset, count: Integer; transform: TMatrix); cdecl; external R3D_DLLNAME name 'R3D_DrawDecalInstancedPro';

// ============================ r3d_visibility.inc ============================

{$IFDEF R3D_INCLUDE_VISIBILITY}
function R3D_IsPointVisible(position: TVector3): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsPointVisible';
function R3D_IsSphereVisible(position: TVector3; radius: Single): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsSphereVisible';
function R3D_IsBoundingBoxVisible(aabb: TBoundingBox): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsBoundingBoxVisible';
function R3D_IsOrientedBoxVisible(aabb: TBoundingBox; transform: TMatrix): Boolean; cdecl; external R3D_DLLNAME name 'R3D_IsOrientedBoxVisible';
{$ENDIF}

implementation

// Small local helpers (no dependency on ColorCreate/Vector2Create)
function R3D_MakeColorB(R, G, B, A: Byte): TColorB;
begin
  Result.r := R; Result.g := G; Result.b := B; Result.a := A;
end;

{ r3d_material_helpers }

function R3D_MATERIAL_BASE: TR3D_Material;
begin
  Result := Default(TR3D_Material);   // Bugfix: Previously not zeroed out
  Result.albedo.texture := Default(TTexture2D);
  Result.albedo.color := WHITE;
  Result.emission.texture := Default(TTexture2D);
  Result.emission.color := WHITE;
  Result.emission.energy := 0.0;
  Result.normal.texture := Default(TTexture2D);
  Result.normal.scale := 1.0;
  Result.orm.texture := Default(TTexture2D);
  Result.orm.occlusion := 1.0;
  Result.orm.roughness := 1.0;
  Result.orm.metalness := 0.0;
  Result.orm.specular := 0.5;         // Bugfix: C-Default, was missing in the FPC header
  Result.uvOffset.x := 0.0;  Result.uvOffset.y := 0.0;
  Result.uvScale.x := 1.0;   Result.uvScale.y := 1.0;
  Result.alphaCutoff := 0.01;
  Result.depth.mode := R3D_COMPARE_LESS;
  Result.depth.offsetFactor := 0.0;
  Result.depth.offsetUnits := 0.0;
  Result.depth.rangeNear := 0.0;
  Result.depth.rangeFar := 1.0;
  Result.stencil.mode := R3D_COMPARE_ALWAYS;
  Result.stencil.ref := 0;
  Result.stencil.mask := $FF;
  Result.stencil.opFail := R3D_STENCIL_KEEP;
  Result.stencil.opZFail := R3D_STENCIL_KEEP;
  Result.stencil.opPass := R3D_STENCIL_REPLACE;
  Result.transparencyMode := R3D_TRANSPARENCY_DISABLED;
  Result.billboardMode := R3D_BILLBOARD_DISABLED;
  Result.blendMode := R3D_BLEND_MIX;
  Result.cullMode := R3D_CULL_BACK;
  Result.unlit := False;
  Result.priority := 0;
  Result.shader := nil;
end;

{ r3d_decal_helpers }

function R3D_DECAL_BASE: TR3D_Decal;
begin
  Result := Default(TR3D_Decal);
  Result.albedo.color := WHITE;
  Result.emission.color := WHITE;
  Result.emission.energy := 0.0;
  Result.normal.scale := 1.0;
  Result.orm.occlusion := 1.0;
  Result.orm.roughness := 1.0;
  Result.orm.metalness := 0.0;
  Result.uvOffset.x := 0.0;  Result.uvOffset.y := 0.0;
  Result.uvScale.x := 1.0;   Result.uvScale.y := 1.0;
  Result.alphaCutoff := 0.01;
  Result.normalThreshold := 0.0;
  Result.fadeWidth := 0.0;
  Result.applyColor := True;
  Result.shader := nil;
end;

{ r3d_sky_helpers }

function R3D_PROCEDURAL_SKY_BASE: TR3D_ProceduralSky;
begin
  Result.skyTopColor := R3D_MakeColorB(98, 116, 140, 255);
  Result.skyHorizonColor := R3D_MakeColorB(165, 167, 171, 255);
  Result.skyHorizonCurve := 0.15;
  Result.skyEnergy := 1.0;
  Result.groundBottomColor := R3D_MakeColorB(51, 43, 34, 255);
  Result.groundHorizonColor := R3D_MakeColorB(165, 167, 171, 255);
  Result.groundHorizonCurve := 0.02;
  Result.groundEnergy := 1.0;
  Result.sunDirection.x := -1.0; Result.sunDirection.y := -1.0; Result.sunDirection.z := -1.0;
  Result.sunColor := WHITE;
  Result.sunSize := PI / 180.0;   // 1 degree in rad (instead of DEG2RAD)
  Result.sunCurve := 0.15;
  Result.sunEnergy := 1.0;
end;

{ r3d_environment_helpers }

function R3D_ENVIRONMENT_BASE: TR3D_Environment;
begin
  Result.background.color := GRAY;
  Result.background.energy := 1.0;
  Result.background.skyBlur := 0.0;
  Result.background.sky := Default(TR3D_Cubemap);
  Result.background.rotation.x := 0.0;
  Result.background.rotation.y := 0.0;
  Result.background.rotation.z := 0.0;
  Result.background.rotation.w := 1.0;

  Result.ambient.color := BLACK;
  Result.ambient.energy := 1.0;
  Result.ambient.map := Default(TR3D_AmbientMap);

  Result.ssao.sampleCount := 16;
  Result.ssao.intensity := 1.0;
  Result.ssao.power := 1.0;
  Result.ssao.maxRadius := 0.2;
  Result.ssao.radius := 1.0;
  Result.ssao.bias := 0.03;
  Result.ssao.enabled := False;

  Result.ssil.sampleCount := 16;
  Result.ssil.giIntensity := 1.0;
  Result.ssil.aoIntensity := 1.0;
  Result.ssil.aoPower := 1.0;
  Result.ssil.maxRadius := 0.2;
  Result.ssil.radius := 4.0;
  Result.ssil.bias := 0.03;
  Result.ssil.enabled := False;

  Result.ssgi.sliceCount := 4;
  Result.ssgi.edgeFade := 0.1;
  Result.ssgi.distanceFalloff := 1.0;
  Result.ssgi.normalRejection := 0.0;
  Result.ssgi.intensity := 1.0;
  Result.ssgi.denoiseSteps := 4;
  Result.ssgi.enabled := False;

  Result.ssr.maxRaySteps := 32;
  Result.ssr.binarySteps := 4;
  Result.ssr.stepSize := 0.125;
  Result.ssr.thickness := 0.2;
  Result.ssr.maxDistance := 4.0;
  Result.ssr.edgeFade := 0.25;
  Result.ssr.enabled := False;

  Result.fog.mode := R3D_FOG_DISABLED;
  Result.fog.color := WHITE;
  Result.fog.start := 1.0;
  Result.fog.end_ := 50.0;
  Result.fog.density := 0.05;
  Result.fog.skyAffect := 0.5;

  Result.volumetricFog.scatteringDensity := 0.01;
  Result.volumetricFog.absortionDensity := 0.03;
  Result.volumetricFog.scatteringColor := WHITE;
  Result.volumetricFog.anisotropy := 0.5;
  Result.volumetricFog.emissionColor := WHITE;
  Result.volumetricFog.emissionEnergy := 0.0;
  Result.volumetricFog.skyAffect := 0.5;
  Result.volumetricFog.length := 50.0;
  Result.volumetricFog.stepSize := 1.0;
  Result.volumetricFog.enabled := False;

  Result.dof.mode := R3D_DOF_DISABLED;
  Result.dof.focusPoint := 10.0;
  Result.dof.focusScale := 1.0;
  Result.dof.nearScale := 1.0;
  Result.dof.maxBlurSize := 20.0;

  Result.bloom.mode := R3D_BLOOM_DISABLED;
  Result.bloom.levels := 0.5;
  Result.bloom.intensity := 0.05;
  Result.bloom.threshold := 0.0;
  Result.bloom.softThreshold := 0.5;
  Result.bloom.filterRadius := 1.0;

  Result.autoExposure.minEV := -1.0;
  Result.autoExposure.maxEV := 1.0;
  Result.autoExposure.exposureCompensation := 0.0;
  Result.autoExposure.adaptationToBright := 0.5;
  Result.autoExposure.adaptationToDark := 1.0;
  Result.autoExposure.enabled := False;

  Result.tonemap.mode := R3D_TONEMAP_LINEAR;
  Result.tonemap.exposure := 1.0;
  Result.tonemap.white := 1.0;

  Result.color.brightness := 1.0;
  Result.color.contrast := 1.0;
  Result.color.saturation := 1.0;
end;

// Note: Delphi does not support "case <string> of" -> if/else chains with SameText

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Single);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if      SameText(Path, 'background.energy') then Env^.background.energy := Value
  else if SameText(Path, 'background.skyBlur') then Env^.background.skyBlur := Value
  else if SameText(Path, 'ambient.energy') then Env^.ambient.energy := Value
  else if SameText(Path, 'ssao.intensity') then Env^.ssao.intensity := Value
  else if SameText(Path, 'ssao.power') then Env^.ssao.power := Value
  else if SameText(Path, 'ssao.maxRadius') then Env^.ssao.maxRadius := Value
  else if SameText(Path, 'ssao.radius') then Env^.ssao.radius := Value
  else if SameText(Path, 'ssao.bias') then Env^.ssao.bias := Value
  else if SameText(Path, 'ssil.giIntensity') then Env^.ssil.giIntensity := Value
  else if SameText(Path, 'ssil.aoIntensity') then Env^.ssil.aoIntensity := Value
  else if SameText(Path, 'ssil.aoPower') then Env^.ssil.aoPower := Value
  else if SameText(Path, 'ssil.maxRadius') then Env^.ssil.maxRadius := Value
  else if SameText(Path, 'ssil.radius') then Env^.ssil.radius := Value
  else if SameText(Path, 'ssil.bias') then Env^.ssil.bias := Value
  else if SameText(Path, 'ssgi.edgeFade') then Env^.ssgi.edgeFade := Value
  else if SameText(Path, 'ssgi.distanceFalloff') then Env^.ssgi.distanceFalloff := Value
  else if SameText(Path, 'ssgi.normalRejection') then Env^.ssgi.normalRejection := Value
  else if SameText(Path, 'ssgi.intensity') then Env^.ssgi.intensity := Value
  else if SameText(Path, 'ssr.stepSize') then Env^.ssr.stepSize := Value
  else if SameText(Path, 'ssr.thickness') then Env^.ssr.thickness := Value
  else if SameText(Path, 'ssr.maxDistance') then Env^.ssr.maxDistance := Value
  else if SameText(Path, 'ssr.edgeFade') then Env^.ssr.edgeFade := Value
  else if SameText(Path, 'fog.start') then Env^.fog.start := Value
  else if SameText(Path, 'fog.end') then Env^.fog.end_ := Value
  else if SameText(Path, 'fog.density') then Env^.fog.density := Value
  else if SameText(Path, 'fog.skyAffect') then Env^.fog.skyAffect := Value
  else if SameText(Path, 'volumetricFog.scatteringDensity') then Env^.volumetricFog.scatteringDensity := Value
  else if SameText(Path, 'volumetricFog.absortionDensity') then Env^.volumetricFog.absortionDensity := Value
  else if SameText(Path, 'volumetricFog.anisotropy') then Env^.volumetricFog.anisotropy := Value
  else if SameText(Path, 'volumetricFog.emissionEnergy') then Env^.volumetricFog.emissionEnergy := Value
  else if SameText(Path, 'volumetricFog.skyAffect') then Env^.volumetricFog.skyAffect := Value
  else if SameText(Path, 'volumetricFog.length') then Env^.volumetricFog.length := Value
  else if SameText(Path, 'volumetricFog.stepSize') then Env^.volumetricFog.stepSize := Value
  else if SameText(Path, 'dof.focusPoint') then Env^.dof.focusPoint := Value
  else if SameText(Path, 'dof.focusScale') then Env^.dof.focusScale := Value
  else if SameText(Path, 'dof.nearScale') then Env^.dof.nearScale := Value
  else if SameText(Path, 'dof.maxBlurSize') then Env^.dof.maxBlurSize := Value
  else if SameText(Path, 'bloom.levels') then Env^.bloom.levels := Value
  else if SameText(Path, 'bloom.intensity') then Env^.bloom.intensity := Value
  else if SameText(Path, 'bloom.threshold') then Env^.bloom.threshold := Value
  else if SameText(Path, 'bloom.softThreshold') then Env^.bloom.softThreshold := Value
  else if SameText(Path, 'bloom.filterRadius') then Env^.bloom.filterRadius := Value
  else if SameText(Path, 'autoExposure.minEV') then Env^.autoExposure.minEV := Value
  else if SameText(Path, 'autoExposure.maxEV') then Env^.autoExposure.maxEV := Value
  else if SameText(Path, 'autoExposure.exposureCompensation') then Env^.autoExposure.exposureCompensation := Value
  else if SameText(Path, 'autoExposure.adaptationToBright') then Env^.autoExposure.adaptationToBright := Value
  else if SameText(Path, 'autoExposure.adaptationToDark') then Env^.autoExposure.adaptationToDark := Value
  else if SameText(Path, 'tonemap.exposure') then Env^.tonemap.exposure := Value
  else if SameText(Path, 'tonemap.white') then Env^.tonemap.white := Value
  else if SameText(Path, 'color.brightness') then Env^.color.brightness := Value
  else if SameText(Path, 'color.contrast') then Env^.color.contrast := Value
  else if SameText(Path, 'color.saturation') then Env^.color.saturation := Value
  else
    raise Exception.CreateFmt('Unknown Single field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Integer);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if      SameText(Path, 'ssao.sampleCount') then Env^.ssao.sampleCount := Value
  else if SameText(Path, 'ssil.sampleCount') then Env^.ssil.sampleCount := Value
  else if SameText(Path, 'ssr.maxRaySteps') then Env^.ssr.maxRaySteps := Value
  else if SameText(Path, 'ssr.binarySteps') then Env^.ssr.binarySteps := Value
  else if SameText(Path, 'ssgi.sliceCount') then Env^.ssgi.sliceCount := Value
  else if SameText(Path, 'sampleCount') then Env^.ssgi.sliceCount := Value       // Compatibility with the FPC version
  else if SameText(Path, 'ssgi.denoiseSteps') then Env^.ssgi.denoiseSteps := Value
  else if SameText(Path, 'denoiseSteps') then Env^.ssgi.denoiseSteps := Value    // Compatibility with the FPC version
  else
    raise Exception.CreateFmt('Unknown Integer field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: Boolean);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if      SameText(Path, 'ssao.enabled') then Env^.ssao.enabled := Value
  else if SameText(Path, 'ssil.enabled') then Env^.ssil.enabled := Value
  else if SameText(Path, 'ssr.enabled') then Env^.ssr.enabled := Value
  else if SameText(Path, 'ssgi.enabled') then Env^.ssgi.enabled := Value
  else if SameText(Path, 'autoExposure.enabled') then Env^.autoExposure.enabled := Value
  else if SameText(Path, 'volumetricFog.enabled') then Env^.volumetricFog.enabled := Value
  else
    raise Exception.CreateFmt('Unknown Boolean field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TColor);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if      SameText(Path, 'background.color') then Env^.background.color := Value
  else if SameText(Path, 'ambient.color') then Env^.ambient.color := Value
  else if SameText(Path, 'fog.color') then Env^.fog.color := Value
  else if SameText(Path, 'volumetricFog.scatteringColor') then Env^.volumetricFog.scatteringColor := Value
  else if SameText(Path, 'volumetricFog.emissionColor') then Env^.volumetricFog.emissionColor := Value
  else
    raise Exception.CreateFmt('Unknown TColor field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Cubemap);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'background.sky') then Env^.background.sky := Value
  else raise Exception.CreateFmt('Unknown TR3D_Cubemap field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_AmbientMap);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'ambient.map') then Env^.ambient.map := Value
  else raise Exception.CreateFmt('Unknown TR3D_AmbientMap field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TQuaternion);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'background.rotation') then Env^.background.rotation := Value
  else raise Exception.CreateFmt('Unknown TQuaternion field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Bloom);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'bloom.mode') then Env^.bloom.mode := Value
  else raise Exception.CreateFmt('Unknown TR3D_Bloom field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Fog);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'fog.mode') then Env^.fog.mode := Value
  else raise Exception.CreateFmt('Unknown TR3D_Fog field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_DoF);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'dof.mode') then Env^.dof.mode := Value
  else raise Exception.CreateFmt('Unknown TR3D_DoF field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_Tonemap);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'tonemap.mode') then Env^.tonemap.mode := Value
  else raise Exception.CreateFmt('Unknown TR3D_Tonemap field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_EnvBackground);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'background') then Env^.background := Value
  else raise Exception.CreateFmt('Unknown field or wrong type: %s', [Path]);
end;

procedure R3D_ENVIRONMENT_SET(const Path: string; Value: TR3D_EnvAmbient);
var
  Env: PR3D_Environment;
begin
  Env := R3D_GetEnvironment();
  if not Assigned(Env) then Exit;

  if SameText(Path, 'ambient') then Env^.ambient := Value
  else raise Exception.CreateFmt('Unknown field or wrong type: %s', [Path]);
end;

end.

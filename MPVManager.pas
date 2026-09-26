unit MPVManager;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.OpenGL, Raylib, rlgl,
  MPVEmbedded;

type
  TMPVPlayer = class
  private
    FMPV: mpv_handle;
    FRenderCtx: mpv_render_context;
    FTarget: TRenderTexture2D;
    FInitParams: mpv_opengl_init_params;
    FParams: array[0..2] of mpv_render_param;
    FFBO: mpv_opengl_fbo;
    FFlipY: Integer;
    FFBOParams: array[0..2] of mpv_render_param;
    FHasRenderContext: Boolean;
    FPendingFile: string;
    procedure HandleMPVEvents;
  public
    constructor Create(W, H: Integer);
    destructor Destroy; override;
    procedure LoadFile(const AFileName: string);
    procedure Update;
    procedure Render;
    property Target: TRenderTexture2D read FTarget;
    property PendingFile: string read FPendingFile write FPendingFile;
  end;

procedure mpv_update_callback(cb_ctx: pointer); cdecl;

implementation

procedure mpv_update_callback(cb_ctx: pointer); cdecl;
begin
  // Empty, we poll manually in Update
end;

function get_proc_address(ctx: pointer; name: PAnsiChar): pointer; cdecl;
begin
  Result := wglGetProcAddress(name);
  if Result = nil then
    Result := Winapi.Windows.GetProcAddress(GetModuleHandle('opengl32.dll'), name);
end;

{ TMPVPlayer }

constructor TMPVPlayer.Create(W, H: Integer);
begin
  if not LoadMPV then
    raise Exception.Create('mpv-2.dll not found or failed to load');

  FTarget := LoadRenderTexture(W, H);
  SetTextureFilter(FTarget.texture, TEXTURE_FILTER_TRILINEAR);

  FMPV := mpv_create();
  if FMPV = nil then
    raise Exception.Create('Failed to create mpv handle');

  mpv_set_option_string(FMPV, 'vo', 'libmpv');
  mpv_set_option_string(FMPV, 'hwdec', 'auto');

  mpv_set_option_string(FMPV, 'opengl', 'yes');
  mpv_set_option_string(FMPV, 'opengl-debug', 'yes');

  mpv_set_option_string(FMPV, 'ao', 'auto');
  mpv_set_option_string(FMPV, 'audio-display', 'no');
  mpv_set_option_string(FMPV, 'vid', '1');

  mpv_set_option_string(FMPV, 'video-sync', 'audio');
  mpv_set_option_string(FMPV, 'audio-buffer', '0.2');

  if mpv_initialize(FMPV) < 0 then
    raise Exception.Create('Failed to initialize mpv');

  FInitParams.get_proc_address := @get_proc_address;
  FInitParams.get_proc_address_ctx := nil;

  FParams[0]._type := MPV_RENDER_PARAM_OPENGL_INIT_PARAMS;
  FParams[0].data := @FInitParams;
  FParams[1]._type := MPV_RENDER_PARAM_API_TYPE;
  FParams[1].data := MPV_RENDER_API_TYPE_OPENGL;
  FParams[2]._type := MPV_RENDER_PARAM_INVALID;
  FParams[2].data := nil;

  FRenderCtx := nil;
  if mpv_render_context_create(@FRenderCtx, FMPV, @FParams[0]) < 0 then
    raise Exception.Create('Failed to create mpv render context');

  mpv_render_context_set_update_callback(FRenderCtx, mpv_update_callback, nil);

  FHasRenderContext := True;

  if FPendingFile <> '' then
    LoadFile(FPendingFile);
end;


destructor TMPVPlayer.Destroy;
begin
  if FRenderCtx <> nil then
    mpv_render_context_free(FRenderCtx);
  if FMPV <> nil then
    mpv_terminate_destroy(FMPV);

  UnloadRenderTexture(FTarget);
  inherited;
end;

procedure TMPVPlayer.HandleMPVEvents;
var
  Event: Pointer;
  EventID: Integer;
begin
  if FMPV <> nil then
  begin
    while True do
    begin
      Event := mpv_wait_event(FMPV, 0);
      if Event = nil then
        Break;

      EventID := PInteger(Event)^;

      if EventID = 0 then
        Break;

    end;
  end;
end;

procedure TMPVPlayer.Update;
begin
  HandleMPVEvents;
end;

procedure TMPVPlayer.LoadFile(const AFileName: string);
var
  Args: array[0..1] of PAnsiChar;
begin
  Args[0] := 'loadfile';
  Args[1] := PAnsiChar(AnsiString(AFileName));
  mpv_command(FMPV, @Args[0]);
end;

procedure TMPVPlayer.Render;
var
  UpdateFlags: UInt64;
begin
  if FRenderCtx = nil then
    Exit;

  UpdateFlags := mpv_render_context_update(FRenderCtx);

  if (UpdateFlags and MPV_RENDER_UPDATE_FRAME) = 0 then
    Exit;

  FFBO.fbo := FTarget.id;
  FFBO.w := FTarget.texture.width;
  FFBO.h := FTarget.texture.height;
  FFBO.internal_format := 0;

  FFlipY := 0;

  FFBOParams[0]._type := MPV_RENDER_PARAM_OPENGL_FBO;
  FFBOParams[0].data := @FFBO;
  FFBOParams[1]._type := MPV_RENDER_PARAM_FLIP_Y;
  FFBOParams[1].data := @FFlipY;
  FFBOParams[2]._type := MPV_RENDER_PARAM_INVALID;
  FFBOParams[2].data := nil;

  mpv_render_context_render(FRenderCtx, @FFBOParams[0]);
end;

end.


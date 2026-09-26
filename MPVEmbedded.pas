unit MPVEmbedded;

interface

uses
  Winapi.Windows, System.SysUtils;

const
  LIBMPV_DLL = 'mpv-2.dll';

type
  mpv_handle = Pointer;

  Pmpv_handle = ^mpv_handle;

  mpv_render_context = Pointer;

  Pmpv_render_context = ^mpv_render_context;

  // MPV Enums
  mpv_format = (MPV_FORMAT_NONE = 0, MPV_FORMAT_STRING = 1, MPV_FORMAT_OSD_STRING = 2, MPV_FORMAT_FLAG = 3, MPV_FORMAT_INT64 = 4, MPV_FORMAT_DOUBLE = 5, MPV_FORMAT_NODE = 6, MPV_FORMAT_NODE_ARRAY = 7, MPV_FORMAT_NODE_MAP = 8, MPV_FORMAT_BYTE_ARRAY = 9);

  mpv_render_param_type = (MPV_RENDER_PARAM_INVALID = 0, MPV_RENDER_PARAM_API_TYPE = 1, MPV_RENDER_PARAM_OPENGL_INIT_PARAMS = 2, MPV_RENDER_PARAM_OPENGL_FBO = 3, MPV_RENDER_PARAM_FLIP_Y = 4, MPV_RENDER_PARAM_DEPTH = 5, MPV_RENDER_PARAM_ICC_PROFILE = 6, MPV_RENDER_PARAM_AMBIENT_LIGHT = 7, MPV_RENDER_PARAM_X11_DISPLAY = 8, MPV_RENDER_PARAM_WL_DISPLAY = 9, MPV_RENDER_PARAM_ADVANCED_CONTROL = 10, MPV_RENDER_PARAM_NEXT_FRAME_INFO = 11, MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME = 12, MPV_RENDER_PARAM_SKIP_RENDERING = 13);

  mpv_opengl_init_params = record
    get_proc_address: function(ctx: Pointer; name: PAnsiChar): Pointer; cdecl;
    get_proc_address_ctx: Pointer;
  end;

  Pmpv_opengl_init_params = ^mpv_opengl_init_params;

  mpv_opengl_fbo = record
    fbo: Integer;
    w: Integer;
    h: Integer;
    internal_format: Integer;
  end;

  Pmpv_opengl_fbo = ^mpv_opengl_fbo;

  mpv_render_param = record
    _type: mpv_render_param_type;
    data: Pointer;
  end;

  Pmpv_render_param = ^mpv_render_param;

  mpv_render_update_fn = procedure(cb_ctx: Pointer); cdecl;

const
  MPV_RENDER_API_TYPE_OPENGL: PAnsiChar = 'opengl';
  MPV_RENDER_UPDATE_FRAME = 1;

var
  mpv_create: function: Pmpv_handle; cdecl;
  mpv_initialize: function(ctx: mpv_handle): Integer; cdecl;
  mpv_terminate_destroy: procedure(ctx: mpv_handle); cdecl;
  mpv_set_option_string: function(ctx: mpv_handle; name: PAnsiChar; data: PAnsiChar): Integer; cdecl;
  mpv_command: function(ctx: mpv_handle; args: PPAnsiChar): Integer; cdecl;
  mpv_wait_event: function(ctx: mpv_handle; timeout: Double): Pointer; cdecl;
  mpv_render_context_create: function(res: Pmpv_render_context; mpv: mpv_handle; params: Pmpv_render_param): Integer; cdecl;
  mpv_render_context_set_update_callback: procedure(ctx: mpv_render_context; callback: mpv_render_update_fn; callback_ctx: Pointer); cdecl;
  mpv_render_context_update: function(ctx: mpv_render_context): UInt64; cdecl;
  mpv_render_context_render: function(ctx: mpv_render_context; params: Pmpv_render_param): Integer; cdecl;
  mpv_render_context_free: procedure(ctx: mpv_render_context); cdecl;

var
  MPVLibHandle: THandle = 0;

function LoadMPV: Boolean;

procedure UnloadMPV;

implementation

function GetProcAddr(Lib: THandle; const Name: string): Pointer;
begin
  Result := GetProcAddress(Lib, PChar(Name));
  if not Assigned(Result) then
    raise Exception.CreateFmt('MPV function %s not found', [Name]);
end;

function LoadMPV: Boolean;
begin
  Result := False;
  if MPVLibHandle <> 0 then
    Exit(True);

  MPVLibHandle := LoadLibrary(LIBMPV_DLL);
  if MPVLibHandle = 0 then
    Exit;

  try
    mpv_create := GetProcAddr(MPVLibHandle, 'mpv_create');
    mpv_initialize := GetProcAddr(MPVLibHandle, 'mpv_initialize');
    mpv_terminate_destroy := GetProcAddr(MPVLibHandle, 'mpv_terminate_destroy');
    mpv_set_option_string := GetProcAddr(MPVLibHandle, 'mpv_set_option_string');
    mpv_command := GetProcAddr(MPVLibHandle, 'mpv_command');
    mpv_wait_event := GetProcAddr(MPVLibHandle, 'mpv_wait_event');

    mpv_render_context_create := GetProcAddr(MPVLibHandle, 'mpv_render_context_create');
    mpv_render_context_set_update_callback := GetProcAddr(MPVLibHandle, 'mpv_render_context_set_update_callback');
    mpv_render_context_update := GetProcAddr(MPVLibHandle, 'mpv_render_context_update');
    mpv_render_context_render := GetProcAddr(MPVLibHandle, 'mpv_render_context_render');
    mpv_render_context_free := GetProcAddr(MPVLibHandle, 'mpv_render_context_free');

    Result := True;
  except
    on E: Exception do
    begin
      FreeLibrary(MPVLibHandle);
      MPVLibHandle := 0;
      raise;
    end;
  end;
end;

procedure UnloadMPV;
begin
  if MPVLibHandle <> 0 then
  begin
    FreeLibrary(MPVLibHandle);
    MPVLibHandle := 0;
  end;
end;

end.


unit MiniAudio4Delphi;

{==============================================================================*
 *  MiniAudio4Delphi - Complete Wrapper for MiniAudio
 *------------------------------------------------------------------------------
 *  Version: 0.1 (Initial Release)
 *
 *  This unit wraps the full high-level API exported by the miniaudio.dll.
 *  It provides Delphi access to Engine, Sounds, 3D Spatialization, Groups,
 *  Decoders and Effects.
 *
 *  Note on Memory Management:
 *  Because the internal C structs of miniaudio are huge, we use untyped
 *  pointers and dynamically allocate the exact required memory at runtime
 *  using the ma_*_sizeof() helper functions.
 *==============================================================================}

interface

uses
  System.SysUtils;

type
  // Opaque handles (We use Pointer because the internal C structs are massive)
  ma_engine = Pointer;

  ma_sound = Pointer;

  ma_sound_group = Pointer;

  ma_data_source = Pointer;

  ma_device = Pointer;

  ma_context = Pointer;

  ma_log = Pointer;

  ma_node = Pointer;

  ma_node_graph = Pointer;

  ma_resource_manager = Pointer;

  ma_decoder = Pointer;

  ma_encoder = Pointer;

  ma_spatializer = Pointer;

  // Result type for miniaudio functions (0 = MA_SUCCESS)
  ma_result = Integer;

const
  MINIAUDIO_LIB = 'miniaudio.dll';
  MA_SUCCESS = 0;

  // Attenuation Models (Used for 3D Audio)
  ma_attenuation_model_none = 0;
  ma_attenuation_model_inverse = 1;
  ma_attenuation_model_linear = 2;
  ma_attenuation_model_exponential = 3;

// =============================================================================
// CORE & MEMORY (Sizeof helper functions for dynamic allocation)
// =============================================================================
function ma_engine_sizeof(): NativeUInt; cdecl;

function ma_sound_sizeof(): NativeUInt; cdecl;

function ma_sound_group_sizeof(): NativeUInt; cdecl;

function ma_device_sizeof(): NativeUInt; cdecl;

function ma_context_sizeof(): NativeUInt; cdecl;

function ma_decoder_sizeof(): NativeUInt; cdecl;

function ma_spatializer_sizeof(): NativeUInt; cdecl;

function ma_log_sizeof(): NativeUInt; cdecl;

function ma_node_graph_sizeof(): NativeUInt; cdecl;

// =============================================================================
// ENGINE
// =============================================================================
function ma_engine_init(pConfig: Pointer; pEngine: ma_engine): ma_result; cdecl;

procedure ma_engine_uninit(pEngine: ma_engine); cdecl;

procedure ma_engine_start(pEngine: ma_engine); cdecl;

procedure ma_engine_stop(pEngine: ma_engine); cdecl;

procedure ma_engine_set_volume(pEngine: ma_engine; volume: Single); cdecl;

function ma_engine_get_volume(pEngine: ma_engine): Single; cdecl;

procedure ma_engine_set_gain_db(pEngine: ma_engine; gainDB: Single); cdecl;

function ma_engine_get_sample_rate(pEngine: ma_engine): Integer; cdecl;

function ma_engine_get_channels(pEngine: ma_engine): Integer; cdecl;

function ma_engine_get_time(pEngine: ma_engine): UInt64; cdecl;

procedure ma_engine_set_time(pEngine: ma_engine; time: UInt64); cdecl;

// Engine Convenience (Plays a sound directly without an ma_sound object)
function ma_engine_play_sound(pEngine: ma_engine; pFilePath: PAnsiChar; pGroup: ma_sound_group): ma_result; cdecl;

// =============================================================================
// ENGINE LISTENER (The "ear" in the 3D world - usually the camera)
// =============================================================================
procedure ma_engine_listener_set_position(pEngine: ma_engine; x, y, z: Single); cdecl;

procedure ma_engine_listener_set_direction(pEngine: ma_engine; x, y, z: Single); cdecl;

procedure ma_engine_listener_set_velocity(pEngine: ma_engine; x, y, z: Single); cdecl;

procedure ma_engine_listener_set_world_up(pEngine: ma_engine; x, y, z: Single); cdecl;

procedure ma_engine_listener_set_enabled(pEngine: ma_engine; enabled: Integer); cdecl;

// =============================================================================
// SOUND (Load and play audio files)
// =============================================================================
function ma_sound_init_from_file(pEngine: ma_engine; pFilePath: PAnsiChar; Flags: UInt32; pGroup: ma_sound_group; pDone: Pointer; pSound: ma_sound): ma_result; cdecl;

function ma_sound_init_copy(pEngine: ma_engine; pExistingSound: ma_sound; Flags: UInt32; pGroup: ma_sound_group; pSound: ma_sound): ma_result; cdecl;

function ma_sound_init_from_data_source(pEngine: ma_engine; pDataSource: ma_data_source; Flags: UInt32; pGroup: ma_sound_group; pSound: ma_sound): ma_result; cdecl;

procedure ma_sound_uninit(pSound: ma_sound); cdecl;

procedure ma_sound_start(pSound: ma_sound); cdecl;

procedure ma_sound_stop(pSound: ma_sound); cdecl;

function ma_sound_is_playing(pSound: ma_sound): Integer; cdecl;

procedure ma_sound_set_looping(pSound: ma_sound; isLooping: Integer); cdecl;

function ma_sound_is_looping(pSound: ma_sound): Integer; cdecl;

procedure ma_sound_seek_to_pcm_frame(pSound: ma_sound; frameIndex: UInt64); cdecl;

function ma_sound_get_cursor_in_pcm_frames(pSound: ma_sound; out pCursor: UInt64): ma_result; cdecl;

function ma_sound_get_length_in_pcm_frames(pSound: ma_sound; out pLength: UInt64): ma_result; cdecl;

// Sound Properties
procedure ma_sound_set_volume(pSound: ma_sound; volume: Single); cdecl;

function ma_sound_get_volume(pSound: ma_sound): Single; cdecl;

procedure ma_sound_set_pan(pSound: ma_sound; pan: Single); cdecl;

function ma_sound_get_pan(pSound: ma_sound): Single; cdecl;

procedure ma_sound_set_pitch(pSound: ma_sound; pitch: Single); cdecl;

function ma_sound_get_pitch(pSound: ma_sound): Single; cdecl;

procedure ma_sound_set_fade_in_pcm_frames(pSound: ma_sound; volumeBeg: Single; volumeEnd: Single; fadeLengthInFrames: UInt64); cdecl;

// =============================================================================
// SOUND 3D AUDIO
// =============================================================================
procedure ma_sound_set_position(pSound: ma_sound; x, y, z: Single); cdecl;

procedure ma_sound_set_direction(pSound: ma_sound; x, y, z: Single); cdecl;

procedure ma_sound_set_velocity(pSound: ma_sound; x, y, z: Single); cdecl;

procedure ma_sound_set_attenuation_model(pSound: ma_sound; model: Integer); cdecl;

procedure ma_sound_set_min_distance(pSound: ma_sound; minDistance: Single); cdecl;

procedure ma_sound_set_max_distance(pSound: ma_sound; maxDistance: Single); cdecl;

procedure ma_sound_set_rolloff(pSound: ma_sound; rolloff: Single); cdecl;

procedure ma_sound_set_doppler_factor(pSound: ma_sound; factor: Single); cdecl;

procedure ma_sound_set_spatialization_enabled(pSound: ma_sound; enabled: Integer); cdecl;

// =============================================================================
// SOUND GROUPS (Buses for e.g. Music, SFX, Voice)
// =============================================================================
function ma_sound_group_init(pEngine: ma_engine; Flags: UInt32; pParentGroup: ma_sound_group; pGroup: ma_sound_group): ma_result; cdecl;

procedure ma_sound_group_uninit(pGroup: ma_sound_group); cdecl;

procedure ma_sound_group_start(pGroup: ma_sound_group); cdecl;

procedure ma_sound_group_stop(pGroup: ma_sound_group); cdecl;

procedure ma_sound_group_set_volume(pGroup: ma_sound_group; volume: Single); cdecl;

procedure ma_sound_group_set_pan(pGroup: ma_sound_group; pan: Single); cdecl;

procedure ma_sound_group_set_pitch(pGroup: ma_sound_group; pitch: Single); cdecl;

// =============================================================================
// NODE GRAPH (For advanced audio routing)
// =============================================================================
function ma_node_graph_init(pConfig: Pointer; pAllocationCallbacks: Pointer; pNodeGraph: ma_node_graph): ma_result; cdecl;

procedure ma_node_graph_uninit(pNodeGraph: ma_node_graph); cdecl;

procedure ma_node_set_output_bus_volume(pNode: ma_node; outputBusIndex: Cardinal; volume: Single); cdecl;

// =============================================================================
// SPATIALIZER (Advanced 3D Audio Control)
// =============================================================================
function ma_spatializer_init(pConfig: Pointer; pAllocationCallbacks: Pointer; pSpatializer: ma_spatializer): ma_result; cdecl;

procedure ma_spatializer_uninit(pSpatializer: ma_spatializer); cdecl;

procedure ma_spatializer_set_position(pSpatializer: ma_spatializer; x, y, z: Single); cdecl;

procedure ma_spatializer_set_direction(pSpatializer: ma_spatializer; x, y, z: Single); cdecl;

procedure ma_spatializer_set_velocity(pSpatializer: ma_spatializer; x, y, z: Single); cdecl;

// =============================================================================
// DEVICE (Low-Level Audio Device Control)
// =============================================================================
function ma_device_init(pContext: ma_context; pConfig: Pointer; pDevice: ma_device): ma_result; cdecl;

function ma_device_init_ex(pConfig: Pointer; pDevice: ma_device): ma_result; cdecl;

procedure ma_device_uninit(pDevice: ma_device); cdecl;

function ma_device_start(pDevice: ma_device): ma_result; cdecl;

function ma_device_stop(pDevice: ma_device): ma_result; cdecl;

procedure ma_device_set_master_volume(pDevice: ma_device; volume: Single); cdecl;

// =============================================================================
// DATA SOURCES (Generic Audio Sources)
// =============================================================================
function ma_data_source_init(pConfig: Pointer; pDataSource: ma_data_source): ma_result; cdecl;

procedure ma_data_source_uninit(pDataSource: ma_data_source); cdecl;

function ma_data_source_read_pcm_frames(pDataSource: ma_data_source; pFramesOut: Pointer; frameCount: NativeUInt; out pFramesRead: NativeUInt): ma_result; cdecl;

function ma_data_source_seek_to_pcm_frame(pDataSource: ma_data_source; frameIndex: UInt64): ma_result; cdecl;

function ma_data_source_get_data_format(pDataSource: ma_data_source; out pFormat: Cardinal; out pChannels: Cardinal; out pSampleRate: Cardinal; pChannelMap: Pointer; channelMapCap: Cardinal): ma_result; cdecl;

function ma_data_source_get_cursor_in_pcm_frames(pDataSource: ma_data_source; out pCursor: UInt64): ma_result; cdecl;

function ma_data_source_get_length_in_pcm_frames(pDataSource: ma_data_source; out pLength: UInt64): ma_result; cdecl;

procedure ma_data_source_set_looping(pDataSource: ma_data_source; isLooping: Integer); cdecl;

// =============================================================================
// AUDIO BUFFER (Loads audio entirely into RAM)
// =============================================================================
function ma_audio_buffer_init(pConfig: Pointer; pAudioBuffer: Pointer): ma_result; cdecl;

function ma_audio_buffer_init_copy(pConfig: Pointer; pExistingBuffer: Pointer; pAudioBuffer: Pointer): ma_result; cdecl;

function ma_audio_buffer_alloc_and_init(pConfig: Pointer; out ppAudioBuffer: Pointer): ma_result; cdecl;

procedure ma_audio_buffer_uninit(pAudioBuffer: Pointer); cdecl;

procedure ma_audio_buffer_uninit_and_free(pAudioBuffer: Pointer); cdecl;

function ma_audio_buffer_config_init(format: Cardinal; channels: Cardinal; sampleRate: Cardinal; sizeInFrames: UInt64; pData: Pointer): Pointer; cdecl; // Returns Config

// =============================================================================
// DECODERS (MP3, WAV, FLAC - Low-Level Decode)
// =============================================================================

function ma_decoder_config_init(): Pointer; cdecl; // Returns initialized Config

function ma_decoder_init(pFilePath: PAnsiChar; pConfig: Pointer; pDecoder: ma_decoder): ma_result; cdecl;

function ma_decoder_init_memory(pData: Pointer; dataSize: NativeUInt; pConfig: Pointer; pDecoder: ma_decoder): ma_result; cdecl;

function ma_decoder_init_file(pFilePath: PAnsiChar; pConfig: Pointer; pDecoder: ma_decoder): ma_result; cdecl;

function ma_decoder_init_file_w(pFilePath: PWideChar; pConfig: Pointer; pDecoder: ma_decoder): ma_result; cdecl;

procedure ma_decoder_uninit(pDecoder: ma_decoder); cdecl;

function ma_decoder_read_pcm_frames(pDecoder: ma_decoder; pFramesOut: Pointer; frameCount: NativeUInt; out pFramesRead: NativeUInt): ma_result; cdecl;

function ma_decoder_seek_to_pcm_frame(pDecoder: ma_decoder; frameIndex: UInt64): ma_result; cdecl;

function ma_decoder_get_data_format(pDecoder: ma_decoder; out pFormat: Cardinal; out pChannels: Cardinal; out pSampleRate: Cardinal; pChannelMap: Pointer; channelMapCap: Cardinal): ma_result; cdecl;

function ma_decoder_get_length_in_pcm_frames(pDecoder: ma_decoder; out pLength: UInt64): ma_result; cdecl;

// Specific Decoder Init functions for formats
function ma_wav_init_memory(pData: Pointer; dataSize: NativeUInt; pWav: Pointer): ma_result; cdecl;

function ma_mp3_init_memory(pData: Pointer; dataSize: NativeUInt; pMp3: Pointer): ma_result; cdecl;

function ma_flac_init_memory(pData: Pointer; dataSize: NativeUInt; pFlac: Pointer): ma_result; cdecl;

procedure ma_wav_uninit(pWav: Pointer); cdecl;

procedure ma_mp3_uninit(pMp3: Pointer); cdecl;

procedure ma_flac_uninit(pFlac: Pointer); cdecl;

// =============================================================================
// ENCODERS (Record audio and save as WAV)
// =============================================================================
function ma_encoder_config_init(): Pointer; cdecl;

function ma_encoder_init_file(pFilePath: PAnsiChar; pConfig: Pointer; pEncoder: ma_encoder): ma_result; cdecl;

function ma_encoder_init_file_w(pFilePath: PWideChar; pConfig: Pointer; pEncoder: ma_encoder): ma_result; cdecl;

procedure ma_encoder_uninit(pEncoder: ma_encoder); cdecl;

function ma_encoder_write_pcm_frames(pEncoder: ma_encoder; pFramesIn: Pointer; frameCount: NativeUInt; out pFramesWritten: NativeUInt): ma_result; cdecl;

// =============================================================================
// NODES & EFFECTS (Biquad Filter, Delay, etc.)
// =============================================================================
function ma_node_init(pNodeGraph: ma_node_graph; pConfig: Pointer; pAllocationCallbacks: Pointer; pNode: ma_node): ma_result; cdecl;

procedure ma_node_uninit(pNode: ma_node; pAllocationCallbacks: Pointer); cdecl;

procedure ma_node_attach_output_bus(pNode: ma_node; outputBusIndex: Cardinal; pOtherNode: ma_node; otherNodeInputBusIndex: Cardinal); cdecl;

procedure ma_node_detach_output_bus(pNode: ma_node; outputBusIndex: Cardinal); cdecl;

// Biquad Filter (Lowpass, Highpass, etc.)
function ma_biquad_node_config_init(format: Cardinal; channels: Cardinal; loPass: Single; hiPass: Single): Pointer; cdecl;

function ma_biquad_node_init(pNodeGraph: ma_node_graph; pConfig: Pointer; pAllocationCallbacks: Pointer; pNode: ma_node): ma_result; cdecl;

procedure ma_biquad_node_uninit(pNode: ma_node; pAllocationCallbacks: Pointer); cdecl;

// Delay Effect
function ma_delay_node_config_init(format: Cardinal; channels: Cardinal; sampleRate: Cardinal; delayInFrames: UInt32; decay: Single): Pointer; cdecl;

function ma_delay_node_init(pNodeGraph: ma_node_graph; pConfig: Pointer; pAllocationCallbacks: Pointer; pNode: ma_node): ma_result; cdecl;

procedure ma_delay_node_uninit(pNode: ma_node; pAllocationCallbacks: Pointer); cdecl;

// Waveform (Generate Sine, Square, Sawtooth)
function ma_waveform_config_init(format: Cardinal; channels: Cardinal; sampleRate: Cardinal; type_: Integer; amplitude: Single; frequency: Single): Pointer; cdecl;

function ma_waveform_init(pConfig: Pointer; pWaveform: Pointer): ma_result; cdecl;

procedure ma_waveform_uninit(pWaveform: Pointer); cdecl;

// =============================================================================
// RESOURCE MANAGER (Audio-Streaming & Memory Management)
// =============================================================================
function ma_resource_manager_init(pConfig: Pointer; pResourceManager: ma_resource_manager): ma_result; cdecl;

procedure ma_resource_manager_uninit(pResourceManager: ma_resource_manager); cdecl;

function ma_resource_manager_register_file(pResourceManager: ma_resource_manager; pFilePath: PAnsiChar): ma_result; cdecl;

function ma_resource_manager_unregister_file(pResourceManager: ma_resource_manager; pFilePath: PAnsiChar): ma_result; cdecl;

// =============================================================================
// UTILS & CONVERSION (Volume, Clamp, etc.)
// =============================================================================
function ma_volume_db_to_linear(decibels: Single): Single; cdecl;

function ma_volume_linear_to_db(linear: Single): Single; cdecl;

procedure ma_apply_volume_factor_f32(pFrames: PSingle; frameCount: NativeUInt; channels: Cardinal; volumeFactor: Single); cdecl;

procedure ma_silence_pcm_frames(pFrames: Pointer; frameCount: NativeUInt; format: Cardinal; channels: Cardinal); cdecl;

function ma_convert_frames(pFramesOut: Pointer; frameCountOut: NativeUInt; formatOut: Cardinal; channelsOut: Cardinal; sampleRateOut: Cardinal; pFramesIn: Pointer; frameCountIn: NativeUInt; formatIn: Cardinal; channelsIn: Cardinal; sampleRateIn: Cardinal): NativeUInt; cdecl;

// =============================================================================
// LOGGING
// =============================================================================
function ma_log_init(pAllocationCallbacks: Pointer; pLog: ma_log): ma_result; cdecl;

procedure ma_log_uninit(pLog: ma_log); cdecl;

procedure ma_log_post(pLog: ma_log; level: Integer; pMessage: PAnsiChar); cdecl;

implementation

// CORE & MEMORY

function ma_engine_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_sound_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_sound_group_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_device_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_context_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_decoder_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_spatializer_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_log_sizeof; cdecl; external MINIAUDIO_LIB;

function ma_node_graph_sizeof; cdecl; external MINIAUDIO_LIB;

// ENGINE
function ma_engine_init; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_start; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_stop; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_set_volume; cdecl; external MINIAUDIO_LIB;

function ma_engine_get_volume; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_set_gain_db; cdecl; external MINIAUDIO_LIB;

function ma_engine_get_sample_rate; cdecl; external MINIAUDIO_LIB;

function ma_engine_get_channels; cdecl; external MINIAUDIO_LIB;

function ma_engine_get_time; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_set_time; cdecl; external MINIAUDIO_LIB;

function ma_engine_play_sound; cdecl; external MINIAUDIO_LIB;

// LISTENER
procedure ma_engine_listener_set_position; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_listener_set_direction; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_listener_set_velocity; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_listener_set_world_up; cdecl; external MINIAUDIO_LIB;

procedure ma_engine_listener_set_enabled; cdecl; external MINIAUDIO_LIB;

// SOUND
function ma_sound_init_from_file; cdecl; external MINIAUDIO_LIB;

function ma_sound_init_copy; cdecl; external MINIAUDIO_LIB;

function ma_sound_init_from_data_source; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_start; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_stop; cdecl; external MINIAUDIO_LIB;

function ma_sound_is_playing; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_looping; cdecl; external MINIAUDIO_LIB;

function ma_sound_is_looping; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_seek_to_pcm_frame; cdecl; external MINIAUDIO_LIB;

function ma_sound_get_cursor_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_sound_get_length_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_volume; cdecl; external MINIAUDIO_LIB;

function ma_sound_get_volume; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_pan; cdecl; external MINIAUDIO_LIB;

function ma_sound_get_pan; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_pitch; cdecl; external MINIAUDIO_LIB;

function ma_sound_get_pitch; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_fade_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

// 3D AUDIO
procedure ma_sound_set_position; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_direction; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_velocity; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_attenuation_model; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_min_distance; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_max_distance; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_rolloff; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_doppler_factor; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_set_spatialization_enabled; cdecl; external MINIAUDIO_LIB;

// GROUPS
function ma_sound_group_init; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_start; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_stop; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_set_volume; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_set_pan; cdecl; external MINIAUDIO_LIB;

procedure ma_sound_group_set_pitch; cdecl; external MINIAUDIO_LIB;

// NODE GRAPH
function ma_node_graph_init; cdecl; external MINIAUDIO_LIB;

procedure ma_node_graph_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_node_set_output_bus_volume; cdecl; external MINIAUDIO_LIB;

// SPATIALIZER
function ma_spatializer_init; cdecl; external MINIAUDIO_LIB;

procedure ma_spatializer_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_spatializer_set_position; cdecl; external MINIAUDIO_LIB;

procedure ma_spatializer_set_direction; cdecl; external MINIAUDIO_LIB;

procedure ma_spatializer_set_velocity; cdecl; external MINIAUDIO_LIB;

// DEVICE
function ma_device_init; cdecl; external MINIAUDIO_LIB;

function ma_device_init_ex; cdecl; external MINIAUDIO_LIB;

procedure ma_device_uninit; cdecl; external MINIAUDIO_LIB;

function ma_device_start; cdecl; external MINIAUDIO_LIB;

function ma_device_stop; cdecl; external MINIAUDIO_LIB;

procedure ma_device_set_master_volume; cdecl; external MINIAUDIO_LIB;

// DATA SOURCES
function ma_data_source_init; cdecl; external MINIAUDIO_LIB;

procedure ma_data_source_uninit; cdecl; external MINIAUDIO_LIB;

function ma_data_source_read_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_data_source_seek_to_pcm_frame; cdecl; external MINIAUDIO_LIB;

function ma_data_source_get_data_format; cdecl; external MINIAUDIO_LIB;

function ma_data_source_get_cursor_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_data_source_get_length_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

procedure ma_data_source_set_looping; cdecl; external MINIAUDIO_LIB;

// AUDIO BUFFER
function ma_audio_buffer_init; cdecl; external MINIAUDIO_LIB;

function ma_audio_buffer_init_copy; cdecl; external MINIAUDIO_LIB;

function ma_audio_buffer_alloc_and_init; cdecl; external MINIAUDIO_LIB;

procedure ma_audio_buffer_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_audio_buffer_uninit_and_free; cdecl; external MINIAUDIO_LIB;

function ma_audio_buffer_config_init; cdecl; external MINIAUDIO_LIB;

// DECODERS
function ma_decoder_config_init; cdecl; external MINIAUDIO_LIB;

function ma_decoder_init; cdecl; external MINIAUDIO_LIB;

function ma_decoder_init_memory; cdecl; external MINIAUDIO_LIB;

function ma_decoder_init_file; cdecl; external MINIAUDIO_LIB;

function ma_decoder_init_file_w; cdecl; external MINIAUDIO_LIB;

procedure ma_decoder_uninit; cdecl; external MINIAUDIO_LIB;

function ma_decoder_read_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_decoder_seek_to_pcm_frame; cdecl; external MINIAUDIO_LIB;

function ma_decoder_get_data_format; cdecl; external MINIAUDIO_LIB;

function ma_decoder_get_length_in_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_wav_init_memory; cdecl; external MINIAUDIO_LIB;

function ma_mp3_init_memory; cdecl; external MINIAUDIO_LIB;

function ma_flac_init_memory; cdecl; external MINIAUDIO_LIB;

procedure ma_wav_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_mp3_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_flac_uninit; cdecl; external MINIAUDIO_LIB;

// ENCODERS
function ma_encoder_config_init; cdecl; external MINIAUDIO_LIB;

function ma_encoder_init_file; cdecl; external MINIAUDIO_LIB;

function ma_encoder_init_file_w; cdecl; external MINIAUDIO_LIB;

procedure ma_encoder_uninit; cdecl; external MINIAUDIO_LIB;

function ma_encoder_write_pcm_frames; cdecl; external MINIAUDIO_LIB;

// NODES & EFFECTS
function ma_node_init; cdecl; external MINIAUDIO_LIB;

procedure ma_node_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_node_attach_output_bus; cdecl; external MINIAUDIO_LIB;

procedure ma_node_detach_output_bus; cdecl; external MINIAUDIO_LIB;

function ma_biquad_node_config_init; cdecl; external MINIAUDIO_LIB;

function ma_biquad_node_init; cdecl; external MINIAUDIO_LIB;

procedure ma_biquad_node_uninit; cdecl; external MINIAUDIO_LIB;

function ma_delay_node_config_init; cdecl; external MINIAUDIO_LIB;

function ma_delay_node_init; cdecl; external MINIAUDIO_LIB;

procedure ma_delay_node_uninit; cdecl; external MINIAUDIO_LIB;

function ma_waveform_config_init; cdecl; external MINIAUDIO_LIB;

function ma_waveform_init; cdecl; external MINIAUDIO_LIB;

procedure ma_waveform_uninit; cdecl; external MINIAUDIO_LIB;

// RESOURCE MANAGER
function ma_resource_manager_init; cdecl; external MINIAUDIO_LIB;

procedure ma_resource_manager_uninit; cdecl; external MINIAUDIO_LIB;

function ma_resource_manager_register_file; cdecl; external MINIAUDIO_LIB;

function ma_resource_manager_unregister_file; cdecl; external MINIAUDIO_LIB;

// UTILS & CONVERSION
function ma_volume_db_to_linear; cdecl; external MINIAUDIO_LIB;

function ma_volume_linear_to_db; cdecl; external MINIAUDIO_LIB;

procedure ma_apply_volume_factor_f32; cdecl; external MINIAUDIO_LIB;

procedure ma_silence_pcm_frames; cdecl; external MINIAUDIO_LIB;

function ma_convert_frames; cdecl; external MINIAUDIO_LIB;

// LOG
function ma_log_init; cdecl; external MINIAUDIO_LIB;

procedure ma_log_uninit; cdecl; external MINIAUDIO_LIB;

procedure ma_log_post; cdecl; external MINIAUDIO_LIB;

end.


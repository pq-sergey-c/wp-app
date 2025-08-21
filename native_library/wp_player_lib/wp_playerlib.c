#include <stdio.h>

// =====================[ Threading Unix/Windows ]=====================
#ifdef _WIN32
    #include <windows.h>
#else
    #include <pthread.h>
    #include <sys/time.h>
    #include <unistd.h>
#endif
// ====================================================================


#include <stdatomic.h>
#include <math.h>

// =====================[ Miniaudio setup ]=====================

#define MA_NO_AAUDIO // uncomment out to disable new android audio backend

#define MA_NO_ENCODING

#if !defined(_WIN32)
  #define MA_NO_WASAPI
  #define MA_NO_DSOUND
  #define MA_NO_WINMM
#endif

#define MA_NO_FLAC
#define MA_DEBUG_OUTPUT
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include "miniaudio_libopus.h"

// ====================================================================


#include "wp_playerlib.h"

#include "wp_playerlib_util.c"
#include "wp_playerlib_custom_decoders.c"
#include "wp_playerlib_id.c"
#include "wp_playerlib_io.c"
#include "wp_playerlib_network.c"
#include "wp_playerlib_tick.c"
#include "wp_playerlib_m3u8.c"
#include "wp_playerlib_fader.c"
#include "wp_playerlib_compressor.c"
#include "wp_playerlib_stream_playlist.c"
#include "wp_playerlib_stream_chunk.c"
#include "wp_playerlib_stream.c"

// Helper macros for cross-platform mutex usage
#ifdef _WIN32
    #define MUTEX_TYPE CRITICAL_SECTION
    #define MUTEX_INIT(mutex) InitializeCriticalSection(&(mutex))
    #define MUTEX_LOCK(mutex) EnterCriticalSection(&(mutex))
    #define MUTEX_UNLOCK(mutex) LeaveCriticalSection(&(mutex))
    #define MUTEX_DESTROY(mutex) DeleteCriticalSection(&(mutex))
#else
    #define MUTEX_TYPE pthread_mutex_t
    #define MUTEX_INIT(mutex) pthread_mutex_init(&(mutex), NULL)
    #define MUTEX_LOCK(mutex) pthread_mutex_lock(&(mutex))
    #define MUTEX_UNLOCK(mutex) pthread_mutex_unlock(&(mutex))
    #define MUTEX_DESTROY(mutex) pthread_mutex_destroy(&(mutex))
#endif

typedef enum WpPlayerLibPlaybackState {
  WP_PB_STOPPED,
  WP_PB_PLAYING,
  WP_PB_STOPPING,
  WP_PB_STOP_FINALISING
} WpPlayerLibPlaybackState;

typedef struct WpPlayerLibState {
  MUTEX_TYPE mutex;

  WpPlayerLibNetworkState network;
  WpPlayerLibTickState ticker;

  ma_resource_manager* maResourceManager;
  ma_context* context;
  ma_device* device;
  ma_engine* engine;
  WpPlayerLibPhase phase;
  _Atomic WpPlayerLibPlaybackState playbackState;
  int64_t timelineToEngineFrameDelta[_WP_PHASE_COUNT];
  int64_t bufferingLookahead;

  wp_playerlib_fader *masterFader;
  wp_playerlib_fader *volumeControlFader;
  wp_playerlib_compressor *compressor;

  size_t streamCount;
  WpPlayerLibStreamState **streams;

} WpPlayerLibState;

void _wp_playerlib_on_master_fader_target_reached(void* context);
WpPlayerLibTickResult _wp_playerlib_tick_callback(void* context);

void deviceDataCallback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
  (void)pInput;
  WpPlayerLibState* state = (WpPlayerLibState*)pDevice->pUserData;
  ma_engine *engine = state->engine;
  ma_engine_read_pcm_frames(engine, pOutput, frameCount, NULL);
}

WpPlayerLibState* wp_playerlib_create(float sampleRate, int64_t bufferingLookahead) {
  WpPlayerLibState* state = (WpPlayerLibState*)malloc(sizeof(WpPlayerLibState));
  if (!state) {
    printf("Failed to allocate memory for WpPlayerLibState\n");
    return NULL;
  }
  state->maResourceManager = NULL;
  state->context = NULL;
  state->device = NULL;
  state->engine = NULL;
  state->phase = WP_PHASE_NONE;
  state->playbackState = WP_PB_STOPPED;
  state->timelineToEngineFrameDelta[WP_PHASE_NONE] = 0;
  state->timelineToEngineFrameDelta[WP_PHASE_PRE] = 0;
  state->timelineToEngineFrameDelta[WP_PHASE_SESSION] = 0;
  state->timelineToEngineFrameDelta[WP_PHASE_POST] = 0;
  state->streamCount = 0;
  state->streams = NULL;
  state->bufferingLookahead = bufferingLookahead;
  MUTEX_INIT(state->mutex);
  wp_playerlib_network_init(&state->network);
  wp_playerlib_tick_init(&state->ticker, _wp_playerlib_tick_callback, state);

  ma_resource_manager_config maResourceManagerConfig = ma_resource_manager_config_init();
  maResourceManagerConfig.decodedFormat = ma_format_f32;
  maResourceManagerConfig.decodedChannels = 2;
  maResourceManagerConfig.decodedSampleRate = sampleRate;
  maResourceManagerConfig.ppCustomDecodingBackendVTables = pCustomBackendVTables;
  maResourceManagerConfig.customDecodingBackendCount = sizeof(pCustomBackendVTables) / sizeof(pCustomBackendVTables[0]);
  maResourceManagerConfig.pCustomDecodingBackendUserData = NULL;
  #ifdef MA_NO_DEVICE_IO_FAKE
    maResourceManagerConfig.jobThreadCount = 0;
    maResourceManagerConfig.flags = MA_RESOURCE_MANAGER_FLAG_NON_BLOCKING;
  #endif

  state->maResourceManager = (ma_resource_manager*)malloc(sizeof(ma_resource_manager));
  if (!state->maResourceManager) {
    printf("Failed to allocate memory for ma_resource_manager\n");
    wp_playerlib_destroy(state);
    return NULL;
  }
  ma_result result = ma_resource_manager_init(&maResourceManagerConfig, state->maResourceManager);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize ma_resource_manager. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }

  #ifndef MA_NO_DEVICE_IO_FAKE
    ma_context_config contextConfig = ma_context_config_init();
    contextConfig.coreaudio.sessionCategory = ma_ios_session_category_playback;
    state->context = (ma_context*)malloc(sizeof(ma_context));
    if (!state->context) {
      printf("Failed to allocate memory for ma_context\n");
      wp_playerlib_destroy(state);
      return NULL;
    }
    result = ma_context_init(NULL, 0, &contextConfig, state->context);
    if (result != MA_SUCCESS) {
      printf("Failed to initialize context. Error code: %d\n", result);
      wp_playerlib_destroy(state);
      return NULL;
    }
    ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.playback.format = ma_format_f32;
    deviceConfig.playback.channels = 2;
    deviceConfig.sampleRate = sampleRate;
    deviceConfig.noPreSilencedOutputBuffer = MA_TRUE;
    deviceConfig.noClip = MA_TRUE;
    deviceConfig.performanceProfile = ma_performance_profile_conservative;
    deviceConfig.dataCallback = deviceDataCallback;
    deviceConfig.pUserData = state;
    state->device = (ma_device*)malloc(sizeof(ma_device));
    if (!state->device) {
      printf("Failed to allocate memory for ma_device\n");
      wp_playerlib_destroy(state);
      return NULL;
    }
    result = ma_device_init(state->context, &deviceConfig, state->device);
    if (result != MA_SUCCESS) {
      printf("Failed to initialize device. Error code: %d\n", result);
      wp_playerlib_destroy(state);
      return NULL;
    }
  #endif

  ma_engine_config engineConfig = ma_engine_config_init();
  engineConfig.sampleRate = sampleRate;
  engineConfig.channels = 2;
  engineConfig.noAutoStart = MA_TRUE;
  #ifndef MA_NO_DEVICE_IO_FAKE
    engineConfig.pContext = state->context;
    engineConfig.pDevice = state->device;
  #endif
  engineConfig.pResourceManager = state->maResourceManager;
  state->engine = (ma_engine*)malloc(sizeof(ma_engine));
  if (!state->engine) {
    printf("Failed to allocate memory for ma_engine\n");
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = ma_engine_init(&engineConfig, state->engine);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize engine. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }

  state->masterFader = (wp_playerlib_fader*)malloc(sizeof(wp_playerlib_fader));
  if (!state->masterFader) {
    printf("Failed to allocate memory for wp_playerlib_fader\n");
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = wp_playerlib_fader_init_with_callback(state->masterFader, 0.0f, _wp_playerlib_on_master_fader_target_reached, state, state->engine);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize master fader. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = ma_node_attach_output_bus(state->masterFader, 0, ma_node_graph_get_endpoint(ma_engine_get_node_graph(state->engine)), 0);
  if (result != MA_SUCCESS) {
    printf("Failed to attach master fader to engine. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }
  state->volumeControlFader = (wp_playerlib_fader*)malloc(sizeof(wp_playerlib_fader));
  if (!state->volumeControlFader) {
    printf("Failed to allocate memory for wp_playerlib_fader\n");
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = wp_playerlib_fader_init(state->volumeControlFader, 1.0f, state->engine);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize volume control fader. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = ma_node_attach_output_bus(state->volumeControlFader, 0, state->masterFader, 0);
  if (result != MA_SUCCESS) {
    printf("Failed to attach volume control fader to master fader. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }
  state->compressor = (wp_playerlib_compressor*)malloc(sizeof(wp_playerlib_compressor));
  if (!state->compressor) {
    printf("Failed to allocate memory for wp_playerlib_compressor\n");
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = wp_playerlib_compressor_init(state->compressor, 0.01f, 3.0f, -30.f, 1.f, 3.f, 0.f, state->engine);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize compressor. Error code: %d\n", result);
    wp_playerlib_destroy(state);
    return NULL;
  }
  result = ma_node_attach_output_bus(state->compressor, 0, state->volumeControlFader, 0);
  if (result != MA_SUCCESS) {
    printf("Failed to attach compressor to volume control fader. Error code: %d\n", result);
  MUTEX_LOCK(state->mutex);
  MUTEX_UNLOCK(state->mutex);
    MUTEX_LOCK(state->mutex);
    return NULL;
  }

  return state;
}

void wp_playerlib_register_network_request_callbacks(WpPlayerLibState* state, WpNetworkRequestCallback networkRequestCallback, WpCancelNetworkRequestCallback cancelNetworkRequestCallback, const void *networkRequestCallbackContext) {
  MUTEX_LOCK(state->mutex);
  wp_playerlib_network_connect(&state->network, networkRequestCallback, cancelNetworkRequestCallback, networkRequestCallbackContext);
  MUTEX_UNLOCK(state->mutex);
}

void wp_playerlib_on_network_response(WpPlayerLibState* state, uint32_t id, int32_t status, const char *filePath) {
  MUTEX_LOCK(state->mutex);
  bool isPlaying = state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
  if (!wp_playerlib_network_retry_network_response(&state->network, id, status)) {
    for (size_t i = 0; i < state->streamCount; i++) {
      wp_playerlib_stream_on_network_response(state->streams[i], id, status, filePath, isPlaying);
    }
  }
  MUTEX_UNLOCK(state->mutex);
}

const void* wp_playerlib_get_network_request_callback_context(WpPlayerLibState* state) {
  return state->network.networkRequestCallbackContext;
}

int _wp_playerlib_init_or_update_stream(WpPlayerLibState *state, const WpPlayerLibStream *stream) {
  bool isPlaying = state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
  // See if we have this stream already and update it if so
  for (size_t i = 0; i < state->streamCount; i++) {
    if (strcmp(state->streams[i]->id, stream->id) == 0) {
      return wp_playerlib_stream_update_attributes(
        state->streams[i],
        stream->fromTime,
        stream->toTime,
        stream->fadeOutTime,
        stream->gain,
        stream->sidechainGain,
        isPlaying
      );
    }
  }
  // Otherwise create it
  size_t streamIndex = state->streamCount;
  state->streamCount++;
  state->streams = state->streams == NULL ?
    (WpPlayerLibStreamState**)malloc(sizeof(WpPlayerLibStreamState*) * state->streamCount) :
    (WpPlayerLibStreamState**)realloc(state->streams, sizeof(WpPlayerLibStreamState*) * state->streamCount);
  state->streams[streamIndex] = (WpPlayerLibStreamState*)malloc(sizeof(WpPlayerLibStreamState));
  WpPlayerLibStreamOutputs outputs = {
    .outputNode = state->compressor,
    .outputBusIndex = 0,
    .sideChainNode = state->compressor,
    .sideChainBusIndex = 1,
    .compressorBypassNode = state->volumeControlFader,
    .compressorBypassBusIndex = 0,
  };
  if (stream->usesSidechain) {
    wp_playerlib_compressor_enable(state->compressor);
  }
  int initResult = wp_playerlib_stream_init(
    state->streams[streamIndex],
    stream->id,
    stream->phase,
    stream->fromTime,
    stream->toTime,
    stream->fadeOutTime,
    stream->url,
    stream->loopContent,
    state->bufferingLookahead,
    stream->gain,
    stream->usesSidechain,
    stream->sidechainGain,
    &state->network,
    &outputs,
    state->engine
  );
  if (initResult != 0) {
    return initResult;
  }
  if (state->phase == stream->phase) {
    return wp_playerlib_stream_enter_phase(state->streams[streamIndex], state->timelineToEngineFrameDelta[stream->phase], isPlaying);
  }
  return 0;
}

int wp_playerlib_set_session(WpPlayerLibState* state, const WpPlayerLibStream *streams, int streamCount) {
  MUTEX_LOCK(state->mutex);
  for (int i = 0; i < streamCount ; i++) {
    int result = _wp_playerlib_init_or_update_stream(state, &streams[i]);
    if (result != 0) {
      MUTEX_UNLOCK(state->mutex);
      return result;
    }
  }
  for (size_t i = 0; i < state->streamCount; i++) {
    bool stillExists = false;
    for (int j = 0; j < streamCount; j++) {
      if (strcmp(state->streams[i]->id, streams[j].id) == 0) {
        stillExists = true;
        break;
      }
    }
    if (!stillExists) {
      wp_playerlib_stream_destroy(state->streams[i]);
      free(state->streams[i]);
      for (size_t j = i; j < state->streamCount - 1; j++) {
        state->streams[j] = state->streams[j + 1];
      }
      state->streamCount--;
      state->streams = (WpPlayerLibStreamState**)realloc(state->streams, sizeof(WpPlayerLibStreamState*) * state->streamCount);
    }
  }
  MUTEX_UNLOCK(state->mutex);
  return 0;
}

void wp_playerlib_tick(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  bool isPlaying = state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
  for (size_t i = 0; i < state->streamCount; i++) {
    wp_playerlib_stream_tick(state->streams[i], isPlaying);
  }
  MUTEX_UNLOCK(state->mutex);
}

WpPlayerLibTickResult _wp_playerlib_tick_callback(void* context) {
  WpPlayerLibState* state = (WpPlayerLibState*)context;
  MUTEX_LOCK(state->mutex);
  WpPlayerLibTickResult result = WP_TICK_RESULT_OK;
  if (state->playbackState == WP_PB_STOP_FINALISING) {
    printf("Finalising stop\n");
    #ifndef MA_NO_DEVICE_IO_FAKE
      ma_result engineResult = ma_engine_stop(state->engine);
      if (engineResult != MA_SUCCESS) {
        printf("Failed to stop audio device %d\n", engineResult);
      }
    #endif
    state->playbackState = WP_PB_STOPPED;
    result = WP_TICK_RESULT_STOP;
  } else {
    #ifdef MA_NO_DEVICE_IO_FAKE
      bool isStillStarted = true;
    #else
      bool isStillStarted = ma_device_is_started(ma_engine_get_device(state->engine));
    #endif
    if (!isStillStarted) {
      printf("Audio device has stopped. Stopping ticker and the rest.\n");
      state->playbackState = WP_PB_STOPPED;
      result = WP_TICK_RESULT_STOP;
    } else {
      // Just a regular tick
      for (size_t i = 0; i < state->streamCount; i++) {
        wp_playerlib_stream_tick(state->streams[i], isStillStarted);
      }
    }
  }
  MUTEX_UNLOCK(state->mutex);
  return result;
}


WpPlayerLibPhase wp_playerlib_get_phase(WpPlayerLibState* state) {
  return state->phase;
}

int64_t wp_playerlib_get_time_in_phase(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  int64_t timeInFrames = ma_engine_get_time_in_pcm_frames(state->engine) - state->timelineToEngineFrameDelta[state->phase];
  int64_t timeInMs = timeInFrames * 1000 / ma_engine_get_sample_rate(state->engine);
  MUTEX_UNLOCK(state->mutex);
  return timeInMs;
}

int wp_playerlib_set_phase(WpPlayerLibState* state, WpPlayerLibPhase phase, int64_t timeInPhase) {
  MUTEX_LOCK(state->mutex);
  bool isPlaying = state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
  if (state->phase != phase) {
    int64_t initialEffectiveFrame = timeInPhase * ma_engine_get_sample_rate(state->engine) * 0.001;
    state->timelineToEngineFrameDelta[phase] = (int64_t)ma_engine_get_time_in_pcm_frames(state->engine) - initialEffectiveFrame;
    for (size_t i = 0; i < state->streamCount; i++) {
      if (state->streams[i]->phase == phase) {
        wp_playerlib_stream_enter_phase(state->streams[i], state->timelineToEngineFrameDelta[phase], isPlaying);
      } else if (state->streams[i]->phase == state->phase) {
        wp_playerlib_stream_leave_phase(state->streams[i], isPlaying);
      }
    }
    state->phase = phase;
  }
  MUTEX_UNLOCK(state->mutex);
  return 0;
}

int wp_playerlib_seek_to_time_in_phase(WpPlayerLibState* state, int64_t timeWithinPhase) {
  MUTEX_LOCK(state->mutex);
  bool isPlaying = state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
  int64_t newInitialEffectiveFrame = timeWithinPhase * ma_engine_get_sample_rate(state->engine) * 0.001;
  state->timelineToEngineFrameDelta[state->phase] = (int64_t)ma_engine_get_time_in_pcm_frames(state->engine) - newInitialEffectiveFrame;
  for (size_t i = 0; i < state->streamCount; i++) {
    if (state->streams[i]->phase == state->phase) {
      wp_playerlib_stream_seek_to_time_in_phase(state->streams[i], state->timelineToEngineFrameDelta[state->phase], isPlaying);
    }
  }
  MUTEX_UNLOCK(state->mutex);
  return 0;
}

bool wp_playerlib_is_started(WpPlayerLibState* state) {
  if (state == NULL) {
    return false;
  }
  return state->playbackState == WP_PB_PLAYING || state->playbackState == WP_PB_STOPPING;
}

int wp_playerlib_start(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  if (state->playbackState != WP_PB_STOPPED) {
    MUTEX_UNLOCK(state->mutex);
    return 0;
  }
  #ifndef MA_NO_DEVICE_IO_FAKE
    ma_result result = ma_engine_start(state->engine);
    if (result != MA_SUCCESS) {
      printf("Failed to start engine: %d\n", result);
      MUTEX_UNLOCK(state->mutex);
      return result;
    }
  #endif
  state->playbackState = WP_PB_PLAYING;
  int tickerResult = wp_playerlib_tick_start(&state->ticker);
  if (tickerResult != 0) {
    printf("Failed to start ticker: %d\n", tickerResult);
    state->playbackState = WP_PB_STOPPED;
    #ifndef MA_NO_DEVICE_IO_FAKE
      ma_engine_stop(state->engine);
    #endif
    MUTEX_UNLOCK(state->mutex);
    return tickerResult;
  }
  wp_playerlib_fader_set_target(state->masterFader, 1.0f, ma_engine_get_sample_rate(state->engine) * 1);
  MUTEX_UNLOCK(state->mutex);
  return 0;
}

int wp_playerlib_stop(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  if (state->playbackState != WP_PB_PLAYING) {
    MUTEX_UNLOCK(state->mutex);
    return 0;
  }
  state->playbackState = WP_PB_STOPPING;
  wp_playerlib_fader_set_target(state->masterFader, 0.0f, ma_engine_get_sample_rate(state->engine) * 1);
  MUTEX_UNLOCK(state->mutex);
  return 0;
}

void _wp_playerlib_on_master_fader_target_reached(void* context) {
  // This will be on the audio thread. Don't mess with mutexes or the audio graph here.
  WpPlayerLibState* state = (WpPlayerLibState*)context;
  if (state->playbackState == WP_PB_STOPPING) {
    state->playbackState = WP_PB_STOP_FINALISING;
    wp_playerlib_tick_tick_now(&state->ticker);
  }
}

void wp_playerlib_set_volume(WpPlayerLibState* state, float volume) {
  MUTEX_LOCK(state->mutex);
  static const float minDb = -40.0f;
  static const float maxDb = 0.0f;
  float clampedVolume = volume < 0.f ? 0.f : (volume > 1.f ? 1.f : volume);
  float targetDb = clampedVolume * (maxDb - minDb) + minDb;
  float targetGain = clampedVolume > 0.f ? ma_volume_db_to_linear(targetDb) : 0.f;
  wp_playerlib_fader_set_target(state->volumeControlFader, targetGain, ma_engine_get_sample_rate(state->engine) * 0.1);
  MUTEX_UNLOCK(state->mutex);
}

float wp_playerlib_get_buffered_time(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  // The amount of time we can play with the current buffer is the minimum
  // of the buffered time of all streams
  float bufferedTime = 0.0f;
  for (size_t i = 0; i < state->streamCount; i++) {
    if (state->streams[i]->phase == WP_PHASE_SESSION) {
      bufferedTime = fmaxf(bufferedTime, wp_playerlib_stream_get_buffered_time(state->streams[i]));
    }
  }
  MUTEX_UNLOCK(state->mutex);
  return bufferedTime;
}

void wp_playerlib_destroy(WpPlayerLibState* state) {
  MUTEX_LOCK(state->mutex);
  state->playbackState = WP_PB_STOP_FINALISING;
  MUTEX_UNLOCK(state->mutex);

  wp_playerlib_tick_await_stop(&state->ticker);

  MUTEX_LOCK(state->mutex);

  for (size_t i = 0; i < state->streamCount; i++) {
    wp_playerlib_stream_destroy(state->streams[i]);
    free(state->streams[i]);
  }
  free(state->streams);
  wp_playerlib_network_destroy(&state->network);

  wp_playerlib_compressor_destroy(state->compressor);
  free(state->compressor);

  wp_playerlib_fader_destroy(state->volumeControlFader);
  free(state->volumeControlFader);

  wp_playerlib_fader_destroy(state->masterFader);
  free(state->masterFader);

  if (state->engine != NULL) {
    #ifndef MA_NO_DEVICE_IO_FAKE
      int engineResult = ma_engine_stop(state->engine);
      if (engineResult != MA_SUCCESS) {
        printf("Failed to stop audio device %d\n", engineResult);
      }
    #endif
    ma_engine_uninit(state->engine);
    free(state->engine);
  }
  if (state->maResourceManager != NULL) {
    ma_resource_manager_uninit(state->maResourceManager);
    free(state->maResourceManager);
    state->maResourceManager = NULL;
  }
  #ifndef MA_NO_DEVICE_IO_FAKE
    if (state->device != NULL) {
      ma_device_uninit(state->device);
      free(state->device);
      state->device = NULL;
    }
    if (state->context != NULL) {
      ma_context_uninit(state->context);
      free(state->context);
      state->context = NULL;
    }
  #endif

  wp_playerlib_tick_destroy(&state->ticker);

  MUTEX_UNLOCK(state->mutex);
  MUTEX_DESTROY(state->mutex);

  free(state);
}

void _wp_playerlib_read_pcm_frames(WpPlayerLibState* state, void *output, uint64_t framesToRead) {
  for (;;) {
    ma_job job;
    ma_result result = ma_resource_manager_next_job(state->maResourceManager, &job);
    if (result != MA_SUCCESS) {
      if (result == MA_NO_DATA_AVAILABLE) {
        break;
      } else if (result == MA_CANCELLED) {
        // MA_JOB_TYPE_QUIT was posted. Exit.
        printf("Jobs cancelled\n");
        break;
      } else {
        printf("Failed to retrieve job: %d\n", result);
        // Some other error occurred.
        break;
      }
    }
    ma_job_process(&job);
  }
  ma_engine_read_pcm_frames(state->engine, output, framesToRead, NULL);
}

void wp_playerlib_read_pcm_frames(WpPlayerLibState* state, void *output, uint64_t framesToRead) {
  float *outArray = (float*)output;

  if (state->playbackState == WP_PB_STOPPED) {
    for (uint64_t i = 0 ; i < framesToRead ; i++) {
      outArray[i * 2] = 0;
      outArray[i * 2 + 1] = 0;
    }
    return;
  }

  // There may be timing issues starting/stopping stuff
  // if we render a quantum larger than the internal buffer size.
  static const uint64_t chunkSize = MA_DEFAULT_NODE_CACHE_CAP_IN_FRAMES_PER_BUS;
  uint64_t numChunks = framesToRead / chunkSize;
  for (uint64_t i = 0 ; i < numChunks ; i++) {
    _wp_playerlib_read_pcm_frames(state, outArray + i * chunkSize * 2, chunkSize);
  }
  uint64_t remainingFrames = framesToRead - numChunks * chunkSize;
  if (remainingFrames > 0) {
    _wp_playerlib_read_pcm_frames(state, outArray + numChunks * chunkSize * 2, remainingFrames);
  }
}

char* hello_ohayo(void) {
  return strdup("Hello from original lib");
}

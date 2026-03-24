#define WP_PLAYERLIB_CHUNK_ARM_LOOKAHEAD 30
#define WP_PLAYERLIB_CHUNK_LATE_START_PREEMPT 0.1

#include <inttypes.h>

typedef enum WpPlayerLibStreamChunkStatus {
  WP_SC_UNINITIALISED,
  WP_SC_LOADING,
  WP_SC_LOADED,
  WP_SC_ARMED,
  WP_SC_STARTED,
  WP_SC_ERROR
} WpPlayerLibStreamChunkStatus;

typedef struct WpPlayerLibStreamChunkState {
  uint32_t id;

  WpPlayerLibStreamChunkStatus status;
  bool startCued;

  ma_node *outputNode;
  ma_engine *engine;
  WpPlayerLibNetworkState *network;

  ma_uint64 streamStartTimelineFrame;
  ma_uint64 streamEndTimelineFrame;
  ma_int64 timelineToEngineFrameDelta;
  ma_int64 phaseEndEngineFrame;

  const char *filePath;
  bool ownsFile;
  double fromTime;
  double toTime;

  ma_resource_manager_data_source *dataSource;
  ma_sound *sound;

  _Atomic bool *audioStartedFlag;

} WpPlayerLibStreamChunkState;

int wp_playerlib_stream_chunk_init(WpPlayerLibStreamChunkState *state, ma_uint64 streamStartTimelineFrame, ma_uint64 streamEndTimelineFrame, ma_int64 phaseEndEngineFrame, ma_node *outputNode, ma_engine *engine, WpPlayerLibNetworkState *network, _Atomic bool *audioStartedFlag) {
  state->id = wp_playerlib_id_next();
  state->status = WP_SC_UNINITIALISED;
  state->outputNode = outputNode;
  state->engine = engine;
  state->network = network;
  state->audioStartedFlag = audioStartedFlag;
  state->dataSource = NULL;
  state->sound = NULL;
  state->filePath = NULL;
  state->ownsFile = false;
  state->startCued = false;
  state->fromTime = 0;
  state->toTime = 0;
  state->streamStartTimelineFrame = streamStartTimelineFrame;
  state->streamEndTimelineFrame = streamEndTimelineFrame;
  state->timelineToEngineFrameDelta = 0;
  state->phaseEndEngineFrame = phaseEndEngineFrame;
  return 0;
}

int64_t wp_playerlib_stream_chunk_stream_get_start_engine_frame(WpPlayerLibStreamChunkState *state) {
  return (int64_t)state->streamStartTimelineFrame + state->timelineToEngineFrameDelta;
}

int64_t wp_playerlib_stream_chunk_stream_get_end_engine_frame(WpPlayerLibStreamChunkState *state) {
  return min64(
    (int64_t)state->streamEndTimelineFrame + state->timelineToEngineFrameDelta,
    state->phaseEndEngineFrame
  );
}

int _wp_playerlib_stream_chunk_start(WpPlayerLibStreamChunkState *state, bool isPlaying) {
  int64_t sr = ma_engine_get_sample_rate(state->engine);
  int64_t startEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->fromTime * sr;
  int64_t endEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->toTime * sr;
  // End the chunk when its parent stream ends, if it's earlier than the chunk's own end time.
  endEngineFrame = min64(endEngineFrame, wp_playerlib_stream_chunk_stream_get_end_engine_frame(state));
  // printf("Chunk schedule %lld->%lld (%lf->%lf) (stream eng %lld->%lld) (stream tl %lld->%lld)\n", startEngineFrame, endEngineFrame, state->fromTime, state->toTime, wp_playerlib_stream_chunk_stream_start_engine_frame(state), wp_playerlib_stream_chunk_stream_end_engine_frame(state), state->streamStartTimelineFrame, state->streamEndTimelineFrame);

  int64_t currentEngineFrame = ma_engine_get_time_in_pcm_frames(state->engine);
  int64_t preemptStartUntilEngineFrame = currentEngineFrame;
  if (isPlaying) {
    preemptStartUntilEngineFrame += (ma_uint64)(WP_PLAYERLIB_CHUNK_LATE_START_PREEMPT * ma_engine_get_sample_rate(state->engine));
  }
  if (endEngineFrame <= preemptStartUntilEngineFrame) {
    printf("Chunk would start when it's already past its end time: %"PRId64" < %"PRId64". Ignoring.\n", endEngineFrame, preemptStartUntilEngineFrame);
    state->status = WP_SC_ARMED;
    return 0;
  }
  if (startEngineFrame < preemptStartUntilEngineFrame) {
    uint64_t seekToFrame = preemptStartUntilEngineFrame - startEngineFrame;
    ma_result result = ma_resource_manager_data_source_seek_to_pcm_frame(state->dataSource, seekToFrame);
    if (result != MA_SUCCESS) {
      printf("Failed to seek to start of sound. Error code: %d\n", result);
      state->status = WP_SC_ERROR;
      return -1;
    } else {
      printf("Chunk late start, seeking to %"PRIu64" and moving start time %"PRId64"->%"PRId64" (now %"PRId64")\n", seekToFrame, startEngineFrame, preemptStartUntilEngineFrame, currentEngineFrame);
    }
    startEngineFrame = preemptStartUntilEngineFrame;
  }
  ma_sound_set_start_time_in_pcm_frames(state->sound, startEngineFrame);
  ma_sound_set_stop_time_in_pcm_frames(state->sound, endEngineFrame);
  ma_result result = ma_sound_start(state->sound);
  if (result != MA_SUCCESS) {
    printf("Failed to start sound. Error code: %d\n", result);
    state->status = WP_SC_ERROR;
    return -1;
  } else {
    state->status = WP_SC_STARTED;
    if (state->audioStartedFlag && !(*state->audioStartedFlag)) {
      *state->audioStartedFlag = true;
    }
    return 0;
  }
}

int _wp_playerlib_stream_chunk_arm_if_playing_soon(WpPlayerLibStreamChunkState *state, bool isPlaying) {
  int64_t willStartAtEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + (ma_int64)(state->fromTime * ma_engine_get_sample_rate(state->engine));
  int64_t shouldArmAtEngineFrame = willStartAtEngineFrame - min64(WP_PLAYERLIB_CHUNK_ARM_LOOKAHEAD * ma_engine_get_sample_rate(state->engine), willStartAtEngineFrame);
  int64_t currentEngineFrame = ma_engine_get_time_in_pcm_frames(state->engine);
  if (shouldArmAtEngineFrame > currentEngineFrame) {
    return 0;
  }

  state->dataSource = malloc(sizeof(ma_resource_manager_data_source));
  if (state->dataSource == NULL) {
    printf("Failed to allocate memory for data source\n");
    state->status = WP_SC_ERROR;
    return -1;
  }

  ma_result result = ma_resource_manager_data_source_init(ma_engine_get_resource_manager(state->engine), state->filePath, MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_STREAM, NULL, state->dataSource);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize data source. Error code: %d\n", result);
    state->status = WP_SC_ERROR;
    return -1;
  }

  state->sound = malloc(sizeof(ma_sound));
  if (state->sound == NULL) {
    printf("Failed to allocate memory for sound\n");
    state->status = WP_SC_ERROR;
    return -1;
  }
  ma_sound_config config = ma_sound_config_init();
  config.pDataSource = state->dataSource;
  config.flags = MA_SOUND_FLAG_NO_SPATIALIZATION | MA_SOUND_FLAG_NO_PITCH;
  config.channelsOut = 2;
  config.pInitialAttachment = state->outputNode;
  result = ma_sound_init_ex(state->engine, &config, state->sound);
  if (result != MA_SUCCESS) {
    printf("Failed to initialize sound from file. Error code: %d\n", result);
    state->status = WP_SC_ERROR;
    return -1;
  }

  if (state->startCued) {
    int result = _wp_playerlib_stream_chunk_start(state, isPlaying);
    if (result != 0) {
      return result;
    }
  } else {
    state->status = WP_SC_ARMED;
  }

  return 0;
}

int wp_playerlib_stream_chunk_load_url(WpPlayerLibStreamChunkState *state, const char *streamId, const char *url, double fromTime, double toTime) {
  state->status = WP_SC_LOADING;
  state->fromTime = fromTime;
  state->toTime = toTime;
  wp_playerlib_network_request(state->network, streamId, state->id, url, time_now());
  return 0;
}

int wp_playerlib_stream_chunk_load_direct(WpPlayerLibStreamChunkState *state, const char *filePath, double fromTime, double toTime, bool isPlaying) {
  state->status = WP_SC_LOADED;
  state->fromTime = fromTime;
  state->toTime = toTime;
  state->filePath = strdup(filePath);
  state->ownsFile = false;
  return _wp_playerlib_stream_chunk_arm_if_playing_soon(state, isPlaying);
}

bool wp_playerlib_stream_chunk_is_uninitialised(WpPlayerLibStreamChunkState *state) {
  return state->status == WP_SC_UNINITIALISED;
}

bool wp_playerlib_stream_chunk_is_buffered(WpPlayerLibStreamChunkState *state) {
  return state->status == WP_SC_LOADED || state->status == WP_SC_ARMED || state->status == WP_SC_STARTED;
}

bool wp_playerlib_stream_chunk_is_for_time(WpPlayerLibStreamChunkState *state, double fromTime, double toTime) {
  return state->status != WP_SC_UNINITIALISED && state->fromTime == fromTime && state->toTime == toTime;
}

bool wp_playerlib_stream_chunk_network_response(WpPlayerLibStreamChunkState *state, uint32_t id, int32_t status, const char *filePath, bool isPlaying) {
  if (id == state->id && state->status == WP_SC_LOADING) {
    if (status == 0) {
      state->status = WP_SC_LOADED;
      state->filePath = strdup(filePath);
      state->ownsFile = true;
      _wp_playerlib_stream_chunk_arm_if_playing_soon(state, isPlaying);
    } else {
      state->status = WP_SC_ERROR;
    }
    return true;
  }
  return false;
}

int wp_playerlib_stream_chunk_start(WpPlayerLibStreamChunkState *state, bool isPlaying) {
  state->startCued = true;
  if (state->status == WP_SC_ARMED) {
    return _wp_playerlib_stream_chunk_start(state, isPlaying);
  } else {
    return 0;
  }
}

int wp_playerlib_stream_chunk_stop(WpPlayerLibStreamChunkState *state) {
  if (state->status == WP_SC_STARTED) {
    ma_result result = ma_sound_stop(state->sound);
    if (result != MA_SUCCESS) {
      printf("Failed to stop sound. Error code: %d\n", result);
      state->status = WP_SC_ERROR;
      return -1;
    }
    state->status = WP_SC_ARMED;
  } else if (state->status == WP_SC_LOADING || state->status == WP_SC_UNINITIALISED) {
    state->startCued = false;
  }
  return 0;
}

void wp_playerlib_stream_chunk_tick(WpPlayerLibStreamChunkState *state, bool isPlaying) {
  if (state->status == WP_SC_LOADED && state->startCued) {
    _wp_playerlib_stream_chunk_arm_if_playing_soon(state, isPlaying);
  }
}

void wp_playerlib_stream_chunk_update_stream_timing(WpPlayerLibStreamChunkState *state, uint64_t streamStartTimelineFrame, uint64_t streamEndTimelineFrame, int64_t phaseEndEngineFrame) {
  int64_t sr = ma_engine_get_sample_rate(state->engine);
  if (state->status == WP_SC_STARTED) {
    int64_t previousStartEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->fromTime * sr;
    int64_t previousEndEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->toTime * sr;
    state->streamStartTimelineFrame = streamStartTimelineFrame;
    state->streamEndTimelineFrame = streamEndTimelineFrame;
    state->phaseEndEngineFrame = phaseEndEngineFrame;
    int64_t newStartEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->fromTime * sr;
    int64_t newEndEngineFrame = wp_playerlib_stream_chunk_stream_get_start_engine_frame(state) + state->toTime * sr;
    newEndEngineFrame = min64(newEndEngineFrame, wp_playerlib_stream_chunk_stream_get_end_engine_frame(state));
    int64_t currentEngineFrame = ma_engine_get_time_in_pcm_frames(state->engine);
    int64_t startSafetyBufferFrames = WP_PLAYERLIB_CHUNK_LATE_START_PREEMPT * sr;
    if (newStartEngineFrame != previousStartEngineFrame && currentEngineFrame < previousStartEngineFrame - startSafetyBufferFrames && currentEngineFrame < newStartEngineFrame - startSafetyBufferFrames) {
      printf("Rescheduling chunk start from %"PRId64" to %"PRId64"\n", previousStartEngineFrame, newStartEngineFrame);
      ma_sound_set_start_time_in_pcm_frames(state->sound, newStartEngineFrame);
    }
    if (newEndEngineFrame != previousEndEngineFrame && currentEngineFrame < previousEndEngineFrame && currentEngineFrame < newEndEngineFrame) {
      printf("Rescheduling chunk end from %"PRId64" to %"PRId64"\n", previousEndEngineFrame, newEndEngineFrame);
      ma_sound_set_stop_time_in_pcm_frames(state->sound, newEndEngineFrame);
    }
  } else {
    state->streamStartTimelineFrame = streamStartTimelineFrame;
    state->streamEndTimelineFrame = streamEndTimelineFrame;
    state->phaseEndEngineFrame = phaseEndEngineFrame;
  }
}

void wp_playerlib_stream_chunk_uninit(WpPlayerLibStreamChunkState *state) {
  if (state->status == WP_SC_LOADING) {
    wp_playerlib_network_cancel(state->network, state->id);
  }
  if (state->sound != NULL) {
    ma_sound_uninit(state->sound);
    free(state->sound);
    state->sound = NULL;
  }
  if (state->dataSource != NULL) {
    ma_resource_manager_data_source_uninit(state->dataSource);
    free(state->dataSource);
    state->dataSource = NULL;
  }
  if (state->filePath != NULL) {
    if (state->ownsFile) {
      unlink(state->filePath);
    }
    free((void*)state->filePath);
    state->filePath = NULL;
  }
  state->status = WP_SC_UNINITIALISED;
}

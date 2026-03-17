#define WP_PLAYERLIB_STREAM_CHUNK_COUNT 200

#define WP_PLAYERLIB_CHUNK_WINDOW_LOOKBACK 10
#include <inttypes.h>
typedef enum WpPlayerLibStreamStatus {
  WP_S_ARMED,
  WP_S_STARTED,
  WP_S_ERROR
} WpPlayerLibStreamStatus;

typedef struct WpPlayerLibStreamState {
  const char* id;
  WpPlayerLibPhase phase;
  WpPlayerLibStreamStatus status;
  WpPlayerLibStreamPlaylistState playlist;
  int64_t bufferingLookahead;

  ma_engine *engine;
  wp_playerlib_fader *gainFader;
  wp_playerlib_fader *fadeOutFader;
  ma_splitter_node *sidechainSplitter;
  wp_playerlib_fader *sidechainFader;
  WpPlayerLibStreamChunkState chunks[WP_PLAYERLIB_STREAM_CHUNK_COUNT];

  uint64_t streamStartTimelineFrame;
  uint64_t streamEndTimelineFrame;
  uint64_t fadeOutFrames;
  int64_t timelineToEngineFrameDelta;
  int64_t phaseEndEngineFrame;

} WpPlayerLibStreamState;

typedef struct WpPlayerLibStreamOutputs {
  ma_node *outputNode;
  int outputBusIndex;
  ma_node *sideChainNode;
  int sideChainBusIndex;
  ma_node *compressorBypassNode;
  int compressorBypassBusIndex;
} WpPlayerLibStreamOutputs;

void wp_playerlib_stream_destroy(WpPlayerLibStreamState *state);

int wp_playerlib_stream_init(WpPlayerLibStreamState *state, const char *id, WpPlayerLibPhase phase, uint64_t fromTime, uint64_t toTime, uint64_t fadeOutTime, const char *streamUrl, bool loop, int64_t bufferingLookahead, float gain, bool usesSidechain, float sidechainGain, WpPlayerLibNetworkState *network, WpPlayerLibStreamOutputs *outputs, ma_engine *engine) {
  state->id = strdup(id);
  state->phase = phase;
  state->status = WP_S_ARMED;
  state->engine = engine;
  uint64_t sr = ma_engine_get_sample_rate(engine);
  state->streamStartTimelineFrame = fromTime * sr / 1000;
  state->streamEndTimelineFrame = toTime * sr / 1000;
  state->phaseEndEngineFrame = INT64_MAX;
  state->fadeOutFrames = fadeOutTime * sr / 1000;
  state->bufferingLookahead = bufferingLookahead;

  state->gainFader = NULL;
  state->fadeOutFader = NULL;
  state->sidechainSplitter = NULL;
  state->sidechainFader = NULL;

  int result = wp_playerlib_stream_playlist_init(&state->playlist, network);
  if (result != 0) { // Note: Seems that it always returns 0 - may be unneaded
    wp_playerlib_stream_destroy(state);
    return result;
  }

  state->gainFader = malloc(sizeof(wp_playerlib_fader));
  if (state->gainFader == NULL) {
    wp_playerlib_stream_destroy(state);
    return -1;
  }
  ma_result nodeResult = wp_playerlib_fader_init(state->gainFader, gain, engine);
  if (nodeResult != MA_SUCCESS) {
    wp_playerlib_stream_destroy(state);
    return -1;
  }

  state->fadeOutFader = malloc(sizeof(wp_playerlib_fader));
  if (state->fadeOutFader == NULL) {
    wp_playerlib_stream_playlist_destroy(&state->playlist);
    return -1;
  }
  nodeResult = wp_playerlib_fader_init(state->fadeOutFader, 1.0f, engine);
  if (nodeResult != MA_SUCCESS) {
    wp_playerlib_stream_destroy(state);
    return -1;
  }

  nodeResult = ma_node_attach_output_bus(state->gainFader, 0, state->fadeOutFader, 0);
  if (nodeResult != MA_SUCCESS) {
    wp_playerlib_stream_destroy(state);
    return -1;
  }

  if (!usesSidechain) {
    nodeResult = ma_node_attach_output_bus(state->fadeOutFader, 0, outputs->outputNode, outputs->outputBusIndex);
    if (nodeResult != MA_SUCCESS) {
      wp_playerlib_stream_destroy(state);
      return -1;
    }
  } else {
    state->sidechainSplitter = (ma_splitter_node*)malloc(sizeof(ma_splitter_node));
    if (!state->sidechainSplitter) {
      printf("Failed to allocate memory for output splitter\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    ma_splitter_node_config splitterConfig = ma_splitter_node_config_init(2);
    nodeResult = ma_splitter_node_init(ma_engine_get_node_graph(engine), &splitterConfig, NULL, state->sidechainSplitter);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to initialize sidechain splitter\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    state->sidechainFader = malloc(sizeof(wp_playerlib_fader));
    if (state->sidechainFader == NULL) {
      printf("Failed to allocate memory for sidechain fader\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    nodeResult = wp_playerlib_fader_init(state->sidechainFader, sidechainGain, engine);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to initialize sidechain fader\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    // We'll send our output to the sidechain by the configured amount, and also to the bypass so we don't attenuate ourselves.
    nodeResult = ma_node_attach_output_bus(state->fadeOutFader, 0, state->sidechainSplitter, 0);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to attach output bus to splitter\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    nodeResult = ma_node_attach_output_bus(state->sidechainSplitter, 0, state->sidechainFader, 0);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to attach output bus to sidechain fader\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    nodeResult = ma_node_attach_output_bus(state->sidechainFader, 0, outputs->sideChainNode, outputs->sideChainBusIndex);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to attach output bus to sidechain\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
    nodeResult = ma_node_attach_output_bus(state->sidechainSplitter, 1, outputs->compressorBypassNode, outputs->compressorBypassBusIndex);
    if (nodeResult != MA_SUCCESS) {
      printf("Failed to attach output bus to bypass\n");
      wp_playerlib_stream_destroy(state);
      return -1;
    }
  }

  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    result = wp_playerlib_stream_chunk_init(&state->chunks[i], state->streamStartTimelineFrame, state->streamEndTimelineFrame, state->phaseEndEngineFrame, state->gainFader, engine, network);
    if (result != 0) { // Note: Seems that it always returns 0 - may be unneaded
      wp_playerlib_stream_destroy(state);
      return result;
    }
  }

  wp_playerlib_stream_playlist_arm(&state->playlist, streamUrl, loop);

  return 0;
}

int64_t wp_playerlib_stream_get_start_engine_frame(WpPlayerLibStreamState *state) {
  return (int64_t)state->streamStartTimelineFrame + state->timelineToEngineFrameDelta;
}

int64_t wp_playerlib_stream_get_end_engine_frame(WpPlayerLibStreamState *state) {
  return min64(
    (int64_t)state->streamEndTimelineFrame + state->timelineToEngineFrameDelta,
    state->phaseEndEngineFrame
  );
}

bool _wp_playerlib_stream_chunk_is_in_window(int64_t frameWindowStart, int64_t frameWindowEnd, double chunkFromTime, double chunkToTime, uint32_t sr) {
  int64_t chunkFrameWindowStart = chunkFromTime * sr;
  int64_t chunkFrameWindowEnd = chunkToTime * sr;
  return !(chunkFrameWindowEnd < frameWindowStart || chunkFrameWindowStart > frameWindowEnd);
}

bool _wp_playerlib_stream_m3u8_chunk_is_loaded(WpPlayerLibStreamState *state, WpPlayerLibM3u8Chunk *m3u8Chunk) {
  for (size_t i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    if (wp_playerlib_stream_chunk_is_for_time(&state->chunks[i], m3u8Chunk->fromTime, m3u8Chunk->toTime)) {
      return true;
    }
  }
  return false;
}

int _wp_playerlib_stream_load_m3u8_chunk(WpPlayerLibStreamState *state, WpPlayerLibM3u8Chunk *m3u8Chunk, bool isPlaying) {
  for (size_t i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    if (wp_playerlib_stream_chunk_is_uninitialised(&state->chunks[i])) {
      int result = m3u8Chunk->directFilePath ?
        wp_playerlib_stream_chunk_load_direct(&state->chunks[i], m3u8Chunk->directFilePath, m3u8Chunk->fromTime, m3u8Chunk->toTime, isPlaying) :
        wp_playerlib_stream_chunk_load_url(&state->chunks[i], state->id, m3u8Chunk->url, m3u8Chunk->fromTime, m3u8Chunk->toTime);
      if (result != 0) {
        printf("Failed to load chunk %zu\n", i);
        return result;
      } else {
        return 0;
      }
    }
  }
  printf("Failed to load chunk - no free slots\n");
  return -1;
}

int _wp_playerlib_stream_update_chunks(WpPlayerLibStreamState *state, bool isPlaying) {
  // How many frames into the stream are we? 0 = beginning of this particular stream
  int64_t currentStreamPosFrames = state->status == WP_S_STARTED ?
    (int64_t)ma_engine_get_time_in_pcm_frames(state->engine) - wp_playerlib_stream_get_start_engine_frame(state) :
    0;
  uint32_t sr = ma_engine_get_sample_rate(state->engine);

  // What frame range do we want have playlist chunks loaded for right now
  int64_t streamFrameWindowStart = currentStreamPosFrames - min64(WP_PLAYERLIB_CHUNK_WINDOW_LOOKBACK * sr, currentStreamPosFrames);
  int64_t streamFrameWindowEnd = currentStreamPosFrames + state->bufferingLookahead * sr;
  // Cap the end window at the duration of the whole stream. No point loading what we'll never hear.
  uint64_t streamDurationFrames = wp_playerlib_stream_get_end_engine_frame(state) - wp_playerlib_stream_get_start_engine_frame(state);
  streamFrameWindowEnd = min64(streamFrameWindowEnd, streamDurationFrames);

  // printf("Chunk check at %lld (engine %lld) for stream %lld-%lld window %lld-%lld\n", currentStreamPosFrames, ma_engine_get_time_in_pcm_frames(state->engine), wp_playerlib_stream_start_engine_frame(state), wp_playerlib_stream_end_engine_frame(state), streamFrameWindowStart, streamFrameWindowEnd);

  // See what loaded chunks may have left the window and destroy them
  for (int i=0 ; i<WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    if (!wp_playerlib_stream_chunk_is_uninitialised(&state->chunks[i])) {
      if (!_wp_playerlib_stream_chunk_is_in_window(streamFrameWindowStart, streamFrameWindowEnd, state->chunks[i].fromTime, state->chunks[i].toTime, sr)) {
        // printf("Unloading chunk for %f-%f\n", state->chunks[i].fromTime, state->chunks[i].toTime);
        wp_playerlib_stream_chunk_uninit(&state->chunks[i]);
      }
    }
  }

  // See what new chunks may have entered the window and load them
  for (size_t i = 0; i < state->playlist.m3u8.chunkCount; i++) {
    WpPlayerLibM3u8Chunk *m3u8Chunk = &state->playlist.m3u8.chunks[i];
    bool m3u8ChunkIsInWindow = _wp_playerlib_stream_chunk_is_in_window(streamFrameWindowStart, streamFrameWindowEnd, m3u8Chunk->fromTime, m3u8Chunk->toTime, sr);
    bool m3u8ChunkIsLoaded = _wp_playerlib_stream_m3u8_chunk_is_loaded(state, m3u8Chunk);
    if (m3u8ChunkIsInWindow && !m3u8ChunkIsLoaded) {
      // printf("Loading chunk for %f-%f\n", m3u8Chunk->fromTime, m3u8Chunk->toTime);
      int result = _wp_playerlib_stream_load_m3u8_chunk(state, m3u8Chunk, isPlaying);
      if (result != 0) {
        return result;
      }
    }
  }

  return 0;
}

bool wp_playerlib_stream_on_network_response(WpPlayerLibStreamState *state, uint32_t id, int32_t status, const char *filePath, bool isPlaying) {
  bool handled = wp_playerlib_stream_playlist_network_response(&state->playlist, id, status, filePath);
  if (handled) {
    _wp_playerlib_stream_update_chunks(state, isPlaying);
  } else {
    for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
      handled |= wp_playerlib_stream_chunk_network_response(&state->chunks[i], id, status, filePath, isPlaying);
      if (handled) {
        break;
      }
    }
  }
  return handled;
}

void wp_playerlib_stream_print_state(WpPlayerLibStreamState *state) {
  char statusString[10];
  switch (state->status) {
    case WP_S_ARMED:
      strcpy(statusString, "ARMED  ");
      break;
    case WP_S_STARTED:
      strcpy(statusString, "STARTED");
      break;
    case WP_S_ERROR:
      strcpy(statusString, "ERROR  ");
      break;
  }
  printf("Stream %s state: %s at frame %lld\n", state->id, statusString, ma_engine_get_time_in_pcm_frames(state->engine));
  int initialisedChunkIndexes[WP_PLAYERLIB_STREAM_CHUNK_COUNT];
  int initialisedChunkCount = 0;
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    if (!wp_playerlib_stream_chunk_is_uninitialised(&state->chunks[i])) {
      initialisedChunkIndexes[initialisedChunkCount++] = i;
    }
  }
  for (int i = 0; i < initialisedChunkCount - 1; i++) {
    for (int j = 0; j < initialisedChunkCount - i - 1; j++) {
      if (state->chunks[initialisedChunkIndexes[j]].fromTime > state->chunks[initialisedChunkIndexes[j + 1]].fromTime) {
        int temp = initialisedChunkIndexes[j];
        initialisedChunkIndexes[j] = initialisedChunkIndexes[j + 1];
        initialisedChunkIndexes[j + 1] = temp;
      }
    }
  }
  uint32_t sr = ma_engine_get_sample_rate(state->engine);
  for (int i = 0; i < initialisedChunkCount; i++) {
    WpPlayerLibStreamChunkState *chunk = &state->chunks[initialisedChunkIndexes[i]];
    char stateString[10];
    switch (chunk->status) {
      case WP_SC_UNINITIALISED: strcpy(stateString, "UNINIT "); break;
      case WP_SC_LOADING:       strcpy(stateString, "LOADING"); break;
      case WP_SC_LOADED:        strcpy(stateString, "LOADED "); break;
      case WP_SC_ARMED: strcpy(stateString, "ARMED "); break;
      case WP_SC_STARTED: strcpy(stateString, "STARTED"); break;
      case WP_SC_ERROR: strcpy(stateString, "ERROR  "); break;
    }
    printf("  Chunk state=%s %f-%f (%"PRId64"->%"PRId64")\n",
      stateString,
      chunk->fromTime,
      chunk->toTime,
      (int64_t)(wp_playerlib_stream_chunk_stream_get_start_engine_frame(chunk) + chunk->fromTime * sr),
      (int64_t)(wp_playerlib_stream_chunk_stream_get_start_engine_frame(chunk) + chunk->toTime * sr)
    );
  }
}

void wp_playerlib_stream_tick(WpPlayerLibStreamState *state, bool isPlaying) {
  // wp_playerlib_stream_print_state(state);
  if (state->status != WP_S_STARTED) {
    return;
  }
  _wp_playerlib_stream_update_chunks(state, isPlaying);
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    wp_playerlib_stream_chunk_tick(&state->chunks[i], isPlaying);
  }
}

void _wp_playerlib_stream_schedule_fade_out(WpPlayerLibStreamState *state) {
  int64_t fadeOutScheduledAtEngineFrame = wp_playerlib_stream_get_end_engine_frame(state) - (int64_t)state->fadeOutFrames;
  int64_t startFadeOutAtEngineFrame = max64(fadeOutScheduledAtEngineFrame, ma_engine_get_time_in_pcm_frames(state->engine));
  int64_t endEngineFrame = wp_playerlib_stream_get_end_engine_frame(state);
  uint64_t fadeOutFrames = endEngineFrame < 0 ? 0 : endEngineFrame - min64(endEngineFrame, startFadeOutAtEngineFrame);
  printf("Fade out scheduled at frame %"PRId64", starting at frame %"PRId64", fading out %"PRIu64" frames\n", fadeOutScheduledAtEngineFrame, startFadeOutAtEngineFrame, fadeOutFrames);
  if (startFadeOutAtEngineFrame > (int64_t)ma_engine_get_time_in_pcm_frames(state->engine)) {
    // Ensure we're at full gain first if we're not already in the frame time.
    // This is mostly to address seek-back from previous faded streams.
    wp_playerlib_fader_set_source_and_target_starting_at_frame(
      state->fadeOutFader,
      1.0f,
      0.0f,
      startFadeOutAtEngineFrame,
      fadeOutFrames
    );
  } else {
    wp_playerlib_fader_set_target_starting_at_frame(
      state->fadeOutFader,
      0.0f,
      startFadeOutAtEngineFrame,
      fadeOutFrames
    );
  }
}

int wp_playerlib_stream_enter_phase(WpPlayerLibStreamState *state, int64_t timelineToEngineFrameDelta, bool isPlaying) {
  if (state->status != WP_S_ARMED) {
    return 0;
  }
  state->status = WP_S_STARTED;
  state->timelineToEngineFrameDelta = timelineToEngineFrameDelta;
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    state->chunks[i].timelineToEngineFrameDelta = timelineToEngineFrameDelta;
  }
  wp_playerlib_stream_tick(state, isPlaying);
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    int result = wp_playerlib_stream_chunk_start(&state->chunks[i], isPlaying);
    if (result != 0) {
      return result;
    }
  }
  _wp_playerlib_stream_schedule_fade_out(state);
  return 0;
}

int wp_playerlib_stream_leave_phase(WpPlayerLibStreamState *state, bool isPlaying) {
  if (state->status != WP_S_STARTED) {
    return -1;
  }
  state->phaseEndEngineFrame = ma_engine_get_time_in_pcm_frames(state->engine) + state->fadeOutFrames;
  _wp_playerlib_stream_schedule_fade_out(state);
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    wp_playerlib_stream_chunk_update_stream_timing(&state->chunks[i], state->streamStartTimelineFrame, state->streamEndTimelineFrame, state->phaseEndEngineFrame);
  }
  wp_playerlib_stream_tick(state, isPlaying);
  return 0;
}

int wp_playerlib_stream_seek_to_time_in_phase(WpPlayerLibStreamState *state, int64_t timelineToEngineFrameDelta, bool isPlaying) {
  state->timelineToEngineFrameDelta = timelineToEngineFrameDelta;
  // Uninit chunks in reverse order so that queued network requests (higher slots)
  // are cancelled before the active request (slot 0). This prevents the cancel cascade
  // where cancelling the active request promotes a queued one that's about to be cancelled.
  for (int i = WP_PLAYERLIB_STREAM_CHUNK_COUNT - 1; i >= 0; i--) {
    state->chunks[i].timelineToEngineFrameDelta = timelineToEngineFrameDelta;
    wp_playerlib_stream_chunk_uninit(&state->chunks[i]);
  }
  wp_playerlib_fader_set_target(state->gainFader, 1.0f, 10);
  _wp_playerlib_stream_schedule_fade_out(state);
  wp_playerlib_stream_tick(state, isPlaying);
  return 0;
}

int wp_playerlib_stream_update_attributes(WpPlayerLibStreamState *state, uint64_t fromEffectiveTime, uint64_t toEffectiveTime, uint64_t fadeOutTime, float gain, float sidechainGain, bool isPlaying) {
  uint64_t sr = ma_engine_get_sample_rate(state->engine);
  state->streamStartTimelineFrame = fromEffectiveTime * sr / 1000;
  state->streamEndTimelineFrame = toEffectiveTime * sr / 1000;
  state->fadeOutFrames = fadeOutTime * sr / 1000;
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    wp_playerlib_stream_chunk_update_stream_timing(&state->chunks[i], state->streamStartTimelineFrame, state->streamEndTimelineFrame, state->phaseEndEngineFrame);
  }
  wp_playerlib_fader_set_target(state->gainFader, gain, sr);
  if (state->sidechainFader != NULL) {
    wp_playerlib_fader_set_target(state->sidechainFader, sidechainGain, sr);
  }
  wp_playerlib_stream_tick(state, isPlaying);
  if (state->status == WP_S_STARTED) {
    _wp_playerlib_stream_schedule_fade_out(state);
  }
  return 0;
}

float wp_playerlib_stream_get_buffered_time(WpPlayerLibStreamState *state) {
  int64_t sr = ma_engine_get_sample_rate(state->engine);

  // We have the stream start frame if it's in fact been started.
  // Otherwise we simulate by calculating what the stream start frame would be
  // if it was started now.
  int64_t currentEngineFrame = ma_engine_get_time_in_pcm_frames(state->engine);
  int64_t streamStartEngineFrame = state->status == WP_S_STARTED ?
    wp_playerlib_stream_get_start_engine_frame(state) :
    currentEngineFrame;
  // The current frame in the stream is the current engine frame minus the stream start frame
  // If the stream start frame is in the future, this'll be negative, which adds to the effective buffered time from now.
  int64_t currentStreamFrame = currentEngineFrame - streamStartEngineFrame;
  // Convert current frame to time in seconds
  float currentTime = (float)currentStreamFrame / (float)sr;

  // Collect the fromTime/toTime of all actually-buffered (downloaded) chunks.
  // We then find the contiguous range starting from the current playback position,
  // so we never overcount when there are gaps between loaded chunks.
  int bufferedCount = 0;
  float bufferedFromTimes[WP_PLAYERLIB_STREAM_CHUNK_COUNT];
  float bufferedToTimes[WP_PLAYERLIB_STREAM_CHUNK_COUNT];
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    if (wp_playerlib_stream_chunk_is_buffered(&state->chunks[i])) {
      bufferedFromTimes[bufferedCount] = state->chunks[i].fromTime;
      bufferedToTimes[bufferedCount] = state->chunks[i].toTime;
      bufferedCount++;
    }
  }

  if (bufferedCount == 0) {
    return 0.0f;
  }

  // Sort by fromTime (simple insertion sort — at most 200 elements)
  for (int i = 1; i < bufferedCount; i++) {
    float keyFrom = bufferedFromTimes[i];
    float keyTo = bufferedToTimes[i];
    int j = i - 1;
    while (j >= 0 && bufferedFromTimes[j] > keyFrom) {
      bufferedFromTimes[j + 1] = bufferedFromTimes[j];
      bufferedToTimes[j + 1] = bufferedToTimes[j];
      j--;
    }
    bufferedFromTimes[j + 1] = keyFrom;
    bufferedToTimes[j + 1] = keyTo;
  }

  // Walk the sorted chunks and find the contiguous end from currentTime.
  // A small tolerance (0.01s) handles floating-point gaps between adjacent chunks.
  float contiguousEnd = currentTime;
  for (int i = 0; i < bufferedCount; i++) {
    if (bufferedFromTimes[i] <= contiguousEnd + 0.01f && bufferedToTimes[i] > contiguousEnd) {
      contiguousEnd = bufferedToTimes[i];
    }
  }

  return fmaxf(contiguousEnd - currentTime, 0.0f);
}


void wp_playerlib_stream_destroy(WpPlayerLibStreamState *state) {
  for (int i = 0; i < WP_PLAYERLIB_STREAM_CHUNK_COUNT; i++) {
    wp_playerlib_stream_chunk_uninit(&state->chunks[i]);
  }
  if (state->sidechainFader != NULL) {
    wp_playerlib_fader_destroy(state->sidechainFader);
    free(state->sidechainFader);
  }
  if (state->gainFader != NULL) {
    wp_playerlib_fader_destroy(state->gainFader);
    free(state->gainFader);
  }
  if (state->sidechainSplitter != NULL) {
    ma_node_uninit(state->sidechainSplitter, NULL);
    free(state->sidechainSplitter);
  }
  wp_playerlib_fader_destroy(state->fadeOutFader);
  free(state->fadeOutFader);
  wp_playerlib_stream_playlist_destroy(&state->playlist);
  free((void *)state->id);
}

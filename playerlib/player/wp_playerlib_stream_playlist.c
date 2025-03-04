#define PLAYLIST_POLL_INTERVAL_MS 2000
typedef enum WpPlayerLibStreamPlaylistStatus {
  WP_SPL_FREE,
  WP_SPL_LOADING,
  WP_SPL_LOADED_PARTIAL,
  WP_SPL_LOADED_FULL,
  WP_SPL_ERROR
} WpPlayerLibStreamPlaylistStatus;

typedef struct WpPlayerLibStreamPlaylistState {
  const char *id;
  WpPlayerLibStreamPlaylistStatus status;
  const char *url;
  const char *filePath;
  bool loop;
  WpPlayerLibM3u8State m3u8;
  uint32_t currentRequestId;
  WpPlayerLibNetworkState *network;
} WpPlayerLibStreamPlaylistState;

static bool is_m3u8_url(const char *url) {
  size_t len = strlen(url);
  if (len < 5 || strcmp(url + len - 5, ".m3u8") != 0) {
    return false;
  }
  return true;
}

int wp_playerlib_stream_playlist_init(WpPlayerLibStreamPlaylistState *state, WpPlayerLibNetworkState *network) {
  char idStr[32];
  snprintf(idStr, sizeof(idStr), "%u", wp_playerlib_id_next());
  state->id = strdup(idStr);
  state->status = WP_SPL_FREE;
  state->url = NULL;
  state->filePath = NULL;
  state->currentRequestId = 0;
  state->network = network;
  wp_playerlib_m3u8_init(&state->m3u8);
  return 0;
}

void wp_playerlib_stream_playlist_arm(WpPlayerLibStreamPlaylistState *state, const char *playlistUrl, bool loop) {
  state->status = WP_SPL_LOADING;
  state->url = strdup(playlistUrl);
  state->loop = loop;
  state->currentRequestId = wp_playerlib_id_next();
  wp_playerlib_network_request(state->network, state->id, state->currentRequestId, state->url, time_now());
}

double wp_playerlib_stream_get_file_duration(const char *filePath) {
  ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 2, 48000);
  config.ppCustomBackendVTables = pCustomBackendVTables;
  config.customBackendCount = sizeof(pCustomBackendVTables) / sizeof(pCustomBackendVTables[0]);

  ma_decoder decoder;
  ma_result result = ma_decoder_init_file(filePath, &config, &decoder);
  if (result != MA_SUCCESS) {
    printf("Failed to init decoder for %s: %s\n", filePath, ma_result_description(result));
    return -1;
  }
  ma_uint64 length;
  result = ma_decoder_get_length_in_pcm_frames(&decoder, &length);
  ma_decoder_uninit(&decoder);
  if (result != MA_SUCCESS) {
    printf("Failed to get length for %s\n", filePath);
    return -1;
  }
  return (double)length / 48000.0;
}

bool wp_playerlib_stream_playlist_network_response(WpPlayerLibStreamPlaylistState *state, uint32_t id, int32_t status, const char *filePath) {
  if (id == state->currentRequestId) {
    if (status != 0) {
      state->status = WP_SPL_ERROR;
    } else if (is_m3u8_url(state->url)) {
      if (state->filePath != NULL) {
        unlink(state->filePath);
        free((void *)state->filePath);
        state->filePath = NULL;
      }
      state->filePath = strdup(filePath);
      int parseResult = wp_playerlib_m3u8_parse(&state->m3u8, state->url, filePath, state->loop);
      if (parseResult == 0) {
        if (!state->m3u8.isEnded) {
          // Schedule the next poll of the playlist if it hasn't finished yet
          state->currentRequestId = wp_playerlib_id_next();
          wp_playerlib_network_request(state->network, state->id,state->currentRequestId, state->url, time_after(PLAYLIST_POLL_INTERVAL_MS));
        } else {
          state->currentRequestId = 0;
        }
      } else {
        state->status = WP_SPL_ERROR;
      }
    } else {
      wp_playerlib_m3u8_populate_single_chunk(&state->m3u8, state->url, filePath, wp_playerlib_stream_get_file_duration(filePath), state->loop);
      state->status = WP_SPL_LOADED_FULL;
    }
    return true;
  } else {
    return false;
  }
}

void wp_playerlib_stream_playlist_destroy(WpPlayerLibStreamPlaylistState *state) {
  if (state->currentRequestId != 0 ) {
    wp_playerlib_network_cancel(state->network, state->currentRequestId);
  } 
  wp_playerlib_m3u8_destroy(&state->m3u8);
  if (state->url != NULL) {
    free((void *)state->url);
    state->url = NULL;
  }
  if (state->filePath != NULL) {
    unlink(state->filePath);
    free((void *)state->filePath);
    state->filePath = NULL;
  }
  state->currentRequestId = 0;
  state->network = NULL;
  state->status = WP_SPL_FREE;
  free((void *)state->id);
}

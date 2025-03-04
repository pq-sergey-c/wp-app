#ifndef wp_playerlib_h
#define wp_playerlib_h

#include <stdint.h>
#include <stdbool.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*WpNetworkRequestCallback)(const void *context, uint32_t id, const char* url, int64_t scheduledTime);
typedef void (*WpCancelNetworkRequestCallback)(const void *context, uint32_t id);

typedef enum WpPlayerLibPhase {
  WP_PHASE_NONE,
  WP_PHASE_PRE,
  WP_PHASE_SESSION,
  WP_PHASE_POST,

  _WP_PHASE_COUNT
} WpPlayerLibPhase;

typedef struct WpPlayerLibStream {
  const char* id;
  WpPlayerLibPhase phase;
  const char* url;
  uint64_t fromTime;
  uint64_t toTime;
  uint64_t fadeOutTime;
  uint8_t loopContent;
  float gain;
  uint8_t usesSidechain;
  float sidechainGain;
} WpPlayerLibStream;

typedef struct WpPlayerLibState WpPlayerLibState;

WpPlayerLibState* wp_playerlib_create(float sampleRate, int64_t bufferingLookahead);
void wp_playerlib_register_network_request_callbacks(WpPlayerLibState* state, WpNetworkRequestCallback networkRequestCallback, WpCancelNetworkRequestCallback cancelNetworkRequestCallback, const void *networkRequestCallbackContext);
void wp_playerlib_on_network_response(WpPlayerLibState* state, uint32_t id, int32_t status, const char *filePath);
const void* wp_playerlib_get_network_request_callback_context(WpPlayerLibState* state);
int wp_playerlib_set_session(WpPlayerLibState* state, const WpPlayerLibStream *streams, int streamCount);
WpPlayerLibPhase wp_playerlib_get_phase(WpPlayerLibState* state);
int64_t wp_playerlib_get_time_in_phase(WpPlayerLibState* state);
int wp_playerlib_set_phase(WpPlayerLibState* state, WpPlayerLibPhase phase, int64_t timeWithinPhase);
int wp_playerlib_seek_to_time_in_phase(WpPlayerLibState* state, int64_t timeWithinPhase);
bool wp_playerlib_is_started(WpPlayerLibState* state);
int wp_playerlib_start(WpPlayerLibState* state);
int wp_playerlib_stop(WpPlayerLibState* state);
void wp_playerlib_set_volume(WpPlayerLibState* state, float volume);
float wp_playerlib_get_buffered_time(WpPlayerLibState* state);
void wp_playerlib_destroy(WpPlayerLibState* state);

// For manual PCM reading outside of regular audio context (e.g. tests, static file rendering)
void wp_playerlib_read_pcm_frames(WpPlayerLibState* state, void *output, uint64_t framesToRead);
void wp_playerlib_tick(WpPlayerLibState* state);

#ifdef __cplusplus
}
#endif

#endif

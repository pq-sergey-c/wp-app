#ifndef WpPlayerLib__wp_playerlib
#define WpPlayerLib__wp_playerlib

// Disclaimer: non author attempt of structuring
// Note: has its own additional thread (at least one)

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @param scheduledTime - seems to be UTC timestamp in miliseconds
 */
typedef void (*WpNetworkRequestCallback)(const void *context, uint32_t id, const char* url, int64_t scheduledTime);
typedef void (*WpCancelNetworkRequestCallback)(const void *context, uint32_t id);

typedef enum WpPlayerLibPhase {
  WP_PHASE_NONE,
  WP_PHASE_PRE,
  WP_PHASE_SESSION,
  WP_PHASE_POST,

  _WP_PHASE_COUNT
} WpPlayerLibPhase;

/**
 * @param url - it seems that this base url is been modified and send as param back to client of lib via callback
 * @param fromTime - seems to be miliseconds
 * @param toTime - seems to be miliseconds
 * @param fadeOutTime - seems to be in miliseconds
 * @param usesSidechain - seems to be bool as uint8_t
 * @param loopContent - seems to be bool as uint8_t
 *
 */
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

// ================= Constructor/destructor =================
WpPlayerLibState* wp_playerlib_create(float sampleRate, int64_t bufferingLookahead);
void wp_playerlib_destroy(WpPlayerLibState* state);

// ================= Music run - it has smooth volume in/out effect =================
/**
 * @brief it may be the case that you firstly need to provide data/possibility of requesting data before starting
 */
int wp_playerlib_start(WpPlayerLibState* state);

int wp_playerlib_stop(WpPlayerLibState* state);

/**
 * @return real is_started (fading out on stop is still is_started)
 */
bool wp_playerlib_is_started(WpPlayerLibState* state);

// ================= Network =================
// Note: seems that workflow is: you set callbacks -> lib calls callback -> you may need to do work and send result to wp_playerlib_on_network_response

/**
 * @param networkRequestCallback, @param cancelNetworkRequestCallback - just calls this callbacks while working (fire-go no await/etc.)
 * @param networkRequestCallbackContext - is been ssend inside callbacks that also passed in this setter as first param in call
 *                                        it isn't freed by lib, so you need manually operate with memory on usage (on usage + usage with dynamic memory)
 */
void wp_playerlib_register_network_request_callbacks(WpPlayerLibState* state, WpNetworkRequestCallback networkRequestCallback, WpCancelNetworkRequestCallback cancelNetworkRequestCallback, const void *networkRequestCallbackContext);

/**
 * @param filePath - expects real filePath to file with audio
 * @param status - expects POSIX/Unix type of status
 */
void wp_playerlib_on_network_response(WpPlayerLibState* state, uint32_t id, int32_t status, const char *filePath);

/**
 * @brief returns network request context that you are setting in [wp_playerlib_register_network_request_callbacks]
 */
const void* wp_playerlib_get_network_request_callback_context(WpPlayerLibState* state);

// ================= Change of tracks/streams =================
/**
 * @brief - swaps current playing tracks/streams, for some reason (stillExists?) can remove provided
 *          stream from internal array and by this also shorten total streamCount
 *
 * @remarks - maybe can be optimized if to move realloc out of for-loop (only one realloc if any)
 * @return - (seems to) 0 - success, -1 - failed somewhere
 */
int wp_playerlib_set_session(WpPlayerLibState* state, const WpPlayerLibStream *streams, int streamCount);

// ================= Get/Set info =================
/**
 * @param volume - [0.0f, 1.0f] where 0.0f - min dB, 1.0f max dB, has min-max inside on (0.0f, 1.0f)
 */
void wp_playerlib_set_volume(WpPlayerLibState* state, float volume);

WpPlayerLibPhase wp_playerlib_get_phase(WpPlayerLibState* state);

/**
 * @param timeWithinPhase - seems to be in milliseconds
 * @return int - seems to return only 0, but I assume you can check on 0 - success, non 0 - failed
 */
int wp_playerlib_set_phase(WpPlayerLibState* state, WpPlayerLibPhase phase, int64_t timeWithinPhase);

/**
 * @return int64_t - seems to be in milliseconds
 */
int64_t wp_playerlib_get_time_in_phase(WpPlayerLibState* state);

/**
 * @param timeWithinPhase - seems to be in milliseconds
 * @return int - seems to return only 0, but I assume you can check on 0 - success, non 0 - failed
 */
int wp_playerlib_seek_to_time_in_phase(WpPlayerLibState* state, int64_t timeWithinPhase);

/**
 * @return float - seems to be time in seconds
 */
float wp_playerlib_get_buffered_time(WpPlayerLibState* state);

// =================   =================
// For manual PCM reading outside of regular audio context (e.g. tests, static file rendering)
void wp_playerlib_read_pcm_frames(WpPlayerLibState* state, void *output, uint64_t framesToRead);
void wp_playerlib_tick(WpPlayerLibState* state);

#ifdef __cplusplus
}
#endif

#endif // WpPlayerLib__wp_playerlib

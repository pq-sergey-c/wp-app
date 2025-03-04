#include <emscripten.h>
#include <emscripten/threading.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/time.h>

#include "wp_playerlib.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_TRACK_IDS 100
#define MAX_TRACK_ID_LENGTH 100


typedef struct WpPlayerLibWasmState {
  WpPlayerLibState* playerState;
} WpPlayerLibWasmState;

void wp_playerlib_wasm_network_response(void* state, uint32_t id, int32_t status, const char* filePath) {
  wp_playerlib_on_network_response(state, id, status, filePath);
}

EM_JS(void, fetchUrlAsync, (const char* url, uint32_t id, int32_t delay, void* state), {
  let urlString = UTF8ToString(url);
  _free(url); // strdup'd below when sending from the worker pthread, so we own it

  let abort = new AbortController();
  window._wpPlayerLibAborts = window._wpPlayerLibAborts || new Map();
  window._wpPlayerLibAborts.set(id, abort);

  function req() {
    let startTime = Date.now();
    console.log('Fetch', urlString);
    fetch(urlString, { signal: abort.signal })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.arrayBuffer();
      })
      .then(arrayBuffer => {
        let randId = Math.floor(Math.random() * 1000000);
        let fileName = '/tmp/wp_playerlib_file_' + randId;
        FS.writeFile(fileName, new Uint8Array(arrayBuffer));
        let fileNamePtr = _malloc(fileName.length + 1);
        stringToUTF8(fileName, fileNamePtr, fileName.length + 1);
        _wp_playerlib_wasm_network_response(state, id, 0, fileNamePtr);
        _free(fileNamePtr);
      })
      .catch(error => {
        console.error('Fetch error for ', urlString, ':', error);
        _wp_playerlib_wasm_network_response(state, id, 1, null);
      })
      .finally(() => {
        window._wpPlayerLibAborts.delete(id);
        console.log('Fetch for', urlString, 'completed in', Date.now() - startTime, 'ms');
      });
  }

  if (delay > 0) {
    setTimeout(() => {
      if (!abort.signal.aborted) {
        req();
      }
    }, delay);
  } else {
    req();
  }

});

EM_JS(void, cancelNetworkRequest, (uint32_t id), {
  if (window._wpPlayerLibAborts) {
    window._wpPlayerLibAborts.get(id)?.abort('Cancelled');
    window._wpPlayerLibAborts.delete(id);
  }
});


static int64_t time_now(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

void networkRequestCallback(const void *context, uint32_t id, const char* url, int64_t scheduledTime) {
  char* urlCopy = strdup(url);
  int64_t now = time_now();
  int32_t delay = scheduledTime - now;
  emscripten_async_run_in_main_runtime_thread(
    EM_FUNC_SIG_WITH_N_PARAMETERS(4),
    fetchUrlAsync,
    urlCopy,
    id,
    delay,
    (void*)context
  );
}


void cancelNetworkRequestCallback(const void *context, uint32_t id) {
  emscripten_async_run_in_main_runtime_thread(
    EM_FUNC_SIG_WITH_N_PARAMETERS(1),
    cancelNetworkRequest,
    id
  );
}

void* wp_playerlib_wasm_create(float sampleRate) {
    WpPlayerLibWasmState* state = malloc(sizeof(WpPlayerLibWasmState));
    WpPlayerLibState* playerState = wp_playerlib_create(sampleRate, 20 * 60);
    wp_playerlib_register_network_request_callbacks(playerState, networkRequestCallback, cancelNetworkRequestCallback, playerState);
    state->playerState = playerState;
    return state;
}

int wp_playerlib_wasm_set_session(void* state, const WpPlayerLibStream *streams, int streamCount) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_set_session(wasmState->playerState, streams, streamCount);
}

WpPlayerLibPhase wp_playerlib_wasm_get_phase(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_get_phase(wasmState->playerState);
}

int64_t wp_playerlib_wasm_get_time_in_phase(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_get_time_in_phase(wasmState->playerState);
}

int wp_playerlib_wasm_set_phase(void* state, WpPlayerLibPhase phase, int64_t timeWithinPhase) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_set_phase(wasmState->playerState, phase, timeWithinPhase);
}

int wp_playerlib_wasm_seek_to_time_in_phase(void* state, int64_t timeWithinPhase) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_seek_to_time_in_phase(wasmState->playerState, timeWithinPhase);
}

int wp_playerlib_wasm_start(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_start(wasmState->playerState);
}

int wp_playerlib_wasm_stop(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_stop(wasmState->playerState);
}

bool wp_playerlib_wasm_is_started(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_is_started(wasmState->playerState);
}

void wp_playerlib_wasm_set_volume(void* state, float volume) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    wp_playerlib_set_volume(wasmState->playerState, volume);
}

float wp_playerlib_wasm_get_buffered_time(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    return wp_playerlib_get_buffered_time(wasmState->playerState);
}

void wp_playerlib_wasm_destroy(void* state) {
    WpPlayerLibWasmState* wasmState = (WpPlayerLibWasmState*)state;
    wp_playerlib_destroy(wasmState->playerState);
    free(wasmState);
}

WpPlayerLibStream* wp_playerlib_wasm_malloc_streams(int streamCount) {
    return malloc(streamCount * sizeof(WpPlayerLibStream));
}

void wp_playerlib_wasm_set_stream(WpPlayerLibStream* streams, int index, const char *id, WpPlayerLibPhase phase, const char *url, uint64_t fromTime, uint64_t toTime, uint64_t fadeOutTime, uint8_t loopContent, float gain, bool usesSidechain, float sidechainGain) {
    streams[index].id = id;
    streams[index].phase = phase;
    streams[index].url = url;
    streams[index].fromTime = fromTime;
    streams[index].toTime = toTime;
    streams[index].fadeOutTime = fadeOutTime;
    streams[index].loopContent = loopContent;
    streams[index].gain = gain;
    streams[index].usesSidechain = usesSidechain;
    streams[index].sidechainGain = sidechainGain;
}


#ifdef __cplusplus
}
#endif
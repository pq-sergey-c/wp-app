#include <emscripten.h>
#include <emscripten/html5.h>
#include <emscripten/threading.h>

typedef struct WpPlayerLibTickState {
  long intervalId;
  WpPlayerLibTickResult (*callback)(void*);
  void* context;
} WpPlayerLibTickState;

void wp_playerlib_tick_init(WpPlayerLibTickState* state, WpPlayerLibTickResult (*callback)(void*), void* context) {
  state->callback = callback;
  state->context = context;
  state->intervalId = 0;
}

void _wp_playerlib_tick_interval_callback(void* context) {
  WpPlayerLibTickState* state = (WpPlayerLibTickState*)context;
  WpPlayerLibTickResult result = state->callback(state->context);
  if (result == WP_TICK_RESULT_STOP) {
    emscripten_clear_interval(state->intervalId);
  }
}

int wp_playerlib_tick_start(WpPlayerLibTickState* state) {
  state->intervalId = emscripten_set_interval(_wp_playerlib_tick_interval_callback, 1000, state);
  return 0;
}

void wp_playerlib_tick_tick_now(WpPlayerLibTickState* state) {
  emscripten_async_run_in_main_runtime_thread(
    EM_FUNC_SIG_WITH_N_PARAMETERS(1),
    _wp_playerlib_tick_interval_callback,
    state
  );
}

void wp_playerlib_tick_await_stop(WpPlayerLibTickState* state) {
  WpPlayerLibTickResult result = state->callback(state->context);
  if (result == WP_TICK_RESULT_STOP) {
    emscripten_clear_interval(state->intervalId);
  } else {
    printf("Warning: Tick callback expected to return WP_TICK_RESULT_STOP, but returned %d\n", result);
  }
}

void wp_playerlib_tick_destroy(WpPlayerLibTickState* state) {
  (void)state;
}

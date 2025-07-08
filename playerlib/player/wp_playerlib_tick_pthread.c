typedef struct WpPlayerLibTickState {
  pthread_cond_t cond;
  pthread_mutex_t mutex;
  pthread_t thread;
  WpPlayerLibTickResult (*callback)(void*);
  void* context;
} WpPlayerLibTickState;

void wp_playerlib_tick_init(WpPlayerLibTickState* state, WpPlayerLibTickResult (*callback)(void*), void* context) {
  pthread_mutex_init(&state->mutex, NULL);
  pthread_cond_init(&state->cond, NULL);
  state->thread = (pthread_t)0;
  state->callback = callback;
  state->context = context;
}

void* _wp_playerlib_tick_thread_callback(void *arg) {
  WpPlayerLibTickState* state = (WpPlayerLibTickState*)arg;
  pthread_mutex_lock(&state->mutex);
  printf("Ticker thread started\n");
  while (true) {
    struct timeval tv;
    struct timespec t = { 0 };
    gettimeofday(&tv, NULL);
    t.tv_sec = tv.tv_sec + 1;
    pthread_cond_timedwait(&state->cond, &state->mutex, &t);
    WpPlayerLibTickResult result = state->callback(state->context);
    if (result == WP_TICK_RESULT_STOP) {
      pthread_mutex_unlock(&state->mutex);
      return NULL;
    }
  }
  return NULL;
}

int wp_playerlib_tick_start(WpPlayerLibTickState* state) {
  return pthread_create(&state->thread, NULL, _wp_playerlib_tick_thread_callback, state);
}

void wp_playerlib_tick_tick_now(WpPlayerLibTickState* state) {
  pthread_cond_signal(&state->cond);
}

void wp_playerlib_tick_await_stop(WpPlayerLibTickState* state) {
  pthread_mutex_lock(&state->mutex);
  pthread_cond_signal(&state->cond);
  pthread_mutex_unlock(&state->mutex);
  if (state->thread != (pthread_t)0) {
    pthread_join(state->thread, NULL);
  }
}

void wp_playerlib_tick_destroy(WpPlayerLibTickState* state) {
  pthread_mutex_destroy(&state->mutex);
  pthread_cond_destroy(&state->cond);
  state->thread = (pthread_t)0;
}

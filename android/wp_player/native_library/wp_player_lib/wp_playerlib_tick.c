typedef enum WpPlayerLibTickResult {
  WP_TICK_RESULT_OK = 0,
  WP_TICK_RESULT_STOP = 1,
} WpPlayerLibTickResult;

#ifdef __EMSCRIPTEN__
  #include "wp_playerlib_tick_js.c"
#else
  #include "wp_playerlib_tick_pthread.c"
#endif

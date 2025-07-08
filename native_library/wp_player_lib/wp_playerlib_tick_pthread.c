#ifdef _WIN32
#include <windows.h>
#include <process.h>
#else
#include <pthread.h>
#include <sys/time.h>
#endif
#include <stdbool.h>
#include <stdio.h>
#include "wp_playerlib.h"

#ifdef _WIN32
#define TICK_MUTEX_TYPE CRITICAL_SECTION
#define TICK_COND_TYPE CONDITION_VARIABLE
#define TICK_THREAD_TYPE HANDLE
#define TICK_THREAD_RETURN unsigned __stdcall
#define TICK_THREAD_CALLCONV __stdcall
#else
#define TICK_MUTEX_TYPE pthread_mutex_t
#define TICK_COND_TYPE pthread_cond_t
#define TICK_THREAD_TYPE pthread_t
#define TICK_THREAD_RETURN void*
#define TICK_THREAD_CALLCONV
#endif

typedef struct WpPlayerLibTickState {
  TICK_COND_TYPE cond;
  TICK_MUTEX_TYPE mutex;
  TICK_THREAD_TYPE thread;
  WpPlayerLibTickResult (*callback)(void*);
  void* context;
} WpPlayerLibTickState;

void wp_playerlib_tick_init(WpPlayerLibTickState* state, WpPlayerLibTickResult (*callback)(void*), void* context) {
#ifdef _WIN32
  InitializeCriticalSection(&state->mutex);
  InitializeConditionVariable(&state->cond);
  state->thread = NULL;
#else
  pthread_mutex_init(&state->mutex, NULL);
  pthread_cond_init(&state->cond, NULL);
  state->thread = (pthread_t)0;
#endif
  state->callback = callback;
  state->context = context;
}

#ifdef _WIN32
unsigned TICK_THREAD_CALLCONV _wp_playerlib_tick_thread_callback(void *arg) {
  WpPlayerLibTickState* state = (WpPlayerLibTickState*)arg;
  EnterCriticalSection(&state->mutex);
  printf("Ticker thread started\n");
  while (true) {
    SleepConditionVariableCS(&state->cond, &state->mutex, 1000); // 1 second
    WpPlayerLibTickResult result = state->callback(state->context);
    if (result == WP_TICK_RESULT_STOP) {
      LeaveCriticalSection(&state->mutex);
      return 0;
    }
  }
  return 0;
}
#else
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
#endif

int wp_playerlib_tick_start(WpPlayerLibTickState* state) {
#ifdef _WIN32
  unsigned threadID;
  state->thread = (HANDLE)_beginthreadex(NULL, 0, _wp_playerlib_tick_thread_callback, state, 0, &threadID);
  return state->thread ? 0 : -1;
#else
  return pthread_create(&state->thread, NULL, _wp_playerlib_tick_thread_callback, state);
#endif
}

void wp_playerlib_tick_tick_now(WpPlayerLibTickState* state) {
#ifdef _WIN32
  WakeConditionVariable(&state->cond);
#else
  pthread_cond_signal(&state->cond);
#endif
}

void wp_playerlib_tick_await_stop(WpPlayerLibTickState* state) {
#ifdef _WIN32
  EnterCriticalSection(&state->mutex);
  WakeConditionVariable(&state->cond);
  LeaveCriticalSection(&state->mutex);
  if (state->thread) {
    WaitForSingleObject(state->thread, INFINITE);
    CloseHandle(state->thread);
    state->thread = NULL;
  }
#else
  pthread_mutex_lock(&state->mutex);
  pthread_cond_signal(&state->cond);
  pthread_mutex_unlock(&state->mutex);
  if (state->thread != (pthread_t)0) {
    pthread_join(state->thread, NULL);
  }
#endif
}

void wp_playerlib_tick_destroy(WpPlayerLibTickState* state) {
#ifdef _WIN32
  DeleteCriticalSection(&state->mutex);
  state->thread = NULL;
#else
  pthread_mutex_destroy(&state->mutex);
  pthread_cond_destroy(&state->cond);
  state->thread = (pthread_t)0;
#endif
}

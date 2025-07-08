#include "wp_playerlib.h"
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ONGOING_REQUESTS 200

// Let's be fairly persistent with our retries
#define MAX_RETRIES 100
#define RETRY_INTERVAL_MS 3000

typedef struct WpPlayerLibNetworkOngoingRequest {
  bool occupied;
  int64_t requestedAt;
  const char *groupId;
  uint32_t id;
  const char *url;
  uint32_t tryCount;
} WpPlayerLibNetworkOngoingRequest;

typedef struct WpPlayerLibNetworkState {
  WpNetworkRequestCallback networkRequestCallback;
  WpCancelNetworkRequestCallback cancelNetworkRequestCallback;
  const void *networkRequestCallbackContext;
  WpPlayerLibNetworkOngoingRequest ongoingRequests[MAX_ONGOING_REQUESTS];
} WpPlayerLibNetworkState;

void wp_playerlib_network_init(WpPlayerLibNetworkState *state) {
  state->networkRequestCallback = NULL;
  state->cancelNetworkRequestCallback = NULL;
  state->networkRequestCallbackContext = NULL;
  for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
    state->ongoingRequests[i].occupied = false;
  }
}

void wp_playerlib_network_connect(WpPlayerLibNetworkState *state, WpNetworkRequestCallback networkRequestCallback, WpCancelNetworkRequestCallback cancelNetworkRequestCallback, const void *networkRequestCallbackContext) {
  state->networkRequestCallback = networkRequestCallback;
  state->cancelNetworkRequestCallback = cancelNetworkRequestCallback;
  state->networkRequestCallbackContext = networkRequestCallbackContext;
}

WpPlayerLibNetworkOngoingRequest* init_ongoing_request(WpPlayerLibNetworkState *state, const char *groupId, uint32_t id, const char *url) {
  for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
    if (!state->ongoingRequests[i].occupied) {
      state->ongoingRequests[i].occupied = true;
      state->ongoingRequests[i].requestedAt = time_now();
      state->ongoingRequests[i].groupId = strdup(groupId);
      state->ongoingRequests[i].id = id;
      state->ongoingRequests[i].url = strdup(url);
      if (state->ongoingRequests[i].url == NULL) {
        printf("ERROR: Failed to strdup url: %d\n", errno);
        state->ongoingRequests[i].occupied = false;
        return NULL;
      }
      state->ongoingRequests[i].tryCount = 0;
      return &state->ongoingRequests[i];
    }
  }
  return NULL;
}

WpPlayerLibNetworkOngoingRequest* get_ongoing_request(WpPlayerLibNetworkState *state, uint32_t id) {
  for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
    if (state->ongoingRequests[i].occupied && state->ongoingRequests[i].id == id) {
      return &state->ongoingRequests[i];
    }
  }
  return NULL;
}

void clear_ongoing_request(WpPlayerLibNetworkState *state, uint32_t id) {
  for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
    if (state->ongoingRequests[i].occupied && state->ongoingRequests[i].id == id) {
      state->ongoingRequests[i].occupied = false;
      // See if the group has a further request we could fire now
      const char *groupId = state->ongoingRequests[i].groupId;
      int nextRequestIdx = -1;
      for (uint32_t j = 0; j < MAX_ONGOING_REQUESTS; j++) {
        if (
          state->ongoingRequests[j].occupied &&
          strcmp(state->ongoingRequests[j].groupId, groupId) == 0 &&
          state->ongoingRequests[j].tryCount == 0 &&
          (nextRequestIdx == -1 || state->ongoingRequests[j].requestedAt < state->ongoingRequests[nextRequestIdx].requestedAt)
        ) {
          nextRequestIdx = j;
        }
      }
      if (nextRequestIdx >= 0) {
        state->networkRequestCallback(state->networkRequestCallbackContext, state->ongoingRequests[nextRequestIdx].id, state->ongoingRequests[nextRequestIdx].url, time_now());
        state->ongoingRequests[nextRequestIdx].tryCount = 1;
      }
      free((void*)state->ongoingRequests[i].groupId);
      free((void*)state->ongoingRequests[i].url);
      break;
    }
  }
}

void wp_playerlib_network_request(WpPlayerLibNetworkState *state, const char *groupId, uint32_t id, const char *url, int64_t scheduledTime) {
  if (state->networkRequestCallback != NULL) {
    WpPlayerLibNetworkOngoingRequest* ongoingRequest = init_ongoing_request(state, groupId, id, url);
    if (ongoingRequest != NULL) {
      // Let's only fire this now if the group doesn't already have an ongoing request
      bool groupHasOngoingRequest = false;
      for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
        if (
          state->ongoingRequests[i].occupied &&
          strcmp(state->ongoingRequests[i].groupId, groupId) == 0 &&
          state->ongoingRequests[i].tryCount > 0
        ) {
          groupHasOngoingRequest = true;
          break;
        }
      }
      if (!groupHasOngoingRequest) {
        ongoingRequest->tryCount = 1;
        state->networkRequestCallback(state->networkRequestCallbackContext, id, url, scheduledTime);
      }
    } else {
      printf("ERROR: Too many ongoing requests to track %s\n", url);
    }
  }
}

void wp_playerlib_network_cancel(WpPlayerLibNetworkState *state, uint32_t id) {
  if (state->cancelNetworkRequestCallback != NULL) {
    clear_ongoing_request(state, id);
    state->cancelNetworkRequestCallback(state->networkRequestCallbackContext, id);
  }
}


bool wp_playerlib_network_retry_network_response(WpPlayerLibNetworkState *state, uint32_t id, int32_t status) {
  if (status == 0) {
    clear_ongoing_request(state, id);
    return false; // Let successful requests just go to their receivers
  } else {
    WpPlayerLibNetworkOngoingRequest* ongoingRequest = get_ongoing_request(state, id);
    if (ongoingRequest != NULL) {
      if (ongoingRequest->tryCount >= MAX_RETRIES) {
        // Give up
        printf("ERROR: Request retry limit exceeded for %s\n", ongoingRequest->url);
        clear_ongoing_request(state, id);
        return false;
      } else {
        // Schedule a retry and say we got this for now
        ongoingRequest->tryCount++;
        printf("Request retry %d for %s\n", ongoingRequest->tryCount, ongoingRequest->url);
        state->networkRequestCallback(state->networkRequestCallbackContext, id, ongoingRequest->url, time_after(RETRY_INTERVAL_MS));
        return true;
      }
    } else {
      // We aren't handling retries for this request (presumably because there wasn't room to track it which shouldn't really happen)
      return false;
    }
  }
}

void wp_playerlib_network_destroy(WpPlayerLibNetworkState *state) {
  state->networkRequestCallback = NULL;
  state->cancelNetworkRequestCallback = NULL;
  state->networkRequestCallbackContext = NULL;
  for (uint32_t i = 0; i < MAX_ONGOING_REQUESTS; i++) {
    if (state->ongoingRequests[i].occupied) {
      free((void*)state->ongoingRequests[i].url);
    }
  }
}

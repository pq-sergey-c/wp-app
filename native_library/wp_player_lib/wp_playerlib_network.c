#include "wp_playerlib.h"
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "android_print.h"
// Let's be fairly persistent with our retries
#define MAX_RETRIES 100
#define RETRY_INTERVAL_MS 3000

typedef struct WpPlayerLibNetworkOngoingRequest {
  int64_t requestedAt;
  const char *groupId;
  uint32_t id;
  const char *url;
  uint32_t tryCount;
  struct WpPlayerLibNetworkOngoingRequest *next;
} WpPlayerLibNetworkOngoingRequest;

typedef struct WpPlayerLibNetworkState {
  WpNetworkRequestCallback networkRequestCallback;
  WpCancelNetworkRequestCallback cancelNetworkRequestCallback;
  const void *networkRequestCallbackContext;
  WpPlayerLibNetworkOngoingRequest *ongoingRequests;
} WpPlayerLibNetworkState;

void wp_playerlib_network_init(WpPlayerLibNetworkState *state) {
  state->networkRequestCallback = NULL;
  state->cancelNetworkRequestCallback = NULL;
  state->networkRequestCallbackContext = NULL;
  state->ongoingRequests = NULL;
}

void wp_playerlib_network_connect(WpPlayerLibNetworkState *state, WpNetworkRequestCallback networkRequestCallback, WpCancelNetworkRequestCallback cancelNetworkRequestCallback, const void *networkRequestCallbackContext) {
  state->networkRequestCallback = networkRequestCallback;
  state->cancelNetworkRequestCallback = cancelNetworkRequestCallback;
  state->networkRequestCallbackContext = networkRequestCallbackContext;
}

WpPlayerLibNetworkOngoingRequest* init_ongoing_request(WpPlayerLibNetworkState *state, const char *groupId, uint32_t id, const char *url) {
  WpPlayerLibNetworkOngoingRequest *req = (WpPlayerLibNetworkOngoingRequest *)malloc(sizeof(WpPlayerLibNetworkOngoingRequest));
  if (req == NULL) {
    printf("ERROR: Failed to allocate memory for network request\n");
    return NULL;
  }
  req->requestedAt = time_now();
  req->groupId = strdup(groupId);
  req->id = id;
  req->url = strdup(url);
  if (req->url == NULL) {
    printf("ERROR: Failed to strdup url: %d\n", errno);
    free((void*)req->groupId);
    free(req);
    return NULL;
  }
  req->tryCount = 0;
  req->next = state->ongoingRequests;
  state->ongoingRequests = req;
  return req;
}

WpPlayerLibNetworkOngoingRequest* get_ongoing_request(WpPlayerLibNetworkState *state, uint32_t id) {
  WpPlayerLibNetworkOngoingRequest *req = state->ongoingRequests;
  while (req != NULL) {
    if (req->id == id) {
      return req;
    }
    req = req->next;
  }
  return NULL;
}

void clear_ongoing_request(WpPlayerLibNetworkState *state, uint32_t id) {
  WpPlayerLibNetworkOngoingRequest *prev = NULL;
  WpPlayerLibNetworkOngoingRequest *req = state->ongoingRequests;
  while (req != NULL) {
    if (req->id == id) {
      // Remove from list
      if (prev == NULL) {
        state->ongoingRequests = req->next;
      } else {
        prev->next = req->next;
      }
      // Only promote the next queued request if we removed an active one.
      // Removing a queued request (tryCount == 0) shouldn't promote because
      // it didn't free a network slot - the group still has its active request.
      if (req->tryCount > 0) {
        const char *groupId = req->groupId;
        WpPlayerLibNetworkOngoingRequest *candidate = state->ongoingRequests;
        WpPlayerLibNetworkOngoingRequest *nextRequest = NULL;
        while (candidate != NULL) {
          if (
            strcmp(candidate->groupId, groupId) == 0 &&
            candidate->tryCount == 0 &&
            (nextRequest == NULL || candidate->requestedAt <= nextRequest->requestedAt)
          ) {
            nextRequest = candidate;
          }
          candidate = candidate->next;
        }
        if (nextRequest != NULL) {
          state->networkRequestCallback(state->networkRequestCallbackContext, nextRequest->id, nextRequest->url, time_now());
          nextRequest->tryCount = 1;
        }
      }
      free((void*)req->groupId);
      free((void*)req->url);
      free(req);
      break;
    }
    prev = req;
    req = req->next;
  }
}

void wp_playerlib_network_request(WpPlayerLibNetworkState *state, const char *groupId, uint32_t id, const char *url, int64_t scheduledTime) {
  if (state->networkRequestCallback != NULL) {
    WpPlayerLibNetworkOngoingRequest* ongoingRequest = init_ongoing_request(state, groupId, id, url);
    if (ongoingRequest != NULL) {
      // Let's only fire this now if the group doesn't already have an ongoing request
      bool groupHasOngoingRequest = false;
      WpPlayerLibNetworkOngoingRequest *req = state->ongoingRequests;
      while (req != NULL) {
        if (
          strcmp(req->groupId, groupId) == 0 &&
          req->tryCount > 0
        ) {
          groupHasOngoingRequest = true;
          break;
        }
        req = req->next;
      }
      if (!groupHasOngoingRequest) {
        ongoingRequest->tryCount = 1;
        state->networkRequestCallback(state->networkRequestCallbackContext, id, url, scheduledTime);
      }
    } else {
      printf("ERROR: Failed to allocate network request for %s\n", url);
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
      return false;
    }
  }
}

void wp_playerlib_network_destroy(WpPlayerLibNetworkState *state) {
  state->networkRequestCallback = NULL;
  state->cancelNetworkRequestCallback = NULL;
  state->networkRequestCallbackContext = NULL;
  WpPlayerLibNetworkOngoingRequest *req = state->ongoingRequests;
  while (req != NULL) {
    WpPlayerLibNetworkOngoingRequest *next = req->next;
    free((void*)req->groupId);
    free((void*)req->url);
    free(req);
    req = next;
  }
  state->ongoingRequests = NULL;
}

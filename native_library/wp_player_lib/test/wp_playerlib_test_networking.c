#include "wp_playerlib.h"
#include <errno.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

static int64_t time_now (void); // due to author usage of #include ".c"

typedef struct TestNetworkResponse {
  bool armed;
  WpPlayerLibState *player;
  uint32_t id;
  int32_t status;
  const char *filePath;
  int64_t timeUntilScheduled;
} TestNetworkResponse;
static TestNetworkResponse testNetworkResponses[100];

static int64_t time_now(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

void test_network_request_callback(const void *context, uint32_t id, const char* url, int64_t scheduledTime) {
  for (int i = 0; i < 100; i++) {
    if (!testNetworkResponses[i].armed) {
      testNetworkResponses[i].armed = true;
      testNetworkResponses[i].player = (WpPlayerLibState *)context;
      testNetworkResponses[i].id = id;
      testNetworkResponses[i].status = access(url, F_OK) == 0 ? 0 : -1;
      testNetworkResponses[i].filePath = strdup(url);
      testNetworkResponses[i].timeUntilScheduled = scheduledTime - time_now();
      return;
    }
  }
}

void test_cancel_network_request_callback(const void *context, uint32_t id) {
  for (int i = 0; i < 100; i++) {
    if (testNetworkResponses[i].armed && testNetworkResponses[i].id == id) {
      testNetworkResponses[i].armed = false;
      free((void *)testNetworkResponses[i].filePath);
    }
  }
}

bool is_m3u8_url(const char *url) {
  size_t len = strlen(url);
  if (len < 5 || strcmp(url + len - 5, ".m3u8") != 0) {
    return false;
  }
  return true;
}

void copy_file_to_tmp(const char *src, const char *dst) {
  FILE *srcFile = fopen(src, "rb");
  if (srcFile == NULL) {
    printf("ERROR: Failed to open %s: %d\n", src, errno);
    return;
  }
  FILE *dstFile = fopen(dst, "wb");
  if (dstFile == NULL) {
    printf("ERROR: Failed to open %s: %d\n", dst, errno);
    fclose(srcFile);
    return;
  }
  char buf[4096];
  size_t n;
  while ((n = fread(buf, 1, sizeof(buf), srcFile)) > 0) {
    fwrite(buf, 1, n, dstFile);
  }
  fflush(dstFile);
  fclose(srcFile);
  fclose(dstFile);
}

void deliver_test_responses(const char *playlistContent, int64_t timePassed) {
  for (int i = 0; i < 100; i++) {
    if (testNetworkResponses[i].armed) {
      if (timePassed != -1) {
        testNetworkResponses[i].timeUntilScheduled -= timePassed;
      } else {
        testNetworkResponses[i].timeUntilScheduled = 0;
      }
      if (testNetworkResponses[i].timeUntilScheduled <= 0) {
        if (is_m3u8_url(testNetworkResponses[i].filePath)) {
          char *playlistTmp = strdup("/tmp/wp_playerlib_XXXXXX");
          int playlistFd = mkstemp(playlistTmp);
          FILE *playlistFile = fdopen(playlistFd, "w");
          fwrite(playlistContent, 1, strlen(playlistContent), playlistFile);
          fclose(playlistFile);
          wp_playerlib_on_network_response(testNetworkResponses[i].player, testNetworkResponses[i].id, testNetworkResponses[i].status, playlistTmp);
          free((void *)playlistTmp);
        } else {
          if (testNetworkResponses[i].status == 0) {
            char *chunkTmp = strdup("/tmp/wp_playerlib_XXXXXX");
            int chunkFd = mkstemp(chunkTmp);
            close(chunkFd);
            copy_file_to_tmp(testNetworkResponses[i].filePath, chunkTmp);
            wp_playerlib_on_network_response(testNetworkResponses[i].player, testNetworkResponses[i].id, testNetworkResponses[i].status, chunkTmp);
            free((void *)chunkTmp);
          } else {
            wp_playerlib_on_network_response(testNetworkResponses[i].player, testNetworkResponses[i].id, testNetworkResponses[i].status, NULL);
          }
        }
        free((void *)testNetworkResponses[i].filePath);
        testNetworkResponses[i].armed = false;
      }
    }
  }
}

void fail_test_responses(int32_t timePassed) {
  for (int i = 0; i < 100; i++) {
    if (testNetworkResponses[i].armed) {
      if (timePassed != -1) {
        testNetworkResponses[i].timeUntilScheduled -= timePassed;
      } else {
        testNetworkResponses[i].timeUntilScheduled = 0;
      }
      if (testNetworkResponses[i].timeUntilScheduled <= 0) {
        wp_playerlib_on_network_response(testNetworkResponses[i].player, testNetworkResponses[i].id, -999, NULL);
        free((void *)testNetworkResponses[i].filePath);
        testNetworkResponses[i].armed = false;
      }
    }
  }
}

void deliver_all_test_responses(const char *playlistContent) {
  while (true) {
    deliver_test_responses(playlistContent, -1);
    bool noneArmed = true;
    for (int i = 0; i < 100; i++) {
      if (testNetworkResponses[i].armed) {
        noneArmed = false;
      }
    }
    if (noneArmed) {
      break;
    }
  }
}

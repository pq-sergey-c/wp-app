#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/time.h>

#include <unity.h>

#include "test_config.h"

#include "wp_playerlib.h"

#include "wp_playerlib_testutils.c"
#include "wp_playerlib_test_networking.c"
#include "wp_playerlib_playlist_testdata.c"

#define LOW_SINE_LOOP_FILE_PATH TEST_DATA_DIR "/60s_220Hz.ogg"
#define HIGH_SINE_PLAYLIST_FILE_PATH TEST_DATA_DIR "/300s_440Hz/playlist.m3u8"
#define HIGH_SINE_PLAYLIST_SHORT_CHUNKS_FILE_PATH TEST_DATA_DIR "/30s_440Hz_short/playlist.m3u8"
#define SILENCE_LOOP_FILE_PATH TEST_DATA_DIR "/silence.ogg"
#define TEST_SINE_AMPLITUDE 0.088f

#define MAX_OUTPUT_FRAMES 96000
static float output[MAX_OUTPUT_FRAMES * 2];

static WpPlayerLibState *state = NULL;

void setUp(void) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  for (int i = 0; i < TEST_NETWORK_RESPONSES_SIZE; i++) {
    testNetworkResponses[i].armed = false;
  }
  memset(output, 0, sizeof(output));
  state = wp_playerlib_create(48000.f, 20 * 60);
  TEST_ASSERT_NOT_NULL(state);
  wp_playerlib_register_network_request_callbacks(state, test_network_request_callback, test_cancel_network_request_callback, state);
}

void tearDown(void) {
  wp_playerlib_destroy(state);
  for (int i = 0; i < TEST_NETWORK_RESPONSES_SIZE; i++) {
    if (testNetworkResponses[i].armed) {
      free((void *)testNetworkResponses[i].filePath);
      testNetworkResponses[i].armed = false;
    }
  }
}

void render_advance(WpPlayerLibState *state, float *output, int32_t frames) {
  wp_playerlib_read_pcm_frames(state, output, frames);
  wp_playerlib_tick(state);
}


void testIsInitiallyInNonPlayingStateAndRendersSilence(void) {
  TEST_ASSERT_FALSE(wp_playerlib_is_started(state));
  render_advance(state, output, 48000);
  for (int i = 0; i < 96000; i++) {
      TEST_ASSERT_EQUAL_FLOAT(0.f, output[i]);
  }
}

void testStartsPlayingSomethingInPrelude(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  TEST_ASSERT_EQUAL(WP_PHASE_PRE, wp_playerlib_get_phase(state));
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}

void testReportsTimeInPrelude(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  TEST_ASSERT_EQUAL(0, wp_playerlib_get_time_in_phase(state));
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_EQUAL(1000, wp_playerlib_get_time_in_phase(state));
}

void testFadesInWhenStartingPrelude(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, 1));
}

void testFadesOutWhenStoppingDuringPrelude(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);
    
  render_advance(state, output, 48000);
  
  wp_playerlib_stop(state);

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 48000));
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  TEST_ASSERT_FALSE(wp_playerlib_is_started(state));
}

void testStartsPlayingSomethingInPreludeWhenStartedBeforeItsReady(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  TEST_ASSERT_EQUAL(WP_PHASE_PRE, wp_playerlib_get_phase(state));
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}

void testPreludeIsValidAudio(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  float frequency = detect_frequency(output, 48000, 48000.f);
  TEST_ASSERT_FLOAT_WITHIN(1.f, 220.f, frequency);
}

void testPreludeIsLooping(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);
  for (int s = 0 ; s < 180 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    deliver_all_test_responses(PL_COMPLETE);
  }
}

void testPreludeWithChunksIsLooping(void) {
  WpPlayerLibStream streams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);
  for (int s = 0 ; s < 1000 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    deliver_all_test_responses(PL_COMPLETE);
  }
}

void testStartsPlayingSomethingInSession(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  TEST_ASSERT_EQUAL(WP_PHASE_SESSION, wp_playerlib_get_phase(state));
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}

void testReportsTimeInSession(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_EQUAL(1000, wp_playerlib_get_time_in_phase(state));
  render_advance(state, output, 48000);
  TEST_ASSERT_EQUAL(2000, wp_playerlib_get_time_in_phase(state));
}

void testOnlyStartsPlayingSessionStreamWhenItsTimedToStart(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 5000, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  TEST_ASSERT_EQUAL(WP_PHASE_SESSION, wp_playerlib_get_phase(state));

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}

void doesNotPlaySessionStreamThatsBeenLoadedButSubsequentlyRemoved(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  WpPlayerLibStream removedStreams[] = {};
  wp_playerlib_set_session(state, removedStreams, 0);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  TEST_ASSERT_EQUAL(WP_PHASE_SESSION, wp_playerlib_get_phase(state));

  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void immediatelyStopsPlayingAnAlreadyStartedSessionStreamWhenItsRemovedFromTimeline(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  TEST_ASSERT_EQUAL(WP_PHASE_SESSION, wp_playerlib_get_phase(state));

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));

  WpPlayerLibStream removedStreams[] = {};
  wp_playerlib_set_session(state, removedStreams, 0);

  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void whenAStreamIsRemovedOtherStreamsAreNotAffected(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 5000, .loopContent = false, .gain = 1.0f },
    { .id = "2", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, initialStreams, 2);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  TEST_ASSERT_EQUAL(WP_PHASE_SESSION, wp_playerlib_get_phase(state));

  for (int s = 0 ; s < 4 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }

  WpPlayerLibStream updatedStreams[] = {
    { .id = "2", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, updatedStreams, 1);

  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }
}


void testFadesInWhenStartingSession(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, 1));
}

void testFadesOutWhenStoppingDuringSession(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_test_responses(PL_COMPLETE, 0);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
    
  render_advance(state, output, 48000);
  render_advance(state, output, 48000);
  render_advance(state, output, 48000);
  
  wp_playerlib_stop(state);

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 48000));
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  TEST_ASSERT_FALSE(wp_playerlib_is_started(state));
}

void testPlaysContinuousChunkedStream(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  deliver_all_test_responses(PL_COMPLETE);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  for (int s = 0 ; s < 180 ; s++) {
    render_advance(state, output, 48050);
    // printf("s: %d first frame %f, %f last frame %f, %f\n", s, output[0], output[1], output[96100-2], output[96100-1]);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96100));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48050, 48000.f));
    if (s > 0) {
      TEST_ASSERT_TRUE(is_continuous(output, 48050, 48000.f));
    }
  }
}

void testPlaysContinuousChunkedStreamThatsNotFullyLoadedBeforeStarting(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  deliver_test_responses(PL_COMPLETE, 0); // playlist
  deliver_test_responses(PL_COMPLETE, 0); // first chunk
  deliver_test_responses(PL_COMPLETE, 0); // second chunk
  wp_playerlib_start(state);
  for (int s = 0 ; s < 180 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
    if (s > 0) {
      TEST_ASSERT_TRUE(is_continuous(output, 48000, 48000.f));
    }
    deliver_test_responses(PL_COMPLETE, 1000); // any subsequent chunks
  }
}

void testPlaysContinuousChunkedStreamThatsNotFullyGeneratedBeforeStarting(void) {
  WpPlayerLibStream streams[] = {  
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk
  wp_playerlib_start(state);
  render_advance(state, output, 10); // start delay
  for (int s = 0 ; s < 180 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
    if (s > 0) {
      TEST_ASSERT_TRUE(is_continuous(output, 48000, 48000.f));
    }
    deliver_test_responses(PL_COMPLETE, 1000); // any subsequent chunks
  }
}

void testFetchingRecoversFromIntermittentFailuresInNetworkResponses(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk
  wp_playerlib_start(state);
  for (int s = 0 ; s < 180 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
    if (s > 0) {
      TEST_ASSERT_TRUE(is_continuous(output, 48000, 48000.f));
    }
    if (s % 2 == 0) {
      fail_test_responses(1000);
    } else {
      deliver_test_responses(PL_COMPLETE, 1000);
    }
  }
}

void testPlaybackRecoversFromStallsDueToNetworkIntermittency(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk
  
  wp_playerlib_start(state);

  // First chunk playback
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    fail_test_responses(1000);
  }

  /// Should be stalled by second 11
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));

  // Deliver second chunk
  deliver_test_responses(PL_TWO_CHUNKS, -1); // playlist with second chunk
  deliver_test_responses(PL_TWO_CHUNKS, -1); // second chunk

  // Should be unstalled for another 9s now
  for (int s = 0 ; s < 9 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    fail_test_responses(1000);
  }

  // Should be stalled again
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));

  // Then should be stalled. Let's remain thus for a whole minute
  for (int s = 0 ; s < 60 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
    fail_test_responses(1000);
  }

  // Deliver the rest of the playlist
  deliver_all_test_responses(PL_COMPLETE);

  // Should be unstalled for the last minute
  for (int s = 0 ; s < 60 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }
}

void testPlaybackRecoversFromStallDiscoveredJustAfterGettingNetworkChunk(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_SHORT_CHUNKS_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_test_responses(PL_SHORT_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_SHORT_ONE_CHUNK, 0); // first chunk

  wp_playerlib_start(state);

  // We have half a second in the first chunk. See that we can render 0.4s
  render_advance(state, output, 48000 * 0.4);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000 * 0.4));

  // Then deliver the second chunk
  deliver_test_responses(PL_SHORT_TWO_CHUNKS, -1); // playlist with second chunk
  deliver_test_responses(PL_SHORT_TWO_CHUNKS, -1); // second chunk

  // Then we should go all the way to 0.6s without stalling or discontinuities. See that we can render 0.6s more
  render_advance(state, output, 48000 * 0.6);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000 * 0.1)); // The remainder of the first chunk
  TEST_ASSERT_FALSE(are_all_zeroes(output + 9600, 96000 * 0.5)); // The second chunk
  TEST_ASSERT_TRUE(is_continuous(output, 48000 * 0.6, 48000.f));
}

void testPlaybackRecoversFromStallMidChunk(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_SHORT_CHUNKS_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_test_responses(PL_SHORT_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_SHORT_ONE_CHUNK, 0); // first chunk

  wp_playerlib_start(state);

  // We have half a second in the first chunk. See that we can render that 0.5s
  render_advance(state, output, 48000 * 0.5);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000 * 0.5));

  // Then we are stalled. We should be getting silence. Let's go to 0.75s, half way into the chunk we don't have yet
  render_advance(state, output, 48000 * 0.25);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000 * 0.25));

  // Then deliver the second and third chunks
  deliver_test_responses(PL_SHORT_THREE_CHUNKS, -1); // playlist with second and third chunks
  deliver_test_responses(PL_SHORT_THREE_CHUNKS, -1); // second chunk
  deliver_test_responses(PL_SHORT_THREE_CHUNKS, -1); // third chunk

  // We'll still get zeroes for the pre-emptive late start period, 0.1s
  render_advance(state, output, 4800);
  printf("first frame %f, %f last frame %f, %f\n", output[0], output[1], output[9600-2], output[9600-1]);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 9600));

  // We should then go all the way from 0.85s to 1.5s without stalling,
  // nor discontinuities when moving from the second to the third chunk
  render_advance(state, output, 48000 * 0.65);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000 * 0.65));
  TEST_ASSERT_TRUE(is_continuous(output, 48000 * 0.65, 48000.f));
}

void testPlaybackSeeksIntoMidStreamStart(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 240000);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // We've seeked 240s into a 300s stream. We should first get 60s of non-zeroes + a bit of tail from the decoder cooloff
  for (int s = 0 ; s < 60 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(is_continuous(output, 48000, 48000.f));
  }
  render_advance(state, output, 100);


  // Then it should be silent as the stream has ended
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
}

void testPlaybackSeeksIntoMidStreamMidChunkStart(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 245000);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // We've seeked 245s into a 300s stream. We should get a continuous waveform with the seek into the chunk we joined during
  render_advance(state, output, 48000); // fade-in
  for (int s = 0 ; s < 30 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(is_continuous(output, 48000, 48000.f));
  }
}

void testPlaybackSeeksIntoMidStreamMidChunkStartDuringPlayback(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_start(state);

  render_advance(state, output, 4800);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 245487);
  
  deliver_all_test_responses(PL_COMPLETE);

  // We've seeked 245s into a 300s stream. We should get a continuous waveform with the seek into the chunk we joined during
  render_advance(state, output, 48000); // fade-in
  for (int s = 0 ; s < 30 ; s++) {
    render_advance(state, output, 48050);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96100));
    TEST_ASSERT_TRUE(is_continuous(output, 48050, 48000.f));
    for (int i = 0 ; i < 96000 ; i+=2) {
      if (output[i] == 0.0f) {
        printf("zero at %d %d\n", s, i);
      }
    }
  }
}


void testPlaybackSeeksIntoMidStreamWhenAlreadyInPhase(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));

  wp_playerlib_seek_to_time_in_phase(state, 240000);
  deliver_all_test_responses(PL_COMPLETE);

  // We've seeked 240s into a 300s stream. We should first get 60s of non-zeroes + a bit of tail from the decoder cooloff
  for (int s = 0 ; s < 60 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }
  render_advance(state, output, 100);

  // Then it should be silent as the stream has ended
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
}

void testPlaybackSeeksIntoMidAnotherStreamWhenAlreadyInPhase(void) {
  WpPlayerLibStream streams[] = {
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 60000, .loopContent = false, .gain = 1.0f },
    { .id = "2", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 60000, .toTime = 120000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, streams, 2);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));

  wp_playerlib_seek_to_time_in_phase(state, 80000);
  deliver_all_test_responses(PL_COMPLETE);

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));

  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
}

void testBasicTimelineTiming(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 5000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 2);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  //The first five seconds should be 220Hz
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // And the next five seconds should be 440Hz
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }
  render_advance(state, output, 100);

  // Then it should be silent as both timeline items have ended
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
}

void testBasicTimelineTimingWithStartMidStream(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 5000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 2);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 3000);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  //The first 2 seconds should be 220Hz
  for (int s = 0 ; s < 2 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // And the next five seconds should be 440Hz
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }
  render_advance(state, output, 100);

  // Then it should be silent as both timeline items have ended
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
}

void testBasicTimelineTimingWithStartAfterOneStreamHasEnded(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 5000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 2);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 7000);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // The first three seconds should be 440Hz
  for (int s = 0 ; s < 3 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }
  render_advance(state, output, 100);

  // Then it should be silent as both timeline items have ended
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
  }
}

void testUpdateTimelineTimingMidStream(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // Should be 220Hz to begin with
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // Then we update, ending the first stream and starting a second one
  WpPlayerLibStream updatedStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 15000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 15000, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, updatedStreams, 2);
  deliver_all_test_responses(PL_COMPLETE);

  // The first five seconds onward should still be 220Hz
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // And then it should switch to the 440Hz stream
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }
}

void testUpdateTimelineTimingMidStreamWithNonZeroInitialEffectiveFrame(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 3000);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // Should be 220Hz to begin with
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // Then we update, ending the first stream and starting a second one
  WpPlayerLibStream updatedStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 15000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 15000, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, updatedStreams, 2);
  deliver_all_test_responses(PL_COMPLETE);

  // The first 2 seconds onward should still be 220Hz
  for (int s = 0 ; s < 2 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // Then should switch to the 440Hz stream
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
  }
}

void testUpdateTimelineTimingLate(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // Should be 220Hz to begin with
  for (int s = 0 ; s < 20 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  // Then we update, ending the first stream and starting a second one
  // The timeline has the first stream ending earlier than we've already been playing it.
  WpPlayerLibStream updatedStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 15000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 15000, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, updatedStreams, 2);
  deliver_all_test_responses(PL_COMPLETE);

  // Should immediately to the 440Hz stream
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    // seek in a little so the frequency detection doesn't get confused by the late start of the chunk
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output + 9600, 48000 - 4800, 48000.f)); 
  }
}

void testSwitchesTimelinePhases(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "pre", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
    { .id = "post", .phase = WP_PHASE_POST, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 3);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);

  // Should be 220Hz to begin with
  for (int s = 0 ; s < 20 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f));
  }

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  render_advance(state, output, 4800);
  // Should now be 440Hz
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f)); 
  }

  wp_playerlib_set_phase(state, WP_PHASE_POST, 0);
  render_advance(state, output, 4800);
  // Should now be 220Hz again
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FLOAT_WITHIN(5.f, 220.f, detect_frequency(output, 48000, 48000.f)); 
  }
}

void testPreludeFadesOutWhenSwitchingToSession(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .fadeOutTime = 5000, .loopContent = true, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 20 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testPreludeFadesOutUsingLatestKnownFadeOutTimeWhenSwitchingToSession(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "p", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .fadeOutTime = 5000, .loopContent = true, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 20 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  initialStreams[0].fadeOutTime = 2000;
  wp_playerlib_set_session(state, initialStreams, 1);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  for (int s = 0 ; s < 2 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionFadesOutWhenSwitchingToPostlude(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .fadeOutTime = 5000, .loopContent = true, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 20 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  wp_playerlib_set_phase(state, WP_PHASE_POST, 0);
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionStreamFadesOutAccordingToItsTiming(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 10000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionStreamFadesOutAccordingToItsUpdatedTiming(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 20000, .fadeOutTime = 1000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }
  
  initialStreams[0].toTime = 10000;
  initialStreams[0].fadeOutTime = 5000;
  wp_playerlib_set_session(state, initialStreams, 1);

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionStreamFadesOutAccordingToItsUpdatedTimingWhenUpdatedAfterFadeAlreadyStarted(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 10000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // The 5 second fade-out begins
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  
  // Then we decide the fade should be shorter
  initialStreams[0].fadeOutTime = 2000;
  wp_playerlib_set_session(state, initialStreams, 1);

  // We should be stationary for 2 seconds
  for (int s = 0 ; s < 2 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_FALSE(hasVolumeDelta(output, 48000, -1));
  }

  // Then we should fade out the rest
  for (int s = 0 ; s < 2 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionStreamFadesOutAfterLateTruncation(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 20000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 7 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // We decide fade-out should begin at 5s, but we're already 7s in
  initialStreams[0].toTime = 10000;
  wp_playerlib_set_session(state, initialStreams, 1);

  // There's a 3 second fade-out remaining
  for (int s = 0 ; s < 3 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }

  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testSessionStreamComesBackFromFadeOutAfterSeek(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 20000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 15 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // There's a 5 second fade-out 
  for (int s = 0 ; s < 5 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }

  // Silent now
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));

  // Then seek back to the beginning
  wp_playerlib_seek_to_time_in_phase(state, 0);
  deliver_all_test_responses(PL_COMPLETE);

  // We should be audible again
  render_advance(state, output, 48000);
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}


void testSessionStreamJustEndsAfterVeryLateTruncation(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 20000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 11 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // We decide fade-out should begin at 5s, but we're already 11s in
  initialStreams[0].toTime = 10000;
  wp_playerlib_set_session(state, initialStreams, 1);

  // It's just silent right away
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testStreamTimedFadeOutDoesNotOverrideEarlierPhaseFadeOut(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 20000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // Let's move to postlude here
  wp_playerlib_set_phase(state, WP_PHASE_POST, 0);

  // We should start getting the phase fade-out
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));

  // Then let's decide the stream should fade out 
  initialStreams[0].toTime = 16000;
  wp_playerlib_set_session(state, initialStreams, 1);

  // We should continue getting the phase fade-out between seconds 11-15
  for (int s = 0 ; s < 4 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }

  // But then it should be silent - the stream fade-out started at 11s should not have elongated the fade-out
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testPhaseFadeOutDoesNotOverrideEarlierStreamFadeOut(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 15000, .fadeOutTime = 5000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);

  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

  // We should start getting the stream fade-out
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));

  // Let's move to postlude here
  wp_playerlib_set_phase(state, WP_PHASE_POST, 0);

  // We should continue getting the stream fade-out between seconds 11-15
  for (int s = 0 ; s < 4 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_TRUE(hasVolumeDelta(output, 48000, -1));
  }

  // But then it should be silent - the phase fade-out started at 11s should not have elongated the fade-out
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));
}

void testVolumeControl(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  // Master fade in
  render_advance(state, output, 48000);

  // Should be full amplitude at first
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE, rmsGain(output, 48000));

  wp_playerlib_set_volume(state, 0.5f);
  render_advance(state, output, 48000 * 0.1);  // fade
  // Should be quieter
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE * 0.02f, rmsGain(output, 48000));

  wp_playerlib_set_volume(state, 0.f);
  render_advance(state, output, 48000 * 0.1);  // fade
  // Should be silent
  render_advance(state, output, 48000);
  TEST_ASSERT_TRUE(are_all_zeroes(output, 96000));

  wp_playerlib_set_volume(state, 1.f);
  render_advance(state, output, 48000 * 0.1); // fade
  // Should be full again
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE, rmsGain(output, 48000));
}

void testStreamGain(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 0.5f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  render_advance(state, output, 48000);

  // Should be half amplitude
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE * 0.5, rmsGain(output, 48000));
}

void testUpdatingStreamGain(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  render_advance(state, output, 48000);

  // Should be full amplitude
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE, rmsGain(output, 48000));

  streams[0].gain = 0.5f;
  wp_playerlib_set_session(state, streams, 1);
  render_advance(state, output, 48000);

  // Should now be quieter
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE * 0.5, rmsGain(output, 48000));

  streams[0].gain = 1.0f;
  wp_playerlib_set_session(state, streams, 1);
  render_advance(state, output, 48000);

  // Should now be full again
  render_advance(state, output, 48000);
  TEST_ASSERT_FLOAT_WITHIN(0.01f, TEST_SINE_AMPLITUDE, rmsGain(output, 48000));
}

void testDuckingDoesNotBreakOutputs(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f },
    { .id = "a1", .phase = WP_PHASE_SESSION, .url = SILENCE_LOOP_FILE_PATH, .fromTime = 5000, .toTime = 10000, .loopContent = true, .gain = 1.0f, .usesSidechain = 1, .sidechainGain = 0.0f },
    { .id = "a2", .phase = WP_PHASE_SESSION, .url = SILENCE_LOOP_FILE_PATH, .fromTime = 10000, .toTime = 15000, .loopContent = true, .gain = 1.0f, .usesSidechain = 1, .sidechainGain = 0.5f },
    { .id = "a3", .phase = WP_PHASE_SESSION, .url = SILENCE_LOOP_FILE_PATH, .fromTime = 15000, .toTime = 20000, .loopContent = true, .gain = 1.0f, .usesSidechain = 1, .sidechainGain = 1.0f },
    { .id = "a4", .phase = WP_PHASE_SESSION, .url = SILENCE_LOOP_FILE_PATH, .fromTime = 20000, .toTime = 25000, .loopContent = true, .gain = 1.0f, .usesSidechain = 1, .sidechainGain = 0.5f },
    { .id = "a5", .phase = WP_PHASE_SESSION, .url = SILENCE_LOOP_FILE_PATH, .fromTime = 21000, .toTime = 24000, .loopContent = true, .gain = 1.0f, .usesSidechain = 1, .sidechainGain = 0.25f },
  };
  wp_playerlib_set_session(state, streams, 6);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_start(state);

  for (int s = 0 ; s < 25 ; s++) {
    render_advance(state, output, 48000);
    TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  }

}


void testBufferedTimeReporting(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));
  
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk

  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));
  
  deliver_test_responses(PL_TWO_CHUNKS, -1); // playlist
  deliver_test_responses(PL_TWO_CHUNKS, -1); // second chunk

  TEST_ASSERT_EQUAL(20.f, wp_playerlib_get_buffered_time(state));


  wp_playerlib_start(state);

  render_advance(state, output, 48000);

  TEST_ASSERT_EQUAL(19.f, wp_playerlib_get_buffered_time(state));

  for (int s = 0 ; s < 19 ; s++) {
    render_advance(state, output, 48000);
  }

  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));

  deliver_all_test_responses(PL_COMPLETE);

  TEST_ASSERT_EQUAL(280.f, wp_playerlib_get_buffered_time(state));
}

void testBufferedTimeReportingOnFutureStream(void) {
  wp_playerlib_register_network_request_callbacks(state, test_network_request_callback, test_cancel_network_request_callback, state);
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 10000, .toTime = 9999999, .loopContent = false, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  
  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));
  
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk

  TEST_ASSERT_EQUAL(20.f, wp_playerlib_get_buffered_time(state));
}

void testBufferedTimeReportingOnPastStream(void) {
  WpPlayerLibStream initialStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 10000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, initialStreams, 1);
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 0);
  wp_playerlib_start(state);
  
  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk
  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));

  // render 10s
  for (int s = 0 ; s < 10 ; s++) {
    render_advance(state, output, 48000);
  }
  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));
  
  WpPlayerLibStream updatedStreams[] = {
    { .id = "0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 10000, .loopContent = false, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 10000, .toTime = 20000, .loopContent = false, .gain = 1.0f  }
  };
  wp_playerlib_set_session(state, updatedStreams, 2);

  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk
  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));
}

void testBufferedTimeReportingDoesNotChangeDuringPrelude(void) {
  WpPlayerLibStream streams[] = {
    { .id = "0", .phase = WP_PHASE_PRE, .url = LOW_SINE_LOOP_FILE_PATH, .fromTime = 0, .toTime = 9999999, .loopContent = true, .gain = 1.0f },
    { .id = "1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 9999999, .gain = 1.0f }
  };
  wp_playerlib_set_session(state, streams, 2);
  wp_playerlib_set_phase(state, WP_PHASE_PRE, 0);
  
  TEST_ASSERT_EQUAL(0.f, wp_playerlib_get_buffered_time(state));
  
  deliver_test_responses(PL_ONE_CHUNK, 0); // playlist
  deliver_test_responses(PL_ONE_CHUNK, 0); // first chunk

  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));
  
  render_advance(state, output, 48000);

  TEST_ASSERT_EQUAL(10.f, wp_playerlib_get_buffered_time(state));
}

// -- Network pool overflow / zombie chunk tests --
// These tests reproduce the bug where too many concurrent streams overflow the
// 200-slot network request pool, leaving chunks permanently stuck in WP_SC_LOADING
// ("zombie chunks") that are never delivered and never re-requested.

void testNetworkPoolOverflowCausesSilenceOnAffectedStream(void) {
  // Create 7 session streams. Streams s0-s5 cover 0-300s (same 300s_440Hz content).
  // Stream s6 is the only stream covering 400-700s.
  // With 7 streams × 31 chunks = 217 pool slots needed, the 200-slot pool overflows.
  // Stream s6 (loaded last) has its later chunks (14-30) silently dropped.
  WpPlayerLibStream streams[] = {
    { .id = "s0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s2", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s3", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s4", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s5", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s6", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 400000, .toTime = 700000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, streams, 7);
  deliver_all_test_responses(PL_COMPLETE);

  // Set phase at 550s. At this point:
  // - Streams s0-s5 (0-300s) have all ended and produce no audio.
  // - Stream s6 (400-700s) is active. 550s = 150s into its content.
  // - Chunk 15 (150-160s local) should be playing, but it's a zombie.
  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 550000);
  wp_playerlib_start(state);

  render_advance(state, output, 48000); // 1s — includes fade-in
  render_advance(state, output, 48000); // 2nd second — should be steady-state 440Hz

  // BUG: This should be 440Hz audio from stream s6, but zombie chunks cause silence.
  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
}

void testPlaybackWorksWithManyStreams(void) {
  // Same structure as the overflow test but verifying audio plays correctly.
  // With the linked list network pool, all chunks load regardless of count.
  WpPlayerLibStream streams[] = {
    { .id = "s0", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s1", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s2", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s3", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s4", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s5", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 0, .toTime = 300000, .loopContent = false, .gain = 1.0f },
    { .id = "s6", .phase = WP_PHASE_SESSION, .url = HIGH_SINE_PLAYLIST_FILE_PATH, .fromTime = 400000, .toTime = 700000, .loopContent = false, .gain = 1.0f },
  };
  wp_playerlib_set_session(state, streams, 7);
  deliver_all_test_responses(PL_COMPLETE);

  wp_playerlib_set_phase(state, WP_PHASE_SESSION, 550000);
  wp_playerlib_start(state);

  render_advance(state, output, 48000); // 1s — fade-in
  render_advance(state, output, 48000); // 2s — late-start preempt may cause brief silence
  render_advance(state, output, 48000); // 3s — fully steady-state

  TEST_ASSERT_FALSE(are_all_zeroes(output, 96000));
  TEST_ASSERT_FLOAT_WITHIN(5.f, 440.f, detect_frequency(output, 48000, 48000.f));
}

int main(void)
{
    UNITY_BEGIN();
    RUN_TEST(testIsInitiallyInNonPlayingStateAndRendersSilence);
    RUN_TEST(testStartsPlayingSomethingInPrelude);
    RUN_TEST(testReportsTimeInPrelude);
    RUN_TEST(testFadesInWhenStartingPrelude);
    RUN_TEST(testFadesOutWhenStoppingDuringPrelude);
    RUN_TEST(testStartsPlayingSomethingInPreludeWhenStartedBeforeItsReady);
    RUN_TEST(testPreludeIsValidAudio);
    RUN_TEST(testPreludeIsLooping);
    RUN_TEST(testPreludeWithChunksIsLooping);
    RUN_TEST(testStartsPlayingSomethingInSession);
    RUN_TEST(testReportsTimeInSession);
    RUN_TEST(testOnlyStartsPlayingSessionStreamWhenItsTimedToStart);
    RUN_TEST(doesNotPlaySessionStreamThatsBeenLoadedButSubsequentlyRemoved);
    RUN_TEST(immediatelyStopsPlayingAnAlreadyStartedSessionStreamWhenItsRemovedFromTimeline);
    RUN_TEST(whenAStreamIsRemovedOtherStreamsAreNotAffected);
    RUN_TEST(testFadesInWhenStartingSession);
    RUN_TEST(testFadesOutWhenStoppingDuringSession);
    RUN_TEST(testPlaysContinuousChunkedStream);
    RUN_TEST(testPlaysContinuousChunkedStreamThatsNotFullyLoadedBeforeStarting);
    RUN_TEST(testPlaysContinuousChunkedStreamThatsNotFullyGeneratedBeforeStarting);
    RUN_TEST(testFetchingRecoversFromIntermittentFailuresInNetworkResponses);
    RUN_TEST(testPlaybackRecoversFromStallsDueToNetworkIntermittency);
    RUN_TEST(testPlaybackRecoversFromStallDiscoveredJustAfterGettingNetworkChunk);
    RUN_TEST(testPlaybackRecoversFromStallMidChunk);
    RUN_TEST(testPlaybackSeeksIntoMidStreamStart);
    RUN_TEST(testPlaybackSeeksIntoMidStreamMidChunkStart);
    RUN_TEST(testPlaybackSeeksIntoMidStreamMidChunkStartDuringPlayback);
    RUN_TEST(testPlaybackSeeksIntoMidStreamWhenAlreadyInPhase);
    RUN_TEST(testPlaybackSeeksIntoMidAnotherStreamWhenAlreadyInPhase);
    RUN_TEST(testBasicTimelineTiming);
    RUN_TEST(testBasicTimelineTimingWithStartMidStream);
    RUN_TEST(testBasicTimelineTimingWithStartAfterOneStreamHasEnded);
    RUN_TEST(testUpdateTimelineTimingMidStream);
    RUN_TEST(testUpdateTimelineTimingMidStreamWithNonZeroInitialEffectiveFrame);
    RUN_TEST(testUpdateTimelineTimingLate);
    RUN_TEST(testSwitchesTimelinePhases);
    RUN_TEST(testPreludeFadesOutWhenSwitchingToSession);
    RUN_TEST(testPreludeFadesOutUsingLatestKnownFadeOutTimeWhenSwitchingToSession);
    RUN_TEST(testSessionFadesOutWhenSwitchingToPostlude);
    RUN_TEST(testSessionStreamFadesOutAccordingToItsTiming);
    RUN_TEST(testSessionStreamFadesOutAccordingToItsUpdatedTiming);
    RUN_TEST(testSessionStreamFadesOutAccordingToItsUpdatedTimingWhenUpdatedAfterFadeAlreadyStarted);
    RUN_TEST(testSessionStreamFadesOutAfterLateTruncation);
    RUN_TEST(testSessionStreamComesBackFromFadeOutAfterSeek);
    RUN_TEST(testSessionStreamJustEndsAfterVeryLateTruncation);
    RUN_TEST(testStreamTimedFadeOutDoesNotOverrideEarlierPhaseFadeOut);
    RUN_TEST(testPhaseFadeOutDoesNotOverrideEarlierStreamFadeOut);
    RUN_TEST(testVolumeControl);
    RUN_TEST(testStreamGain);
    RUN_TEST(testUpdatingStreamGain);
    RUN_TEST(testDuckingDoesNotBreakOutputs);
    RUN_TEST(testBufferedTimeReporting);
    RUN_TEST(testBufferedTimeReportingOnFutureStream);
    RUN_TEST(testBufferedTimeReportingOnPastStream);
    RUN_TEST(testBufferedTimeReportingDoesNotChangeDuringPrelude);
    RUN_TEST(testNetworkPoolOverflowCausesSilenceOnAffectedStream);
    RUN_TEST(testPlaybackWorksWithManyStreams);
    return UNITY_END();
}
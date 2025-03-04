#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <unity.h>
#include <opusfile.h>

#include "test_config.h"

#include "wp_encoderlib.h"



void setUp(void) {
}

void tearDown(void) {
}


void generateSineWave(int16_t* buffer, size_t numSamples, int channels, int sampleRate, float frequency) {
  for (size_t i = 0; i < numSamples; i++) {
    float t = (float)i / sampleRate;
    int16_t sample = (int16_t)(32767.0f * sinf(2.0f * M_PI * frequency * t));
    for (int ch = 0; ch < channels; ch++) {
        buffer[i * channels + ch] = sample;
    }
  }
}

int64_t getFrameCount(const char *filename) {
  int error;
  OggOpusFile *opusFile = op_open_file(filename, &error);
  if (!opusFile) {
    fprintf(stderr, "Failed to open OggOpusFile %s: %d\n", filename, error);
    return -1;
  }
  int64_t totalFrames = op_pcm_total(opusFile, -1);
  op_free(opusFile);
  return totalFrames;
}


void testEncodeOggYieldsValidStream(void) {
    int sr = 48000;
    int channels = 2;
    size_t numSamples = sr * 30;
    size_t bufferSize = numSamples * channels * sizeof(int16_t);

    int16_t *buffer = malloc(bufferSize);
    generateSineWave(buffer, numSamples, channels, sr, 440);

    FILE *input = fmemopen(buffer, bufferSize, "rb");
    TEST_ASSERT_NOT_NULL(input);
    TEST_ASSERT_EQUAL(0, encode(input, channels, sr, 10000, 1000, "."));
    fclose(input);

    FILE *playlist = fopen("playlist.m3u8", "r");
    TEST_ASSERT_NOT_NULL(playlist);

    int numChunks = 0;
    double nextChunkDuration = -1;

    char *line = malloc(1024);
    while (fgets(line, 1024, playlist) != NULL) {
        if (strncmp(line, "#", 1) != 0) {
            numChunks++;
            const char *filename = strtok(line, "\n");
            int64_t frameCount = getFrameCount(filename);
            double chunkDuration = frameCount / 48000.0;
            TEST_ASSERT_EQUAL_DOUBLE(nextChunkDuration, chunkDuration);
            nextChunkDuration = -1;
        } else if (strncmp(line, "#EXTINF:", 8) == 0) {
            sscanf(line, "#EXTINF:%lf,", &nextChunkDuration);
        }
    }

    TEST_ASSERT_GREATER_THAN(0, numChunks);

    free(line);
    fclose(playlist);
}

void testEncodeOggWithLongChunksYieldsValidStream(void) {
    int sr = 48000;
    int channels = 2;
    size_t numSamples = sr * 300;
    size_t bufferSize = numSamples * channels * sizeof(int16_t);

    int16_t *buffer = malloc(bufferSize);
    generateSineWave(buffer, numSamples, channels, sr, 440);

    FILE *input = fmemopen(buffer, bufferSize, "rb");
    TEST_ASSERT_NOT_NULL(input);
    TEST_ASSERT_EQUAL(0, encode(input, channels, sr, 30000, 1000, "."));
    fclose(input);

    FILE *playlist = fopen("playlist.m3u8", "r");
    TEST_ASSERT_NOT_NULL(playlist);

    int numChunks = 0;
    double nextChunkDuration = -1;

    char *line = malloc(1024);
    while (fgets(line, 1024, playlist) != NULL) {
        if (strncmp(line, "#", 1) != 0) {
            numChunks++;
            const char *filename = strtok(line, "\n");
            int64_t frameCount = getFrameCount(filename);
            double chunkDuration = frameCount / 48000.0;
            TEST_ASSERT_EQUAL_DOUBLE(nextChunkDuration, chunkDuration);
            nextChunkDuration = -1;
        } else if (strncmp(line, "#EXTINF:", 8) == 0) {
            sscanf(line, "#EXTINF:%lf,", &nextChunkDuration);
        }
    }

    TEST_ASSERT_GREATER_THAN(0, numChunks);

    free(line);
    fclose(playlist);
}

void testEncodeOggWithManyShortChunksYieldsValidStream(void) {
    int sr = 48000;
    int channels = 2;
    size_t numSamples = sr * 2000;
    size_t bufferSize = numSamples * channels * sizeof(int16_t);

    int16_t *buffer = malloc(bufferSize);
    generateSineWave(buffer, numSamples, channels, sr, 440);

    FILE *input = fmemopen(buffer, bufferSize, "rb");
    TEST_ASSERT_NOT_NULL(input);
    TEST_ASSERT_EQUAL(0, encode(input, channels, sr, 1000, 100, "."));
    fclose(input);

    FILE *playlist = fopen("playlist.m3u8", "r");
    TEST_ASSERT_NOT_NULL(playlist);

    int numChunks = 0;
    double nextChunkDuration = -1;

    char *line = malloc(1024);
    while (fgets(line, 1024, playlist) != NULL) {
        if (strncmp(line, "#", 1) != 0) {
            numChunks++;
            const char *filename = strtok(line, "\n");
            int64_t frameCount = getFrameCount(filename);
            double chunkDuration = frameCount / 48000.0;
            TEST_ASSERT_EQUAL_DOUBLE(nextChunkDuration, chunkDuration);
            nextChunkDuration = -1;
        } else if (strncmp(line, "#EXTINF:", 8) == 0) {
            sscanf(line, "#EXTINF:%lf,", &nextChunkDuration);
        }
    }

    TEST_ASSERT_GREATER_THAN(0, numChunks);

    free(line);
    fclose(playlist);
}
typedef struct WatcherTreadData {
  int numChunks;
  bool allValid;
} WatcherThreadData;

void* watcherThread(void* arg) {
  WatcherThreadData *data = (WatcherThreadData*)arg;
  data->numChunks = 0;
  data->allValid = true;

  char *line = malloc(1024);
  bool ended = false;
  while (true) {
    FILE *playlist = fopen("playlist.m3u8", "r");
    if (playlist != NULL) {
      int numChunks = 0;
      double nextChunkDuration = -1;
      while (fgets(line, 1024, playlist) != NULL) {
        if (strncmp(line, "#", 1) != 0) {
          numChunks++;
          if (numChunks > data->numChunks) {
            char *filename = strtok(line, "\n");
            int64_t frameCount = getFrameCount(filename);
            double actualChunkDuration = frameCount / 48000.0;
            if (actualChunkDuration != nextChunkDuration) {
              printf("CHUNK DURATION MISMATCH %s: %f != %f\n", filename, actualChunkDuration, nextChunkDuration);
              data->allValid = false;
            }
            nextChunkDuration = -1;
          }
        } else if (strncmp(line, "#EXTINF:", 8) == 0) {
          sscanf(line, "#EXTINF:%lf,", &nextChunkDuration);
        } else if (strncmp(line, "#EXT-X-ENDLIST", 14) == 0) {
          ended = true;
        }
      }
      data->numChunks = numChunks;
    }
    fclose(playlist);
    if (ended) {
      break;
    } else {
      usleep(10 * 1000);
    }
  }
  free(line);
}

void testEncodeOggWithLongChunksYielsStreamWithImmediatelyValidChunks(void) {
    int sr = 48000;
    int channels = 2;
    size_t numSamples = sr * 300;
    size_t bufferSize = numSamples * channels * sizeof(int16_t);

    int16_t *buffer = malloc(bufferSize);
    generateSineWave(buffer, numSamples, channels, sr, 440);

    FILE *input = fmemopen(buffer, bufferSize, "rb");
    TEST_ASSERT_NOT_NULL(input);

    unlink("playlist.m3u8");

    WatcherThreadData data;
    pthread_t watcher;
    pthread_create(&watcher, NULL, watcherThread, &data);

    TEST_ASSERT_EQUAL(0, encode(input, channels, sr, 30000, 1000, "."));
    fclose(input);

    pthread_join(watcher, NULL);

    TEST_ASSERT_GREATER_THAN(0, data.numChunks);
    TEST_ASSERT_TRUE(data.allValid);
}

int main(void)
{
    UNITY_BEGIN();
    RUN_TEST(testEncodeOggYieldsValidStream);
    RUN_TEST(testEncodeOggWithLongChunksYieldsValidStream);
    RUN_TEST(testEncodeOggWithManyShortChunksYieldsValidStream);
    RUN_TEST(testEncodeOggWithLongChunksYielsStreamWithImmediatelyValidChunks);
    return UNITY_END();
}

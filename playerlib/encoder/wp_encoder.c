#include "wp_encoderlib.h"

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  if (argc != 6) {
    fprintf(stderr, "Usage: %s <num_channels> <samplerate> <stream_chunk_duration> <stream_chunk_fast_start_duration> <output_dir>\n", argv[0]);
    return 1;
  }

  int numChannels = atoi(argv[1]);
  if (numChannels <= 0) {
    fprintf(stderr, "Number of channels must be positive\n");
    return 1;
  }

  int sampleRate = atoi(argv[2]);
  if (sampleRate <= 0) {
    fprintf(stderr, "Sample rate must be positive\n");
    return 1;
  }

  int32_t streamChunkDuration = atoi(argv[3]);
  printf("Stream chunk duration: %d\n", streamChunkDuration);
  if (streamChunkDuration <= 0) {
    fprintf(stderr, "Stream chunk duration must be positive\n");
    return 1;
  }

  int32_t streamChunkFastStartDuration = atoi(argv[4]);
  printf("Stream chunk fast start duration: %d\n", streamChunkFastStartDuration);
  if (streamChunkFastStartDuration <= 0) {
    fprintf(stderr, "Stream chunk fast start duration must be positive\n");
    return 1;
  }

  return encode(stdin, numChannels, sampleRate, streamChunkDuration, streamChunkFastStartDuration, argv[5]);
}

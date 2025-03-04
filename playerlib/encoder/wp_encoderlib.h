#include <stdint.h>
#include <stdio.h>

int encode(FILE *input, int numChannels, int sampleRate, int32_t streamChunkDuration, int32_t streamChunkFastStartDuration, const char *outputDir);

#include <math.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>

bool are_all_zeroes(float *arr, int32_t length) {
  for (int32_t i = 0 ; i < length ; i++) {
    if (fabsf(arr[i]) > 0.0001f) {
      return false;
    }
  }
  return true;
}

int32_t count_zero_crossings(float *samples, int32_t numFrames) {
    int32_t crossings = 0;
    // Only look at left channel (even indices) since we have stereo interleaved samples
    for (int32_t i = 2; i < numFrames * 2; i += 2) {
        float curr = samples[i];
        float prev = samples[i-2];
        // Zero crossing occurs when samples change sign
        if ((curr >= 0 && prev < 0) ||
            (curr < 0 && prev >= 0)) {
            crossings++;
        }
    }
    return crossings;
}

float detect_frequency(float *samples, int32_t numFrames, float sampleRate) {
    int32_t zeroCrossings = count_zero_crossings(samples, numFrames);
    float numCycles = zeroCrossings * 0.5f;
    float duration = numFrames / sampleRate;
    float frequency = numCycles / duration;
    return frequency;
}

bool is_continuous(float *samples, int32_t numFrames, float sampleRate) {
  float frequency = detect_frequency(samples, numFrames, sampleRate);
  float amplitude = 0.0f;
  for (int32_t i = 0; i < numFrames * 2; i++) {
    amplitude = fmaxf(amplitude, fabsf(samples[i]));
  }
  float maxDeltaPerSample = 2.f * amplitude * sinf(2 * M_PI * frequency / sampleRate);
  for (int32_t i = 0; i < numFrames * 2 - 2; i += 2) {
    float delta = samples[i+2] - samples[i];
    if (fabsf(delta) > maxDeltaPerSample) {
      printf("Delta at %d %d: %f (%f->%f), maxDeltaPerSample: %f\n", i, i/2, delta, samples[i], samples[i+2], maxDeltaPerSample);
      return false;
    } else if (samples[i+2] == 0.f && samples[i] == 0.f) {
      printf("Zeros at %d\n", i);
      return false;
    }
  }
  return true;
}

float rmsGain(float *samples, int32_t numFrames) {
  float sumSquares = 0;
  for (int32_t i = 0; i < numFrames * 2; i += 2) {
    sumSquares += samples[i] * samples[i];
  }
  return sqrtf(sumSquares / (float)numFrames);
}

bool hasVolumeDelta(float *samples, int32_t numFrames, int sign) {
  float prevRMS = 0;
  static const int blockSize = 8192;
  for (int32_t block = 0; block < numFrames/blockSize; block++) {
    float rms = rmsGain(samples + block*blockSize*2, blockSize);
    if (block > 0) {
      float delta = rms - prevRMS;
      if ((sign > 0 && delta <= 0) || (sign < 0 && delta >= 0)) {
        printf("Delta at block %d: %f (%f->%f), sign: %d\n", block, delta, prevRMS, rms, sign);
        return false;
      }
    }
    prevRMS = rms;
  }
  return true;
}

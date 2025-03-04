#include "wp_encoderlib.h"

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <opusenc.h>

typedef struct EncFileCallbackCtx {
  bool inUse;
  FILE *playlistFile;

  int chunkNumber;
  FILE *file;
  const char *fileName;

  double writtenDuration;
} EncFileCallbackCtx;

int encWrite(void *user_data, const unsigned char *ptr, opus_int32 len) {
  EncFileCallbackCtx *ctx = (EncFileCallbackCtx*)user_data;
  return fwrite(ptr, 1, len, ctx->file) != (size_t)len ? -1 : 0;
}

int encClose(void *user_data) {
  EncFileCallbackCtx *ctx = (EncFileCallbackCtx*)user_data;
  int result = fclose(ctx->file);
  fprintf(ctx->playlistFile, "#EXTINF:%.8f,\n", ctx->writtenDuration);
  fprintf(ctx->playlistFile, "chunk_%04d.ogg\n", ctx->chunkNumber);
  fflush(ctx->playlistFile);
  printf("CHUNK %s\n", ctx->fileName);
  free((void*)ctx->fileName);
  ctx->inUse = false;
  return result;
}

int encode(FILE *input, int numChannels, int sampleRate, int32_t targetStreamChunkDuration, int32_t streamChunkFastStartDuration, const char *outputDir) {
  // We want to make stdout line-buffered so that we can see the progress of the encoding
  setvbuf(stdout, NULL, _IOLBF, 0);

  printf("Encoding %d channels to %s\n", numChannels, outputDir);
  
  char *playlistOutputFilename = NULL;
  char *chunkOutputFilename = NULL;
  OggOpusComments *comments = NULL;
  OggOpusEnc *encoder = NULL;
  EncFileCallbackCtx *contexts = NULL;
  int16_t *buffer = NULL;
  FILE *playlistFile = NULL;

  int resultCode = 0;

  comments = ope_comments_create();
  if (!comments) {
    fprintf(stderr, "Failed to create OggOpusComments\n");
    resultCode = -1;
    goto cleanup;
  }

  int32_t currentStreamChunkDuration = streamChunkFastStartDuration;
  int32_t currentFramesPerStreamChunk = currentStreamChunkDuration * sampleRate / 1000;

  int chunkCounter = 0;

  playlistOutputFilename = malloc(1024);
  chunkOutputFilename = malloc(1024);
  if (!playlistOutputFilename || !chunkOutputFilename) {
    fprintf(stderr, "Failed to allocate memory\n");
    resultCode = -1;
    goto cleanup;
  }

  snprintf(playlistOutputFilename, 1024, "%s/playlist.m3u8", outputDir);
  snprintf(chunkOutputFilename, 1024, "%s/chunk_%04d.ogg", outputDir, chunkCounter);
  
  playlistFile = fopen(playlistOutputFilename, "w");
  if (!playlistFile) {
    fprintf(stderr, "Failed to open playlist file for writing\n");
    resultCode = -1;
    goto cleanup;
  }

  OpusEncCallbacks encCallbacks;
  encCallbacks.write = encWrite;
  encCallbacks.close = encClose;

  static const int contextCount = 10;
  contexts = malloc(sizeof(EncFileCallbackCtx) * contextCount);
  for (int i = 0; i < contextCount; i++) {
    contexts[i].inUse = false;
    contexts[i].playlistFile = playlistFile;
  }
  int currentContextIndex = 0;


  FILE *chunkOutputFile = fopen(chunkOutputFilename, "w");
  contexts[currentContextIndex].chunkNumber = chunkCounter;
  contexts[currentContextIndex].file = chunkOutputFile;
  contexts[currentContextIndex].fileName = strdup(chunkOutputFilename);
  contexts[currentContextIndex].inUse = true;

  int encoderError = 0;
  encoder = ope_encoder_create_callbacks(&encCallbacks, &contexts[currentContextIndex], comments, sampleRate, numChannels, 0, &encoderError);
  if (encoderError != 0) {
    fprintf(stderr, "Failed to create OggOpusEnc: %d\n", encoderError);
    resultCode = -1;
    goto cleanup;
  }

  static size_t opusFrameSizeMs = 20;
  size_t framesPerOpusFrame = sampleRate * opusFrameSizeMs / 1000;
  buffer = malloc(sizeof(int16_t) * framesPerOpusFrame * numChannels);
  if (!buffer) {
    fprintf(stderr, "Failed to allocate buffer\n");
    resultCode = -1;
    goto cleanup;
  }

  encoderError = ope_encoder_ctl(encoder, OPUS_SET_BITRATE_REQUEST, 192000);
  if (encoderError != 0) {
    fprintf(stderr, "Failed to set bitrate: %d\n", encoderError);
    resultCode = -1;
    goto cleanup;
  }

  fprintf(playlistFile, "#EXTM3U\n");
  fprintf(playlistFile, "#EXT-X-VERSION:3\n");
  fprintf(playlistFile, "#EXT-X-TARGETDURATION:%f\n", (float)targetStreamChunkDuration / 1000);
  fprintf(playlistFile, "#EXT-X-MEDIA-SEQUENCE:0\n");
  fprintf(playlistFile, "#EXT-X-PLAYLIST-TYPE:EVENT\n");
  fflush(playlistFile);
  printf("PLAYLIST %s\n", playlistOutputFilename);

  int32_t framesInChunk = 0;
  while (true) {
    size_t samplesRead = fread(buffer, sizeof(int16_t), framesPerOpusFrame * numChannels, input);
    if (samplesRead == 0) {
      break;
    }
    int framesRead = samplesRead / numChannels;
    framesInChunk += framesRead;
    encoderError = ope_encoder_write(encoder, buffer, framesRead);
    if (encoderError != 0) {
      fprintf(stderr, "Failed to write to encoder: %d\n", encoderError);
      resultCode = -1;
      goto cleanup;
    }
    if (framesInChunk >= currentFramesPerStreamChunk) {
      contexts[currentContextIndex].writtenDuration = (double)framesInChunk / sampleRate;
      snprintf(chunkOutputFilename, 1024, "%s/chunk_%04d.ogg", outputDir, chunkCounter + 1);
      chunkCounter++;

      currentContextIndex = -1;
      for (int i = 0; i < contextCount; i++) {
        if (!contexts[i].inUse) {
          currentContextIndex = i;
          break;
        }
      }
      if (currentContextIndex == -1) {
        fprintf(stderr, "Out of free chunk encoder contexts\n");
        resultCode = -1;
        goto cleanup;
      }
      FILE *nextChunkOutputFile = fopen(chunkOutputFilename, "w");
      if (!nextChunkOutputFile) {
        fprintf(stderr, "Failed to open next chunk file for writing\n");
        resultCode = -1;
        goto cleanup;
      }
      contexts[currentContextIndex].chunkNumber = chunkCounter;
      contexts[currentContextIndex].file = nextChunkOutputFile;
      contexts[currentContextIndex].fileName = strdup(chunkOutputFilename);
      contexts[currentContextIndex].inUse = true;
      encoderError = ope_encoder_continue_new_callbacks(encoder, &contexts[currentContextIndex], comments);

      if (encoderError != 0) {
        fprintf(stderr, "Failed to continue new file: %d\n", encoderError);
        resultCode = -1;
        goto cleanup;
      }

      framesInChunk = 0;
      currentStreamChunkDuration *= 2;
      if (currentStreamChunkDuration > targetStreamChunkDuration) {
        currentStreamChunkDuration = targetStreamChunkDuration;
      }
      currentFramesPerStreamChunk = currentStreamChunkDuration * sampleRate / 1000;
    }
  }

  if (framesInChunk > 0) {
    contexts[currentContextIndex].writtenDuration = (double)framesInChunk / sampleRate;
  }

  ope_encoder_drain(encoder);
  fprintf(playlistFile, "#EXT-X-ENDLIST\n");

  cleanup:
  if (encoder) ope_encoder_destroy(encoder);
  if (comments) ope_comments_destroy(comments);
  if (playlistFile) fclose(playlistFile);
  if (buffer) free(buffer);
  if (playlistOutputFilename) free(playlistOutputFilename);
  if (chunkOutputFilename) free(chunkOutputFilename);
  if (contexts) free(contexts);

  return resultCode;
}

#define CHUNK_COUNT_MAX 3000
#define CHUNK_URL_MAX_LENGTH 1024

typedef struct WpPlayerLibM3u8Chunk {
  char *url;
  char *directFilePath;
  double fromTime;
  double toTime;
} WpPlayerLibM3u8Chunk;

typedef struct WpPlayerLibM3u8State {
  WpPlayerLibM3u8Chunk chunks[CHUNK_COUNT_MAX];
  size_t chunkCount;
  bool isEnded;
} WpPlayerLibM3u8State;

void wp_playerlib_m3u8_init(WpPlayerLibM3u8State *state) {
  state->chunkCount = 0;
  state->isEnded = false;
  for (int i = 0; i < CHUNK_COUNT_MAX; i++) {
    state->chunks[i].url = NULL;
    state->chunks[i].directFilePath = NULL;
  }
}

char *get_url_path(const char *url) {
  char *urlPath = strdup(url);
  char *lastSlash = strrchr(urlPath, '/');
  if (lastSlash) {
    *(lastSlash + 1) = '\0';
  }
  return urlPath;
}

void _wp_playerlib_m3u8_clear(WpPlayerLibM3u8State *state) {
  for (size_t i = 0; i < state->chunkCount; i++) {
    free(state->chunks[i].url);
    if (state->chunks[i].directFilePath != NULL) {
      unlink(state->chunks[i].directFilePath);
      free(state->chunks[i].directFilePath);
    }
  }
  state->chunkCount = 0;
}

int wp_playerlib_m3u8_parse(WpPlayerLibM3u8State *state, const char *url, const char *filePath, bool loop) {
  FILE *file = fopen(filePath, "r");
  if (file == NULL) {
    return -1;
  }
  _wp_playerlib_m3u8_clear(state);
  state->isEnded = false;
  char *urlPath = get_url_path(url);
  char *line = malloc(1024);
  
  double cumulativeTime = 0;
  double chunkDuration = 0;
  
  while (fgets(line, 1024, file) != NULL) {
    if (strncmp(line, "#EXTINF:", 8) == 0) {
      sscanf(line, "#EXTINF:%lf,", &chunkDuration);
    } else if (strncmp(line, "#", 1) != 0) {
      char *filename = strtok(line, "\n");
      unsigned long chunkUrlLength = strlen(urlPath) + strlen(filename) + 1;
      if (chunkUrlLength > CHUNK_URL_MAX_LENGTH) {
        fprintf(stderr, "Chunk URL length is too long\n");
        free(line);
        free(urlPath);
        fclose(file);
        return -1;
      }
      state->chunks[state->chunkCount].url = malloc(chunkUrlLength);
      snprintf(state->chunks[state->chunkCount].url, chunkUrlLength, "%s%s", urlPath, filename);
      state->chunks[state->chunkCount].fromTime = cumulativeTime;
      state->chunks[state->chunkCount].directFilePath = NULL;
      cumulativeTime += chunkDuration;
      state->chunks[state->chunkCount].toTime = cumulativeTime;
      state->chunkCount++;
    } else if (strncmp(line, "#EXT-X-ENDLIST", 14) == 0) {
      state->isEnded = true;
    }
  }

  if (state->isEnded && loop) {
    size_t initialChunkCount = state->chunkCount;
    for (size_t i = initialChunkCount; i < CHUNK_COUNT_MAX; i++) {
      WpPlayerLibM3u8Chunk *chunkToRepeat = &state->chunks[i - initialChunkCount];
      double chunkDuration = chunkToRepeat->toTime - chunkToRepeat->fromTime;
      WpPlayerLibM3u8Chunk *previousChunk = &state->chunks[i - 1];
      state->chunks[i].url = strdup(chunkToRepeat->url);
      state->chunks[i].directFilePath = NULL;
      state->chunks[i].fromTime = previousChunk->toTime;
      state->chunks[i].toTime = previousChunk->toTime + chunkDuration;
    }
    state->chunkCount = CHUNK_COUNT_MAX;
  }

  free(line);
  free(urlPath);
  fclose(file);
  unlink(filePath);
  return 0;
}

void wp_playerlib_m3u8_populate_single_chunk(WpPlayerLibM3u8State *state, const char *url, const char *filePath, double duration, bool loop) {
  state->chunks[0].url = strdup(url);
  state->chunks[0].directFilePath = strdup(filePath);
  state->chunks[0].fromTime = 0;
  state->chunks[0].toTime = duration;
  state->isEnded = true;
  if (loop) {
    // Repeat the single chunk for a very long time
    for (size_t i = 1; i < CHUNK_COUNT_MAX; i++) {
      state->chunks[i].url = strdup(url);
      state->chunks[i].directFilePath = strdup(filePath);
      state->chunks[i].fromTime = state->chunks[i - 1].toTime;
      state->chunks[i].toTime = state->chunks[i - 1].toTime + duration;
    }
    state->chunkCount = CHUNK_COUNT_MAX;
  } else {
    state->chunkCount = 1;
  }
}

void wp_playerlib_m3u8_destroy(WpPlayerLibM3u8State *state) {
  _wp_playerlib_m3u8_clear(state);
}

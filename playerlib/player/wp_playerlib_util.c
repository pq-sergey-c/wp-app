static int64_t time_after(uint64_t ms) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec * 1000 + tv.tv_usec / 1000 + ms;
}

static int64_t time_now(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

int64_t min64(int64_t a, int64_t b) {
  return a < b ? a : b;
}

uint64_t minu64(uint64_t a, uint64_t b) {
  return a < b ? a : b;
}

int64_t max64(int64_t a, int64_t b) {
  return a > b ? a : b;
}

uint64_t maxu64(uint64_t a, uint64_t b) {
  return a > b ? a : b;
}

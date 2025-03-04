#include <stdatomic.h>

static _Atomic(uint32_t) __wp_playerlib_id = 1;

uint32_t wp_playerlib_id_next(void) {
  return atomic_fetch_add(&__wp_playerlib_id, 1);
}

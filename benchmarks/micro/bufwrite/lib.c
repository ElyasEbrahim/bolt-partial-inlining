#include <stdint.h>
#include <string.h>
#include "buf.h"

/* Out-of-line flush: folds the buffer into a running hash (stands in for
 * write(2)). */
__attribute__((noinline)) uint64_t hash_bytes(uint64_t h, const unsigned char *p,
                                              size_t n) {
  for (size_t i = 0; i < n; i++)
    h = (h ^ p[i]) * 0x100000001B3ULL;
  return h;
}

/* Hot entry point. Fast path: room in the buffer -> append and return.
 * Slow path: flush (calls), bookkeeping, then append. The slow path needs
 * callee-saved registers, so the compiler shrink-wraps the prologue and the
 * fast path is frameless. */
int buf_putc(struct buf *b, int c) {
  if (b->pos < b->cap) {
    b->data[b->pos++] = (unsigned char)c;
    return c;
  }
  b->hash = hash_bytes(b->hash, b->data, b->pos);
  b->flushes++;
  b->bytes += b->pos;
  memset(b->data, 0, b->pos);
  b->pos = 0;
  b->data[b->pos++] = (unsigned char)c;
  return c;
}

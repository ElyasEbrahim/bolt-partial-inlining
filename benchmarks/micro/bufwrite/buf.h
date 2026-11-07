#include <stddef.h>
#include <stdint.h>
struct buf {
  unsigned char *data;
  size_t pos, cap;
  uint64_t hash, flushes, bytes;
};
int buf_putc(struct buf *b, int c);
uint64_t hash_bytes(uint64_t h, const unsigned char *p, size_t n);

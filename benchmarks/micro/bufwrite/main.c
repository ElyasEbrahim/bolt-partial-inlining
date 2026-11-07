/* bufwrite: emit N pseudo-random "text" bytes through buf_putc().
 * usage: bufwrite [N=200000000] [bufsize=4096] */
#include "../common.h"
#include "buf.h"

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 200000000L);
  long cap = arg_or(argc, argv, 2, 4096);
  struct buf b = {malloc(cap), 0, (size_t)cap, 1469598103934665603ULL, 0, 0};
  uint64_t s = 88172645463325252ULL, acc = 0;
  for (long i = 0; i < n; i++) {
    int c = 'a' + (int)((i * 7 + (i >> 5)) % 26);
    if ((i & 1023) == 0)
      c = (int)(rng_next(&s) & 0x7f);
    acc += buf_putc(&b, c);
  }
  b.hash = hash_bytes(b.hash, b.data, b.pos);
  printf("bufwrite n=%ld flushes=%llu hash=%016llx acc=%llu\n", n,
         (unsigned long long)b.flushes, (unsigned long long)b.hash,
         (unsigned long long)acc);
  return 0;
}

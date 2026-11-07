/* pool: allocate/free objects with a sliding window of live objects.
 * usage: pool [N=100000000] [window=256] */
#include "../common.h"
#include "pool.h"

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 100000000L);
  long w = arg_or(argc, argv, 2, 256);
  struct pool p = {0, 64, 512, 0, 0};
  void **win = calloc(w, sizeof(void *));
  uint64_t s = 12345, acc = 0;
  for (long i = 0; i < n; i++) {
    long slot = (long)(rng_next(&s) % (uint64_t)w);
    if (win[slot])
      pool_free(&p, win[slot]);
    long *o = pool_alloc(&p);
    o[1] = i;
    acc += (uint64_t)o[1] ^ (uint64_t)slot;
    win[slot] = o;
  }
  printf("pool n=%ld live=%zu slabs=%zu acc=%016llx\n", n, p.live, p.slabs,
         (unsigned long long)acc);
  return 0;
}

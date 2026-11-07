/* mixed: classify() is called from two loops. Loop A only ever sees kind-0
 * items (fast path), loop B only kind!=0 items (slow path). The aggregate
 * (context-insensitive) profile says "75% fast", which is wrong for site B.
 * usage: mixed [N=50000000] [ratioA=3] */
#include "../common.h"
#include "item.h"
extern long classify_slow;

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 50000000L);
  long ra = arg_or(argc, argv, 2, 3);
  enum { K = 256 };
  static struct item fast[K], slow[K];
  for (int i = 0; i < K; i++) {
    fast[i] = (struct item){0, i * 3, i, i + 1};
    slow[i] = (struct item){1 + i % 5, 0, i, 2 * i};
  }
  uint64_t acc = 0;
  for (long r = 0; r < n; r++) {
    for (long j = 0; j < ra; j++) /* site A: always fast */
      acc += (uint64_t)classify(&fast[(r + j) & (K - 1)]);
    acc ^= (uint64_t)classify(&slow[r & (K - 1)]); /* site B: always slow */
  }
  printf("mixed n=%ld slow=%ld acc=%016llx\n", n, classify_slow,
         (unsigned long long)acc);
  return 0;
}

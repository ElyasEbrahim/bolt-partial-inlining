/* chain: hot calls to a function that overwrites its argument register
 * before its fast/slow decision.
 * usage: chain [N=100000000] */
#include "../common.h"
#include "obj.h"
extern long chain_walks;

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 100000000L);
  enum { K = 64 };
  static struct obj objs[K];
  for (int i = 0; i < K; i++) {
    objs[i].rc = 1 + (i % 7) * 100;
    objs[i].next = &objs[(i + 1) % K];
    /* one of 64 objects sends its predecessor to the slow path */
    objs[i].payload[1] = i == 40 ? -1 : i;
    objs[i].payload[2] = 3 * i;
  }
  uint64_t acc = 0;
  for (long i = 0; i < n; i++)
    acc += (uint64_t)chain_value(&objs[i & (K - 1)]);
  printf("chain n=%ld walks=%ld acc=%llu\n", n, chain_walks,
         (unsigned long long)acc);
  return 0;
}

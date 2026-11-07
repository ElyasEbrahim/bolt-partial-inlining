/* unsafe: hot calls to functions whose fast paths are unsafe to duplicate.
 * usage: unsafe [N=100000000] */
#include "../common.h"
#include "obj.h"
extern long objs_destroyed;

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 100000000L);
  enum { K = 64 };
  static struct obj objs[K];
  for (int i = 0; i < K; i++) {
    objs[i].rc = 1 + (i % 7) * 100;
    objs[i].next = &objs[(i + 1) % K];
    objs[i].payload[1] = i;
  }
  uint64_t acc = 0;
  for (long i = 0; i < n; i++) {
    struct obj *o = &objs[i & (K - 1)];
    acc += obj_release(o);
    acc += (uint64_t)chain_value(o);
  }
  printf("unsafe n=%ld destroyed=%ld acc=%llu\n", n, objs_destroyed,
         (unsigned long long)acc);
  return 0;
}

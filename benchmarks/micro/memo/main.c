/* memo: look up keys with a configurable hit rate.
 * usage: memo [N=100000000] [miss_permille=20] */
#include "../common.h"
uint64_t memo_get(uint64_t key);
extern uint64_t memo_misses;

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 100000000L);
  long miss = arg_or(argc, argv, 2, 20);
  uint64_t s = 0x9E3779B97F4A7C15ULL, acc = 0;
  for (long i = 0; i < n; i++) {
    uint64_t r = rng_next(&s);
    /* hot working set of 1024 keys; occasionally a fresh key */
    uint64_t key = (long)(r % 1000) < miss ? (r >> 20) : (r >> 40) % 1024;
    acc += memo_get(key);
  }
  printf("memo n=%ld misses=%llu acc=%016llx\n", n,
         (unsigned long long)memo_misses, (unsigned long long)acc);
  return 0;
}

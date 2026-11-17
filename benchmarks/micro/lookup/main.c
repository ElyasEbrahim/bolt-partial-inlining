/* lookup: hash table lookups in chains of two nodes.
 * usage: lookup [N=100000000] [deep_permille=50]
 * deep_permille of 1000 lookups do not find their key in the first node of
 * the chain: 7 of 8 of them find it in the second node, 1 of 8 not at all.
 *
 * The keys are derived from the loop counter, not from the generator in
 * common.h: its state would be a dependency chain from one iteration to the
 * next that bounds the time of an iteration (see the analysis of 'pool' in
 * the design document), and the cost of the lookup would hide behind it. */
#include "../common.h"
#include "tab.h"

enum { BUCKETS = 1024 };

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 100000000L);
  long deep = arg_or(argc, argv, 2, 50);
  static struct ent first[BUCKETS], second[BUCKETS];
  static struct ent *buckets[BUCKETS];
  struct tab t = {buckets, BUCKETS - 1};
  for (uint64_t i = 0; i < BUCKETS; i++) {
    /* the keys i and i + BUCKETS share bucket i */
    second[i] = (struct ent){i + BUCKETS, (long)(7 * i + 3), 0};
    first[i] = (struct ent){i, (long)(3 * i + 1), &second[i]};
    buckets[i] = &first[i];
  }
  uint64_t acc = 0;
  long walks = 0;
  for (long i = 0; i < n; i++) {
    uint64_t h = (uint64_t)i * 0x9E3779B97F4A7C15ULL;
    uint64_t key = (h >> 40) % BUCKETS;
    if ((long)((h >> 20) % 1000) < deep) {
      key += ((h >> 8) & 7) ? BUCKETS : 2 * BUCKETS;
      walks++;
    }
    acc += (uint64_t)tab_get(&t, key);
  }
  printf("lookup n=%ld walks=%ld acc=%016llx\n", n, walks,
         (unsigned long long)acc);
  return 0;
}

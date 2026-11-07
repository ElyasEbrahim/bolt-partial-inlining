#include <stdint.h>

#define CACHE_BITS 12
struct entry { uint64_t key, val; };
static struct entry cache[1u << CACHE_BITS];
uint64_t memo_misses;

/* Expensive pure function (a few hundred cycles). */
__attribute__((noinline)) uint64_t expensive(uint64_t k) {
  uint64_t h = k;
  for (int i = 0; i < 64; i++)
    h = (h ^ (h >> 31)) * 0x7fb5d329728ea185ULL + (uint64_t)i;
  return h;
}

/* Hot entry point: hit -> return cached value (frameless fast path).
 * Miss -> compute, fill, count. */
uint64_t memo_get(uint64_t key) {
  struct entry *e = &cache[(key ^ (key >> CACHE_BITS)) & ((1u << CACHE_BITS) - 1)];
  if (e->key == key + 1)
    return e->val;
  uint64_t v = expensive(key);
  e->key = key + 1;
  e->val = v;
  memo_misses++;
  return v;
}

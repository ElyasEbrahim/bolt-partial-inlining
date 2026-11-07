#include "item.h"
long classify_slow;

/* Fast path: kind 0 items have a precomputed weight. Slow path: a small
 * computation that needs a frame (it calls a helper). */
__attribute__((noinline)) long weigh(const struct item *it, long salt) {
  long w = it->a * 31 + it->b * 17 + salt;
  return w ^ (w >> 7);
}
long classify(const struct item *it) {
  if (it->kind == 0)
    return it->w;
  long w = weigh(it, it->kind) + weigh(it, 3);
  classify_slow++;
  return w;
}

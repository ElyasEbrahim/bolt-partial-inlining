#include "tab.h"

/* Hash table with chaining. The loop usually returns in its first iteration:
 * most keys are the first node of their chain. */
long tab_get(const struct tab *t, uint64_t key) {
  for (const struct ent *e = t->buckets[key & t->mask]; e; e = e->next)
    if (e->key == key)
      return e->val;
  return -1;
}

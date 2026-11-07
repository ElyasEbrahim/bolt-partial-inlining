#include <stdlib.h>
#include "obj.h"

long objs_destroyed;

__attribute__((noinline)) static void destroy(struct obj *o) {
  objs_destroyed++;
  o->rc = 1000;            /* resurrect so the benchmark can keep going */
  o->payload[0] ^= 0x5a;
}

/* Side effect (the decrement is a store) happens BEFORE the fast/slow
 * decision: re-executing the region on the slow path would decrement twice,
 * so the pass must reject this function. */
int obj_release(struct obj *o) {
  if (--o->rc != 0)
    return 0;
  destroy(o);
  return 1;
}

/* The argument register is overwritten before the decision (p = p->next):
 * re-execution would start from the wrong pointer, so the pass must reject
 * it as well. */
long chain_value(struct obj *p) {
  p = p->next;
  if (p->payload[1] >= 0)
    return p->payload[1];
  long s = 0;
  for (struct obj *q = p; q; q = q->next)
    s += q->payload[2] + (long)q->rc;
  objs_destroyed += s & 1;
  return s;
}

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

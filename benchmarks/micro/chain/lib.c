#include "obj.h"

long chain_walks;

/* The argument register is overwritten before the fast/slow decision
 * (p = p->next), and the slow path starts from the new p. A copy of the fast
 * path that falls back to calling this function again must pass the original
 * argument: the pass saves it in a scratch register and restores it in front
 * of the call. Without the restore the result differs. */
long chain_value(struct obj *p) {
  p = p->next;
  if (p->payload[1] >= 0)
    return p->payload[1];
  long s = 0;
  for (struct obj *q = p; q && q->payload[1] < 0; q = q->next)
    s += q->payload[2] + q->rc;
  chain_walks++;
  return s;
}

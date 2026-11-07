#include <stdlib.h>
#include "pool.h"

/* Slow path: carve a new slab into the free list. */
static void pool_refill(struct pool *p) {
  size_t n = p->slab_objs;
  char *slab = malloc(n * p->obj_size);
  for (size_t i = 0; i < n; i++) {
    struct node *nd = (struct node *)(slab + i * p->obj_size);
    nd->next = p->free;
    p->free = nd;
  }
  p->slabs++;
}

void *pool_alloc(struct pool *p) {
  struct node *n = p->free;
  if (n) {
    p->free = n->next;
    p->live++;
    return n;
  }
  pool_refill(p);
  n = p->free;
  p->free = n->next;
  p->live++;
  return n;
}

void pool_free(struct pool *p, void *ptr) {
  struct node *n = ptr;
  n->next = p->free;
  p->free = n;
  p->live--;
}

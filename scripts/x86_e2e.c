// End-to-end test program for --partial-inline (identical to the program in
// bolt/test/runtime/AArch64/partial-inline.c, without the lit RUN lines).
// Used by x86_validate.sh to validate the pass on x86-64 binaries.

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NOINLINE __attribute__((noinline))

// Frameless fast path.
int trace_level;
unsigned long trace_bytes;
NOINLINE void trace_event(int level, long a) {
  if (level > trace_level)
    return;
  char line[64];
  int n = snprintf(line, sizeof line, "%d:%ld\n", level, a);
  trace_bytes += n;
}

// Callee-saved temporaries on the fast path (typically not shrink-wrapped).
struct entry {
  uint64_t key, val;
};
static struct entry cache[256];
uint64_t misses;
NOINLINE uint64_t expensive(uint64_t k) {
  for (int i = 0; i < 16; i++)
    k = (k ^ (k >> 29)) * 0xbf58476d1ce4e5b9ULL;
  return k;
}
NOINLINE uint64_t memo_get(uint64_t key) {
  struct entry *e = &cache[key & 255];
  if (e->key == key + 1)
    return e->val;
  uint64_t v = expensive(key);
  e->key = key + 1;
  e->val = v;
  misses++;
  return v;
}

// Stores on the fast path after the decision.
struct buf {
  unsigned char *data;
  size_t pos, cap;
  uint64_t hash;
};
NOINLINE void flush(struct buf *b) {
  for (size_t i = 0; i < b->pos; i++)
    b->hash = (b->hash ^ b->data[i]) * 0x100000001b3ULL;
  b->pos = 0;
}
NOINLINE int buf_putc(struct buf *b, int c) {
  if (b->pos < b->cap) {
    b->data[b->pos++] = (unsigned char)c;
    return c;
  }
  flush(b);
  b->data[b->pos++] = (unsigned char)c;
  return c;
}

struct node {
  struct node *next;
};
struct pool {
  struct node *free;
  size_t live, slabs;
};
NOINLINE void *pool_alloc(struct pool *p) {
  struct node *n = p->free;
  if (n) {
    p->free = n->next;
    p->live++;
    return n;
  }
  char *slab = malloc(64 * 32);
  for (int i = 0; i < 32; i++) {
    struct node *nd = (struct node *)(slab + i * 64);
    nd->next = p->free;
    p->free = nd;
  }
  p->slabs++;
  n = p->free;
  p->free = n->next;
  p->live++;
  return n;
}
NOINLINE void pool_free(struct pool *p, void *ptr) {
  struct node *n = ptr;
  n->next = p->free;
  p->free = n;
  p->live--;
}

// Store before the decision: must be rejected.
struct obj {
  long rc;
  long destroyed;
};
NOINLINE void destroy(struct obj *o) {
  o->destroyed++;
  o->rc = 100;
}
NOINLINE int obj_release(struct obj *o) {
  if (--o->rc != 0)
    return 0;
  destroy(o);
  return 1;
}

// A loop on the fast path: the first node of a chain usually has the key.
// Longer walks and misses leave the copy through the back edge of the loop.
struct hnode {
  uint64_t key, val;
  struct hnode *next;
};
static struct hnode hnodes[128];
static struct hnode *buckets[64];
NOINLINE uint64_t chain_get(struct hnode **bucket, uint64_t key) {
  for (struct hnode *n = *bucket; n; n = n->next)
    if (n->key == key)
      return n->val;
  return 0;
}

// The argument register is overwritten before the decision. The slow path
// starts again from the argument, so it computes a different result if the
// fallback call does not receive the original value.
struct lnode {
  struct lnode *next;
  long val;
};
static struct lnode ring[64];
long slow_walks;
NOINLINE long next_value(struct lnode *p) {
  p = p->next;
  if (p->val >= 0)
    return p->val;
  long sum = 0;
  for (int i = 0; i < 8; i++, p = p->next)
    sum = sum * 31 + p->val;
  slow_walks++;
  return sum;
}

static uint64_t rng(uint64_t *s) {
  *s ^= *s << 13;
  *s ^= *s >> 7;
  *s ^= *s << 17;
  return *s;
}

int main(int argc, char **argv) {
  long n = argc > 1 ? atol(argv[1]) : 100000;
  uint64_t s = 42, acc = 0;
  struct buf b = {malloc(4096), 0, 4096, 1469598103934665603ULL};
  struct pool p = {0, 0, 0};
  void *window[64] = {0};
  struct obj o = {100, 0};
  // Two nodes per bucket; the second one is rarely looked up.
  for (int i = 0; i < 64; i++) {
    hnodes[2 * i] = (struct hnode){i, 3 * i + 1, &hnodes[2 * i + 1]};
    hnodes[2 * i + 1] = (struct hnode){i + 64, 5 * i + 2, 0};
    buckets[i] = &hnodes[2 * i];
  }
  // A ring in which every 16th value is negative.
  for (int i = 0; i < 64; i++)
    ring[i] = (struct lnode){&ring[(i + 1) & 63], (i & 15) == 7 ? -i : i};
  for (long i = 0; i < n; i++) {
    uint64_t r = rng(&s);
    trace_event(2, (long)r);
    if ((i & 1023) == 0)
      trace_event(0, i); // rarely taken slow path
    acc += memo_get((r & 15) ? (r >> 32) & 63 : r >> 20);
    acc += buf_putc(&b, 'a' + (int)(r % 26));
    unsigned slot = (unsigned)(r >> 40) & 63;
    if (window[slot])
      pool_free(&p, window[slot]);
    window[slot] = pool_alloc(&p);
    acc += obj_release(&o);
    // 1 of 16 lookups needs the second node, 1 of 64 finds nothing.
    unsigned b = (unsigned)(r >> 8) & 63;
    uint64_t key = b;
    if (((r >> 16) & 15) == 0)
      key += ((r >> 20) & 3) ? 64 : 128;
    acc += chain_get(&buckets[b], key);
    acc += (uint64_t)next_value(&ring[(r >> 24) & 63]);
  }
  flush(&b);
  printf("acc=%016llx misses=%llu hash=%016llx live=%zu slabs=%zu "
         "trace=%lu destroyed=%ld walks=%ld\n",
         (unsigned long long)acc, (unsigned long long)misses,
         (unsigned long long)b.hash, p.live, p.slabs, trace_bytes,
         o.destroyed, slow_walks);
  return 0;
}

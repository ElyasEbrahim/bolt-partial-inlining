#include <stdint.h>
struct ent { uint64_t key; long val; struct ent *next; };
struct tab { struct ent **buckets; uint64_t mask; };
long tab_get(const struct tab *t, uint64_t key);

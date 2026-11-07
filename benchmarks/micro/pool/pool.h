#include <stddef.h>
struct node { struct node *next; };
struct pool { struct node *free; size_t obj_size, slab_objs, live, slabs; };
void *pool_alloc(struct pool *p);
void pool_free(struct pool *p, void *ptr);

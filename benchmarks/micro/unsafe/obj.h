struct obj { long rc; struct obj *next; long payload[6]; };
int obj_release(struct obj *o);
long chain_value(struct obj *p);

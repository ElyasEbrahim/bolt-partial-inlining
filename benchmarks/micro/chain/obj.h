struct obj { long rc; struct obj *next; long payload[6]; };
long chain_value(struct obj *p);

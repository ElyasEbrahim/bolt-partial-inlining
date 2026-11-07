#include <stdio.h>
#include <string.h>

int trace_level = 0;          /* tracing disabled at run time */
unsigned long trace_bytes;
static char trace_ring[1 << 16];
static unsigned trace_head;

/* Typical logging hook: cheap level check, expensive formatting path with a
 * large stack frame. */
void trace_event(int level, const char *what, long a, long b) {
  if (level > trace_level)
    return;
  char line[256];
  int n = snprintf(line, sizeof line, "[%d] %s a=%ld b=%ld\n", level, what, a, b);
  for (int i = 0; i < n; i++)
    trace_ring[(trace_head + i) & (sizeof trace_ring - 1)] = line[i];
  trace_head += n;
  trace_bytes += n;
}

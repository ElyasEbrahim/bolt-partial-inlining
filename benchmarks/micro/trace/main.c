/* trace: a small compute kernel instrumented with two trace points.
 * usage: trace [N=200000000] [level=0] */
#include "../common.h"
void trace_event(int level, const char *what, long a, long b);
extern int trace_level;
extern unsigned long trace_bytes;

int main(int argc, char **argv) {
  long n = arg_or(argc, argv, 1, 200000000L);
  trace_level = (int)arg_or(argc, argv, 2, 0);
  uint64_t x = 1, y = 2;
  for (long i = 0; i < n; i++) {
    x = x * 6364136223846793005ULL + 1442695040888963407ULL;
    trace_event(2, "step", (long)i, (long)(x >> 33));
    y += x >> 17;
    trace_event(3, "acc", (long)y, 0);
  }
  printf("trace n=%ld x=%016llx y=%016llx bytes=%lu\n", n,
         (unsigned long long)x, (unsigned long long)y, trace_bytes);
  return 0;
}

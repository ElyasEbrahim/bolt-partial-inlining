/* Shared helpers for the partial-inlining microbenchmarks.
 * Every benchmark is split into a driver TU (main.c) and a library TU
 * (lib.c) that is compiled separately without LTO, so the compiler cannot
 * inline the callee into the hot loop. */
#ifndef MICRO_COMMON_H
#define MICRO_COMMON_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/* xorshift64* PRNG: deterministic, cheap, identical across variants. */
static inline uint64_t rng_next(uint64_t *s) {
  uint64_t x = *s;
  x ^= x >> 12;
  x ^= x << 25;
  x ^= x >> 27;
  *s = x;
  return x * 0x2545F4914F6CDD1DULL;
}

static inline long arg_or(int argc, char **argv, int i, long dflt) {
  return argc > i ? strtol(argv[i], NULL, 0) : dflt;
}
#endif

/* compute: CRC-32C over a buffer and a dense matmul.
 * usage: compute [rounds=40] [n=160] */
#include "../common.h"
uint32_t crc32c(uint32_t crc, const unsigned char *p, size_t n);
void matmul(const double *a, const double *b, double *c, int n);

int main(int argc, char **argv) {
  long rounds = arg_or(argc, argv, 1, 40);
  int n = (int)arg_or(argc, argv, 2, 160);
  size_t len = 1 << 20;
  unsigned char *buf = malloc(len);
  uint64_t s = 7;
  for (size_t i = 0; i < len; i++)
    buf[i] = (unsigned char)rng_next(&s);
  double *a = malloc(sizeof(double) * n * n), *b = malloc(sizeof(double) * n * n),
         *c = malloc(sizeof(double) * n * n);
  for (int i = 0; i < n * n; i++) {
    a[i] = (double)(rng_next(&s) % 1000) / 999.0;
    b[i] = (double)(rng_next(&s) % 1000) / 999.0;
  }
  uint32_t crc = 0;
  double tr = 0;
  for (long r = 0; r < rounds; r++) {
    crc = crc32c(crc, buf, len);
    matmul(a, b, c, n);
    tr += c[(r * 7) % (n * n)];
  }
  printf("compute rounds=%ld crc=%08x tr=%.6f\n", rounds, crc, tr);
  return 0;
}

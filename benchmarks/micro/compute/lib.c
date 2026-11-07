#include <stdint.h>
#include <stddef.h>
/* Bitwise CRC-32C plus a small matrix multiply: no calls in hot loops. */
uint32_t crc32c(uint32_t crc, const unsigned char *p, size_t n) {
  crc = ~crc;
  for (size_t i = 0; i < n; i++) {
    crc ^= p[i];
    for (int k = 0; k < 8; k++)
      crc = (crc >> 1) ^ (0x82F63B78u & (0u - (crc & 1u)));
  }
  return ~crc;
}
void matmul(const double *a, const double *b, double *c, int n) {
  for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++) {
      double s = 0;
      for (int k = 0; k < n; k++)
        s += a[i * n + k] * b[k * n + j];
      c[i * n + j] = s;
    }
}

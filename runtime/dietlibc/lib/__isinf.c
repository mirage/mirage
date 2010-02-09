#include <math.h>

int isinf(double d) {
  union {
    unsigned long long l;
    double d;
  } u;
  u.d=d;
  return (u.l==0x7FF0000000000000ll?1:u.l==0xFFF0000000000000ll?-1:0);
}
int __isinf(double d) __attribute__((alias("isinf")));

#if 0
TestFromIeeeExtended("7FFF0000000000000000");   /* +infinity */
TestFromIeeeExtended("FFFF0000000000000000");   /* -infinity */
TestFromIeeeExtended("7FFF8001000000000000");   /* Quiet NaN(1) */
TestFromIeeeExtended("7FFF0001000000000000");   /* Signalling NaN(1) */
TestFromIeeeExtended("3FFFFEDCBA9876543210");   /* accuracy test */
#endif

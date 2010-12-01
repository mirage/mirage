#include <math.h>

int isnan(double d) {
  union {
    unsigned long long l;
    double d;
  } u;
  u.d=d;
  return (u.l==0x7FF8000000000000ll || u.l==0x7FF0000000000000ll || u.l==0xfff8000000000000ll);
}
int __isnan(double d) __attribute__((alias("isnan")));

#if 0
TestFromIeeeExtended("7FFF0000000000000000");   /* +infinity */
TestFromIeeeExtended("FFFF0000000000000000");   /* -infinity */
TestFromIeeeExtended("7FFF8001000000000000");   /* Quiet NaN(1) */
TestFromIeeeExtended("7FFF0001000000000000");   /* Signalling NaN(1) */
TestFromIeeeExtended("3FFFFEDCBA9876543210");   /* accuracy test */
#endif

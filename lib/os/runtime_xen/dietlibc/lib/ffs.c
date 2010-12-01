#include <strings.h>

int ffs(int i) {
  int plus=0;
  /* return index of rightmost bit set */
  /* ffs(1) == 1, ffs(2) == 2, ffs(256) == 9, ffs(257)=1 */
#if 0
  if (sizeof(i)==8)	/* fold 64-bit archs */
    if ((i&0xffffffff)==0) {
      plus=32;
      i>>=32;
    }
#endif
  if ((i&0xffff)==0) {
    plus+=16;
    i>>=16;
  }
  if ((i&0xff)==0) {
    plus+=8;
    i>>=8;
  }
  if ((i&0xf)==0) {
    plus+=4;
    i>>=4;
  }
  if (i&1) return plus+1;
  if (i&2) return plus+2;
  if (i&4) return plus+3;
  if (i&8) return plus+4;
  return 0;
}

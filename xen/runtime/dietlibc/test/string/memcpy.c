#include <string.h>
#include <assert.h>
#include <sys/param.h>

#define WO	(__WORDSIZE/8)

int main() {
  size_t const	LENS[] = {
    1, 2, 3, 4, 5, 6, 7, 8,
    WO  -3, WO  -2, WO  -1,  WO,   WO  +1, WO  +2, WO  +3, WO  +4,
    WO*2-3, WO*2-2, WO*2-1,  WO*2, WO*2+1, WO*2+2, WO*2+3, WO*2+4,
    WO*3-3, WO*3-2, WO*3-1,  WO*3, WO*3+1, WO*3+2, WO*3+3, WO*3+4,
    (size_t)(-1) };

  size_t i,j;
  size_t const *len;
  char test[100]="blubber";

  assert(memcpy(test,"blubber",8)==test);
  assert(!memcmp(test,"blubber",8));
  assert(memcpy(0,0,0)==0);
  assert(memcpy(test,"foobar",3) && test[2]=='o');

  /* test all possible alignments of src and destination in combination with
   * some interesting lengths */
  for (len=LENS+0; *len!=(size_t)(-1); ++len) {
    unsigned char	src[WO * 5];

    for (i=0; i<*len + WO; ++i)
      src[i] = i;

    for (i=MIN(WO,*len); i>0;) {
      --i;
      
      for (j=MIN(WO,*len); j>0;) {
	unsigned char	dst[WO * 5];
	size_t k;
	--j;

	for (k=0; k<*len; ++k)
	  dst[j+k]=src[i+k]+1;
			  
	assert(memcpy(dst+j, src+i, *len)==dst+j);

	for (k=0; k<*len; ++k)
	  assert(dst[j+k]==src[i+k]);
      }
    }
  }

  return 0;
}

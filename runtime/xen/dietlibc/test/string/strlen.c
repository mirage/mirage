#include <assert.h>
#include <string.h>
#include <endian.h>

/* make it large enough to test all possible alignments, number of trailing
 * bytes and word sizes  */
#define BUFLEN	(__WORDSIZE/8 * 4)

int main() {
  /* will hold the string, the trailing zero and a test pattern */
  char		buf[BUFLEN + 1 + __WORDSIZE/8];
  size_t	len;

  assert(strlen("")==0);

  for (len=0; len<BUFLEN; ++len) {
	  unsigned int	mask;

	  buf[len]   = len%10 + '0';
	  buf[len+1] = '\0';

	  for (mask=0; mask<(1u<<__WORDSIZE/8); ++mask) {
		  size_t	bit;
		  size_t	i;

		  for (bit=0; bit<__WORDSIZE/8; ++bit)
			  buf[len+2+bit] = (mask & (1u<<bit)) ? 0xff : 0;

		  for (i=0; i<=len; ++i)
			  assert(strlen(buf+i)==len+1-i);
	  }
  }

  return 0;
}

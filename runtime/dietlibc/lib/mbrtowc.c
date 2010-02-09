#include "dietlocale.h"
#include <wchar.h>
#include <errno.h>

static mbstate_t internal;

size_t mbrtowc(wchar_t *pwc, const char *s, size_t n, mbstate_t *ps) {
  size_t i;
  if (!ps) ps=&internal;
  if (!s) {
    if (ps->count) {
      errno=EILSEQ;
      return (size_t)-1;
    } else {
      ps->count=0;
      ps->sofar=0;
      return 0;
    }
  }
  for (i=0; i<n; ++i) {
    unsigned char c=s[i];
    switch (lc_ctype) {
    case CT_8BIT:
      if (pwc) { *pwc=c; ++pwc; }
      return (!!c);
    case CT_UTF8:
      if (ps->count) {
	/* we have an unfinished multibyte sequence */
	if ((c&0xc0)!=0x80) {
	  /* expected a continuation, didn't get one */
kaputt:
	  errno=EILSEQ;
	  ps->count=0;
	  return (size_t)-1;
	}
	ps->sofar=(ps->sofar << 6) + (c & 0x3f);
	if (!--ps->count) {
complete:
	  if (pwc) { *pwc=ps->sofar; ++pwc; }
	  if (ps->sofar) {
	    ps->sofar=0;
	    return i+1;
	  } else {
	    ps->count=0; ps->sofar=0;
	    return 0;
	  }
	}
      } else {
	if (c&0x80) {	/* start of multibyte sequence? */
	  unsigned char x=c<<1;
	  unsigned char cnt=0;
	  while (x&0x80) {
	    x<<=1;
	    ++cnt;
	  }
	  if (!cnt || cnt>5) goto kaputt;
	  ps->sofar=x>>(cnt+1);
	  ps->count=cnt;
	} else {
	  ps->sofar=c;
	  goto complete;
	}
      }
    }
  }
  return n;
}

#include <wchar.h>
#include "dietlocale.h"

static mbstate_t internal;

size_t wcrtomb(char *s, wchar_t wc, mbstate_t *ps) {
  if (!ps) ps=&internal;
  switch (lc_ctype) {
  case CT_8BIT:
    if (!s) return 0;
    *s=wc;
    return 1;
  case CT_UTF8:
    if (!s) return (wc>=0x80);
    {
      unsigned int bits,j,k;
      if (wc>=0x04000000) { bits=30; *s=0xFC; j=6; } else
      if (wc>=0x00200000) { bits=24; *s=0xF8; j=5; } else
      if (wc>=0x00010000) { bits=18; *s=0xF0; j=4; } else
      if (wc>=0x00000800) { bits=12; *s=0xE0; j=3; } else
      if (wc>=0x00000080) { bits=6; *s=0xC0; j=2; } else
			{ *s=wc; return 1; }
      *s |= (unsigned char)(wc>>bits);
      for (k=1; k<j; ++k) {
	bits-=6;
	s[k]=0x80+((wc>>bits)&0x3f);
      }
      return k;
    }
  }
  return 0;
}

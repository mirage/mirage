#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>
#include <reent.h>
#include <string.h>

wint_t
btowc (int c)
{
  mbstate_t mbs;
  int retval = 0;
  wchar_t pwc;
  unsigned char b;

  b = (unsigned char)c;

  /* Put mbs in initial state. */
  memset (&mbs, '\0', sizeof (mbs));

  _REENT_CHECK_MISC(_REENT);

  retval = _mbtowc_r (_REENT, &pwc, &b, 1, &mbs);

  if (c == EOF || retval != 1)
    return WEOF;
  else
    return (wint_t)pwc;
}

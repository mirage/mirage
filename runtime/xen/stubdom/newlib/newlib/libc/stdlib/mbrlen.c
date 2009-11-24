#include <reent.h>
#include <newlib.h>
#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

size_t
mbrlen(const char *s, size_t n, mbstate_t *ps)
{
#ifdef _MB_CAPABLE
  if (ps == NULL)
    {
      _REENT_CHECK_MISC(_REENT);
      ps = &(_REENT_MBRLEN_STATE(_REENT));
    }
#endif

  return mbrtowc(NULL, s, n, ps);
}

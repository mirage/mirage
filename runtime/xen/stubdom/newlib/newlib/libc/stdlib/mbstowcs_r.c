#include <stdlib.h>
#include <wchar.h>

size_t
_DEFUN (_mbstowcs_r, (reent, pwcs, s, n, state),
        struct _reent *r    _AND         
        wchar_t       *pwcs _AND
        const char    *s    _AND
        size_t         n    _AND
        mbstate_t     *state)
{
  wchar_t *ptr = pwcs;
  size_t max = n;
  char *t = (char *)s;
  int bytes;

  while (n > 0)
    {
      bytes = _mbtowc_r (r, ptr, t, MB_CUR_MAX, state);
      if (bytes < 0)
	{
	  state->__count = 0;
	  return -1;
	}
      else if (bytes == 0)
        return ptr - pwcs;
      t += bytes;
      ++ptr;
      --n;
    }

  return max;
}   

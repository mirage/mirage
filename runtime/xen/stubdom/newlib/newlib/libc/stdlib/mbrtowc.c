#include <reent.h>
#include <newlib.h>
#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

size_t
_DEFUN (_mbrtowc_r, (ptr, pwc, s, n, ps),
	struct _reent *ptr _AND
	wchar_t *pwc _AND
	const char *s _AND
	size_t n _AND
	mbstate_t *ps)
{
  int retval = 0;

#ifdef _MB_CAPABLE
  if (ps == NULL)
    {
      _REENT_CHECK_MISC(ptr);
      ps = &(_REENT_MBRTOWC_STATE(ptr));
    }
#endif

  if (s == NULL)
    retval = _mbtowc_r (ptr, NULL, "", 1, ps);
  else
    retval = _mbtowc_r (ptr, pwc, s, n, ps);

  if (retval == -1)
    {
      ps->__count = 0;
      ptr->_errno = EILSEQ;
      return (size_t)(-1);
    }
  else
    return (size_t)retval;
}

#ifndef _REENT_ONLY
size_t
_DEFUN (mbrtowc, (pwc, s, n, ps),
	wchar_t *pwc _AND
	const char *s _AND
	size_t n _AND
	mbstate_t *ps)
{
  return _mbrtowc_r (_REENT, pwc, s, n, ps);
}
#endif /* !_REENT_ONLY */

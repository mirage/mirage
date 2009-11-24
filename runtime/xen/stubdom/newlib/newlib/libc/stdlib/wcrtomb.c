#include <reent.h>
#include <newlib.h>
#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

size_t
_DEFUN (_wcrtomb_r, (ptr, s, wc, ps),
	struct _reent *ptr _AND
	char *s _AND
	wchar_t wc _AND
	mbstate_t *ps)
{
  int retval = 0;
  char buf[10];

#ifdef _MB_CAPABLE
  if (ps == NULL)
    {
      _REENT_CHECK_MISC(ptr);
      ps = &(_REENT_WCRTOMB_STATE(ptr));
    }
#endif

  if (s == NULL)
    retval = _wctomb_r (ptr, buf, L'\0', ps);
  else
    retval = _wctomb_r (ptr, s, wc, ps);

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
_DEFUN (wcrtomb, (s, wc, ps),
	char *s _AND
	wchar_t wc _AND
	mbstate_t *ps)
{
  return _wcrtomb_r (_REENT, s, wc, ps);
}
#endif /* !_REENT_ONLY */

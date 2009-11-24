/*
FUNCTION
	<<wcpncpy>>---copy part of a wide-character string returning a pointer to its end

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcpncpy(wchar_t *<[s1]>, const wchar_t *<[s2]>, size_t <[n]>);

TRAD_SYNOPSIS
	wchar_t *wcpncpy(<[s1]>, <[s2]>, <[n]>
	wchar_t *<[s1]>;
	const wchar_t *<[s2]>;
	size_t <[n]>;

DESCRIPTION
	The <<wcpncpy>> function copies not more than n wide-character codes
	(wide-character codes that follow a null wide-character code are not
	copied) from the array pointed to by <[s2]> to the array pointed to
	by <[s1]>. If copying takes place between objects that overlap, the
	behaviour is undefined.

	If the array pointed to by <[s2]> is a wide-character string that is
	shorter than <[n]> wide-character codes, null wide-character codes are
	appended to the copy in the array pointed to by <[s1]>, until <[n]>
	wide-character codes in all are written. 

RETURNS
	The <<wcpncpy>> function returns <[s1]>; no return value is reserved to
	indicate an error. 

PORTABILITY
<<wcpncpy>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcpncpy, (dst, src, count),
	wchar_t * dst _AND
	_CONST wchar_t * src _AND
	size_t count)
{
  wchar_t *ret = NULL;

  while (count > 0)
    {
      --count;
      if ((*dst++ = *src++) == L'\0')
	{
	  ret = dst - 1;
	  break;
	}
    }
  while (count-- > 0)
    *dst++ = L'\0';

  return ret ? ret : dst;
}

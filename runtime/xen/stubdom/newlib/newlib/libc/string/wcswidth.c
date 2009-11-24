/*
FUNCTION
	<<wcswidth>>---number of column positions of a wide-character string
	
INDEX
	wcswidth

ANSI_SYNOPSIS
	#include <wchar.h>
	int wcswidth(const wchar_t *<[pwcs]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <wchar.h>
	int wcswidth(<[pwcs]>, <[n]>)
	wchar_t *<[wc]>;
	size_t <[n]>;

DESCRIPTION
	The <<wcswidth>> function shall determine the number of column
	positions required for <[n]> wide-character codes (or fewer than <[n]>
	wide-character codes if a null wide-character code is encountered
	before <[n]> wide-character codes are exhausted) in the string pointed
	to by <[pwcs]>.

RETURNS
	The <<wcswidth>> function either shall return 0 (if <[pwcs]> points to a
	null wide-character code), or return the number of column positions
	to be occupied by the wide-character string pointed to by <[pwcs]>, or
	return -1 (if any of the first <[n]> wide-character codes in the
	wide-character string pointed to by <[pwcs]> is not a printable
	wide-character code).

PORTABILITY
<<wcswidth>> has been introduced in the Single UNIX Specification Volume 2.
<<wcswidth>> has been marked as an extension in the Single UNIX Specification Volume 3.
*/

#include <_ansi.h>
#include <wchar.h>

int
_DEFUN (wcswidth, (pwcs, n),
	_CONST wchar_t *pwcs _AND
	size_t n)

{
  int w, len = 0;
  if (!pwcs || n == 0)
    return 0;
  do {
    if ((w = wcwidth (*pwcs)) < 0)
      return -1;
    len += w;
  } while (*pwcs++ && --n > 0);
  return len;
}

/*
FUNCTION
	<<wcwidth>>---number of column positions of a wide-character code
	
INDEX
	wcwidth

ANSI_SYNOPSIS
	#include <wchar.h>
	int wcwidth(const wchar_t <[wc]>);

TRAD_SYNOPSIS
	#include <wchar.h>
	int wcwidth(<[wc]>)
	wchar_t *<[wc]>;

DESCRIPTION
	The <<wcwidth>> function shall determine the number of column
	positions required for the wide character <[wc]>. The application
	shall ensure that the value of <[wc]> is a character representable
	as a wchar_t, and is a wide-character code corresponding to a
	valid character in the current locale.

RETURNS
	The <<wcwidth>> function shall either return 0 (if <[wc]> is a null
	wide-character code), or return the number of column positions to
	be occupied by the wide-character code <[wc]>, or return -1 (if <[wc]>
	does not correspond to a printable wide-character code).

	The current implementation of <<wcwidth>> simply sets the width
	of all printable characters to 1 since newlib has no character
	tables around.

PORTABILITY
<<wcwidth>> has been introduced in the Single UNIX Specification Volume 2.
<<wcwidth>> has been marked as an extension in the Single UNIX Specification Volume 3.
*/

#include <_ansi.h>
#include <wchar.h>
#include <wctype.h>

int
_DEFUN (wcwidth, (wc),
	_CONST wchar_t wc)

{
  if (iswprint (wc))
    return 1;
  if (iswcntrl (wc) || wc == L'\0')
    return 0;
  return -1;
}

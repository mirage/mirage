/*
FUNCTION
	<<wcpcpy>>---copy a wide-character string returning a pointer to its end

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcpcpy(wchar_t *<[s1]>, const wchar_t *,<[s2]>);

TRAD_SYNOPSIS
	wchar_t *wcpcpy(<[s1]>, <[s2]>
	wchar_t *<[s1]>;
	const wchar_t *<[s2]>;

DESCRIPTION
	The <<wcpcpy>> function copies the wide-character string pointed to by
	<[s2]> (including the terminating null wide-character code) into the
	array pointed to by <[s1]>. If copying takes place between objects that
	overlap, the behaviour is undefined. 

RETURNS
	This function returns a pointer to the end of the destination string,
	thus pointing to the trailing '\0'.

PORTABILITY
<<wcpcpy>> is a GNU extension.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcpcpy, (s1, s2),
	wchar_t * s1 _AND
	_CONST wchar_t * s2)
{
  while ((*s1++ = *s2++))
    ;
  return --s1;
}

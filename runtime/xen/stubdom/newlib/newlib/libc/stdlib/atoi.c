/*
FUNCTION
   <<atoi>>, <<atol>>---string to integer

INDEX
	atoi
INDEX
	atol
INDEX
	_atoi_r
INDEX
	_atol_r

ANSI_SYNOPSIS
	#include <stdlib.h>
        int atoi(const char *<[s]>);
	long atol(const char *<[s]>);
        int _atoi_r(struct _reent *<[ptr]>, const char *<[s]>);
        long _atol_r(struct _reent *<[ptr]>, const char *<[s]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
       int atoi(<[s]>)
       char *<[s]>;

       long atol(<[s]>)
       char *<[s]>;

       int _atoi_r(<[ptr]>, <[s]>)
       struct _reent *<[ptr]>;
       char *<[s]>;

       long _atol_r(<[ptr]>, <[s]>)
       struct _reent *<[ptr]>;
       char *<[s]>;


DESCRIPTION
   <<atoi>> converts the initial portion of a string to an <<int>>.
   <<atol>> converts the initial portion of a string to a <<long>>.

   <<atoi(s)>> is implemented as <<(int)strtol(s, NULL, 10).>>
   <<atol(s)>> is implemented as <<strtol(s, NULL, 10).>>

   <<_atoi_r>> and <<_atol_r>> are reentrant versions of <<atoi>> and
   <<atol>> respectively, passing the reentrancy struct pointer.

RETURNS
   The functions return the converted value, if any. If no conversion was
   made, <<0>> is returned.

PORTABILITY
<<atoi>>, <<atol>> are ANSI.

No supporting OS subroutines are required.
*/

/*
 * Andy Wilson, 2-Oct-89.
 */

#include <stdlib.h>
#include <_ansi.h>

#ifndef _REENT_ONLY
int
_DEFUN (atoi, (s),
	_CONST char *s)
{
  return (int) strtol (s, NULL, 10);
}
#endif /* !_REENT_ONLY */

int
_DEFUN (_atoi_r, (s),
	struct _reent *ptr _AND
	_CONST char *s)
{
  return (int) _strtol_r (ptr, s, NULL, 10);
}


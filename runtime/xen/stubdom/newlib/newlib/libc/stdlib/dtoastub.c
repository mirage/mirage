#include <_ansi.h>
#include <stdlib.h>
#include <reent.h>
#include <string.h>

/* Nothing in newlib actually *calls* dtoa, they all call _dtoa_r, so this 
   is a safe way of providing it to the user. */
#ifndef NO_REENT

char *
_DEFUN (__dtoa,
	(d, mode, ndigits, decpt, sign, rve),
	double d _AND
	int mode _AND
	int ndigits _AND
	int *decpt _AND
	int *sign _AND
	char **rve)
{
  return _dtoa_r (_REENT, d, mode, ndigits, decpt, sign, rve);
}

#endif

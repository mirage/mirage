/*
FUNCTION
   <<atosfix16>>, <<atosfix32>>, <<atosfix64>>---string to signed fixed-point

INDEX
	atosfix16
INDEX
	atosfix32
INDEX
	atosfix64
INDEX
	_atosfix16_r
INDEX
	_atosfix32_r
INDEX
	_atosfix64_r

ANSI_SYNOPSIS
	#include <stdlib.h>
        __int16_t atosfix16(const char *<[s]>);
	__int32_t atosfix32(const char *<[s]>);
	__int64_t atosfix32(const char *<[s]>);

        __int16_t _atosfix16_r(struct __reent *, const char *<[s]>);
	__int32_t _atosfix32_r(struct __reent *, const char *<[s]>);
	__int64_t _atosfix32_r(struct __reent *, const char *<[s]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	__int16_t atosfix16(<[s]>)
	const char *<[s]>;
	
	__int32_t atosfix32(<[s]>)
	const char *<[s]>;

	__int64_t atosfix64(<[s]>)
	const char *<[s]>;

	__int16_t _atosfix16_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
	__int32_t _atosfix32_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
	__int64_t _atosfix64_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
DESCRIPTION
	<<atosfix16>> converts the initial portion of a string to a sign
	+ 15-bit fraction fixed point value.
	<<atosfix32>> converts the initial portion of a string to a sign
	+ 31-bit fraction fixed point value.
	<<atosfix64>> converts the initial portion of a string to a sign
	+ 63-bit fraction fixed point value.
	<<atosfix16(s)>> is implemented as <<strtosfix16(s, NULL).>>
	<<atosfix32(s)>> is implemented as <<strtosfix32(s, NULL).>>
	<<atosfix64(s)>> is implemented as <<strtosfix64(s, NULL).>>

	The alternate functions <<_atosfix16_r>>, <<_atosfix32_r>>,
	and <<_atosfix64_r>> are reentrant versions.
	The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
	The functions return the converted value, if any. If no conversion was
	made, <<0>> is returned.  If saturation occurs, <<ERANGE>> is stored
	in errno.

PORTABILITY
	<<atosfix16>>, <<atosfix32>>, and <<atosfix64>> are non-standard.

	No supporting OS subroutines are directly required.  The
	OS subroutines required by <<strtod>> are used.
*/

/*
 * Jeff Johnston - 02/13/2002
 */

#ifdef __SPE__

#include <stdlib.h>
#include <_ansi.h>

__int16_t
_DEFUN (_atosfix16_r, (reent, s),
	struct _reent *reent _AND
	_CONST char *s)
{
  return _strtosfix16_r (reent, s, NULL);
}

#ifndef _REENT_ONLY
__int16_t
_DEFUN (atosfix16, (s),
	_CONST char *s)
{
  return strtosfix16 (s, NULL);
}

#endif /* !_REENT_ONLY */

#endif /* __SPE__ */

/*
FUNCTION
   <<atoufix16>>, <<atoufix32>>, <<atoufix64>>---string to unsigned fixed-point

INDEX
	atoufix16
INDEX
	atoufix32
INDEX
	atoufix64
INDEX
	_atoufix16_r
INDEX
	_atoufix32_r
INDEX
	_atoufix64_r

ANSI_SYNOPSIS
	#include <stdlib.h>
        __uint16_t atoufix16(const char *<[s]>);
	__uint32_t atoufix32(const char *<[s]>);
	__uint64_t atoufix32(const char *<[s]>);

        __uint16_t _atoufix16_r(struct __reent *, const char *<[s]>);
	__uint32_t _atoufix32_r(struct __reent *, const char *<[s]>);
	__uint64_t _atoufix32_r(struct __reent *, const char *<[s]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	__uint16_t atoufix16(<[s]>)
	const char *<[s]>;
	
	__uint32_t atoufix32(<[s]>)
	const char *<[s]>;

	__uint64_t atoufix64(<[s]>)
	const char *<[s]>;

	__uint16_t _atoufix16_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
	__uint32_t _atoufix32_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
	__uint64_t _atoufix64_r(<reent>, <[s]>)
	struct _reent *<[reent]>;
	const char *<[s]>;
	
DESCRIPTION
	<<atoufix16>> converts the initial portion of a string to a
	16-bit fraction unsigned fixed point value.
	<<atoufix32>> converts the initial portion of a string to a
	32-bit fraction unsigned fixed point value.
	<<atoufix64>> converts the initial portion of a string to a
	64-bit fraction unsigned fixed point value.
	<<atoufix16(s)>> is implemented as <<strtoufix16(s, NULL).>>
	<<atoufix32(s)>> is implemented as <<strtoufix32(s, NULL).>>
	<<atoufix64(s)>> is implemented as <<strtoufix64(s, NULL).>>

	The alternate functions <<_atoufix16_r>>, <<_atoufix32_r>>,
	and <<_atoufix64_r>> are reentrant versions.
	The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
	The functions return the converted value, if any. If no conversion was
	made, <<0>> is returned.  If saturation occurs, <<ERANGE>> is stored
	in errno.

PORTABILITY
	<<atoufix16>>, <<atoufix32>>, and <<atoufix64>> are non-standard.

	No supporting OS subroutines are directly required.  The
	OS subroutines required by <<strtod>> are used.
*/

/*
 * Jeff Johnston - 02/13/2002
 */

#ifdef __SPE__

#include <stdlib.h>
#include <_ansi.h>

__uint16_t
_DEFUN (_atoufix16_r, (reent, s),
	struct _reent *reent _AND
	_CONST char *s)
{
  return _strtoufix16_r (reent, s, NULL);
}

#ifndef _REENT_ONLY
__uint16_t
_DEFUN (atoufix16, (s),
	_CONST char *s)
{
  return strtoufix16 (s, NULL);
}

#endif /* !_REENT_ONLY */

#endif /* __SPE__ */

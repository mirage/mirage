#ifndef	_MACHSTDLIB_H_
#define	_MACHSTDLIB_H_

#ifndef __STRICT_ANSI__

# if defined(__ALTIVEC__)

_PTR    _EXFUN(vec_calloc,(size_t __nmemb, size_t __size));
_PTR    _EXFUN(_vec_calloc_r,(struct _reent *, size_t __nmemb, size_t __size));
_VOID   _EXFUN(vec_free,(_PTR));
#define _vec_freer _freer
_PTR    _EXFUN(vec_malloc,(size_t __size));
#define _vec_mallocr _memalign_r
_PTR    _EXFUN(vec_realloc,(_PTR __r, size_t __size));
_PTR    _EXFUN(_vec_realloc_r,(struct _reent *, _PTR __r, size_t __size));

# endif /* __ALTIVEC__ */

# if defined(__SPE__)

#define __need_inttypes
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif
__int16_t   _EXFUN(atosfix16,(const char *__str));
__int16_t   _EXFUN(_atosfix16_r,(struct _reent *, const char *__str));
__int32_t   _EXFUN(atosfix32,(const char *__str));
__int32_t   _EXFUN(_atosfix32_r,(struct _reent *, const char *__str));
__int64_t   _EXFUN(atosfix64,(const char *__str));
__int64_t   _EXFUN(_atosfix64_r,(struct _reent *, const char *__str));

__uint16_t _EXFUN(atoufix16,(const char *__str));
__uint16_t _EXFUN(_atoufix16_r,(struct _reent *, const char *__str));
__uint32_t _EXFUN(atoufix32,(const char *__str));
__uint32_t _EXFUN(_atoufix32_r,(struct _reent *, const char *__str));
__uint64_t _EXFUN(atoufix64,(const char *__str));
__uint64_t _EXFUN(_atoufix64_r,(struct _reent *, const char *__str));

__int16_t   _EXFUN(strtosfix16,(const char *__str, char **__endptr));
__int16_t   _EXFUN(_strtosfix16_r,(struct _reent *, const char *__str, 
                 char **__endptr));
__int32_t   _EXFUN(strtosfix32,(const char *__str, char **__endptr));
__int32_t   _EXFUN(_strtosfix32_r,(struct _reent *, const char *__str, 
                 char **__endptr));
__int64_t   _EXFUN(strtosfix64,(const char *__str, char **__endptr));
__int64_t   _EXFUN(_strtosfix64_r,(struct _reent *, const char *__str, 
                 char **__endptr));

__uint16_t _EXFUN(strtoufix16,(const char *__str, char **__endptr));
__uint16_t _EXFUN(_strtoufix16_r,(struct _reent *, const char *__str, 
                 char **__endptr));
__uint32_t _EXFUN(strtoufix32,(const char *__str, char **__endptr));
__uint32_t _EXFUN(_strtoufix32_r,(struct _reent *, const char *__str, 
                 char **__endptr));
__uint64_t _EXFUN(strtoufix64,(const char *__str, char **__endptr));
__uint64_t _EXFUN(_strtoufix64_r,(struct _reent *, const char *__str, 
                 char **__endptr));
#ifdef __cplusplus
}
#endif

# endif /* __SPE__ */

#endif /* !__STRICT_ANSI__ */


#endif	/* _MACHSTDLIB_H_ */



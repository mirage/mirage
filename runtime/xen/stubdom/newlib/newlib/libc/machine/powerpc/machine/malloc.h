#ifndef	_MACHMALLOC_H_
#define	_MACHMALLOC_H_

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


#endif	/* _MACHMALLOC_H_ */



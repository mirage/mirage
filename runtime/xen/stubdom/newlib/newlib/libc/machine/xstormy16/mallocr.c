#include <malloc.h>

#ifdef DEFINE_MALLOC
_PTR 
_malloc_r (struct _reent *r, size_t sz)
{
  return malloc (sz);
}
#endif

#ifdef DEFINE_CALLOC
_PTR 
_calloc_r (struct _reent *r, size_t a, size_t b)
{
  return calloc (a, b);
}
#endif

#ifdef DEFINE_FREE
void
_free_r (struct _reent *r, _PTR x)
{
  free (x);
}
#endif

#ifdef DEFINE_REALLOC
_PTR 
_realloc_r (struct _reent *r, _PTR x, size_t sz)
{
  return realloc (x, sz);
}
#endif

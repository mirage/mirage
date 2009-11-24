#include <stdlib.h>

void * 
_pvalloc_r (struct _reent *ptr, size_t bytes)
{
  return pvalloc (bytes);
}

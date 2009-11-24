#include <stdlib.h>

void *
_malloc_r (struct _reent *ptr, size_t size)
{
  return malloc (size);
}

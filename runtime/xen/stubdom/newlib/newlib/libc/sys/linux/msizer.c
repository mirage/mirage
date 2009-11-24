#include <stdlib.h>

size_t 
_malloc_usable_size_r (struct _reent *ptr, void *mem)
{
  return malloc_usable_size (mem);
}

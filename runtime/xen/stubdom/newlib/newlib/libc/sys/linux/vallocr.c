#include <stdlib.h>

void * 
_valloc_r (struct _reent *ptr, size_t bytes)
{
  return valloc (bytes);
}

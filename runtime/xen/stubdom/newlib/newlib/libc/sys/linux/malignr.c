#include <stdlib.h>

void *
_memalign_r (struct _reent *ptr, size_t alignment, size_t bytes)
{
  return memalign (alignment, bytes);
}

#include <stdlib.h>

void
_free_r (struct _reent *ptr, void *addr)
{
  free (addr);
}

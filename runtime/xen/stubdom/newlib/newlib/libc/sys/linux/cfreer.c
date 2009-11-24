#include <stdlib.h>

void
_cfree_r (struct _reent *ptr, void *mem)
{
  return cfree (mem);
}

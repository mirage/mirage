#include <malloc.h>

struct mallinfo
_mallinfo_r (struct _reent *ptr)
{
  return mallinfo ();
}

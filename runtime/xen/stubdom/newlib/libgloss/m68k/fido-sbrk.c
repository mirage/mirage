#include <stddef.h>

extern char _end[];
static char *curbrk = _end;
extern char _heapend;   /* End of heap              */

void *
sbrk (ptrdiff_t incr)
{
  char *oldbrk = curbrk;
  if (curbrk + incr > &_heapend)
    return (void *) -1;
  curbrk += incr;
  return oldbrk;
}

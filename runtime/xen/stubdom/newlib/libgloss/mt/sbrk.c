#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


caddr_t
sbrk (size_t incr)
{
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  char *sp = (char *) &sp;

  if (heap_end == 0)
    {
      heap_end = &end;
    }
  prev_heap_end = heap_end;
  heap_end += incr;

  return (caddr_t) prev_heap_end;
}

#include <_ansi.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


caddr_t
_sbrk (size_t incr)
{
  extern char __stack;       /* Defined by the linker */
  extern char _end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;
  char *sp = (char *)&sp;

  if (heap_end == 0)
    {
      heap_end = &_end;
    }
  prev_heap_end = heap_end;
  heap_end += incr;
  if (heap_end > sp)
    {
      _write (1, "Heap and stack collision\n", 25);
      errno = ENOMEM;
      return (caddr_t)-1;
    }
  return (caddr_t) prev_heap_end;
}

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


caddr_t
_sbrk (size_t incr)
{
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;
#if 0
  char *sp = (char *)stack_ptr;
#else
  char *sp = (char *)&sp;
#endif

  if (heap_end == 0)
    {
      heap_end = &end;
    }
  prev_heap_end = heap_end;
  heap_end += incr;
  if (heap_end > sp)
    {
      _write (1, "Heap and stack collision\n", 25);
      abort ();
    }
  return (caddr_t) prev_heap_end;
}

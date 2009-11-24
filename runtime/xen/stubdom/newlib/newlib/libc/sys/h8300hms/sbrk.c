#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>

register char *stack_ptr asm ("sp");

caddr_t 
  _sbrk(incr)
     int incr;
{
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  if (heap_end == 0) 
    {
      heap_end = &end;
    }
  prev_heap_end = heap_end;
  if (heap_end + incr > stack_ptr)
    {
      _write (1, "Heap and stack collision\n", 25);
      abort ();
    }
  heap_end += incr;
  return (caddr_t)prev_heap_end;
}


#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

caddr_t
_sbrk (int incr)
{
  /* `_end' is defined in the linker script.
     We must handle it carefully as we don't want the compiler to think
     it lives in the small data area.  Use medium model to ensure 32 bit
     addressability.  */
  extern char _end __attribute__ ((__model__(__medium__)));
  static char *heap_end;
  char *prev_heap_end;
  char *sp = (char *)&sp;

  if (heap_end == 0)
    {
      heap_end = &_end;
    }
  prev_heap_end = heap_end;
  if (heap_end > sp)
    {
      _write (1, "Heap and stack collision\n", 25);
#if 0 /* Calling abort brings in the signal handling code.  */
      abort ();
#else
      exit (1);
#endif
    }
  heap_end += incr;
  return (caddr_t) prev_heap_end;
}

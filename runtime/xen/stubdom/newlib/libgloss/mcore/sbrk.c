/* sbrk.c -- allocate memory dynamically.
 * 
 * Copyright (c) 1995,1996,1999 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */
#include <sys/types.h>
#include <sys/stat.h>
#include "glue.h"

caddr_t
_sbrk (size_t incr)
{
  static char *heap_end;
  char *prev_heap_end;
  char *sp = (char *)&sp;

  if (heap_end == 0)
    {
      heap_end = _end;
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

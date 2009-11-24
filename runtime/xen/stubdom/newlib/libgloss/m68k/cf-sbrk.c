/*
 * cf-sbrk.c -- 
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

#include <errno.h>
/*
 * sbrk -- changes heap size size. Get nbytes more
 *         RAM. We just increment a pointer in what's
 *         left of memory on the board.
 */

extern char __end[] __attribute__ ((aligned (4)));

/* End of heap, if non NULL.  */
extern void *__heap_limit;

void *
sbrk (int nbytes)
{
  static char *heap = __end;
  char *end = __heap_limit;
  char *base = heap;
  char *new_heap = heap + nbytes;
  
  if (!end)
    {
      /* Use sp - 256 as the heap limit.  */
      __asm__ __volatile__ ("move.l %/sp,%0" : "=r"(end));
      end -= 256;
    }
  if (nbytes < 0 || (long)(end - new_heap) < 0)
    {
      errno = ENOMEM;
      return (void *)-1;
    }
  heap = new_heap;
  return base;
}

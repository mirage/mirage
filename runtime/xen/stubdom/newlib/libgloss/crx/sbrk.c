/* sbrk.c -- Implementation of the low-level sbrk() routine
 *
 * Copyright (c) 2004 National Semiconductor Corporation
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
#include <stddef.h> /* where ptrdiff_t is defined */
#include <stdlib.h>

/* Extend heap space by size bytes.
   Return start of new space allocated, or -1 for errors 
   Error cases:
    1. Allocation is not within heap range */

void * sbrk (ptrdiff_t size)
{
  /*
  * The following two memory locations should be defined in the linker script file
  */
  extern const char _HEAP_START; /* start of heap */
  extern const char _HEAP_MAX;	 /* end of heap (maximum value of heap_ptr) */

  static const char * heap_ptr;  /* pointer to head of heap */
  const char * old_heap_ptr;
  static unsigned char init_sbrk = 0;

  /* heap_ptr is initialized to HEAP_START */
  if (init_sbrk == 0) 
  {
    heap_ptr = &_HEAP_START;
    init_sbrk = 1;
  }

  old_heap_ptr = heap_ptr;

  if ((heap_ptr + size) > &_HEAP_MAX)
  { 
    /* top of heap is bigger than _HEAP_MAX */
    errno = ENOMEM;
    return (void *) -1;
  }

  /* success: update heap_ptr and return previous value */
  heap_ptr += size;
  return (void *)old_heap_ptr;
}

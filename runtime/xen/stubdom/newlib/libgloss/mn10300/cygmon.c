/* cygmon.c -- Glue code for linking apps to run on top of Cygmon.
 *
 * Copyright (c) 1998, 1999, 2000, 2001 Red Hat, Inc.
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

// These need to be kept in sync with the definitions in Cygmon.
#define SYS_meminfo     1001
#include "syscall.h"

/* Structure filled in by get_mem_info.  Only the size field is
   actually used (by sbrk), so the others aren't even filled in.  */
struct s_mem
{
  unsigned int size;
  unsigned int icsize;
  unsigned int dcsize;
};

// Perform a system call.
// Unused parameters should be set to 0.
int __trap0(unsigned long func, unsigned long p1, unsigned long p2, unsigned long p3)
{
  int ret = 0;
#ifdef __AM33__
  {
    register unsigned long d0 asm ("d0") = func;
    register unsigned long d1 asm ("d1") = p1;
    register unsigned long d2 asm ("d2") = p2;
    register unsigned long d3 asm ("d3") = p3;
    asm volatile ("    syscall 0\n"
		  "    nop"
		  : "+d" (d0) : "d" (d1), "d" (d2), "d" (d3) : "memory");
    ret = d0;
  }
#endif

  if (func == SYS_exit)
    {
      while (1)
        {
          asm volatile (" .byte 0xff ");  // trigger a breakpoint to drop back into Cygmon
        }
    }

  if (ret != 0)
      errno = ret;

  return ret;
}

void *
get_mem_info (mem)
     struct s_mem *mem;
{
  unsigned long totmem = 0, topmem = 0;
  register int numbanks;

  numbanks = __trap0(SYS_meminfo, (unsigned long)&totmem, (unsigned long)&topmem, 0);
  mem->size = totmem;
  return (void*)topmem;
}

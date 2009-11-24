/* cfe_mem.c -- Replaceable memory management hooks for MIPS boards
   running CFE.  */

/*
 * Copyright 2003
 * Broadcom Corporation. All rights reserved.
 * 
 * This software is furnished under license and may be used and copied only
 * in accordance with the following terms and conditions.  Subject to these
 * conditions, you may download, copy, install, use, modify and distribute
 * modified or unmodified copies of this software in source and/or binary
 * form. No title or ownership is transferred hereby.
 * 
 * 1) Any source code used, modified or distributed must reproduce and
 *    retain this copyright notice and list of conditions as they appear in
 *    the source file.
 * 
 * 2) No right is granted to use any trade name, trademark, or logo of
 *    Broadcom Corporation.  The "Broadcom Corporation" name may not be
 *    used to endorse or promote products derived from this software
 *    without the prior written permission of Broadcom Corporation.
 * 
 * 3) THIS SOFTWARE IS PROVIDED "AS-IS" AND ANY EXPRESS OR IMPLIED
 *    WARRANTIES, INCLUDING BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF
 *    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
 *    NON-INFRINGEMENT ARE DISCLAIMED. IN NO EVENT SHALL BROADCOM BE LIABLE
 *    FOR ANY DAMAGES WHATSOEVER, AND IN PARTICULAR, BROADCOM SHALL NOT BE
 *    LIABLE FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *    BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 */

#include "cfe_api.h"

/* Structure filled in by get_mem_info.  Only the size field is
   actually used (by sbrk), so the others aren't even filled in.
   Note that 'size' is the __size__ of the heap starting at _end!  */
struct s_mem {
  unsigned int size;
  unsigned int icsize;
  unsigned int dcsize;
};

void *get_mem_info (struct s_mem *);

extern char _end[];

/* Address immediately after available memory.  */
static unsigned long memtop;

/* Program stack size.  */
static unsigned long stack_size;

void
__libcfe_meminit (void)
{
  /* If the user has provided a memory-limit function, use it to
     determine the end of usable memory.  */
  if (&__libcfe_mem_limit != NULL)
    memtop = __libcfe_mem_limit ();
  else
    {
      uint64_t start, length, type;
      int i, rv;
      long end_segbits, end_pa;

      /* Note that this only works if _end and the program live in kseg0
         or kseg1.  Not a problem with the default linker script, but
         if you're writing your own, keep it in mind.  For more complex
         memory allocation needs, you're encouraged to copy this file
         and syscalls.c (for sbrk()), and reimplement as appropriate.  */
      end_segbits = (long)_end & ~ 0x1fffffffL;
      end_pa = (long)_end & 0x1fffffffL;

      for (i = 0; ; i++)
        {
          rv = cfe_enummem(i, 0, &start, &length, &type);
          if (rv < 0)
            {
              /* Did not find an available entry containing _end.
                 Assume a minimal amount of memory (1MB).  */
              memtop = _end + (1 * 1024 * 1024);
              break;
            }

          /* If not available, try the next.  */
          if (type != CFE_MI_AVAILABLE)
            continue;

          /* If end_pa is between start and (start + length) then we have
	     a winner.  */
          if (end_pa >= start && end_pa < (start + length))
            {
              memtop = (start + length) | end_segbits;
              break;
            }
        }
    }

  /* If the user has provided a memory-limit function, use it to
     determine the end of usable memory.  */
  if (&__libcfe_stack_size != NULL)
    stack_size = __libcfe_stack_size ();
  else
    stack_size = (32 * 1024);		/* Default = 32KB.  */

  /* Chop the top of memory to a 32-byte aligned location, and
     round the stack size up to a 32-byte multiple.  */
  memtop = memtop & ~(unsigned long)31;
  stack_size = (stack_size + 31) & ~(unsigned long)31;
}

void *
__libcfe_stack_top (void)
{
  /* Grow down from the top of available memory.  Obviously, if
     code writes above this limit, problems could result!  */
  return (void *) memtop;
}

/* For compatibility, get_mem_info returns the top of memory
   (i.e., the stack address).  Nothing actually uses that,
   though.  */
void *
get_mem_info (struct s_mem *meminfo)
{
  meminfo->size = (char *)(memtop - stack_size) - _end;
  return (void *) memtop;
}

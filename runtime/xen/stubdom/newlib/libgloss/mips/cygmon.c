/* cygmon.c -- Glue code for linking apps to run on top of Cygmon.
 *
 * Copyright (c) 1998, 1999, 2000 Red Hat, Inc.
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

#include "syscall.h"

int
write ( int file,
        char *buf,
        int nbytes)
{
  return sysCall(SYS_write, file, (unsigned long)buf, nbytes);
}

int
read (int file,
      char *buf,
      int nbytes)
{
  return sysCall(SYS_read, file, (unsigned long)buf, nbytes);
}

int
outbyte (unsigned char c)
{
  return sysCall(SYS_write, 0, (unsigned long)&c, 1);
}

unsigned char
inbyte (void)
{
  char c;
  sysCall(SYS_read, 0, (unsigned long)&c, 1);
  return c;
}


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
int sysCall(unsigned long func, unsigned long p1, unsigned long p2, unsigned long p3)
{
  int ret = 0;
  asm volatile ( "		\n\
          move $4, %1		\n\
          move $5, %2		\n\
          move $6, %3		\n\
          move $7, %4		\n\
          syscall 		\n\
          nop			\n\
          move %0, $2" : "=r"(ret) : "r"(func), "r"(p1), "r"(p2), "r"(p3));
  return ret;
}

// These need to be kept in sync with the definitions in Cygmon.
#define SYS_meminfo     1001

void *
get_mem_info (mem)
     struct s_mem *mem;
{
  unsigned long totmem = 0, topmem = 0;
  int numbanks;

  numbanks = sysCall(SYS_meminfo, (unsigned long)&totmem, (unsigned long)&topmem, 0);
  mem->size = totmem;
  return (void*)topmem;
}

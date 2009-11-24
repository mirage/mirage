/* eva_app.c -- Glue code for linking apps to run under GDB debugger control.
 *
 * Copyright (c) 2001 Red Hat, Inc.
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
#include "glue.h"

typedef void (*write_proc_t)(char *buf, int nbytes);
typedef int  (*read_proc_t)(char *buf, int nbytes);

/* There is no "syscall", so we just call directly into the stub code
   at fixed addresses. */
#define STUB_WRITE(p,n) ((write_proc_t)0x8084)((p),(n))
#define STUB_READ(p,n)  ((read_proc_t)0x8088)((p),(n))

/*
 * print -- do a raw print of a string
 */ 
void
print(char *ptr)
{
  STUB_WRITE(ptr, strlen(ptr));
}

/*
 * write -- write bytes to the serial port. Ignore fd, since
 *          stdout and stderr are the same. Since we have no filesystem,
 *          open will only return an error.
 */
int
_write (int fd, char *buf, int nbytes)
{
  STUB_WRITE(buf, nbytes);
  return (nbytes);
}

int
_read (int fd, char *buf, int nbytes)
{
  return STUB_READ(buf, nbytes);
}

extern char _end[];
#define HEAP_LIMIT ((char *)0xffff)

void *
_sbrk(int inc)
{
  static char *heap_ptr = _end;
  void *base;

  if (inc > (HEAP_LIMIT - heap_ptr))
    return (void *)-1;

  base = heap_ptr;
  heap_ptr += inc;

  return base;
}

void
_exit(int n)
{
  while (1)
   {
     asm volatile ("nop");
     asm volatile (".hword 0x0006");  /* breakpoint (special illegal insn) */
   }
}

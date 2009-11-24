/* pseudo system calls for M68HC11 & M68HC12.
 * Copyright (C) 1999, 2000, 2001, 2002 Stephane Carrez (stcarrez@nerim.fr)	
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
#include <unistd.h>

extern void outbyte(char c);
extern char inbyte(void);

int
read(int file, void *p, size_t nbytes)
{
  int i = 0;
  char* buf = (char*) p;
  
  for (i = 0; i < nbytes; i++) {
    *(buf + i) = inbyte();
    if ((*(buf + i) == '\n') || (*(buf + i) == '\r')) {
      i++;
      break;
    }
  }
  return (i);
}

int
write(int file, const void *p, size_t len)
{
  const char *ptr = (const char*) p;
  int todo;
  
  for (todo = len; todo; --todo)
    {
      outbyte (*ptr++);
    }
  return(len);
}

void *
sbrk(ptrdiff_t incr)
{
  extern char _end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  register char *stack_ptr asm ("sp");

  if (heap_end == 0) 
    {
      heap_end = &_end;
    }
  prev_heap_end = heap_end;
  if (heap_end + incr > stack_ptr)
    {
      write (1, "Heap and stack collision\n", 25);
      abort ();
    }
  heap_end += incr;
  return ((void*) prev_heap_end);
}

/* end of syscalls.c */

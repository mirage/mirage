#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "regs.S"

extern char _end[];

/* FIXME: This is not ideal, since we do a get_mem_info() call for
   every sbrk() call. */
char *
sbrk (nbytes)
     int nbytes;
{
  static char *heap_ptr = _end;
  static char *heap_start = _end;
  char        *base;
  struct s_mem {
    unsigned int size;
    unsigned int icsize;
    unsigned int dcsize;
  } mem;
  unsigned int avail = 0;

  /* The sizeof (s_mem.size) must be 4 bytes.  The compiler should be
     able to eliminate this check */
  if (sizeof (unsigned int) != 4)
    return (char *)-1;

  get_mem_info(&mem);
  /* NOTE: The value returned from the get_mem_info call is the amount
     of memory, and not the address of the (last byte + 1) */

  if (((size_t)heap_ptr >= heap_start) && ((size_t)heap_ptr < (heap_start + mem.size))) {
    avail = (heap_start + mem.size) - (size_t)heap_ptr;
    base = heap_ptr;
  } /* else will fail since "nbytes" will be greater than zeroed "avail" value */

  if ((nbytes > avail) || (heap_ptr + nbytes < _end))
   base = (char *)-1;
  else
   heap_ptr += nbytes;

  return base;
}

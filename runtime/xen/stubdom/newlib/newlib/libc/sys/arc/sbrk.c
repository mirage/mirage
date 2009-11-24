/* sbrk support */

/* The current plan is to have one sbrk handler for all cpus.
   Hence use `asm' for each global variable here to avoid the cpu prefix.
   We can't intrude on the user's namespace (another reason to use asm).  */

#include <sys/types.h>
#include <sys/syscall.h>
#include <errno.h>
#include <stddef.h>

/* These variables are publicly accessible for debugging purposes.
   The user is also free to set sbrk_size to something different.
   See mem-layout.c.  */

extern int sbrk_size asm ("sbrk_size");

caddr_t sbrk_start asm ("sbrk_start");
caddr_t sbrk_loc asm ("sbrk_loc");

/*caddr_t _sbrk_r (struct _reent *, size_t) asm ("__sbrk_r");*/

/* FIXME: We need a semaphore here.  */

caddr_t
_sbrk_r (struct _reent *r, size_t nbytes)
{
  caddr_t result;

  if (
      /* Ensure we don't underflow.  */
      sbrk_loc + nbytes < sbrk_start
      /* Ensure we don't overflow.  */
      || sbrk_loc + nbytes > sbrk_start + sbrk_size)
    {
      errno = ENOMEM;
      return ((caddr_t) -1);
    }

  result = sbrk_loc;
  sbrk_loc += nbytes;
  return result;
}

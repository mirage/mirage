/* connector for times */

#include <reent.h>
#include <sys/times.h>

clock_t
_DEFUN (times, (buf),
     struct tms *buf)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _times_r (_REENT, buf);
#else
  return _times (buf);
#endif
}

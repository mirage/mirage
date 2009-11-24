/* connector for close */

#include <reent.h>

int
_DEFUN (close, (fd),
     int fd)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _close_r (_REENT, fd);
#else
  return _close (fd);
#endif
}

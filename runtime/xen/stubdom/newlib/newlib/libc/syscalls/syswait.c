/* connector for wait */

#include <reent.h>

int
_DEFUN (wait, (status),
        int *status)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _wait_r (_REENT, status);
#else
  return _wait (status);
#endif
}

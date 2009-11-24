/* connector for kill */

#include <reent.h>

int
_DEFUN (kill, (pid, sig),
     int pid _AND
     int sig)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _kill_r (_REENT, pid, sig);
#else
  return _kill (pid, sig);
#endif
}

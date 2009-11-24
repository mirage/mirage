/* connector for getpid */

#include <reent.h>

int
_DEFUN_VOID (getpid)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _getpid_r (_REENT);
#else
  return _getpid ();
#endif
}

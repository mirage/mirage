/* connector for stat */

#include <reent.h>
#include <unistd.h>

int
_DEFUN (stat, (file, pstat),
     char *file _AND
     struct stat *pstat)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _stat_r (_REENT, file, pstat);
#else
  return _stat (file, pstat);
#endif
}

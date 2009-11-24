/* connector for fstat */

#include <reent.h>
#include <unistd.h>

int
_DEFUN (fstat, (fd, pstat),
     int fd _AND
     struct stat *pstat)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _fstat_r (_REENT, fd, pstat);
#else
  return _fstat (fd, pstat);
#endif
}

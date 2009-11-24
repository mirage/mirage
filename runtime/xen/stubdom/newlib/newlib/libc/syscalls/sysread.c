/* connector for read */

#include <reent.h>
#include <unistd.h>

_READ_WRITE_RETURN_TYPE
_DEFUN (read, (fd, buf, cnt),
     int fd _AND
     void *buf _AND
     size_t cnt)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _read_r (_REENT, fd, buf, cnt);
#else
  return _read (fd, buf, cnt);
#endif
}

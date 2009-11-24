/* connector for write */

#include <reent.h>
#include <unistd.h>

_READ_WRITE_RETURN_TYPE
_DEFUN (write, (fd, buf, cnt),
     int fd _AND
     const void *buf _AND
     size_t cnt)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _write_r (_REENT, fd, buf, cnt);
#else
  return _write (fd, buf, cnt);
#endif
}

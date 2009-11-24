/* connector for fcntl */
/* only called from stdio/fdopen.c, so arg can be int. */

#include <reent.h>
#include <errno.h>

int
_DEFUN (fcntl, (fd, flag, arg),
     int fd _AND
     int flag _AND
     int arg)
{
#ifdef HAVE_FCNTL
# ifdef REENTRANT_SYSCALLS_PROVIDED
  return _fcntl_r (_REENT, fd, flag, arg);
# else
  return _fcntl (fd, flag, arg);
# endif
#else /* !HAVE_FCNTL */
  errno = ENOSYS;
  return -1;
#endif /* !HAVE_FCNTL */
}

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <_ansi.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <reent.h>

_ssize_t
_read_r (struct _reent *r, int fd, void *buf, size_t nbytes)
{
  int err;
  _ssize_t rc;

  SYSCALL (SYS_read, rc, err, fd, buf, nbytes);
  if (err)
    __errno_r (r) = err;
  return rc;
}

_ssize_t
_write_r (struct _reent *r, int fd, const void *buf, size_t nbytes)
{
  int err;
  _ssize_t rc;

  SYSCALL (SYS_write, rc, err, fd, buf, nbytes);
  if (err)
    __errno_r (r) = err;
  return rc;
}

/* FIXME: The prototype in <fcntl.h> for open() uses ...,
   but reent.h uses int.  */

int
_open_r (struct _reent *r, const char *buf, int flags, int mode)
{
  int rc,err;
#if 0
  int mode;
  va_list ap;

  va_start (ap, flags);
  mode = va_arg (ap, int);
  va_end (ap);
#endif

  SYSCALL (SYS_open, rc, err, buf, flags, mode);
  if (err)
    __errno_r (r) = err;
  return rc;
}

int
_close_r (struct _reent *r, int fd)
{
  int rc,err;

  SYSCALL (SYS_close, rc, err, fd, 0, 0);
  if (err)
    __errno_r (r) = err;
  return rc;
}

off_t
_lseek_r (struct _reent *r, int fd,  off_t offset, int whence)
{
  int err;
  off_t rc;

  SYSCALL (SYS_lseek, rc, err, fd, offset, whence);
  if (err)
    __errno_r (r) = err;
  return rc;
}

int
_fstat_r (struct _reent *r, int fd, struct stat *buf)
{
  int rc,err;

  SYSCALL (SYS_fstat, rc, err, fd, buf, 0);
  if (err)
    __errno_r (r) = err;
  return rc;
}

/* FIXME: Shouldn't this be _exit_r?  */

void
_exit (int ret)
{
  int rc,err;

  SYSCALL (SYS_exit, rc, err, ret, 0, 0);

  /* If that failed, use an infinite loop.  */
  while (1)
    continue;
}

time_t
_time (time_t *timer)
{
  return 0;
}

int
_creat_r (struct _reent *r, const char *path, int mode)
{
  return _open_r (r, path, O_CREAT | O_TRUNC, mode);
}

int
_getpid_r (struct _reent *r)
{
  return 42;
}

int
_kill_r (struct _reent *r, int pid, int sig)
{
  int rc,err;

  SYSCALL (SYS_kill, rc, err, pid, sig, 0);
  if (err)
    __errno_r (r) = err;
  return rc;
}

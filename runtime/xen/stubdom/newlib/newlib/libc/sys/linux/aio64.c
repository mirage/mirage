/* libc/sys/linux/aio64.c - asychronous I/O */

/* Copyright 2002, Red Hat Inc. */

/* Currently asynchronous I/O is not implemented. */

#include <sys/types.h>
#include <aio.h>
#include <errno.h>

int
aio_cancel64 (int fd, struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_error64 (const struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_fsync64 (int op, struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_read64 (struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

ssize_t
aio_return64 (struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_suspend64 (const struct aiocb64 *const list[], int nent,
             const struct timespec *timeout)
{
  errno = ENOSYS;
  return -1;
}

int
aio_write64 (struct aiocb64 *cb)
{
  errno = ENOSYS;
  return -1;
}

int
lio_listio64 (int mode, struct aiocb64 * const list[], int nent,
              struct sigevent *sig)
{
  errno = ENOSYS;
  return -1;
}

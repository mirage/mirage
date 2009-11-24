/* libc/sys/linux/aio.c - asychronous I/O */

/* Copyright 2002, Red Hat Inc. */

/* Currently asynchronous I/O is not implemented. */

#define _GNU_SOURCE 1

#include <sys/types.h>
#include <aio.h>
#include <errno.h>

int
aio_cancel (int fd, struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_error (const struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_fsync (int op, struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_read (struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

ssize_t
aio_return (struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

int
aio_suspend (const struct aiocb *const list[], int nent,
             const struct timespec *timeout)
{
  errno = ENOSYS;
  return -1;
}

int
aio_write (struct aiocb *cb)
{
  errno = ENOSYS;
  return -1;
}

int
lio_listio (int mode, struct aiocb * const list[], int nent,
            struct sigevent *sig)
{
  errno = ENOSYS;
  return -1;
}

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4
void 
aio_init (const struct aioinit *INIT)
{
  errno = ENOSYS;
}
#endif

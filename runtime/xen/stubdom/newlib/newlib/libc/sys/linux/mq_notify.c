/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <errno.h>
#include <machine/weakalias.h>

#include "mqlocal.h"

int
__libc_mq_notify (mqd_t msgid, const struct sigevent *notification)
{
  errno = ENOSYS;
  return -1;
}
weak_alias (__libc_mq_notify, mq_notify)

      






/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <errno.h>
#include <sys/sem.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

int
mq_close (mqd_t msgid)
{
  struct libc_mq *info;
  struct sembuf sb0 = {0, -1, 0};
  int rc;
  int semid;

  info = __find_mq (msgid);

  if (info == NULL)
    {
      errno = EBADF;
      return -1;
    }

  /* lock message queue */
  semid = info->semid;
  rc = semop (semid, &sb0, 1);

  if (rc == 0)
    {
      __cleanup_mq (msgid);
      
      /* unlock message queue */
      sb0.sem_op = 1;
      semop (semid, &sb0, 1);
    }

  return rc;
}
      






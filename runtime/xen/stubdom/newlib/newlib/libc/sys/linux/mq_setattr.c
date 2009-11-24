/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <errno.h>
#include <sys/sem.h>
#include <string.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

int
mq_setattr (mqd_t msgid, const struct mq_attr *mqstat, struct mq_attr *omqstat)
{
  struct libc_mq *info;
  struct sembuf sb0 = {0, -1, 0};
  int num_msgs;
  int rc = 0;

  info = __find_mq (msgid);

  if (info == NULL)
    {
      errno = EBADF;
      return -1;
    }

  /* temporarily lock message queue */
  semop (info->semid, &sb0, 1);

  /* make copy of old structure */
  if (omqstat != NULL)
    {
      num_msgs = semctl (info->semid, 3, GETVAL);
      if (num_msgs >= 0)
	{
	  memcpy (omqstat, info->attr, sizeof(struct mq_attr));
	  omqstat->mq_curmsgs = num_msgs;
	}
      else
	rc = -1;
    }
  
  /* only the mq_flags field can be changed */
  info->attr->mq_flags = mqstat->mq_flags;

  /* release message queue */
  sb0.sem_op = 1;
  semop (info->semid, &sb0, 1);

  return rc;
}
      






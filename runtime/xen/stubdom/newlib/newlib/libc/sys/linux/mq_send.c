/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <string.h>
#include <stdlib.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

__LOCK_INIT(static, mq_wrbuf_lock);

int
mq_send (mqd_t msgid, const char *msg, size_t msg_len, unsigned int msg_prio)
{
  struct libc_mq *info;
  struct sembuf sb2 = {2, -1, 0};
  struct sembuf sb3 = {3, 1, 0};
  int rc;
  int ipcflag;

  info = __find_mq (msgid);

  if (info == NULL || (info->oflag & O_ACCMODE) == O_RDONLY)
    {
      errno = EBADF;
      return -1;
    }

  if (msg_len > info->attr->mq_msgsize)
    {
      errno = EMSGSIZE;
      return -1;
    }

  if (msg_prio > MQ_PRIO_MAX)
    {
      errno = EINVAL;
      return -1;
    }

  __lock_acquire (mq_wrbuf_lock);

  memcpy (info->wrbuf->text, msg, msg_len);
  info->wrbuf->type = (MQ_PRIO_MAX - msg_prio);

  ipcflag = (info->attr->mq_flags & O_NONBLOCK) ? IPC_NOWAIT : 0;
  sb2.sem_flg = ipcflag;

  /* check to see if max msgs are on queue */
  rc = semop (info->semid, &sb2, 1);

  if (rc == 0)
    rc = msgsnd (info->msgqid, info->wrbuf, msg_len, ipcflag);

  if (rc == 0)
    semop (info->semid, &sb3, 1);  /* increment number of reads */

  __lock_release (mq_wrbuf_lock);
  return rc;
}
      






/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <string.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

__LOCK_INIT(static, mq_rdbuf_lock);

ssize_t
mq_receive (mqd_t msgid, char *msg, size_t msg_len, unsigned int *msg_prio)
{
  struct libc_mq *info;
  struct sembuf sb2 = {2, 1, 0};
  struct sembuf sb3 = {3, -1, IPC_NOWAIT};
  struct sembuf sb5 = {5, 1, IPC_NOWAIT};
  ssize_t num_bytes;
  int ipcflag;

  info = __find_mq (msgid);

  if (info == NULL || (info->oflag & O_ACCMODE) == O_WRONLY)
    {
      errno = EBADF;
      return -1;
    }

  if (msg_len < info->attr->mq_msgsize)
    {
      errno = EMSGSIZE;
      return -1;
    }

  __lock_acquire (mq_rdbuf_lock);

  ipcflag = (info->attr->mq_flags & O_NONBLOCK) ? IPC_NOWAIT : 0;

  semop (info->semid, &sb5, 1); /* increase number of readers */
  num_bytes = msgrcv (info->msgqid, info->rdbuf, msg_len, -MQ_PRIO_MAX, ipcflag);
  sb5.sem_op = -1;
  semop (info->semid, &sb5, 1); /* decrease number of readers */

  if (num_bytes != (ssize_t)-1)
    {
      semop (info->semid, &sb2, 1); /* add one to messages left to write */
      semop (info->semid, &sb3, 1); /* subtract one from messages to read */
      memcpy (msg, info->rdbuf->text, num_bytes);
      if (msg_prio != NULL)
	*msg_prio = MQ_PRIO_MAX - info->rdbuf->type;
    }
  
  __lock_release (mq_rdbuf_lock);
  return num_bytes;
}
      






/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <string.h>

#include "internals.h"
#include <sys/lock.h>

#include "mqlocal.h"

static void *mq_notify_process (void *);

void
__cleanup_mq_notify (struct libc_mq *info)
{
  struct sembuf sb4 = {4, 1, 0};
  /* kill notification thread and allow other processes to set a notification */
  pthread_cancel ((pthread_t)info->th);
  semop (info->semid, &sb4, 1);
}
  
static void *
mq_notify_process (void *arg)
{
  struct libc_mq *info = (struct libc_mq *)arg;
  struct sembuf sb3[2] = {{3, 0, 0}, {5, 0, 0}};
  struct sembuf sb4 = {4, 1, 0};
  int rc;

  /* wait until queue is empty */
  while (!(rc = semop (info->semid, sb3, 1)) && errno == EINTR)
    /* empty */ ;

  if (!rc)
    {
      /* now wait until there are 0 readers and the queue has something in it */
      sb3[0].sem_op = -1;
      while (!(rc = semop (info->semid, sb3, 2)) && errno == EINTR)
	/* empty */ ;
      /* restore value since we have not actually performed a read */
      sb3[0].sem_op = 1;
      semop (info->semid, sb3, 1);
      /* perform desired notification - either run function in this thread or pass signal */
      if (!rc)
	{
	  if (info->sigevent->sigev_notify == SIGEV_SIGNAL)
	    raise (info->sigevent->sigev_signo);
	  else if (info->sigevent->sigev_notify == SIGEV_THREAD)
	    info->sigevent->sigev_notify_function (info->sigevent->sigev_value);
	  /* allow other processes to now mq_notify */
	  semop (info->semid, &sb4, 1);
	}
    }
  pthread_exit (NULL);
}

int
mq_notify (mqd_t msgid, const struct sigevent *notification)
{
  struct libc_mq *info;
  struct sembuf sb4 = {4, -1, IPC_NOWAIT};
  int rc;
  pthread_attr_t *attr = NULL;

  info = __find_mq (msgid);

  if (info == NULL)
    {
      errno = EBADF;
      return -1;
    }

  /* get notification lock */
  rc = semop (info->semid, &sb4, 1);

  if (rc == -1)
    {
      errno = EBUSY;
      return -1;
    }

  /* to get the notification running we use a pthread - if the user has requested
     an action in a pthread, we use the user's attributes when setting up the thread */
  info->sigevent = (struct sigevent *)notification;
  if (info->sigevent->sigev_notify == SIGEV_THREAD)
    attr = (pthread_attr_t *)info->sigevent->sigev_notify_attributes;
  rc = pthread_create ((pthread_t *)&info->th, attr, mq_notify_process, (void *)info);

  if (rc != 0)
    rc = -1;
  else
    info->cleanup_notify = &__cleanup_mq_notify;

  return rc;
}

      






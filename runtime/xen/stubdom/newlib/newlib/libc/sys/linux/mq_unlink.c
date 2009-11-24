/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <string.h>
#include <stdlib.h>
#include <machine/weakalias.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

int
mq_unlink (const char *name)
{
  int size;
  int saved_errno;
  char *real_name;
  char *ptr;
  int i, rc;
  int semid, msgqid;
  key_t key;
  
  /* ignore opening slash if present */
  if (*name == '/')
    ++name;  
  size = strlen(name);

  if ((real_name = (char *)malloc (size + sizeof(MSGQ_PREFIX))) == NULL)
    {
      errno = ENOSPC;
      return -1;
    }
  
  /* use given name to create shared memory file name - we convert any
     slashes to underscores so we don't have to create directories */
  memcpy (real_name, MSGQ_PREFIX, sizeof(MSGQ_PREFIX) - 1);
  memcpy (real_name + sizeof(MSGQ_PREFIX) - 1, name, size + 1);
  ptr = real_name + sizeof(MSGQ_PREFIX) - 1;
  for (i = 0; i < size; ++i)
    {
      if (*ptr == '/')
	*ptr = '_';
      ++ptr;
    }

  /* get key and then unlink shared memory file */
  if ((key = ftok(real_name, 255)) == (key_t)-1)
    return -1;

  rc = unlink (real_name);

  if (rc == 0)
    {
      /* try to remove semaphore and msg queues associated with shared memory file */
      saved_errno = errno;
      semid = semget (key, 6, 0);
      if (semid != -1)
	semctl (semid, 0, IPC_RMID);
      msgqid = msgget (key, 0);
      if (msgqid != -1)
	msgctl (msgqid, IPC_RMID, NULL);
      errno = saved_errno;
    }

  return rc;
}

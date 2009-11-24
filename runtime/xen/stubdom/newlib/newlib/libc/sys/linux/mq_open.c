/* Copyright 2002, Red Hat Inc. */

#include <mqueue.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <stdarg.h>
#include <machine/weakalias.h>
#define _LIBC 1
#include <sys/lock.h>
#undef _LIBC

#include "mqlocal.h"

#define	NHASH	32	          /* Num of hash lists, must be a power of 2 */
#define	LOCHASH(i)	((i)&(NHASH-1))

static long	mq_index;	/* Index of next entry */
static struct	libc_mq *mq_hash[NHASH];   /* Hash list heads for mqopen_infos */

__LOCK_INIT(static, mq_hash_lock);

mqd_t
mq_open (const char *name, int oflag, ...)
{
  MSG *wrbuf = NULL;
  MSG *rdbuf = NULL;
  int msgqid = -1;
  int rc = -1;
  int fd = -1;
  int semid = -1;
  int created = 0;
  key_t key = (key_t)-1;
  struct mq_attr *attr = (struct mq_attr *)MAP_FAILED;
  struct sembuf sb = {0, 0, 0};
  mode_t mode = 0;
  int size;
  int i, index, saved_errno;
  char *real_name;
  char *ptr;
  struct mq_attr *user_attr = NULL;
  struct libc_mq *info;
  union semun arg;
  
  /* ignore opening slash if present */
  if (*name == '/')
    ++name;  
  size = strlen(name);

  if ((real_name = (char *)malloc (size + sizeof(MSGQ_PREFIX))) == NULL ||
      (info = (struct libc_mq *)malloc (sizeof(struct libc_mq))) == NULL)
    {
      errno = ENOSPC;
      if (real_name)
	free (real_name);
      return (mqd_t)-1;
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

  /* open shared memory file based on msg queue open flags and then use memory
     file to create a unique key to use for semaphores, etc.. */
  if (oflag & O_CREAT)
    {
      va_list list;
      va_start (list, oflag);

      saved_errno = errno;
      mode = (mode_t)va_arg (list, int);
      user_attr = va_arg(list,struct mq_attr *);
      va_end (list);

      /* attempt to open the shared memory file for exclusive create so we know
	 whether we are the owners or not */
      fd = open (real_name, O_RDWR | O_CREAT | O_EXCL, mode);
      if (fd < 0 && (oflag & O_EXCL))
	{
	  /* we failed and the user wanted exclusive create */
	  free (real_name);
	  free (info);
	  return (mqd_t)-1;
	}
      errno = saved_errno;
      /* check if we created the file or not */
      if (fd >= 0)
        created = 1;
    }
	  
  if (fd < 0)
    fd = open (real_name, O_RDWR, 0);

  if (fd >= 0)
    key = ftok(real_name, 255);

  if (key != (key_t)-1)
    /* memory map the shared memory file so we have a global shared data area to use */
    attr = (struct mq_attr *)mmap (0, sizeof(struct mq_attr), PROT_READ | PROT_WRITE,
				   MAP_SHARED, fd, 0);
  
  if (attr != (struct mq_attr *)MAP_FAILED)
    {
      /* we need semaphores to prevent multi-process race conditions on the
	 shared storage which contains a shared structure.  The following
	 are the ones we need.
	 
	 0 = open semaphore
	 1 = number of opens
	 2 = number of writes left until queue is full
	 3 = number of reads available in queue
	 4 = notify semaphore 
	 5 = number of readers */
      arg.val = 0;
      /* make sure the creator of the shared memory file also is the creator of the
	 semaphores...this will ensure that it also creates the message queue */
      if (created)
	{
	  saved_errno = errno;
	  semid = semget (key, 6, IPC_CREAT | IPC_EXCL | mode);
	  errno = saved_errno;
	  /* now that we have created the semaphore, we should initialize it */
	  if (semid != -1)
	    semctl (semid, 0, SETVAL, arg);
	}
      else
	{
	  /* if we didn't create the shared memory file but have gotten to here, we want
	     to ensure we haven't gotten ahead of the creator temporarily so we will
	     loop until the semaphore exists.  This ensures that the creator will be the
	     one to create the message queue with the correct mode and we will be blocked
	     by the open semaphore 0.  We impose a time limit to ensure something terrible
	     hasn't gone wrong. */
	  struct timespec tms;
	  int i;

	  tms.tv_sec = 0;
	  tms.tv_nsec = 10000; /* 10 microseconds */
	  for (i = 0; i < 100; ++i)
	    {
	      if ((semid = semget (key, 6, 0)) != -1)
		break;
	      /* sleep in case we our a higher priority process */
	      nanosleep (&tms, NULL);
	    }
	}
    }

  if (semid != -1)
    {
      /* acquire main open semaphore if we didn't create it */
      if (!created)
	{
	  sb.sem_op = -1;
	  rc = semop (semid, &sb, 1);
	}
      else
	rc = 0; /* need this to continue below */
    }
      
  if (rc == 0)
    {
      if (created)
	{
	  /* the creator must get here first so the message queue will be created */
	  msgqid = msgget (key, IPC_CREAT | mode); 
	  if (msgqid >= 0)
	    {
	      /* we have created the message queue so check and set the attributes */
	      if ((wrbuf = (MSG *)malloc (user_attr->mq_msgsize + sizeof(int))) == NULL ||
		  (rdbuf = (MSG *)malloc (user_attr->mq_msgsize + sizeof(int))) == NULL ||
		  user_attr == NULL || user_attr->mq_msgsize <= 0 || user_attr->mq_maxmsg <= 0)
		{
		  /* we're out of space and we created the message queue so we should
		     try to remove it */
		  msgctl (msgqid, IPC_RMID, NULL);
		  msgqid = -1; /* allow clean up to occur below */
		  if (wrbuf && rdbuf)
		    errno = EINVAL;
		  else
		    errno = ENOSPC;
		}
	      else /* valid attributes */
		{
		  write (fd, user_attr, sizeof(struct mq_attr));
		  attr->mq_curmsgs = 0;
		  attr->mq_flags = oflag & O_NONBLOCK;
		  arg.val = 0;
		  semctl (semid, 1, SETVAL, arg); /* number of opens starts at 0 */
		  semctl (semid, 3, SETVAL, arg); /* number of reads available starts at 0 */
		  semctl (semid, 5, SETVAL, arg); /* number of readers starts at 0 */
		  arg.val = 1;
		  semctl (semid, 4, SETVAL, arg); /* notify semaphore */
		  arg.val = user_attr->mq_maxmsg;
		  semctl (semid, 2, SETVAL, arg); /* number of writes left starts at mq_maxmsg */
		}
	    }
	}
      else /* just open it */
        {
	  msgqid = msgget (key, 0);
	  wrbuf = (MSG *)malloc (attr->mq_msgsize + sizeof(int));
	  rdbuf = (MSG *)malloc (attr->mq_msgsize + sizeof(int));
        }
      
      /* release semaphore acquired earlier */
      sb.sem_op = 1;
      semop (semid, &sb, 1);
    }

  /* if we get here and we haven't got a message queue id, then we need to clean up 
     our mess and return failure */
  if (msgqid < 0)
    {
      if (fd >= 0)
	close (fd);
      if (attr != (struct mq_attr *)MAP_FAILED)
	munmap (attr, sizeof(struct mq_attr));
      if (created)
	{
	  unlink (real_name);
	  if (semid != -1)
	    semctl (semid, 0, IPC_RMID);
	}
      free (real_name);
      free (info);
      if (wrbuf)
	free (wrbuf);
      if (rdbuf)
	free (rdbuf);
      return (mqd_t)-1;
    }

  /* we are successful so register the message queue */

  /* up the count of msg queue opens */
  sb.sem_op = 1;
  sb.sem_num = 1;
  semop (semid, &sb, 1);

  /* success, translate into index into mq_info array */  
  __lock_acquire(mq_hash_lock);
  index = mq_index++;
  info->index = index;
  info->msgqid = msgqid;
  info->name = real_name;
  info->semid = semid;
  info->fd = fd;
  info->oflag = oflag;
  info->wrbuf = wrbuf;
  info->rdbuf = rdbuf;
  info->cleanup_notify = NULL;
  info->next = mq_hash[LOCHASH(index)];
  info->attr = attr;
  mq_hash[LOCHASH(index)] = info;
  __lock_release(mq_hash_lock);

  return (mqd_t)index;
}

struct libc_mq *
__find_mq (mqd_t mq)
{
  struct libc_mq *ptr;

  __lock_acquire(mq_hash_lock);

  ptr = mq_hash[LOCHASH((int)mq)];

  while (ptr)
    {
      if (ptr->index == (int)mq)
        break;
      ptr = ptr->next;
    }

  __lock_release(mq_hash_lock);

  return ptr;
}
      
void
__cleanup_mq (mqd_t mq)
{
  struct libc_mq *ptr;
  struct libc_mq *prev;
  int semid;
  struct sembuf sb = {0, 0, 0};

  __lock_acquire(mq_hash_lock);

  ptr = mq_hash[LOCHASH((int)mq)];
  prev = NULL;

  while (ptr)
    {
      if (ptr->index == (int)mq)
        break;
      prev = ptr;
      ptr = ptr->next;
    }

  if (ptr != NULL)
    {
      if (ptr->cleanup_notify != NULL)
	ptr->cleanup_notify (ptr);
      if (prev != NULL)
	prev->next = ptr->next;
      else
	mq_hash[LOCHASH((int)mq)] = NULL;
      munmap (ptr->attr, sizeof(struct mq_attr));
      close (ptr->fd);
      free (ptr->name);
      free (ptr->wrbuf);
      free (ptr->rdbuf);
      semid = ptr->semid;
      free (ptr);
      /* lower the count of msg queue opens */
      sb.sem_op = -1;
      sb.sem_num = 1;
      sb.sem_flg = IPC_NOWAIT;
      semop (semid, &sb, 1);
    }

  __lock_release(mq_hash_lock);
}






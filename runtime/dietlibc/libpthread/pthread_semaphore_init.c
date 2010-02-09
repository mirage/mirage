#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

int sem_init(sem_t*sem,int pshared,unsigned int value) {
  pthread_mutexattr_t attr={PTHREAD_MUTEX_RECURSIVE_NP};

  if (value>SEM_VALUE_MAX) { _errno_=EINVAL; return -1; }
  if (pshared) { _errno_=ENOSYS; return -1; }

  pthread_mutex_init(&(sem->lock),&attr);
  pthread_cond_init(&(sem->cond),0);
  sem->value=value;
  sem->magic=SEM_MAGIC;
  return 0;
}


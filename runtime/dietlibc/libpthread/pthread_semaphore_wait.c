#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

int sem_wait(sem_t*sem) {
  int ret=0;
  _pthread_descr this;

  if (sem->magic!=SEM_MAGIC) { _errno_=EINVAL; return -1; }

  this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);

  if ((ret=pthread_mutex_lock(&sem->lock))) { _errno_=ret; ret=-1; }
  else {
    while (sem->value==0) { pthread_cond_wait(&sem->cond,&sem->lock); }
    sem->value--;
  }
  pthread_mutex_unlock(&sem->lock);

  __NO_ASYNC_CANCEL_END_(this);

  return ret;
}

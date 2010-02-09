#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

int sem_trywait(sem_t*sem) {
  int ret;
  _pthread_descr this;

  if (sem->magic!=SEM_MAGIC) { _errno_=EINVAL; return -1; }

  this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);

  if ((ret=pthread_mutex_lock(&(sem->lock)))) { _errno_=ret; ret=-1; }
  else if (sem->value==0) {
    _errno_=EAGAIN;
    ret=-1;
  } else {
    sem->value--;
    ret=0;
  }
  pthread_mutex_unlock(&(sem->lock));

  __NO_ASYNC_CANCEL_END_(this);

  return ret;
}

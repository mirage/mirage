#include <unistd.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

/* ThreadManager Function / NO_ASYNC_CANCEL
 * this is a pthread_cond_signal + semaphore handling */

/* FIXME: is the pthread_mutex_lock(&sem->lock); and unlock needed ? */
static int __MGR_sem_post(sem_t*sem) {
  int ret=0;
  if (sem->value==0) {
    pthread_cond_t*cond=&sem->cond;
    LOCK(cond);
    if (cond->wait_chain) __thread_restart(cond->wait_chain);
    UNLOCK(cond);
  }
  if (sem->value<SEM_VALUE_MAX) sem->value++;
  else { _errno_=ERANGE; ret=-1; }
  return ret;
}

int sem_post(sem_t*sem) {
  int ret=0;
  _pthread_descr this;

  if (sem->magic!=SEM_MAGIC) { _errno_=EINVAL; return -1; }

  this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);

  if ((ret=pthread_mutex_lock(&sem->lock))) { _errno_=ret; ret=-1; }
  else if (sem->lock.count>1) {
    /* ok... we are in a semaphor handling and a signal handler.
     * now we want to  send a post... let the manager do this for us :) */
    __thread_send_manager((MGR_func)__MGR_sem_post,sem);
  }
  else ret=__MGR_sem_post(sem);
  pthread_mutex_unlock(&sem->lock);

  __NO_ASYNC_CANCEL_END_(this);

  return ret;
}

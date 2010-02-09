#include <unistd.h>
#include <sched.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

/* will never return EINVAL ! */

static int __thread_mutex_lock(pthread_mutex_t*mutex,_pthread_descr this) {
  if (mutex->owner!=this) {
    /* wait for mutex to free */
    LOCK(mutex);
    mutex->owner=this;
    mutex->count=0;
  }
  else if (mutex->kind==PTHREAD_MUTEX_ERRORCHECK_NP) return EDEADLK;
  if (mutex->kind==PTHREAD_MUTEX_RECURSIVE_NP) ++(mutex->count);
  return 0;
}
int __pthread_mutex_lock(pthread_mutex_t*mutex,_pthread_descr this)
__attribute__((alias("__thread_mutex_lock")));

int pthread_mutex_lock(pthread_mutex_t*mutex) {
  return __thread_mutex_lock(mutex,__thread_self());
}

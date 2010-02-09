#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_mutexattr_setkind_np(pthread_mutexattr_t*attr,int kind) {
  if ((kind==PTHREAD_MUTEX_FAST_NP)||(kind==PTHREAD_MUTEX_RECURSIVE_NP)||
      (kind==PTHREAD_MUTEX_ERRORCHECK_NP)) {
    attr->__mutexkind=kind;
    return 0;
  }
  return EINVAL;
}

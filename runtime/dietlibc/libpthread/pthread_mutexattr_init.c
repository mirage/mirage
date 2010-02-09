#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_mutexattr_init(pthread_mutexattr_t*attr) {
  attr->__mutexkind=PTHREAD_MUTEX_FAST_NP;
  return 0;
}
int pthread_mutexattr_destroy(pthread_mutexattr_t*attr) __attribute__((alias ("pthread_mutexattr_init")));

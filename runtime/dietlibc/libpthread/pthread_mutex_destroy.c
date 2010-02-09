#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_mutex_destroy(pthread_mutex_t*mutex) {
  if ((mutex->owner)||(mutex->lock.__spinlock!=PTHREAD_SPIN_UNLOCKED)) {
    return EBUSY;
  }
  return 0;
}

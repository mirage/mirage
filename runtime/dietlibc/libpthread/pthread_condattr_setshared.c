#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_condattr_setpshared(pthread_condattr_t*attr,int pshared) {
  if (0) { attr=0; }
  if ((pshared!=PTHREAD_PROCESS_PRIVATE) && (pshared!=PTHREAD_PROCESS_SHARED))
    return EINVAL;
  if (pshared!=PTHREAD_PROCESS_PRIVATE)
    return ENOSYS;
  return 0;
}


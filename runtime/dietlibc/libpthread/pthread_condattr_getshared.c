#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_condattr_getpshared(const pthread_condattr_t*attr,int*pshared) {
  if (0) { attr=0; }
  *pshared=PTHREAD_PROCESS_PRIVATE;
  return 0;
}


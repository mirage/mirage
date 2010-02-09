#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_cond_init(pthread_cond_t*cond,pthread_condattr_t*cond_attr) {
  if (0) { cond_attr=0; }
  memset(cond,0,sizeof(pthread_cond_t));
  cond->lock.__spinlock=PTHREAD_SPIN_UNLOCKED;
  return 0;
}

#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_setstacksize(pthread_attr_t*attr,size_t stacksize) {
  if (stacksize>PTHREAD_STACK_MAXSIZE) return EINVAL;
  if (stacksize<PTHREAD_STACK_MINSIZE) return EINVAL;
  attr->__stacksize=stacksize;
  return 0;
}

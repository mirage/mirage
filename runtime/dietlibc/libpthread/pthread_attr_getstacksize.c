#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_getstacksize(const pthread_attr_t*attr,size_t*stacksize) {
  *stacksize=attr->__stacksize;
  return 0;
}


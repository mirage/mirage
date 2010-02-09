#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_getdetachstate(const pthread_attr_t*attr,int*detachstate) {
  *detachstate=attr->__detachstate;
  return 0;
}


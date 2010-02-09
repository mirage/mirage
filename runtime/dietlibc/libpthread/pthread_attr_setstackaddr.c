#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_setstackaddr(pthread_attr_t*attr,void*stack) {
  attr->__stackaddr=stack;
  return 0;
}

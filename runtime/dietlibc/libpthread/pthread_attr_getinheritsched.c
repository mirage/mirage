#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_getinheritsched(const pthread_attr_t*attr,int*inherit) {
  *inherit=attr->__inheritsched;
  return 0;
}

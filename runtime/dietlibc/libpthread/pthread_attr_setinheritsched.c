#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_setinheritsched(pthread_attr_t*attr,int inherit) {
  if ((inherit==PTHREAD_INHERIT_SCHED) ||
      (inherit==PTHREAD_EXPLICIT_SCHED)) {
    attr->__inheritsched=inherit;
    return 0;
  }
  return EINVAL;
}

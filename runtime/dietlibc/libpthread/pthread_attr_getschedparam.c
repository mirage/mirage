#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_getschedparam(const pthread_attr_t*attr,struct sched_param*param) {
  param->sched_priority=attr->__schedparam.sched_priority;
  return 0;
}

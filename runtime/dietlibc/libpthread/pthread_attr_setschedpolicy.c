#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_setschedpolicy(pthread_attr_t*attr,int policy) {
  if (policy==SCHED_OTHER) {
    attr->__inheritsched=PTHREAD_EXPLICIT_SCHED;
    attr->__schedpolicy=policy;
    return 0;
  }
  if ((policy==SCHED_FIFO)||(policy==SCHED_RR)) {
    if (geteuid()==0) {
      attr->__inheritsched=PTHREAD_EXPLICIT_SCHED;
      attr->__schedpolicy=policy;
      return 0;
    }
    return ENOTSUP;
  }
  else
    return EINVAL;
}

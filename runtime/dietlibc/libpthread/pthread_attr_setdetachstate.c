#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_attr_setdetachstate(pthread_attr_t*attr,int detachstate) {
  if ((detachstate == PTHREAD_CREATE_JOINABLE) ||
      (detachstate == PTHREAD_CREATE_DETACHED)) {
    attr->__detachstate=detachstate;
    return 0;
  }
  return EINVAL;
}

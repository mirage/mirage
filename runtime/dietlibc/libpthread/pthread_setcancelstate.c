#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_setcancelstate(int state,int*oldstate) {
  if ((state==PTHREAD_CANCEL_ENABLE)||(state==PTHREAD_CANCEL_DISABLE)) {
    _pthread_descr this=__thread_self();
    if (oldstate) *oldstate=this->cancelstate;
    this->cancelstate=state;
    return 0;
  }
  return EINVAL;
}

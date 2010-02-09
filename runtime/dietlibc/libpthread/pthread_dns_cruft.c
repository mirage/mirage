#include "thread_internal.h"

#ifdef PTHREAD_HANDLE_DNS_CORRECT

int *__h_errno_location(void) {
  _pthread_descr td=__thread_self();
  return &(td->h_errno);
}

struct res_state*__res_location(void) {
  _pthread_descr td=__thread_self();
  return &(td->__res);
}

#endif

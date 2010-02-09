#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int sigsuspend(const sigset_t *mask) {
  __TEST_CANCEL();
  return __libc_sigsuspend(mask);
}

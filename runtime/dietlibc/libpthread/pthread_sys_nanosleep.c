#include <time.h>
#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int nanosleep(const struct timespec *req, struct timespec *rem) {
  __TEST_CANCEL();
  return __libc_nanosleep(req,rem);
}

#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int __pthread_open(const char *pathname, int flags, mode_t mode);
int __pthread_open(const char *pathname, int flags, mode_t mode) {
  __TEST_CANCEL();
  return __libc_open(pathname,flags,mode);
}

int open(const char *pathname, int flags, ...) __attribute__((alias("__pthread_open")));

#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int creat(const char *pathname, mode_t mode) {
  __TEST_CANCEL();
  return __libc_creat(pathname,mode);
}

#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int fsync(int fd) {
  __TEST_CANCEL();
  return __libc_fsync(fd);
}

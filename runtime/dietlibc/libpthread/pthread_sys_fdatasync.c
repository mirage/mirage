#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int fdatasync(int fd) {
  __TEST_CANCEL();
  return __libc_fdatasync(fd);
}

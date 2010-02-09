#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int fcntl(int fd, int cmd, void *arg);
int fcntl(int fd, int cmd, void *arg) {
  __TEST_CANCEL();
  return __libc_fcntl(fd,cmd,arg);
}

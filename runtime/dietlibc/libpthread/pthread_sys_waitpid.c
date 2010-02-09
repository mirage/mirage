#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

#include <sys/wait.h>

pid_t waitpid(pid_t pid, int *status, int options) {
  __TEST_CANCEL();
  return __libc_waitpid(pid,status,options);
}

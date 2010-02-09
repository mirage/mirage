#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int pause() {
  __TEST_CANCEL();
  return __libc_pause();
}

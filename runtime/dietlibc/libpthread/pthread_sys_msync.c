#include <unistd.h>
#include <sys/mman.h>

#include <pthread.h>
#include "thread_internal.h"

int msync (void*addr,size_t len,int flags) {
  __TEST_CANCEL();
  return __libc_msync(addr,len,flags);
}

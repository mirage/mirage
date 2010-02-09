#include "syscalls.h"

#ifdef __NR_inotify_init
syscall(inotify_init,inotify_init)
#endif

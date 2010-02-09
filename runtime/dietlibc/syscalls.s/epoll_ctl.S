#include "syscalls.h"

#ifdef __NR_epoll_ctl
syscall(epoll_ctl,epoll_ctl)
#endif

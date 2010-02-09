#include "syscalls.h"

#ifdef __NR_epoll_create
syscall(epoll_create,epoll_create)
#endif

#ifndef _POSIX_SELECT_H
#define _POSIX_SELECT_H

#include <sys/time.h>
#include <lwip/sockets.h>
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);

#endif /* _POSIX_SELECT_H */

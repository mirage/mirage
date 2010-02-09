#ifndef _POSIX_SYS_SOCKET_H_
#define _POSIX_SYS_SOCKET_H_

#include <fcntl.h>
#include <lwip/sockets.h>

int accept(int s, struct sockaddr *addr, socklen_t *addrlen);
int bind(int s, struct sockaddr *name, socklen_t namelen);
int shutdown(int s, int how);
int getpeername (int s, struct sockaddr *name, socklen_t *namelen);
int getsockname (int s, struct sockaddr *name, socklen_t *namelen);
int getsockopt (int s, int level, int optname, void *optval, socklen_t *optlen);
int setsockopt (int s, int level, int optname, const void *optval, socklen_t optlen);
int close(int s);
int connect(int s, struct sockaddr *name, socklen_t namelen);
int listen(int s, int backlog);
int recv(int s, void *mem, int len, unsigned int flags);
//int read(int s, void *mem, int len);
int recvfrom(int s, void *mem, int len, unsigned int flags,
      struct sockaddr *from, socklen_t *fromlen);
int send(int s, void *dataptr, int size, unsigned int flags);
int sendto(int s, void *dataptr, int size, unsigned int flags,
    struct sockaddr *to, socklen_t tolen);
int socket(int domain, int type, int protocol);
//int write(int s, void *dataptr, int size);
int select(int maxfdp1, fd_set *readset, fd_set *writeset, fd_set *exceptset,
                struct timeval *timeout);
//int ioctl(int s, long cmd, void *argp);
int getsockname(int s, struct sockaddr *name, socklen_t *namelen);

#endif /* _POSIX_SYS_SOCKET_H_ */

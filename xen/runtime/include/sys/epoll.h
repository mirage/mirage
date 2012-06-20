#ifndef _SYS_EPOLL_H
#define _SYS_EPOLL_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <poll.h>
#include <signal.h>

__BEGIN_DECLS

/* Valid opcodes ( "op" parameter ) to issue to epoll_ctl() */
#define EPOLL_CTL_ADD 1	/* Add a file decriptor to the interface */
#define EPOLL_CTL_DEL 2	/* Remove a file decriptor from the interface */
#define EPOLL_CTL_MOD 3	/* Change file decriptor epoll_event structure */

enum EPOLL_EVENTS {
	EPOLLIN = 0x001,
#define EPOLLIN EPOLLIN
	EPOLLPRI = 0x002,
#define EPOLLPRI EPOLLPRI
	EPOLLOUT = 0x004,
#define EPOLLOUT EPOLLOUT

#ifdef _XOPEN_SOURCE
	EPOLLRDNORM = 0x040,
#define EPOLLRDNORM EPOLLRDNORM
	EPOLLRDBAND = 0x080,
#define EPOLLRDBAND EPOLLRDBAND
	EPOLLWRNORM = 0x100,
#define EPOLLWRNORM EPOLLWRNORM
	EPOLLWRBAND = 0x200,
#define EPOLLWRBAND EPOLLWRBAND
#endif /* #ifdef __USE_XOPEN */

#ifdef _GNU_SOURCE
	EPOLLMSG = 0x400,
#define EPOLLMSG EPOLLMSG
#endif /* #ifdef __USE_GNU */

	EPOLLERR = 0x008,
#define EPOLLERR EPOLLERR
	EPOLLHUP = 0x010,
#define EPOLLHUP EPOLLHUP

	EPOLLET = (1<<31)
#define EPOLLET EPOLLET
};

typedef union epoll_data {
  void *ptr;
  int fd;
  uint32_t u32;
  uint64_t u64;
} epoll_data_t;

struct epoll_event {
  uint32_t events;
  epoll_data_t data;
}
#ifdef __x86_64__
__attribute__((__packed__))
#endif
;

int epoll_create(int size) __THROW;
int epoll_ctl(int epfd, int op, int fd, struct epoll_event* event) __THROW;
int epoll_wait(int epfd, struct epoll_event *events, int maxevents,
	       int timeout) __THROW;
int epoll_pwait(int epfd, struct epoll_event *events, int maxevents,
	       int timeout, const sigset_t* sigmask) __THROW;

__END_DECLS

#endif

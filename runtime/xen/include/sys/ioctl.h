#ifndef _IOCTL_H
#define _IOCTL_H

#include <sys/cdefs.h>

__BEGIN_DECLS

#if defined(__i386__) || defined(__x86_64__) || defined(__ia64__)
#include <sys/i386-ioctl.h>
#elif defined(__alpha__)
#include <sys/alpha-ioctl.h>
#elif defined(__arm__)
#include <sys/arm-ioctl.h>
#elif defined(__sparc__)
#include <sys/sparc-ioctl.h>
#elif defined(__mips__)
#include <sys/mips-ioctl.h>
#elif defined(__powerpc__) || defined(__powerpc64__)
#include <sys/ppc-ioctl.h>
#elif defined(__s390__)
#include <sys/s390-ioctl.h>
#elif defined(__hppa__)
#include <sys/hppa-ioctl.h>
#endif

/* used for /dev/epoll */
#define EP_ALLOC	_IOR('P', 1, int)
#define EP_POLL		_IOWR('P', 2, struct evpoll)
#define EP_FREE		_IO('P', 3)
#define EP_ISPOLLED	_IOWR('P', 4, struct pollfd)

int ioctl(int d, long int request, ...) __THROW;

__END_DECLS

#endif

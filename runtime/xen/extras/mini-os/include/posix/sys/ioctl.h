#ifndef _POSIX_SYS_IOCTL_H
#define _POSIX_SYS_IOCTL_H

int ioctl(int fd, int request, ...);

#define _IOC_NONE 0
#define _IOC_WRITE 1
#define _IOC_READ 2

#define _IOC(rw, class, n, size) \
    	(((rw   ) << 30) | \
	 ((class) << 22) | \
	 ((n    ) << 14) | \
	 ((size ) << 0))

#endif /* _POSIX_SYS_IOCTL_H */

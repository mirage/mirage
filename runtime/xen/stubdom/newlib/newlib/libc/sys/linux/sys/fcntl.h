/* libc/sys/linux/sys/fcntl.h - File access */

/* Written 2000 by Werner Almesberger */


#ifndef _SYS_FCNTL_H
#define _SYS_FCNTL_H

#include <sys/types.h>
#include <linux/fcntl.h>

/* --- redundant stuff below --- */

#include <_ansi.h>

extern int creat _PARAMS ((const char *, mode_t));
extern int _open _PARAMS ((const char *, int, ...));

#ifdef __KERNEL_PROTOTYPES
extern int open(const char *pathname, int flags, mode_t mode);
extern int fcntl(int fd, int cmd, long arg);
#else
extern int open _PARAMS ((const char *, int, ...));
extern int fcntl _PARAMS ((int, int, ...));
#endif

extern int _fcntl _PARAMS ((int, int, ...));

#endif

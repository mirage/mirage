/* libc/sys/linux/sys/file.h - BSD compatibility */

/* Written 2000 by Werner Almesberger */


#ifndef _SYS_FILE_H
#define _SYS_FILE_H

#include <sys/fcntl.h>

int flock(int fd,int operation);

#endif

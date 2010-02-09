#ifndef _POSIX_SYS_STAT_H
#define _POSIX_SYS_STAT_H

#include_next <sys/stat.h>
int fstat(int fd, struct stat *buf) asm("fstat64");

#endif /* _POSIX_SYS_STAT_H */

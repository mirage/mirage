#ifndef _POSIX_UNISTD_H
#define _POSIX_UNISTD_H

#include_next <unistd.h>

uid_t getuid(void);
uid_t geteuid(void);
gid_t getgid(void);
gid_t getegid(void);
int gethostname(char *name, size_t namelen);
size_t getpagesize(void);
int ftruncate(int fd, off_t length);
int lockf(int fd, int cmd, off_t len);
int nice(int inc);

#endif /* _POSIX_UNISTD_H */

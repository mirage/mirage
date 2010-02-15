#ifndef _I386_FCNTL_H
#define _I386_FCNTL_H

#include_next <fcntl.h>

int open(const char *path, int flags, ...) asm("open64");
int fcntl(int fd, int cmd, ...);

#endif

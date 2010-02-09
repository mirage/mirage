#ifndef _SYS_FILE_H
#define _SYS_FILE_H

#include <sys/cdefs.h>
#include <fcntl.h>

__BEGIN_DECLS

extern int fcntl(int fd, int cmd, ...) __THROW;
extern int flock(int fd, int operation) __THROW;

__END_DECLS

#endif	/* _SYS_FILE_H */

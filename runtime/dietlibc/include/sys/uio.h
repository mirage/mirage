#ifndef _SYS_UIO
#define _SYS_UIO 1

#include <sys/socket.h>

__BEGIN_DECLS

/* I have no idea why susv3 specifies count as int instead of size_t */
ssize_t readv(int filedes, const struct iovec *vector, int count);
ssize_t writev(int filedes, const struct iovec *vector, int count);

__END_DECLS

#endif

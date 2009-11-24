#ifndef _SYS_FEATURES_H
#define _SYS_FEATURES_H

#include <bits/posix_opt.h>

/* We do not support asynchronous I/O.  */
#undef _POSIX_ASYNCHRONOUS_IO
#undef _POSIX_ASYNC_IO
#undef _LFS_ASYNCHRONOUS_IO
#undef _LFS64_ASYNCHRONOUS_IO

/* POSIX message queues are supported.  */
#undef	_POSIX_MESSAGE_PASSING
#define	_POSIX_MESSAGE_PASSING 1

#endif /* _SYS_FEATURES_H */

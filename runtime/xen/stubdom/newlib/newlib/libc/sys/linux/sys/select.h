#ifndef _SYS_SELECT_H
#define _SYS_SELECT_H	1

#include <sys/types.h>
#include <bits/sigset.h>
#include <time.h>

extern int select (int __nfds, fd_set *__restrict __readfds,
		   fd_set *__restrict __writefds,
		   fd_set *__restrict __exceptfds,
		   struct timeval *__restrict __timeout) __THROW;

#endif /* sys/select.h */

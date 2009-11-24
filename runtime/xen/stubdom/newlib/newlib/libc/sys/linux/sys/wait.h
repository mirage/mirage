/* libc/sys/linux/sys/wait.h - Wait for children */

/* Written 2000 by Werner Almesberger */


#ifndef _SYS_WAIT_H
#define _SYS_WAIT_H

#include <linux/wait.h>

#define WIFEXITED(status)	(!WTERMSIG(status))
#define WEXITSTATUS(status)	(((status) >> 8) & 0xff)
#define WIFSIGNALED(status)	(!WIFSTOPPED(status) && !WIFEXITED(status))
#define WTERMSIG(status)	((status ) & 0x7f)
#define WIFSTOPPED(status)	(((status) & 0xff) == 0x7f)
#define WSTOPSIG(status)	WEXITSTATUS(status)

#ifndef _POSIX_SOURCE
#define WCOREDUMP(status) 	((status) & 0x80)
#endif

/* --- redundant stuff below --- */

#include <_ansi.h>
#include <sys/types.h>

pid_t wait (int *);
pid_t waitpid (pid_t, int *, int);

pid_t _wait (int *);


#ifndef _POSIX_SOURCE
#include <sys/resource.h>

pid_t wait3(int *status,int options,struct rusage *rusage);
pid_t wait4(pid_t pid,int *status,int options,struct rusage *rusage);
#endif

#endif

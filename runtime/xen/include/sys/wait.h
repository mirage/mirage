#ifndef _SYS_WAIT_H
#define _SYS_WAIT_H

#include <sys/cdefs.h>
#include <sys/resource.h>

__BEGIN_DECLS

#define WNOHANG		0x00000001
#define WUNTRACED	0x00000002

#define __WNOTHREAD	0x20000000	/* Don't wait on children of other threads in this group */
#define __WALL		0x40000000	/* Wait on all children, regardless of type */
#define __WCLONE	0x80000000	/* Wait only on non-SIGCHLD children */

/* If WIFEXITED(STATUS), the low-order 8 bits of the status.  */
#define __WEXITSTATUS(status)	(((status) & 0xff00) >> 8)
#define WEXITSTATUS __WEXITSTATUS

/* If WIFSIGNALED(STATUS), the terminating signal.  */
#define __WTERMSIG(status)	((status) & 0x7f)
#define WTERMSIG __WTERMSIG

/* If WIFSTOPPED(STATUS), the signal that stopped the child.  */
#define __WSTOPSIG(status)	__WEXITSTATUS(status)
#define WSTOPSIG __WSTOPSIG

/* Nonzero if STATUS indicates normal termination.  */
#define WIFEXITED(status)	(__WTERMSIG(status) == 0)

/* Nonzero if STATUS indicates termination by a signal.  */
#define WIFSIGNALED(status)	(!WIFSTOPPED(status) && !WIFEXITED(status))

/* Nonzero if STATUS indicates the child is stopped.  */
#define WIFSTOPPED(status)	(((status) & 0xff) == 0x7f)

/* Nonzero if STATUS indicates the child dumped core. */
#define WCOREDUMP(status) ((status) & 0x80)

#ifdef _BSD_SOURCE
#define W_STOPCODE(sig) ((sig) << 8 | 0x7f)
#endif

pid_t wait(int *status) __THROW;
pid_t waitpid(pid_t pid, int *status, int options) __THROW;

pid_t wait3(int *status, int options, struct rusage *rusage) __THROW;

pid_t wait4(pid_t pid, int *status, int options, struct rusage *rusage) __THROW;

typedef enum {
  P_ALL,		/* Wait for any child.  */
  P_PID,		/* Wait for specified process.  */
  P_PGID		/* Wait for members of process group.  */
} idtype_t;

int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);

__END_DECLS

#endif

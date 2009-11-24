/* This file is to be kept in sync (well, reasonably so, it's quite
   different) with newlib/libc/include/sys/signal.h on which it is
   based, except values used or returned by syscalls must be those of
   the Linux/CRIS kernel.  */

/* sys/signal.h */

#ifndef _SYS_SIGNAL_H
#define _SYS_SIGNAL_H
#ifdef __cplusplus
extern "C" {
#endif

#include "_ansi.h"

typedef unsigned long sigset_t;

/* Adjusted to linux, has unused sa_restorer field and unsigned long
   sa_flags; relatively unimportant though.  */
/* Type of a signal handler.  */
typedef void (*__sighandler_t)(int);

/* The type used in newlib sources.  */
typedef __sighandler_t _sig_func_ptr;

struct sigaction {
	__sighandler_t sa_handler;
	sigset_t sa_mask;
	unsigned long sa_flags;
	void (*sa_restorer)(void);
};

/* Adjusted to glibc; other values.  */
#define SA_NOCLDSTOP 1	/* only value supported now for sa_flags */
#define SIG_SETMASK 2	/* set mask with sigprocmask() */
#define SIG_BLOCK 0	/* set of signals to block */
#define SIG_UNBLOCK 1	/* set of signals to, well, unblock */

/* These depend upon the type of sigset_t, which right now
   is always a long.. They're in the POSIX namespace, but
   are not ANSI. */
#define sigaddset(what,sig) (*(what) |= (1<<(sig)))
#define sigemptyset(what)   (*(what) = 0)

int sigprocmask (int __how, const sigset_t *__a, sigset_t *__b);

#define SIGHUP		 1
#define SIGINT		 2
#define SIGQUIT		 3
#define SIGILL		 4
#define SIGTRAP		 5
#define SIGABRT		 6
#define SIGIOT		 6
#define SIGBUS		 7
#define SIGFPE		 8
#define SIGKILL		 9
#define SIGUSR1		10
#define SIGSEGV		11
#define SIGUSR2		12
#define SIGPIPE		13
#define SIGALRM		14
#define SIGTERM		15
#define SIGSTKFLT	16
#define SIGCHLD		17
#define SIGCONT		18
#define SIGSTOP		19
#define SIGTSTP		20
#define SIGTTIN		21
#define SIGTTOU		22
#define SIGURG		23
#define SIGXCPU		24
#define SIGXFSZ		25
#define SIGVTALRM	26
#define SIGPROF		27
#define SIGWINCH	28
#define SIGIO		29
#define SIGPOLL		SIGIO
#define SIGPWR		30
#define	NSIG 31

#ifdef __cplusplus
}
#endif
#ifndef _SIGNAL_H_
/* Some applications take advantage of the fact that <sys/signal.h>
 * and <signal.h> are equivalent in glibc.  Allow for that here.  */
#include <signal.h>
#endif
#endif /* _SYS_SIGNAL_H */

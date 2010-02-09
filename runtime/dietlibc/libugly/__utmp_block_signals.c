#include <signal.h>

/* 
 * Block a bunch of signals.  Call with a sigset_t pointer into which
 * the old signal set is placed.  On error (which should never happen),
 * returns NULL, otherwise returns oldset.
 */

sigset_t *__utmp_block_signals (sigset_t *oldset);

sigset_t *
__utmp_block_signals (sigset_t *oldset)
{
    sigset_t blockset;

    /* There are actually more signals to block than not, so just start
     * with everything */
    sigfillset (&blockset);

    /* Don't try to block program error signals */

    /* Unconditionally defined signals */
    sigdelset (&blockset, SIGILL);
    sigdelset (&blockset, SIGTRAP);
    sigdelset (&blockset, SIGABRT);
    sigdelset (&blockset, SIGIOT);  /* Yeah, right */
    sigdelset (&blockset, SIGFPE);
    sigdelset (&blockset, SIGSEGV);

    /* Others.  FIXME - This list may need to be expanded. */
#ifdef SIGBUS
    sigdelset (&blockset, SIGBUS);
#endif
#ifdef SIGEMT
    sigdelset (&blockset, SIGEMT);
#endif
#ifdef SIGSYS
    sigdelset (&blockset, SIGSYS);
#endif

    if (sigprocmask (SIG_BLOCK, &blockset, oldset) < 0)
	oldset = (sigset_t *)0;

    return oldset;
}

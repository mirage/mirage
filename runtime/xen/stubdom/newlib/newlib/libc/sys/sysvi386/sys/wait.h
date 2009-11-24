#ifndef _WAIT_H
# define _WAIT_H

# define WNOHANG 1
# define WUNTRACED 2

/*
 * Unlike the atrocity that BSD ended up using, we do not have a "union
 * wait," although I could probably implement one.  Given the code I
 * sometimes end up porting, it might be a good thing.  Anyway, the
 * format of a stat thingy, filled in by the wait*() routines, is:
 * struct {
 *    int filler:16;
 *    union {
 *        struct stopped {
 *            int signo:8;
 *            int o177:8;	// will be 0177 
 *        };
 *        struct exited {
 *            int retval:8;
 *            int zero:8;	// 0, obviously 8-)
 *        };
 *        struct termed {
 *            int zero:8;	// zeroes
 *            int corep:1;	// was there a core file?
 *            int signo:7;	// what?!  Only 127 signals?!
 *        };
 *        int value:16;
 *     };
 * };
 *
 * Braver souls than I can turn that into a union wait, if desired.  Ick.
 */

# define WIFEXITED(val)	((val)&0xff)
# define WEXITSTATUS(val)	(((val)>>8)&0xff)
# define WIFSIGNALED(val)	((val) && !((val)&0xff))
# define WTERMSIG(val)	(((val)>>8)&0x7f)
# define WIFSTOPPED(val) (((val)&0xff)==0177)
# define WSTOPSIG(val)	(((val)>>8)&0xff)
#endif	/* _SYS_WAIT_H */


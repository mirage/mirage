#ifndef _PTY_H
#define _PTY_H

#include <sys/cdefs.h>
#include <termios.h>

__BEGIN_DECLS

/* Create pseudo tty master slave pair with NAME and set terminal
 *    attributes according to TERMP and WINP and return handles for both
 *       ends in AMASTER and ASLAVE.  */
extern int openpty (int *__amaster, int *__aslave, char *__name, struct
		    termios *__termp, struct winsize *__winp) __THROW;

__END_DECLS

#endif

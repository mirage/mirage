/* libc/sys/linux/sys/termios.h - Terminal control definitions */

/* Written 2000 by Werner Almesberger */


#ifndef _SYS_TERMIOS_H
#define _SYS_TERMIOS_H

#include <linux/termios.h>
#include <machine/termios.h>

/* grr, this shouldn't have to be here */

int tcgetattr(int fd,struct termios *termios_p);
int tcsetattr(int fd,int optional_actions,const struct termios *termios_p);

#endif

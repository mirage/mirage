/******************************************************
  Copyright (C) 2001, 2002 Thomas M. Ogrisegg

   This is free software. You can redistribute and modify
   it under the terms of the GNU General Public License.

   This file is part of the profiling support for dietlibc

   profil (3) generic implementation 

 *************************************************************/

#include <asm/sigcontext.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>

#define SHORT_SIZE sizeof (short)
#define MAX_SHORT 65536

#ifdef DEBUG
# include <stdio.h>
# define debug printf
#else
# define debug
#endif

#ifndef u_short
# define u_short unsigned short
#endif

#ifndef u_int
# define u_int unsigned int
#endif

static unsigned short *buffer = NULL;
static size_t maxhits  = 0;
static unsigned long low_pc = 0;
static unsigned long pscale = 0;

/* profiler - helper function for profil(3) */
static void
profiler (int signal, struct sigcontext ctx)
{
	size_t s = PC(ctx)-low_pc;
	(void)signal;
	if ((PC(ctx)) < low_pc) return;
	s >>= 1;
	if (s < maxhits)
		++buffer[s];
}

/* profil(3) - start or stop the profiling timer */
int
profil (u_short *buf, size_t bufsiz, size_t offset, u_int scale)
{
	struct itimerval itv = { { 0, 1 }, { 0, 1 } };
	struct sigaction sa;
	if (!buf) {
		sigaction (SIGPROF, NULL, NULL);
		setitimer (ITIMER_PROF, NULL, NULL);
		return (0);
	}
	sa.sa_handler = (sighandler_t)&profiler;
	sa.sa_flags   = SA_RESTART;
	sigfillset (&sa.sa_mask);
	sigaction (SIGPROF, &sa, NULL);
	pscale = scale;
	buffer = buf;
	low_pc = offset;
	maxhits = bufsiz/SHORT_SIZE;

	return (setitimer (ITIMER_PROF, &itv, &itv));
}

#ifndef _POSIX_SIGNAL_H
#define _POSIX_SIGNAL_H

#include_next <signal.h>

int sigaction(int signum, const struct sigaction * __restrict,
              struct sigaction * __restrict);

#endif


/* libc/posix/sleep.c - sleep function */

/* Written 2000 by Werner Almesberger */

#ifdef HAVE_NANOSLEEP

#include <errno.h>
#include <time.h>
#include <unistd.h>

unsigned sleep(unsigned seconds)
{
    struct timespec ts;

    ts.tv_sec = seconds;
    ts.tv_nsec = 0;
    if (!nanosleep(&ts,&ts)) return 0;
    if (errno == EINTR) return ts.tv_sec;
    return -1;
}

#endif

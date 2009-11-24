/* Copied from libc/posix/usleep.c, removed the check for HAVE_NANOSLEEP */

/* Written 2002 by Jeff Johnston */

#include <errno.h>
#include <time.h>
#include <unistd.h>

int usleep(useconds_t useconds)
{
    struct timespec ts;

    ts.tv_sec = (long int)useconds / 1000000;
    ts.tv_nsec = ((long int)useconds % 1000000) * 1000;
    if (!nanosleep(&ts,&ts)) return 0;
    if (errno == EINTR) return ts.tv_sec;
    return -1;
}

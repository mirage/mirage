/* libc/sys/linux/sleep.c - sleep function */

/* Written 2000 by Werner Almesberger */


#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <linux/times.h>

unsigned int sleep(unsigned int seconds)
{
    struct timespec ts;

    ts.tv_sec = seconds;
    ts.tv_nsec = 0;
    if (!nanosleep(&ts,&ts)) return 0;
    if (errno == EINTR) return ts.tv_sec;
    return -1;
}

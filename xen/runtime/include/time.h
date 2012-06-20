#ifndef _TIME_H
#define _TIME_H

#include <sys/cdefs.h>
#include <sys/time.h>
#include <signal.h>
#include <unistd.h>

__BEGIN_DECLS

int __isleap(int year);

#define CLOCK_REALTIME           0
#define CLOCK_MONOTONIC          1
#define CLOCK_PROCESS_CPUTIME_ID 2
#define CLOCK_THREAD_CPUTIME_ID  3
#define CLOCK_REALTIME_HR        4
#define CLOCK_MONOTONIC_HR       5

int clock_settime(clockid_t clock_id,const struct timespec*tp);
int clock_gettime(clockid_t clock_id,struct timespec*tp);
int clock_getres(clockid_t clock_id,struct timespec*res);
int clock_nanosleep(clockid_t clock_id, int flags,const struct timespec *rqtp, struct timespec *rmtp);

#define TIMER_ABSTIME            1

int timer_create(clockid_t clock_id,struct sigevent*evp,timer_t*timerid) __THROW;
int timer_delete(timer_t timerid) __THROW;
int timer_settime(timer_t timerid,int flags,const struct itimerspec*ival,struct itimerspec*oval) __THROW;
int timer_gettime(timer_t timerid,const struct itimerspec*val) __THROW;
int timer_getoverrun(timer_t timerid) __THROW;

int nanosleep(const struct timespec *req, struct timespec *rem) __THROW;

time_t mktime(struct tm *timeptr) __THROW __pure;

char *asctime(const struct tm *timeptr) __THROW;
char *asctime_r(const struct tm *timeptr, char *buf) __THROW;

char *ctime(const time_t *timep) __THROW;
char *ctime_r(const time_t *timep, char* buf) __THROW;

size_t strftime(char *s, size_t max, const char *format, const struct tm *tm) __THROW __attribute__((__format__(__strftime__,3,0)));
time_t time(time_t *t) __THROW;

int stime(time_t *t) __THROW;

double difftime(time_t time1, time_t time0) __THROW __attribute__((__const__));

#define CLOCKS_PER_SEC 1000000l

extern long int timezone;
extern int daylight;
extern char* tzname[2];

void tzset (void) __THROW;

struct tm* localtime(const time_t* t) __THROW;
struct tm* gmtime(const time_t* t) __THROW;
struct tm* localtime_r(const time_t* t, struct tm* r) __THROW;
struct tm* gmtime_r(const time_t* t, struct tm* r) __THROW;

clock_t clock(void);

char *strptime(const char *s, const char *format, struct tm *tm);

#ifdef _GNU_SOURCE
time_t timegm(struct tm *timeptr) __THROW __attribute_dontuse__ __pure ;
time_t timelocal(struct tm *timeptr) __THROW __attribute_dontuse__ __pure;
#endif

#define CLK_TCK ((clock_t)sysconf(_SC_CLK_TCK))

__END_DECLS

#endif

#ifndef _SYS_UTIME_H
#define _SYS_UTIME_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Per POSIX
 */
struct utimbuf
{
  time_t actime;
  time_t modtime;
};

int utime(const char *, const struct utimbuf *);

#ifdef __cplusplus
};
#endif

#endif

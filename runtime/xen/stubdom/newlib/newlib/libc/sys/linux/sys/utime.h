#ifndef	_SYS_UTIME_H
#define	_SYS_UTIME_H	1

#include <sys/types.h>

struct utimbuf
  {
    time_t actime;		/* Access time.  */
    time_t modtime;		/* Modification time.  */
  };

int _EXFUN(utime, (const char *__file, const struct utimbuf *__times));

#endif /* _SYS_UTIME_H */

#ifndef _UTIME_H
#define _UTIME_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <time.h>

__BEGIN_DECLS

struct utimbuf {
  time_t actime;  /* access time */
  time_t modtime; /* modification time */
};

int utime(const char* filename, struct utimbuf* buf) __THROW;

__END_DECLS

#endif

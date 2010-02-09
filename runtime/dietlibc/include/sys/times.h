#ifndef _SYS_TIMES_H
#define _SYS_TIMES_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

struct tms {
	clock_t tms_utime;
	clock_t tms_stime;
	clock_t tms_cutime;
	clock_t tms_cstime;
};

clock_t times(struct tms *buf) __THROW;

__END_DECLS

#endif

#ifndef _SYS_UTIME_H
# define _SYS_UTIME_H

#include <time.h>

struct utimbuf {
	time_t	actime;
	time_t	modtime;
};

#endif	/* _SYS_UTIME_H */


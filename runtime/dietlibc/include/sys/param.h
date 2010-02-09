#ifndef _SYS_PARAM_H
#define _SYS_PARAM_H

#include <limits.h>

#define MAXPATHLEN	PATH_MAX
#define MAXHOSTNAMELEN	64
#define NGROUPS		32
#define NOGROUP		(-1)
#define NOFILE		OPEN_MAX

#undef MIN
#undef MAX
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#ifdef __alpha__
#define HZ 1024
#else
#define HZ 100
#endif

#ifndef howmany
# define howmany(x, y)  (((x)+((y)-1))/(y))
#endif
#define roundup(x, y)   ((((x)+((y)-1))/(y))*(y))
#define powerof2(x)     ((((x)-1)&(x))==0)

#endif

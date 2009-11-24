/* libc/sys/linux/include/getopt.h - Extended command line parsing */

/* Written 2000 by Werner Almesberger */


#ifndef _NEWLIB_GETOPT_H
#define _NEWLIB_GETOPT_H

#include <unistd.h>

enum { NO_ARG, REQUIRED_ARG, OPTIONAL_ARG };
/* Define glibc names as well for compatibility.  */
#define no_argument NO_ARG
#define required_argument REQUIRED_ARG
#define optional_argument OPTIONAL_ARG

struct option {
    const char *name;
    int has_arg;
    int *flag;
    int val;
};

int getopt_long(int argc,char *const argv[],const char *optstring,
  const struct option *longopts,int *longindex);

int getopt_long_only(int argc,char *const argv[],const char *optstring,
  const struct option *longopts,int *longindex);

#endif

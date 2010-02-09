#ifndef __GETOPT_H__
#define __GETOPT_H__

#include <unistd.h>

__BEGIN_DECLS

struct option {
  const char* name;
  int has_arg;
  int* flag;
  int val;
};

#define no_argument             0
#define required_argument       1
#define optional_argument       2

extern int getopt_long(int argc, char *const *argv,
		       const char *shortopts, const struct option *longopts,
		       int *longind);

extern int getopt_long_only(int argc, char *const *argv,
			    const char *shortopts, const struct option *longopts,
			    int *longind);

__END_DECLS

#endif

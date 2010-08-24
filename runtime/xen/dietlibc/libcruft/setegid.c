#include <sys/types.h>
#include <unistd.h>
#include "dietwarning.h"

#undef setegid
int setegid(gid_t gid);
int setegid(gid_t gid) {
  return setregid((gid_t)-1,gid);
}

link_warning("setegid","warning: you used setegid without including <unistd.h>")

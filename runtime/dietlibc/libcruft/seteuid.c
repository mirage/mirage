#include <sys/types.h>
#include <unistd.h>
#include "dietwarning.h"

#undef seteuid
int seteuid(uid_t uid);
int seteuid(uid_t uid) {
  return setreuid((uid_t)-1,uid);
}

link_warning("setegid","warning: you used setegid without including <unistd.h>")

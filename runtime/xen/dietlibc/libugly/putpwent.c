/* man, what a crook! */

#include <pwd.h>
#include <stdio.h>
#include <sys/types.h>
#include <errno.h>
#include "dietwarning.h"

int putpwent(const struct passwd *p, FILE *stream) {
  if (p && stream) {
    fprintf(stream,"%s:%s:%d:%d:%s:%s:%s\n", p->pw_name, p->pw_passwd,
	    p->pw_uid, p->pw_gid, p->pw_gecos, p->pw_dir, p->pw_shell);
    return 0;
  }
  (*__errno_location())=EINVAL;
  return -1;
}

link_warning("putpwent","putpwent is garbage, don't use!")

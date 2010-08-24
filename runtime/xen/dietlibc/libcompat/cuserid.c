/* according to the Linux manpages, "nobody knows precisely what cuserid()
 * does".
 * (c) 2002 Andreas Krennmair <ak@tcp-ip.at>
 */
#include <unistd.h>
#include <pwd.h>
#include <string.h>
#include <dietwarning.h>

char * cuserid(char * string) {
  struct passwd * sp;
  static char buf[L_cuserid];
  sp = getpwuid(geteuid());
  if (sp) {
    if (!string) string=buf;
    strlcpy(buf,sp->pw_name,L_cuserid);
    return buf;
  }
  return NULL;
}

link_warning("cuserid","cuserid is obsolete junk, don't use!");

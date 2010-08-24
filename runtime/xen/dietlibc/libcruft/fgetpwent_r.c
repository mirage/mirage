#include <pwd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <paths.h>
#include <string.h>
#include "parselib.h"
#include "dietwarning.h"


static struct state __ps;

void fsetpwent(int fd) {
  __fprepare_parse(fd,&__ps);
}

int fgetpwent_r(int fd,struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) {
  size_t i,j,n;
  unsigned long l;
  if (!__ps.buffirst) fsetpwent(fd);
  if (!__ps.buffirst) goto error;
  if (__ps.cur>=__ps.buflen) goto error;
again:
  n=0;
  for (i=0; i<7; ++i) {
    j=__parse_1(&__ps,':');
    if (__ps.buffirst[__ps.cur+j]!=':' && i<6) {
parseerror:
      while (__ps.cur+j<__ps.buflen) {
	if (__ps.buffirst[__ps.cur+j]=='\n') {
	  __ps.cur+=j+1;
	  goto again;
	}
	++j;
      }
    }
    switch (i) {
    case 0:
      res->pw_name=buf+n;
copy:
      if ((size_t)buflen<=n+j) goto error;
      memcpy(buf+n,__ps.buffirst+__ps.cur,j);
      buf[n+j]=0;
      n+=j+1;
      break;
    case 1: res->pw_passwd=buf+n; goto copy;
    case 4: res->pw_gecos=buf+n; goto copy;
    case 5: res->pw_dir=buf+n; goto copy;
    case 6: res->pw_shell=buf+n; goto copy;
    case 2:
    case 3:
	    if (scan_ulong(__ps.buffirst+__ps.cur,&l)!=j) goto parseerror;
	    if (i==2) res->pw_uid=l; else res->pw_gid=l;
	    break;
    }
    __ps.cur+=j+1;
  }
  *res_sig=res;
  return 0;
error:
  *res_sig=0;/* the glibc people should be taken behind the barn and shot */
  return -1;
}

link_warning("fgetpwent","warning: your code uses fgetpwent(), which is non standard!");



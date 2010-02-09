#include <shadow.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <paths.h>
#include <string.h>
#include "parselib.h"

static struct state __ps;

void setspent(void) {
  __prepare_parse(_PATH_SHADOW,&__ps);
}

void endspent(void) {
  __end_parse(&__ps);
}

int getspent_r(struct spwd *res, char *buf, size_t buflen,
	       struct spwd **res_sig) {
  size_t i,j,n;
  unsigned long l;
  if (!__ps.buffirst) setspent();
  if (!__ps.buffirst) goto error;
  if (__ps.cur>=__ps.buflen) goto error;
again:
  n=0;
  for (i=0; i<9; ++i) {
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
    if (i>1) {
      if (scan_ulong(__ps.buffirst+__ps.cur,&l)!=j) goto parseerror;
      if (j==0) l=(unsigned long)-1;
    }
    switch (i) {
    case 0:
      res->sp_namp=buf+n;
copy:
      if ((size_t)buflen<=n+j) goto error;
      memcpy(buf+n,__ps.buffirst+__ps.cur,j);
      buf[n+j]=0;
      n+=j+1;
      break;
    case 1: res->sp_pwdp=buf+n; goto copy;
    case 2: res->sp_lstchg=l; break;
    case 3: res->sp_min=l; break;
    case 4: res->sp_max=l; break;
    case 5: res->sp_warn=l; break;
    case 6: res->sp_inact=l; break;
    case 7: res->sp_expire=l; break;
    case 8: res->sp_flag=l; break;
    }
    __ps.cur+=j+1;
  }
  *res_sig=res;
  return 0;
error:
  *res_sig=0;/* the glibc people should be taken behind the barn and shot */
  return -1;
}

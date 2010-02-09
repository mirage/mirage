#include <string.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <netdb.h>
#include <ctype.h>
#include "parselib.h"

static struct state __ps;

void setprotoent(int stayopen) {
  (void)stayopen;
  __prepare_parse(_PATH_PROTOCOLS,&__ps);
}

void endprotoent(void) {
  __end_parse(&__ps);
}

#define ALIASES 16

/* "igmp	2	IGMP		# internet group management protocol" */
int getprotoent_r(struct protoent *res, char *buf, size_t buflen,
		  struct protoent **res_sig) {
  size_t i,j,n,g;
  unsigned long l;
  if (!__ps.buffirst) setprotoent(0);
  if (!__ps.buffirst) goto error;
  if (__ps.cur>=__ps.buflen) goto error;
  res->p_aliases=(char**)buf;
/*  getprotoent */
again:
  n=ALIASES*sizeof(char*); g=0;
  for (i=0; i<3; ++i) {
    char found;
    __ps.cur+=__parse_ws(&__ps);
    if (__ps.cur>=__ps.buflen) { if (i==2) break; else goto error; }
    j=__parse_nws(&__ps);
    if (!isblank(found=__ps.buffirst[__ps.cur+j])) {
      if (i==2) break;	/* it's ok, no (more) aliases necessary */
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
      res->p_name=buf+n;
copy:
      if ((size_t)buflen<=n+j) goto error;
      memcpy(buf+n,__ps.buffirst+__ps.cur,j);
      buf[n+j]=0;
      n+=j+1;
      if ((found=='\n' || found=='#') && i==1) i=3;
      break;
    case 1:
      if (scan_ulong(__ps.buffirst+__ps.cur,&l)!=j) goto parseerror;
      res->p_proto=l;
      break;
    case 2:
      res->p_aliases[g]=buf+n;
      ++g;
      if (g==(ALIASES-1)) break;
      --i;	/* again */
      goto copy;
    }
    __ps.cur+=j+1;
  }
  res->p_aliases[g]=0;
  *res_sig=res;
  return 0;
error:
  *res_sig=0;/* the glibc people should be taken behind the barn and shot */
  return -1;
}

#include <grp.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <paths.h>
#include <string.h>
#include "parselib.h"

static struct state __ps;

void setgrent(void) {
  __prepare_parse(_PATH_GROUP,&__ps);
}

void endgrent(void) {
  __end_parse(&__ps);
}

#define GROUPS 16

int getgrent_r(struct group *res, char *buf, size_t buflen,
	       struct group **res_sig) {
  size_t i,j,n,g;
  unsigned long l;
  if (!__ps.buffirst) setgrent();
  if (!__ps.buffirst) goto error;
  if (__ps.cur>=__ps.buflen) goto error;
  res->gr_mem=(char**)buf;
again:
  n=GROUPS*sizeof(char*); g=0;
  for (i=0; i<4; ++i) {
    char sep=i<3?':':',';
    char found;
    j=__parse_1(&__ps,sep);
    if ((found=__ps.buffirst[__ps.cur+j])!=sep) {
      if (found!='\n' || i!=3) {
parseerror:
	while (__ps.cur+j<__ps.buflen) {
	  if (__ps.buffirst[__ps.cur+j]=='\n') {
	    __ps.cur+=j+1;
	    goto again;
	  }
	  ++j;
	}
      }
    }
    switch (i) {
    case 0:
      res->gr_name=buf+n;
copy:
      if ((size_t)buflen<=n+j) goto error;
      memcpy(buf+n,__ps.buffirst+__ps.cur,j);
      buf[n+j]=0;
      n+=j+1;
      if (found=='\n' && i==2) i=3;
      break;
    case 1: res->gr_passwd=buf+n; goto copy;
    case 2:
      if (scan_ulong(__ps.buffirst+__ps.cur,&l)!=j) goto parseerror;
      res->gr_gid=l;
      break;
    case 3:
      res->gr_mem[g]=buf+n;
      ++g;
      if (g==(GROUPS-1)) break;
      --i;	/* again */
      goto copy;
    }
    __ps.cur+=j+1;
  }
  res->gr_mem[g]=0;
  *res_sig=res;
  return 0;
error:
  *res_sig=0;/* the glibc people should be taken behind the barn and shot */
  return -1;
}

/* uucp:x:14:uucp,root */

#include <grp.h>
#include <sys/types.h>
#include <string.h>
#include <limits.h>

static int _getgrouplist(const char*user,gid_t group,gid_t*groups,int*ngroups) {
  long n=0,size=*ngroups;
  struct group*g;
  int ret=0;

  if (0<size) { groups[n++]=group; }
  else { *ngroups=0; return (-1); }

  setgrent();
  while ((g=getgrent())) {
    char **duh;
    if (g->gr_gid==group) continue;
    duh=g->gr_mem;
    while (*duh) {
      if (!strcmp(*duh,user)) {
	if (n>=size) {
	  ret=~ret;
	  goto err_out;
	}
	groups[n++]=g->gr_gid;
	break;
      }
      duh++;
    }
  }
err_out:
  endgrent();
  *ngroups=n;
  return ret;
}
int getgrouplist(const char*user,gid_t group,gid_t*groups,int*ngroups)
__attribute__((alias("_getgrouplist")));

int initgroups(const char*user,gid_t group) {
  int n=NGROUPS_MAX;
  gid_t grouplist[NGROUPS_MAX];
  _getgrouplist(user,group,grouplist,&n);
  return setgroups(n,grouplist);
}


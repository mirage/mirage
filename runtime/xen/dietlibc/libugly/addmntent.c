#include <stdio.h>
#include <stdlib.h>
#include <mntent.h>
#include <string.h>

#include <errno.h>

/* FIXME: what happens with spaces/tabs/newlines in the
 * mountpoint/options/type*/

int addmntent(FILE*filep,const struct mntent*mnt) {
  struct mntent m=*mnt;
  char buf[2048];
  if (strlen(m.mnt_opts)==0) m.mnt_opts="rw";
  if (snprintf(buf,sizeof(buf),"%s %s %s %s %d %d\n",
		m.mnt_fsname,m.mnt_dir,m.mnt_type,m.mnt_opts,
		m.mnt_freq,m.mnt_passno)>=(int)sizeof(buf)) return 1;
  if (fputs(buf,filep)==EOF) return 1;
  return 0;
}


#include <string.h>
#include <mntent.h>

char *hasmntopt(const struct mntent *mnt, const char *opt) {
  char *s=mnt->mnt_opts;
  char *c;
  int len=strlen(opt);
  if (!s) return 0;
  for (c=s;;) {
    if (!(c=strstr(c,opt))) break;
    if (c==s || c[-1]==',') {
      if (c[len]==0 || c[len]==',' || c[len]=='=')
	return c;
    }
    c+=len+1;
  }
  return 0;
}

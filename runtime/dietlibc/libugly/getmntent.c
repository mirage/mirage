#include <stdio.h>
#include <stdlib.h>
#include <mntent.h>
#include <string.h>

struct mntent *getmntent(FILE *filep) {
  static struct mntent m;
  static char buf[1024];
  do {
    char *tmp=buf;
    int num;
    if (!fgets(buf,1024,filep)) return 0;
/* "/dev/ide/host0/bus0/target0/lun0/part2 / reiserfs defaults 1 1" */
    for (num=0; num<6; ++num) {
      switch (num) {
      case 0: m.mnt_fsname=tmp; break;
      case 1: m.mnt_dir=tmp; break;
      case 2: m.mnt_type=tmp; break;
      case 3: m.mnt_opts=tmp; break;
      case 4: m.mnt_freq=strtol(tmp,&tmp,0); if (*tmp!=' ' && *tmp!='\t') continue; break;
      case 5: m.mnt_passno=strtol(tmp,&tmp,0); if (*tmp=='\n') return &m; break;
      }
      while (*tmp && *tmp!=' ' && *tmp!='\n' && *tmp!='\t') ++tmp;
      if (*tmp) {
	if (num<4) *tmp++=0;
	while (*tmp==' ' || *tmp=='\t') ++tmp;
      } else
	continue;
    }
  } while (1);
}

#include "dietfeatures.h"
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>

#ifdef __linux__

#include <stdlib.h>

char *ttyname(int fd) {
#ifdef SLASH_PROC_OK
  char ibuf[20];
  static char obuf[20];
  int len;
  if (!isatty(fd)) return 0;
  strcpy(ibuf,"/proc/self/fd/");
  ibuf[__ltostr(ibuf+14,6,(unsigned long)fd,10,0)+14]=0;
  if ((len=readlink(ibuf,obuf,sizeof(obuf)-1))<0) return 0;
  obuf[len]=0;
  return obuf;
#else
  static char buf[20];
  struct stat s;
  char *c=buf+8;
  int n;
  if (!isatty(fd)) return 0;
  if (fstat(fd,&s)) return 0;
  strcpy(buf,"/dev/tty");
  if (S_ISCHR(s.st_mode)) {
    n=minor(s.st_rdev);
    switch (major(s.st_rdev)) {
    case 4:
      if (n>63) {
	n-=64;
	*c='S';
	++c;
      }
num:
      c[__ltostr(c,6,n,10,0)]=0;
      break;
    case 2:
      buf[8]='p'-(n>>4);
      buf[9]=n%4+'0';
      if (buf[9]>'9') *c+='a'-'0';
      buf[10]=0;
      goto duh;
    case 136:
    case 137:
    case 138:
    case 139:
      buf[7]='s';
duh:
      buf[5]='p';
      n+=(major(s.st_rdev)-136)<<8;
      *c='/'; ++c;
      goto num;
    default:
      return 0;
    }
    return buf;
  }
  return 0;
#endif
}

#endif

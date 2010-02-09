#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>

static char* myrealpath(const char* file, char* dest, int count) {
/* assume dest has PATH_MAX space */
  char buf[PATH_MAX+1];
  char* c;
  int i;

  if (count<0) { errno=EMLINK; return 0; }
  if (chdir(file)==0)
    /* hurray!  The easy case: it's a directory! */
    return getcwd(dest,PATH_MAX);

  c=strrchr(file,'/');
  if (c) {
    if (c-file>PATH_MAX) return 0;
    memcpy(buf,file,c-file);
    buf[c-file]=0;
    if (chdir(buf)==-1) return 0;
    file=c+1;
  }
  if (readlink(file,buf,PATH_MAX)==0)
    return myrealpath(buf,dest,count-1);
  if (getcwd(dest,PATH_MAX)==0) return 0;
  i=strlen(dest); dest[i]='/'; ++i;
  for (; i<PATH_MAX-1; ++i) {
    if (!(dest[i]=*file)) break;
    ++file;
  }
  dest[i]=0;
  return dest;
}

char* realpath(const char* file, char* dest) {
  int fd=open(".",O_RDONLY);	/* save directory */
  char* res=myrealpath(file,dest,31);
  fchdir(fd);
  close(fd);
  return res;
}


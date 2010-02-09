#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include "exec_lib.h"
#include "dietfeatures.h"

int execvp(const char *file, char *const argv[]) {
  const char *path=getenv("PATH");
  char *cur,*next;
  char buf[PATH_MAX];
  if (strchr((char*)file,'/')) {
    if (execve(file,argv,environ)==-1) {
      if (errno==ENOEXEC)
	__exec_shell(file,argv);
      return -1;
    }
  }
  if (!path) path=_PATH_DEFPATH;
  for (cur=(char*)path; cur; cur=next) {
    next=strchr(cur,':');
    if (!next)
      next=cur+strlen(cur);
    if (next==cur) {
      buf[0]='.';
      cur--;
    } else {
      if (next-cur>=PATH_MAX-3) { error: errno=EINVAL; return -1; }
      memmove(buf,cur,(size_t)(next-cur));
    }
    buf[next-cur]='/';
    {
      int len=strlen(file);
      if (len+(next-cur)>=PATH_MAX-2) goto error;
      memmove(&buf[next-cur+1],file,strlen(file)+1);
    }
    if (execve(buf,argv,environ)==-1) {
      if (errno==ENOEXEC)
	return __exec_shell(buf,argv);
      if ((errno!=EACCES) && (errno!=ENOENT) && (errno!=ENOTDIR)) return -1;
    }
    if (*next==0) break;
    next++;
  }
  return -1;
}

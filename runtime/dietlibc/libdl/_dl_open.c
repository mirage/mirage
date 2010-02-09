#include <fcntl.h>
#include <dlfcn.h>
#include <limits.h>
#ifndef __DIET_LD_SO__
#include <string.h>
#endif

#include "_dl_int.h"

#ifdef __DIET_LD_SO__
static
#endif
void*_dl_open(const char*filename,int flags) {
  int fd;
  char buf[PATH_MAX];
  const char*p=0;

  for (fd=0;filename[fd] && (p==0);++fd) if (filename[fd]=='/') p=filename;
  if (p) {
#ifdef __DIET_LD_SO__
    if ((fd=_dl_sys_open(p,O_RDONLY,0))<0) fd=-1;
#else
    fd=open(p,O_RDONLY);
#endif
  } else {
    p=buf;
    fd=_dl_search(buf,sizeof(buf)-1,filename);
  }
  if (fd==-1) {
    _dl_error_data=filename;
    _dl_error=1;
    return 0;
  }
  return _dl_load(filename,p,fd,flags);
}

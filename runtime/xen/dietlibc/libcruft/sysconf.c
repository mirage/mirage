#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <sys/resource.h>
#include <fcntl.h>

extern int __sc_nr_cpus();

static long physpages() {
  int fd=open("/proc/meminfo",O_RDONLY);
  char buf[2048];
  size_t l;
  if (fd==-1) { errno=ENOSYS; return -1; }
  l=read(fd,buf,sizeof(buf));
  if (l!=(size_t)-1) {
    char* c;
    buf[l]=0;
    c=strstr(buf,"\nMemTotal:");
    if (c) {
      c+=10; while (*c==' ' || *c=='\t') ++c;
      l=0;
      while (*c>='0' && *c<='9') {
	l=l*10+*c-'0';
	++c;
      }
    }
  }
  close(fd);
  return l*1024;
}

long sysconf(int name)
{
  switch(name)
  {
  case _SC_OPEN_MAX:
    {
      struct rlimit limit;
      getrlimit(RLIMIT_NOFILE, &limit);
      return limit.rlim_cur;
    }
  case _SC_CLK_TCK:
#ifdef __alpha__
    return 1024;
#else
    return 100;
#endif

  case _SC_PAGESIZE:
#if ( defined(__alpha__) || defined(__sparc__) )
    return 8192;
#else
    return 4096;
#endif

  case _SC_PHYS_PAGES:
    return physpages();

  case _SC_ARG_MAX:
    return ARG_MAX;

  case _SC_NGROUPS_MAX:
    return NGROUPS_MAX;

  case _SC_NPROCESSORS_ONLN:
    return __sc_nr_cpus();

  }
  errno=ENOSYS;
  return -1;
}

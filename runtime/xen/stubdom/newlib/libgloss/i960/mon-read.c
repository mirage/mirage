#include <errno.h>

read (fd, buf, sz)
     int fd;
     char *buf;
     int sz;
{
  int nread;
  int r;

  r = _sys_read (fd, buf, sz, &nread);
  if (r != 0)
    {
      errno = r;
      return -1;
    }
  return nread;
}

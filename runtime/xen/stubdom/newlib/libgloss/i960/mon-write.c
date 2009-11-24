#include <errno.h>

int
write (int fd, const char *buf, int sz)
{
  int nwritten;
  int r = _sys_write (fd, buf, sz, &nwritten);
  if (r != 0)
    {
      errno = r;
      return -1;
    }
  return nwritten;
}

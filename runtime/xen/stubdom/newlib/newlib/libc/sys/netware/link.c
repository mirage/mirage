/* NetWare version of link.  This can not be implemented using an
   MS-DOS file system.  */

#include <unistd.h>
#include <errno.h>

#undef errno
extern int errno;

int
link (path1, path2)
     const char *path1;
     const char *path2;
{
  errno = ENOSYS;
  return -1;
}

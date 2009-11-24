/* isatty.c */

/* Dumb implementation so programs will at least run.  */

#include <sys/stat.h>

int
isatty (int fd)
{
  struct stat buf;

  if (fstat (fd, &buf) < 0)
    return 0;
  if (S_ISCHR (buf.st_mode))
    return 1;
  return 0;
}

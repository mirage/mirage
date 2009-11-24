#include <string.h>
#include <unistd.h>
#include <errno.h>

char *
getwd (char *buf)
{
  char tmp[MAXPATHLEN];

  if (buf == NULL)
    {
      errno = EINVAL;
      return NULL;
    }

  if (getcwd (tmp, MAXPATHLEN) == NULL)
    return NULL;

  return strncpy (buf, tmp, MAXPATHLEN);
}

#include <dirent.h>
#include <string.h>

extern int __strverscmp (char *, char *);

int
versionsort (const void *a, const void *b)
{
  return __strverscmp ((*(const struct dirent **)a)->d_name,
                       (*(const struct dirent **)b)->d_name);
}

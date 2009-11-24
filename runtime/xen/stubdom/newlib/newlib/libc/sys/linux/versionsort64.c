#include <dirent.h>
#include <string.h>

extern int __strverscmp (char *, char *);

int
versionsort64 (const void *a, const void *b)
{
  return __strverscmp ((*(const struct dirent64 **)a)->d_name,
                       (*(const struct dirent64 **)b)->d_name);
}

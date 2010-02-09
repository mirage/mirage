#include <stdlib.h>
#include <string.h>

extern char *getenv(const char *s)
{
  int i;
  unsigned int len;

  if (!environ || !s) return 0;
  len = strlen(s);
  for (i = 0;environ[i];++i)
    if ((memcmp(environ[i],s,len)==0) && (environ[i][len] == '='))
      return environ[i] + len + 1;
  return 0;
}


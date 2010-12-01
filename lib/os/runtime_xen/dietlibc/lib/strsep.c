#include <string.h>

char *strsep(char **stringp, const char *delim) {
  register char *tmp=*stringp;
  register char *tmp2=tmp;
  register const char *tmp3;
  if (!*stringp) return 0;
  for (tmp2=tmp; *tmp2; ++tmp2) {
    for (tmp3=delim; *tmp3; ++tmp3)
      if (*tmp2==*tmp3) {	/* delimiter found */
	*tmp2=0;
	*stringp=tmp2+1;
	return tmp;
      }
  }
  *stringp=0;
  return tmp;
}

#include <sys/types.h>
#include <string.h>

size_t strcspn(const char *s, const char *reject)
{
  size_t l=0;
  int i,al=strlen(reject);

  for (; *s; ++s) {
    for (i=0; reject[i]; ++i)
      if (*s==reject[i]) return l;
    ++l;
  }
  return l;
}

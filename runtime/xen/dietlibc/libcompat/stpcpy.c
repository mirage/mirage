#include <string.h>

char * stpcpy (char *dst, const char *src) {
  while ((*dst++ = *src++));
  return (dst-1);
}

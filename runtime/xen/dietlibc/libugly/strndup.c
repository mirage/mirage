#define _GNU_SOURCE
/* *puke* */
#include <string.h>
#include <stdlib.h>
#include "dietfeatures.h"

char *strndup(const char *s,size_t n) {
  /* This relies on the fact that our malloc(0) returns NULL.
   * Otherwise this would be an exploitable integer overflow! */
#ifdef WANT_MALLOC_ZERO
  char *tmp=!(n+1)?0:(char *)malloc(n+1);
#else
  char *tmp=(char *)malloc(n+1);
#endif
  if (!tmp) return 0;
  strncpy(tmp,s,n);
  tmp[n]=0;
  return tmp;
}

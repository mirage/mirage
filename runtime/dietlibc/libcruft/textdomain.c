#include <libintl.h>
#include <string.h>
#include <stdlib.h>

static char* dom;

char* textdomain(const char* domainname) {
  if (dom) free(dom);
  if (!(dom=strdup(domainname))) return 0;
  return dom;
}

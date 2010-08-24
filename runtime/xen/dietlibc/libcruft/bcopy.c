#include <sys/types.h>
#include <string.h>
#include <strings.h>
#include "dietwarning.h"

#undef bcopy
void bcopy(const void *src, void *dest, size_t n) {
  memmove(dest,src,n);
}

link_warning("bcopy","warning: you used bcopy without including dietlibc <string.h> w/ _BSD_SOURCE!")

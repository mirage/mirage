#include "dietfeatures.h"
#include <unistd.h>
#include <string.h>

#define _BSD_SOURCE
#undef __attribute_dontuse__
#define __attribute_dontuse__
#include <errno.h>

extern const char  __sys_err_unknown [];

char*strerror(int errnum) {
  register const char*message=__sys_err_unknown;
  return (char*)message;
}

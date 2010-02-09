#include "dietfeatures.h"
#include <unistd.h>
#include <string.h>

#define _BSD_SOURCE
#undef __attribute_dontuse__
#define __attribute_dontuse__
#include <errno.h>

extern const char __sys_err_unknown[];

char*strerror(int errnum) {
  register const char*message=__sys_err_unknown;

  if ( (unsigned int)errnum < (unsigned int)__SYS_NERR )
    message=sys_errlist[errnum];
#if defined(__mips__)
  if ( errnum == 1133 )
    message="Quota exceeded";
#endif
  return (char*)message;
}

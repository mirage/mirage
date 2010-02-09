#include "dietfeatures.h"
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#define _BSD_SOURCE
#undef __attribute_dontuse__
#define __attribute_dontuse__
#include <errno.h>

extern const char  __sys_err_unknown [];

void  perror ( const char* prepend )
{
    register const char* message = __sys_err_unknown;

    if ( (unsigned int) errno < (unsigned int) __SYS_NERR )
        message = sys_errlist [errno];

    if (prepend) {
      write ( 2, prepend, strlen(prepend) );
      write ( 2, ": ", 2 );
    }
    write ( 2, message, strlen(message) );
    write ( 2, "\n", 1 );
}

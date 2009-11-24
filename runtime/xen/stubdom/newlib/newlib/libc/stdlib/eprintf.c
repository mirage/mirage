/* This is an implementation of the __eprintf function which is
   compatible with the assert.h which is distributed with gcc.

   This function is provided because in some cases libgcc.a will not
   provide __eprintf.  This will happen if inhibit_libc is defined,
   which is done because at the time that libgcc2.c is compiled, the
   correct <stdio.h> may not be available.  newlib provides its own
   copy of assert.h, which calls __assert, not __eprintf.  However, in
   some cases you may accidentally wind up compiling with the gcc
   assert.h.  In such a case, this __eprintf will be used if there
   does not happen to be one in libgcc2.c.  */

#include <stdlib.h>
#include <stdio.h>

void
__eprintf (format, file, line, expression)
     const char *format;
     const char *file;
     unsigned int line;
     const char *expression;
{
  (void) fiprintf (stderr, format, file, line, expression);
  abort ();
  /*NOTREACHED*/
}

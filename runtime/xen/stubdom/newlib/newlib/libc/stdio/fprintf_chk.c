#include <stdarg.h>
#include <stdio.h>

/*
 * Stub implementation of __fprintf_chk adapted from glibc 2.7.  This 
 * doesn't actually implement any buffer overflow protection.  It just makes
 * the linker happy :)
*/
int
__fprintf_chk (FILE *fp, int flag, const char *format, ...)
{
  va_list ap;
  int done;

  va_start (ap, format);
  done = vfprintf (fp, format, ap);
  va_end (ap);

  return done;
}


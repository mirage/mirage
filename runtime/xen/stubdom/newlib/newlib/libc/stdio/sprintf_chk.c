#include <stdarg.h>
#include <stdio.h>

/*
 * Stub implementation of __sprintf_chk adapted from glibc 2.7.  This 
 * doesn't actually implement any buffer overflow protection.  It just makes
 * the linker happy :)
*/
int
__sprintf_chk (char *s, int flags, size_t slen, const char *format, ...)
{
  va_list arg;
  int done;

  va_start (arg, format);
  done = vsprintf (s, format, arg);
  va_end (arg);

  return done;
}


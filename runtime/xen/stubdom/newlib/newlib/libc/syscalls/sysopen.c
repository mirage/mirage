/* connector for open */

#include <reent.h>
#include <fcntl.h>

#ifdef _HAVE_STDC

/* The prototype in <fcntl.h> uses ..., so we must correspond.  */

#include <stdarg.h>

int
_DEFUN (open, (file, flags, ...),
        const char *file _AND
        int flags _DOTS)
{
  va_list ap;
  int ret;

  va_start (ap, flags);
#ifdef REENTRANT_SYSCALLS_PROVIDED
  ret = _open_r (_REENT, file, flags, va_arg (ap, int));
#else
  ret = _open (file, flags, va_arg (ap, int));
#endif
  va_end (ap);
  return ret;
}

#else /* ! _HAVE_STDC */

int 
open (file, flags, mode)
     const char *file;
     int flags;
     int mode;
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _open_r (_REENT, file, flags, mode);
#else
  return _open (file, flags, mode);
#endif
}

#endif /* ! _HAVE_STDC */

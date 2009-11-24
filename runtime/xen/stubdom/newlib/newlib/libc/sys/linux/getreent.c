/* default function used by _REENT when not using multithreading */

#include <reent.h>
#include <machine/weakalias.h>

struct _reent *
__libc_getreent (void)
{
  return _impure_ptr;
}
weak_alias(__libc_getreent,__getreent)


/* default reentrant pointer when multithread enabled */

#include <_ansi.h>
#include <reent.h>

#define weak_alias(name, aliasname) \
  extern __typeof (name) aliasname __attribute__ ((weak, alias (#name)));

#ifdef __getreent
#undef __getreent
#endif
#ifdef __libc_getreent
#undef __libc_getreent
#endif

struct _reent *
__libc_getreent (void)
{
  return _impure_ptr;
}
weak_alias(__libc_getreent,__getreent)


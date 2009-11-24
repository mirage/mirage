/* stub to allow libpthread to override */

#include <stdio.h>
#include <machine/weakalias.h>

void __libc_funlockfile (FILE *fp)
{
}
weak_alias(__libc_funlockfile,funlockfile)

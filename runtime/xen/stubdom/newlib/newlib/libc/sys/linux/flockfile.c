/* stub to allow libpthread to override */

#include <stdio.h>
#include <machine/weakalias.h>

void __libc_flockfile (FILE *fp)
{
}
weak_alias(__libc_flockfile,flockfile)

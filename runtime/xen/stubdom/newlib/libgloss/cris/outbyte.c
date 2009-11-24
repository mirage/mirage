/* Low-level kind-of-support for CRIS.  Mostly used as a placeholder
   function.  Too small and obvious to warrant a copyright notice.  */

#include <stdio.h>
void
outbyte (int ch)
{
  write (1, &ch, 1);
}

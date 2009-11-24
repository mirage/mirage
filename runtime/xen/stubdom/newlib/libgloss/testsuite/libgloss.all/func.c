/* Oki bug report [OKI002](gcc008_2)

        The following program is not executed.
        Error message is as follow.

	illegal trap: 0x12 pc=d000d954
	d000d954 08000240  NOP

 */

#include <stdio.h>
#include <stdarg.h>

int func (int, ...);

void main ()
{
        func (2, 1., 2., 3.);
	pass ("func [OKI002]");
	fflush (stdout);
}

int func (int i, ...)
{
        return (i);
}

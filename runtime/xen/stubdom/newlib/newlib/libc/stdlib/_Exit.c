/*
FUNCTION
<<_Exit>>---end program execution with no cleanup processing

INDEX
	_Exit

ANSI_SYNOPSIS
	#include <stdlib.h>
	void _Exit(int <[code]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	void _Exit(<[code]>)
	int <[code]>;

DESCRIPTION
Use <<_Exit>> to return control from a program to the host operating
environment.  Use the argument <[code]> to pass an exit status to the
operating environment: two particular values, <<EXIT_SUCCESS>> and
<<EXIT_FAILURE>>, are defined in `<<stdlib.h>>' to indicate success or
failure in a portable fashion.

<<_Exit>> differs from <<exit>> in that it does not run any
application-defined cleanup functions registered with <<atexit>> and
it does not clean up files and streams.  It is identical to <<_exit>>.

RETURNS
<<_Exit>> does not return to its caller.

PORTABILITY
<<_Exit>> is defined by the C99 standard.

Supporting OS subroutines required: <<_exit>>.
*/

#include <stdlib.h>
#include <unistd.h>	/* for _exit() declaration */
#include <reent.h>

void 
_DEFUN (_Exit, (code),
	int code)
{
  _exit (code);
}

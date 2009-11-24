/* NetWare can not use this implementation of abort.  It provides its
   own version of abort in clib.nlm.  If we can not use clib.nlm, then
   we must write abort in sys/netware.  */

#ifdef ABORT_PROVIDED

int _dummy_abort = 1;

#else

/*
FUNCTION
<<abort>>---abnormal termination of a program

INDEX
	abort

ANSI_SYNOPSIS
	#include <stdlib.h>
	void abort(void);

TRAD_SYNOPSIS
	#include <stdlib.h>
	void abort();

DESCRIPTION
Use <<abort>> to signal that your program has detected a condition it
cannot deal with.  Normally, <<abort>> ends your program's execution.

Before terminating your program, <<abort>> raises the exception <<SIGABRT>>
(using `<<raise(SIGABRT)>>').  If you have used <<signal>> to register
an exception handler for this condition, that handler has the
opportunity to retain control, thereby avoiding program termination.

In this implementation, <<abort>> does not perform any stream- or
file-related cleanup (the host environment may do so; if not, you can
arrange for your program to do its own cleanup with a <<SIGABRT>>
exception handler).

RETURNS
<<abort>> does not return to its caller.

PORTABILITY
ANSI C requires <<abort>>.

Supporting OS subroutines required: <<_exit>> and optionally, <<write>>.
*/

#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

_VOID
_DEFUN_VOID (abort)
{
#ifdef ABORT_MESSAGE
  write (2, "Abort called\n", sizeof ("Abort called\n")-1);
#endif

  while (1)
    {
      raise (SIGABRT);
      _exit (1);
    }
}

#endif

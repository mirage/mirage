#include <_ansi.h>
#include <signal.h>
#include "swi.h"

int _kill _PARAMS ((int, int));

int
_kill (int pid, int sig)
{
  (void) pid; (void) sig;
#ifdef ARM_RDI_MONITOR
  /* Note: The pid argument is thrown away.  */
  switch (sig)
    {
    case SIGABRT:
      return do_AngelSWI (AngelSWI_Reason_ReportException,
			  (void *) ADP_Stopped_RunTimeError);
    default:
      return do_AngelSWI (AngelSWI_Reason_ReportException,
			  (void *) ADP_Stopped_ApplicationExit);
    }
#else
  asm ("swi %a0" :: "i" (SWI_Exit));
#endif
}

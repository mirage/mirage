/* Misc. operating system stubs.  */

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>

/* _raise(), getpid(), and kill() are required by abort().
   getpid/kill are prefixed with '_' because of MISSING_SYSCALL_NAMES.  */

int _DEFUN(_raise,(sig),
	   int sig)
{
  return 0;
}

int _DEFUN(_getpid,(),)
{
  return 0;
}

int _DEFUN(_kill,(pid, sig),
	   int pid _AND
	   int sig)
{
  if (pid == 0)
    {
      /* Narrow SIG down to a short, in case we're compiled with -mint32.  */
      short sig2 = sig;
      /* This causes the simulator to indicate abort() was called.
	 The format of r0 is defined by devo/include/wait.h.  */
      asm ("mov.w %0,r0\n\tsleep" : : "r" (sig2) : "r0");
    }
  return 0;
}

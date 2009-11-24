/* Misc. operating system stubs.  */

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>

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
  if (sig == SIGABRT)
    asm ("mov.w #34,r3; trapa #15");
  return 0;
}

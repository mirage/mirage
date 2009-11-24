#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <reent.h>

static const char *sigstring[] =
  {
    "Signal 0",
    "Hangup",
    "Interrupt",
    "Quit",
    "Illegal instruction",
    "Trace/breakpoint trap",
    "IOT trap",
    "EMT trap",
    "Floating point exception",
    "Killed",
    "Bus error",
    "Segmentation fault",
    "Bad system call",
    "Broken pipe",
    "Alarm clock",
    "Terminated",
    "Urgent I/O condition",
    "Stopped (signal)",
    "Stopped",
    "Continued",
    "Child exited",
    "Stopped (tty input)",
    "Stopped (tty output)",
    "I/O possible",
    "CPU time limit exceeded",
    "File size limit exceeded",
    "Virtual timer expired",
    "Profiling timer expired",
    "Window changed",
    "Resource lost",
    "User defined signal 1",
    "User defined signal 2"
  };

char *
strsignal (int sig)
{
  if (sig < 0 || sig >= __SIGRTMIN)
    {
      char *buffer;
      struct _reent *ptr;

      ptr = _REENT;

      _REENT_CHECK_SIGNAL_BUF(ptr);
      buffer = _REENT_SIGNAL_BUF(ptr);

      if (sig < 0 || sig > __SIGRTMAX)
        siprintf (buffer, "Unknown signal %d", sig);
      else
        siprintf (buffer, "Real-time signal %d", sig - __SIGRTMIN);
      return buffer;
    }
  else
    return sigstring[sig];
}

#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <sys/wait.h>
#include "dietwarning.h"
#include "dietfeatures.h"
#include "binshstr.h"

extern char **environ;

int __libc_system (const char *line);

int __libc_system (const char *line)
{
  struct sigaction sa, intr, quit;
  sigset_t block,omask;
  int save,pid,ret=-1;

  if (line == 0) return __libc_system("exit 0") == 0;

  sa.sa_handler = SIG_IGN;
  sa.sa_flags = 0;
  sigemptyset (&sa.sa_mask);

  if (sigaction(SIGINT,  &sa, &intr)<0) return -1;
  if (sigaction(SIGQUIT, &sa, &quit)<0) {
    save = errno;
undo:
    sigaction (SIGINT, &intr, (struct sigaction*)0);
    errno=save;
    return -1;
  }
  sigemptyset(&block);
  sigaddset(&block,SIGCHLD);
  if (sigprocmask(SIG_BLOCK,&block,&omask)<0) {
    save=errno;
    sigaction (SIGQUIT, &quit, (struct sigaction*)0);
    goto undo;
  }

  pid=fork();
  if (pid>0)
  { /* parent */
    int n;
    do
      n=waitpid(pid, &ret, 0);
    while ((n==-1) && (errno==EINTR));
    if (n!=pid) ret=-1;
  }
  else if (!pid)
  { /* child */
    const char *nargs[4];
    nargs[0] = __sh;
    nargs[1] = "-c";
    nargs[2] = line;
    nargs[3] = 0;

    sigaction(SIGINT,  &intr, (struct sigaction*)0);
    sigaction(SIGQUIT, &quit, (struct sigaction*)0);
    sigprocmask(SIG_SETMASK,&omask,0);

    execve(__binsh,(char *const *)nargs, environ);
    _exit(127);
  }
  save = errno;
  sigaction (SIGINT,  &intr, (struct sigaction *)0);
  sigaction (SIGQUIT, &quit, (struct sigaction *)0);
  sigprocmask(SIG_SETMASK,&omask,0);
  errno=save;
  return ret;
}

int system (const char *line) __attribute__((weak,alias("__libc_system")));

link_warning("system","warning: system() is a security risk.  Use fork and execvp instead!")

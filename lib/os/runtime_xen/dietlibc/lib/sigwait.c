#include <signal.h>

int sigwait(const sigset_t* set,int* sig) {
  siginfo_t si;
  int r=sigwaitinfo(set,&si);
  if (r!=-1) *sig=si.si_signo;
  return r;
}

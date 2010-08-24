#include <signal.h>

int sigfillset(sigset_t *set) {
  set->sig[0]=(unsigned long)-1;
  if (_NSIG_WORDS>1) set->sig[1]=(unsigned long)-1;
  if (_NSIG_WORDS>2) {
    set->sig[2]=(unsigned long)-1;
    set->sig[3]=(unsigned long)-1;
  }
  return 0;
}

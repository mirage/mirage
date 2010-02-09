#define _GNU_SOURCE
#include <signal.h>

int sigisemptyset(const sigset_t*set)
{
  unsigned long ret;
  ret=set->sig[0];
  if (_NSIG_WORDS>1) ret|=set->sig[1];
  if (_NSIG_WORDS>2) {
    ret|=set->sig[2];
    ret|=set->sig[3];
  }
  return ret != 0;
}

#define _GNU_SOURCE
#include <signal.h>

int sigandset(sigset_t*set,const sigset_t*left,const sigset_t*right)
{
  set->sig[0]=left->sig[0]&right->sig[0];
  if (_NSIG_WORDS>1) set->sig[1]=left->sig[1]&right->sig[1];
  if (_NSIG_WORDS>2) {
    set->sig[2]=left->sig[2]&right->sig[2];
    set->sig[3]=left->sig[3]&right->sig[3];
  }
  return 0;
}

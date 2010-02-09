#include <signal.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_sigmask(int how, const sigset_t*newset, sigset_t *oldset) {
  sigset_t mask;
  if (newset) {
    mask=*newset;
    switch (how) {
    case SIG_SETMASK:
      sigaddset(&mask,PTHREAD_SIG_RESTART);
      sigdelset(&mask,PTHREAD_SIG_CANCEL);
      break;
    case SIG_BLOCK:
      sigdelset(&mask,PTHREAD_SIG_CANCEL);
      break;
    case SIG_UNBLOCK:
      sigdelset(&mask,PTHREAD_SIG_RESTART);
      break;
    }
    newset=&mask;
  }
  return (sigprocmask(how,newset,oldset)==-1)?_errno_:0;
}

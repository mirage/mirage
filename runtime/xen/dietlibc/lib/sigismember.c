#include <signal.h>
#include <errno.h>

#define __sigmask(sig)		( ((unsigned long)1) << (((sig)-1) % (8*sizeof(unsigned long))) )
#define __sigword(sig)		( ((sig)-1) / (8*sizeof(unsigned long)) )

int sigismember(const sigset_t *set, int signo) {
  if ((signo<1)||(signo>SIGRTMAX)) {
    (*__errno_location())=EINVAL;
    return -1;
  } else {
    unsigned long __mask = __sigmask (signo);
    unsigned long __word = __sigword (signo);
    return (set->sig[__word] & __mask)?1:0;
  }
}

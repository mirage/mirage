#include <sys/select.h>

int pselect(int n, fd_set* readfds, fd_set* writefds, fd_set* exceptfds,
            const struct timespec *timeout, const sigset_t *sigmask) {
  struct timeval t;
  sigset_t old;
  int r;
  if (timeout) {
    t.tv_sec=timeout->tv_sec;
    t.tv_usec=timeout->tv_nsec/1000;
    if (!t.tv_sec && !t.tv_usec && timeout->tv_nsec) ++t.tv_usec;
  }
  if (sigmask)
    sigprocmask(SIG_SETMASK,sigmask,&old);
  r=select(n,readfds,writefds,exceptfds,
	   timeout?&t:0);
  if (sigmask)
    sigprocmask(SIG_SETMASK,&old,0);
  return r;
}

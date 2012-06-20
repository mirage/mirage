#include <sys/types.h>
#include <unistd.h>
#include <signal.h>

int raise(int sig) {
  return kill(getpid(),sig);
}

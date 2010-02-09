#include <sys/types.h>
#include <sys/wait.h>

pid_t wait(int *status) {
  return waitpid(-1,status,0);
}

#include <sys/wait.h>

pid_t wait3(int* status,int opts,struct rusage* rusage) {
  return wait4(-1,status,opts,rusage);
}

#include <sys/types.h>
#include <sys/wait.h>
#include "dietstdio.h"

int pclose(FILE *f) {
  int status;
  pid_t pid=f->popen_kludge;
  fclose(f);
  if (waitpid(pid,&status,0)>=0)
    return status;
  return -1;
}

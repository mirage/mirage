#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main() {
  pid_t t;
  int status;
  switch (t=fork()) {
  case -1:
    perror("fork");
    _exit(1);
  case 0:
    fprintf(stderr,"child, my pid is %u\n",getpid());
    sleep(1);
    _exit(23);
  }
  printf("waitpid returned %u\n",waitpid(-1,&status,0));
  printf("status was: %d\n",WEXITSTATUS(status));
  return 0;
}

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

#include <stdlib.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

#define ps(s) write(2,s,sizeof(s)-1)
#define die(s) do { ps(s); exit(1); } while(0)


static void*thread(void*arg) {
  printf("thread %ld %d %p\n",(long)arg,getpid(),&arg);
  while(1) { pthread_testcancel(); sleep(1); }
}

static int max=32000;
static void __gen_thread(int nr) {
  pthread_t t;
  if (nr>max) {
    printf("stopping at maximum %d\n",nr);
    return;
  }
  if (pthread_create(&t,0,thread,(void*)nr)) {
    printf("can't create thread nr %d\n",nr);
  }
  else {
    __gen_thread(nr+1);
  }
}

void segv_handler(int sig,siginfo_t*info,void*arg) {
  printf("SIG: %d in %d @ %p\n",sig,getpid(),info->si_addr);
  _exit(1);
}

void init_segv() {
  struct sigaction siga;
  memset(&siga,0,sizeof(struct sigaction));
  siga.sa_sigaction=segv_handler;
  siga.sa_flags=SA_SIGINFO;
  sigaction(SIGSEGV,&siga,0);
}

int main(int argc,char*argv[]) {
  if (argc>1) max=atoi(argv[1]);
  printf("MAIN: %d max=%d\n",getpid(),max);
  init_segv();
  nice(20);
  __gen_thread(2);
  sleep(5);
  return 0;
}

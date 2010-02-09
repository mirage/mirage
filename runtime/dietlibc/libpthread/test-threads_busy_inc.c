#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <stdlib.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

#define ps(s) write(2,s,sizeof(s)-1)
#define die(s) do { ps(s); exit(1); } while(0)

pthread_t*t;

static void*thread(void*arg) {
  printf("thread %ld %d\n",(long)arg,getpid());
  while(1) { pthread_testcancel(); }
}

static void __gen_thread(int nr) {
  if (pthread_create(t+nr,0,thread,(void*)nr)) {
    printf("can't create thread nr %d\n",nr);
    exit(42);
  }
  sleep(1);
}


int main(int argc,char*argv[]) {
  int m,i;
  nice(20);
  if ((argc<2) || ((m=atoi(argv[1]))==0)) m=16;
  if ((t=malloc(m*sizeof(pthread_t)))==0) die("no mem....\n");
  for (i=0;i<m;++i) __gen_thread(i);
  sleep(20);
  for (i=0;i<m;++i) pthread_cancel(t[i]);
  return 0;
}

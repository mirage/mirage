#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

extern void* __ipc(int,int,int,void*,const void*);

void* shmat(int shmid,const void* shmaddr,int shmflg) {
  void* raddr;
  register void* result;
  result=__ipc(SHMAT,shmid,shmflg,&raddr,shmaddr);
  if ((unsigned long)result <= -(unsigned long)8196)
    result=raddr;
  return result;
}

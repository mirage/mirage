#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

extern int __ipc(int,int,int,int,const void*);

int shmdt(const void* shmaddr) {
  return __ipc(SHMDT,0,0,0,shmaddr);
}

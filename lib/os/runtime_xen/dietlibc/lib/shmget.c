#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

extern int __ipc(int,key_t,int,int,int);

int shmget(key_t key, int size, int shmflg) {
  return __ipc(SHMGET,key,size,shmflg,0);
}

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/sem.h>

extern int __ipc(int,int,unsigned,int,void*);

int semop(int semid,struct sembuf *sops,unsigned nsops) {
  return __ipc(SEMOP,semid,nsops,0,sops);
}

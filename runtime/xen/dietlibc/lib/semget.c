#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/sem.h>

extern int __ipc(int,key_t,int,int,int);

int semget(key_t key, int nsems, int semflg) {
  return __ipc(SEMGET,key,nsems,semflg,0);
}

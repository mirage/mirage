#include <sys/types.h>
#include <sys/ipc.h>

extern int __ipc(int,int,int,int,void*);

union semun {
  int val;			/* value for SETVAL */
  struct semid_ds *buf;		/* buffer for IPC_STAT & IPC_SET */
  unsigned short *array;		/* array for GETALL & SETALL */
  struct seminfo *__buf;		/* buffer for IPC_INFO */
  void *__pad;
};

int semctl(int semid, int semnum, int cmd, union semun arg);
int semctl(int semid, int semnum, int cmd, union semun arg) {
  return __ipc(SEMCTL,semid,semnum,cmd,&arg);
}

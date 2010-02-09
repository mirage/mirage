#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>

extern int __ipc(int,int,size_t,int,const void*);

int msgsnd (int msqid, const void *msgp, size_t msgsz, int msgflg) {
  return __ipc(MSGSND,msqid, msgsz, msgflg, msgp);
}

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>

extern int __ipc(int,int,size_t,int,void*);

struct ipc_kludge {
  struct msgbuf *msgp;
  long msgtyp;
};

int msgrcv(int msqid, void *msgp, size_t msgsz, long int msgtyp, int msgflg) {
  struct ipc_kludge tmp;
  tmp.msgp = msgp;
  tmp.msgtyp = msgtyp;
  return __ipc(MSGRCV,msqid, msgsz, msgflg, &tmp);
}

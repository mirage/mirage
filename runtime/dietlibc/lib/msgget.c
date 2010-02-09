#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>

extern int __ipc(int,key_t,int,int,int);

int msgget(key_t key,int flag) {
  return __ipc(MSGGET,key,flag,0,0);
}

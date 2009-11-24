/* libc/sys/linux/ipc.c - IPC semaphore and message queue functions */

/* Copyright 2002, Red Hat Inc. */

#include <sys/types.h>
#include <sys/sem.h>
#include <sys/msg.h>
#include <stdarg.h>

#include <machine/syscall.h>

#define IPC_64 0x100

#define IPCOP_semop	1
#define IPCOP_semget	2
#define IPCOP_semctl	3
#define IPCOP_msgsnd	11
#define IPCOP_msgrcv	12
#define IPCOP_msgget	13
#define IPCOP_msgctl	14

static _syscall5(int,ipc,int,op,int,arg1,int,arg2,int,arg3,void *,arg4);

int
semget (key_t key, int nsems, int semflgs)
{
  return __libc_ipc(IPCOP_semget, (int)key, nsems, semflgs, NULL);
}

int
semctl (int semid, int semnum, int cmd, ...)
{
  va_list va;
  union semun {
    int val;
    struct semid_ds *buf;
    unsigned short  *array;
  } arg;

  va_start (va, cmd);

  arg = va_arg (va, union semun);

  va_end (va);

  return __libc_ipc(IPCOP_semctl, semid, semnum, cmd | IPC_64, &arg);
}

int
semop (int semid, struct sembuf *sops, size_t nsems)
{
  return __libc_ipc(IPCOP_semop, semid, (int)nsems, 0, sops);
}

int
msgget (key_t key, int msgflg)
{
  return __libc_ipc(IPCOP_msgget, (int)key, msgflg, 0, NULL);
}

int
msgctl (int msqid, int cmd, struct msqid_ds *buf)
{
  return __libc_ipc(IPCOP_msgctl, msqid, cmd | IPC_64, 0, buf);
}

int
msgsnd (int msqid, const void *msgp, size_t msgsz, int msgflg)
{
  return __libc_ipc(IPCOP_msgsnd, msqid, (int)msgsz, msgflg, (void *)msgp);
}

int
msgrcv (int msqid, void *msgp, size_t msgsz, long int msgtyp, int msgflg)
{
  /* last argument must contain multiple args */
  struct {
    void *msgp;
    long int msgtyp;
  } args;

  args.msgp = msgp;
  args.msgtyp = msgtyp;

  return (ssize_t)__libc_ipc(IPCOP_msgrcv, msqid, (int)msgsz, msgflg, &args);
}


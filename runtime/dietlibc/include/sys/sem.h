#ifndef _SYS_SEM_H
#define _SYS_SEM_H

#include <sys/ipc.h>

__BEGIN_DECLS

/* semop flags */
#define SEM_UNDO        0x1000  /* undo the operation on exit */

/* semctl Command Definitions. */
#define GETPID  11       /* get sempid */
#define GETVAL  12       /* get semval */
#define GETALL  13       /* get all semval's */
#define GETNCNT 14       /* get semncnt */
#define GETZCNT 15       /* get semzcnt */
#define SETVAL  16       /* set semval */
#define SETALL  17       /* set all semval's */

/* ipcs ctl cmds */
#define SEM_STAT 18
#define SEM_INFO 19

struct semid_ds {
  struct ipc_perm	sem_perm;		/* permissions .. see ipc.h */
  time_t		sem_otime;		/* last semop time */
  time_t		sem_ctime;		/* last change time */
  struct sem		*sem_base;		/* ptr to first semaphore in array */
  struct sem_queue	*sem_pending;		/* pending operations to be processed */
  struct sem_queue	**sem_pending_last;	/* last pending operation */
  struct sem_undo	*undo;			/* undo requests on this array */
  uint16_t		sem_nsems;		/* no. of semaphores in array */
};

/* semop system calls takes an array of these. */
struct sembuf {
  uint16_t		sem_num;	/* semaphore index in array */
  int16_t		sem_op;		/* semaphore operation */
  int16_t		sem_flg;	/* operation flags */
};

/* please complain to the glibc goons for the following misbehaviour */
#if 0
/* arg for semctl system calls. */
union semun {
  int val;			/* value for SETVAL */
  struct semid_ds *buf;		/* buffer for IPC_STAT & IPC_SET */
  unsigned short *array;		/* array for GETALL & SETALL */
  struct seminfo *__buf;		/* buffer for IPC_INFO */
  void *__pad;
};
#endif
#define _SEM_SEMUN_UNDEFINED

struct  seminfo {
  int32_t semmap;
  int32_t semmni;
  int32_t semmns;
  int32_t semmnu;
  int32_t semmsl;
  int32_t semopm;
  int32_t semume;
  int32_t semusz;
  int32_t semvmx;
  int32_t semaem;
};

#define SEMMNI  128		/* <= IPCMNI  max # of semaphore identifiers */
#define SEMMSL  250		/* <= 8 000 max num of semaphores per id */
#define SEMMNS  (SEMMNI*SEMMSL) /* <= INT_MAX max # of semaphores in system */
#define SEMOPM  32		/* <= 1 000 max num of ops per semop call */
#define SEMVMX  32767		/* <= 32767 semaphore maximum value */

extern int semget( key_t key, int nsems, int semflg) __THROW;

/* The prototype really is:
 * extern int semctl(int semid, int semnum, int cmd, union semun arg) __THROW;
 * glibc bug compatibility forces us to write it like this: */
extern int semctl(int semid, int semnum, int cmd, ...) __THROW;

extern int semop(int semid, struct sembuf *sops, unsigned nsops) __THROW;

__END_DECLS

#endif

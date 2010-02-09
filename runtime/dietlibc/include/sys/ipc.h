#ifndef _SYS_IPC_H
#define _SYS_IPC_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

#define SEMOP		 1
#define SEMGET		 2
#define SEMCTL		 3
#define MSGSND		11
#define MSGRCV		12
#define MSGGET		13
#define MSGCTL		14
#define SHMAT		21
#define SHMDT		22
#define SHMGET		23
#define SHMCTL		24

#define IPC_PRIVATE ((key_t) 0)

#define IPC_CREAT  00001000   /* create if key is nonexistent */
#define IPC_EXCL   00002000   /* fail if key exists */
#define IPC_NOWAIT 00004000   /* return error on wait */

#define IPC_RMID 0     /* remove resource */
#define IPC_SET  1     /* set ipc_perm options */
#define IPC_STAT 2     /* get ipc_perm options */
#define IPC_INFO 3     /* see ipcs */

/*
 * Version flags for semctl, msgctl, and shmctl commands
 * These are passed as bitflags or-ed with the actual command
 */
#define IPC_OLD 0	/* Old version (no 32-bit UID support on many
			   architectures) */
#define IPC_64  0x0100  /* New version (support 32-bit UIDs, bigger
			   message sizes, etc. */

struct ipc_perm {
  key_t	key;
  uid_t	uid;
  gid_t	gid;
  uid_t	cuid;
  gid_t	cgid;
  mode_t	mode; 
  uint16_t	seq;
};

/* this is so bad, we moved it to -lcompat */
key_t ftok(const char *pathname, int proj_id);

__END_DECLS

#endif

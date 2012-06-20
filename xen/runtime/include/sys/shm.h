#ifndef _SYS_SHM_H
#define _SYS_SHM_H

#include <sys/ipc.h>

__BEGIN_DECLS

#define SHMMAX 0x2000000		 /* max shared seg size (bytes) */
#define SHMMIN 1			 /* min shared seg size (bytes) */
#define SHMMNI 4096			 /* max num of segs system wide */
#define SHMALL (SHMMAX/PAGE_SIZE*(SHMMNI/16)) /* max shm system wide (pages) */
#define SHMSEG SHMMNI			 /* max shared segs per process */

struct shmid_ds {
  struct ipc_perm	shm_perm;	/* operation perms */
  int32_t		shm_segsz;	/* size of segment (bytes) */
  time_t		shm_atime;	/* last attach time */
  time_t		shm_dtime;	/* last detach time */
  time_t		shm_ctime;	/* last change time */
  pid_t			shm_cpid;	/* pid of creator */
  pid_t			shm_lpid;	/* pid of last operator */
  uint16_t		shm_nattch;	/* no. of current attaches */
  uint16_t 		shm_unused;	/* compatibility */
  void 			*shm_unused2;	/* ditto - used by DIPC */
  void			*shm_unused3;	/* unused */
};

/* permission flag for shmget */
#define SHM_R		0400	/* or S_IRUGO from <linux/stat.h> */
#define SHM_W		0200	/* or S_IWUGO from <linux/stat.h> */

/* mode for attach */
#define	SHM_RDONLY	010000	/* read-only access */
#define	SHM_RND		020000	/* round attach address to SHMLBA boundary */
#define	SHM_REMAP	040000	/* take-over region on attach */

/* super user shmctl commands */
#define SHM_LOCK 	11
#define SHM_UNLOCK 	12

/* ipcs ctl commands */
#define SHM_STAT 	13
#define SHM_INFO 	14

/* Obsolete, used only for backwards compatibility */
struct	shminfo {
  int32_t shmmax;
  int32_t shmmin;
  int32_t shmmni;
  int32_t shmseg;
  int32_t shmall;
};

struct shm_info {
  int32_t used_ids;
  unsigned long shm_tot;	/* total allocated shm */
  unsigned long shm_rss;	/* total resident shm */
  unsigned long shm_swp;	/* total swapped shm */
  unsigned long swap_attempts;
  unsigned long swap_successes;
};

#if defined(__i386__) || defined(__mips__) || defined(__arm__) || defined(__powerpc__) || defined (__powerpc64__) || defined(__s390__) || defined(__hppa__) || defined(__x86_64__) || defined(__ia64__)
#define PAGE_SIZE 4096UL
#define PAGE_SHIFT 12
#elif defined(__alpha__) || defined(__sparc__)
/* sun4* has 4k except sun4 architecture, sparc64 has 8k */
#define PAGE_SIZE 8192UL
#define PAGE_SHIFT 13
#endif

extern int shmget(key_t key, int size, int shmflg) __THROW;
extern void *shmat(int shmid, const void *shmaddr, int shmflg) __THROW;
extern int shmdt (const void *shmaddr) __THROW;
extern int shmctl(int shmid, int cmd, struct shmid_ds *buf) __THROW;

__END_DECLS

#endif

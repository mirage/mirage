/* local definitions needed by mq routines */

#include <sys/msg.h>
#include <signal.h>

/* a message */
typedef struct
{
  unsigned int type;
  char text[1];
} MSG; 

union semun {
  int val;
  struct semid_ds *buf;
  unsigned short  *array;
} arg;

/*
 * One of these structures is malloced to describe any open message queue
 * each time mq_open is called. 
 */

struct libc_mq;

struct libc_mq {
  int              index;          /* index of this message queue */
  int              msgqid;         /* value returned by msgget */
  int              semid;          /* semaphore id */
  int              fd;             /* fd of shared memory file */
  int              oflag;          /* original open flag used */
  int              th;             /* thread id for mq_notify */
  char            *name;           /* name used */
  MSG             *wrbuf;          /* msg write buffer */
  MSG             *rdbuf;          /* msg read buffer */
  struct mq_attr  *attr;           /* pointer to attribute structure */
  struct sigevent *sigevent;       /* used for mq_notify */
  void (*cleanup_notify)(struct libc_mq *); /* also used for mq_notify */
  struct libc_mq  *next;           /* next info struct in hash table */
};

extern struct libc_mq *__find_mq (mqd_t mq);
extern void __cleanup_mq (mqd_t mq);
extern void __cleanup_mq_notify (struct libc_mq *ptr);

#define MSGQ_PREFIX "/dev/shm/__MSGQ__"


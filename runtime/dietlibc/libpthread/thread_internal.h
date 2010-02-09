#ifndef __THREAD_INTERNAL_H__
#define __THREAD_INTERNAL_H__

#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <stdarg.h>
#include <setjmp.h>
#include <resolv.h>

#include "dietfeatures.h"
#ifndef WANT_THREAD_SAFE
#error "the diet libc is not compiled with thread safeness enabled!"
#endif

extern int __modern_linux;	/* can be -1 (old linux), 0 (unknown), or 1 (new linux). */
/* if 1, assume 2.6 kernel with TLS and futexes et al */

#undef errno
#define _errno_ (*__errno_location())

/* cleanup */
struct thread_cleanup_t {
  struct thread_cleanup_t*next;
  void (*func)(void*);
  void *arg;
};

/* the thread descriptor / internal */
struct _pthread_descr_struct {
  /* modify only with __thread_struct_lock held */
  struct _pthread_descr_struct*next;
  struct _pthread_descr_struct**prev;

  /* thread/process data */
  pid_t pid;			/* Process id */

  /* "stack handling" / find thread */
  void*stack_begin;		/* begin of stack / lowest address (to free) */
  void*stack_end;		/* end   of stack / highest address */

  /* thread struct lock */
  struct _pthread_fastlock lock;
  struct _pthread_fastlock wlock;

  /* errno handling */
  int errno;

  /* thread exit handling */
  sigjmp_buf jmp_exit;		/* pthread_exit jump */
  void*retval;			/* thread return value */

  /* joined threads */
  struct _pthread_descr_struct*jt; /* joint thread */
  struct _pthread_fastlock joined; /* flag: other thread has joined */

  /* conditional variables */
  struct _pthread_descr_struct*waitnext; /* an other waiting thread or NULL */
  struct _pthread_descr_struct**waitprev;

  /* cancel handling */
  unsigned char cancelstate;		/* cancel state */
  volatile unsigned char canceltype;	/* type of cancellation */

  /* thread flags */
  volatile char dead;		/* thread has terminated */
  volatile char canceled;	/* thread canceled */
  char detached;		/* thread is detached */
  char stack_free;		/* stack is allocated by pthread_create */

  /* signal handling */
  char p_sig;			/* signal */

  /* creation parameter (RO) */
  void*(*func)(void*arg);	/* thread function */
  void*arg;			/* thread argument */
  unsigned long stack_size;	/* stack size for setrlimit */
  unsigned long guard_size;	/* stack guard size for setrlimit */

  /* cleanup stack (modify only with struct lock held) */
  struct thread_cleanup_t*cleanup_stack;

  /* thread specific data */
  void*tkd[PTHREAD_KEYS_MAX];

#ifdef PTHREAD_HANDLE_DNS_CORRECT
  /* DNS cruft */
  int h_errno;
  struct res_state __res;
#endif
} __attribute__((aligned(32)));
#define thread_sig_mask jmp_exit->__saved_mask

/* thread keys */
struct _thread_key {
  int used;
  void (*destructor)(void*);
};

/* internal stuff */

#define PTHREAD_SIG_RESTART (SIGRTMAX)
#define PTHREAD_SIG_CANCEL  (SIGRTMAX-1)
#define __CUR_RTMIN SIGRTMIN
#define __CUR_RTMAX (SIGRTMAX-2)

int __testandset(int*spinlock);

void __pthread_lock(struct _pthread_fastlock*lock);
int __pthread_trylock(struct _pthread_fastlock*lock);
int __pthread_unlock(struct _pthread_fastlock*lock);

#define LOCK(td)    __pthread_lock(&((td)->lock))
#define TRYLOCK(td) __pthread_trylock(&((td)->lock))
#define UNLOCK(td)  __pthread_unlock(&((td)->lock))

int __pthread_mutex_lock(pthread_mutex_t*mutex,_pthread_descr this);
int __pthread_mutex_unlock(pthread_mutex_t*mutex,_pthread_descr this);

int __clone(void*(*fn)(void*),void*stack,int flags,void*arg);
void __thread_manager_close(void);

struct _pthread_descr_struct*__thread_self(void);
struct _pthread_descr_struct*__thread_find(pthread_t pid);

int __thread_join(struct _pthread_descr_struct*td,void**return_value);
int __thread_join_cleanup(struct _pthread_descr_struct*td);

void __thread_restart(struct _pthread_descr_struct*td);
void __thread_suspend(struct _pthread_descr_struct*td,int cancel);
int __thread_suspend_till(struct _pthread_descr_struct*td,int cancel,const struct timespec*abstime);

void __thread_testcancel(struct _pthread_descr_struct*td);
int __thread_setcanceltype(int type,int*oldtype,struct _pthread_descr_struct*td);

/* ASYNC CANCEL ... */
#define __NO_ASYNC_CANCEL_BEGIN_(t) \
{ int oldtype; __thread_setcanceltype(PTHREAD_CANCEL_DEFERRED,&oldtype,(t));
#define __NO_ASYNC_CANCEL_END_(t) \
  __thread_setcanceltype(oldtype,0,(t)); __thread_testcancel((t)); }

#define __TEST_CANCEL_(t) __thread_testcancel(t)

#define __TEST_CANCEL() pthread_testcancel()

/* manager thread stuff */
typedef void(*MGR_func)(void*);
typedef struct __thread_manager_func {
  void(*func)(void*);
  void*arg;
} __thread_manager_func;

int __thread_send_manager(void(*f)(void*),void*arg);

typedef struct __thread_descr {
  struct _pthread_descr_struct*tr;	/* thread sending the request */
  struct _pthread_descr_struct*td;	/* new thread descriptor */
  pthread_attr_t*attr;	/* thread attr */
  pthread_t*pid;	/* pid of thread */
}*_thread_descr;

int __thread_getschedparam(pthread_t th,int*policy,struct sched_param*param);
int __thread_start_new(_thread_descr data);

/* diet libc syscalls */

void  __libc_free(void*ptr);
void *__libc_malloc(size_t size);
void *__libc_realloc(void*ptr,size_t size);

void __libc_closelog(void);
void __libc_openlog(const char*ident,int option,int facility);
void __libc_vsyslog(int priority,const char *format,va_list arg_ptr);

pid_t __libc_fork(void);

void __libc_exit(int retval) __attribute__((noreturn));

int __libc_close(int fd);
int __libc_creat(const char*pathname,mode_t mode);
int __libc_fcntl(int fd,int cmd,void*arg);
int __libc_fsync(int fd);
int __libc_fdatasync(int fd);
int __libc_msync(void*addr,size_t len,int flags);
int __libc_nanosleep(const struct timespec *req,struct timespec*rem);
int __libc_open(const char*pathname,int flags,mode_t mode);
int __libc_pause(void);
ssize_t __libc_read(int fd,void*buf,size_t count);
int __libc_sigsuspend(const sigset_t*mask);
int __libc_tcdrain(int fd);
pid_t __libc_waitpid(pid_t pid,int*status,int options);
ssize_t __libc_write(int fd,const void*buf,size_t count);

int __libc_execve(const char*filename,char*const argv[],char*const envp[]);
int __libc_sigaction(int signum,const struct sigaction*act,struct sigaction*oldact);

#endif

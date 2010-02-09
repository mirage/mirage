#define _GNU_SOURCE
#include <signal.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>

#include <poll.h>
#include <sched.h>
#include <sys/resource.h>

#include <stdlib.h>

#include <pthread.h>
#include "thread_internal.h"

//#define DEBUG

#ifdef DEBUG
#include <stdio.h>
#endif

#ifdef WANT_TLS
#include <sys/tls.h>
#endif

#define INTR_RETRY(e) ({ long ret; do ret=(long)(e); while ((ret==-1)&&(_errno_==EINTR)); ret; })

#define __NO_ASYNC_CANCEL_STOP }

static struct _pthread_descr_struct _main_thread={
  .stack_begin=0,
  .stack_end=(void*)~0,
  .lock={PTHREAD_SPIN_UNLOCKED},
};
static _pthread_descr manager_thread;

static pthread_once_t __thread_started=PTHREAD_ONCE_INIT;

static unsigned long __thread_pagesize;

static int __manager_pipe[2];
#define mgr_recv_fd __manager_pipe[0]
#define mgr_send_fd __manager_pipe[1]

/* only once :) */
static int __pthread_once(pthread_once_t*once_control,void (*init_routine)(void)) {
  if (!(__testandset(once_control))) init_routine();
  return 0;
}
int pthread_once(pthread_once_t*once_control,void(*init_routine)(void)) __attribute__((alias("__pthread_once")));

#define NR_BUCKETS (1<<8)	/* !!! MUST BE A POWER OF 2 !!! */
static _pthread_descr _thread_hash_tid[NR_BUCKETS];
static inline unsigned long hash_tid(int tid) { return (tid&(NR_BUCKETS-1)); }

/* O(1) */
#if defined(__i386__)
static void __attribute__((regparm(2))) __thread_add_tid_(_pthread_descr*root,_pthread_descr thread)
#else
static void __thread_add_tid_(_pthread_descr*root,_pthread_descr thread)
#endif
{
  _pthread_descr tmp=*root;
  thread->prev=root;
  thread->next=tmp;
  (*root)=thread;
  if (tmp) (tmp)->prev=(_pthread_descr*)thread;
}
/* add_list O(1) / this is called pre thread release (without ASYNC_CANCEL) */
static void __thread_add_list(_pthread_descr td) {
  __thread_add_tid_(&_thread_hash_tid[hash_tid(td->pid)],td);
}

/* del_list O(1) / there is only ONE grim reaper without ASYNC_CANCEL */
/* no reinit of struct, so no problem with the _thread_{self,find} functions */
static void __thread_del_list(_pthread_descr td) {
  _pthread_descr*save=td->prev;
  _pthread_descr next=td->next;
  *save=next;
  if (next) next->prev=save;
}

/* find thread by thread-id O(n) (LOCK struct if found) */
/* O(n*) linear to the number of thread in the same bucket */
#if defined(__i386__)
static _pthread_descr __thread_find_(int pid) __attribute__((regparm(1)));
_pthread_descr __thread_find(int pid) { return __thread_find_(pid); }
static _pthread_descr __attribute__((regparm(1))) __thread_find_(int pid)
#else
_pthread_descr __thread_find(int pid) __attribute__((alias("__thread_find_")));
static _pthread_descr __thread_find_(int pid)
#endif
{
  _pthread_descr cur;
  if (__thread_started==PTHREAD_ONCE_INIT) { /* uninitialised */
    LOCK(&_main_thread);
    return &_main_thread;
  }
  cur=_thread_hash_tid[hash_tid(pid)];
  while (cur) {
    _pthread_descr next=cur->next;
    if (pid==cur->pid) { LOCK(cur); break; }
    cur=next;
  }
  return cur;
}

/* get thread-self descriptor O(1)/O(n*) */
_pthread_descr __thread_self(void) {
  /* O(1) "search" */
#if defined(__alpha__)
  register _pthread_descr cur asm("$0");
  asm("call_pal 158" : "=r"(cur) );	/* PAL_rduniq = 158 */
#else	/* alpha */
  register _pthread_descr cur=0;
#if defined(__sparc__)
  asm("mov %%g6,%0" : "=r"(cur) );	/* %g6 (res. system use) is used as thread pointer */
#elif defined(__s390__)
  asm("ear %0,%%a0" : "=d"(cur) );	/* a0 (access register 0) is used as thread pointer */
#elif defined(__ia64__)
  asm("mov %0 = r13" : "=r"(cur) );	/* r13 (tp) is used as thread pointer */
#elif defined(__x86_64__)
  asm("mov %%fs:(16),%0" : "=r"(cur));
#elif defined(__i386__)
  if (__likely(__modern_linux==1))
    asm("mov %%gs:(8),%0" : "=r"(cur));
  else {
    /* old cruft O(n*) */
    cur=__thread_find_(getpid());
    if (cur) UNLOCK(cur);
  }
#else	/* other */
  /* all other archs:
   * search the thread depending on the PID O(n*) */
  cur=__thread_find_(getpid());
  if (cur) UNLOCK(cur);
#endif	/* other */
#endif	/* alpha */
  return (cur)?cur:&_main_thread;
}

/* support for manager / dispatch a signal to ALL threads
 * used for SIG{SEGV,FPE,...} and main thread exits */
static void kill_all_threads(int sig,int main2) {
  int i;
  if (main2) kill(_main_thread.pid,sig);
  for (i=0;i<NR_BUCKETS;++i) {
    _pthread_descr cur=_thread_hash_tid[i];
    for (;(cur &&(cur!=manager_thread));cur=cur->next) kill(cur->pid,sig);
  }
}


/* thread errno location */
int *__errno_location() {
  _pthread_descr td=__thread_self();
  return &(td->errno);
}

/* exit a thread */
static void __pthread_exit(void*retval) {
  _pthread_descr this=__thread_self();
  if (this==&_main_thread) __libc_exit((long)retval);
  __NO_ASYNC_CANCEL_BEGIN_(this);
  LOCK(this);
  this->cancelstate=PTHREAD_CANCEL_DISABLE;
  this->retval=retval;
  UNLOCK(this);
  __NO_ASYNC_CANCEL_STOP;
  siglongjmp(this->jmp_exit,1);
}
void pthread_exit(void*retval) __attribute__((alias("__pthread_exit")));

/* test canceled */
void __thread_testcancel(_pthread_descr td) {
  int cancel=0;
  if (td && (td->cancelstate==PTHREAD_CANCEL_ENABLE)) cancel=td->canceled;
  if (cancel) __pthread_exit(PTHREAD_CANCELED);
}
void pthread_testcancel() {
  __thread_testcancel(__thread_self());
}

/* set canceltype of thread */
int __thread_setcanceltype(int type,int*oldtype,_pthread_descr td) {
  if ((type!=PTHREAD_CANCEL_DEFERRED)&&(type!=PTHREAD_CANCEL_ASYNCHRONOUS)) return EINVAL;
  if (oldtype) *oldtype=td->canceltype;
  td->canceltype=type;
  return 0;
}
int pthread_setcanceltype(int type,int*oldtype) {
  return __thread_setcanceltype(type,oldtype,__thread_self());
}

/* sleep a little (reschedule for this time) */
static void __thread_sleep() {
  struct timespec reg;
  reg.tv_sec=0;
  reg.tv_nsec=SPIN_SLEEP_DURATION;
  __libc_nanosleep(&reg,0);
}

/*
 * cleanup / remove zombie thread
 * this is entered with "td" not in the list of threads and UNLOCKED !!!
 */
static int __thread_cleanup(_pthread_descr td) {
  int cnt=0;
  do { ++cnt;
    /* the next operations are only to make sure any thread_self that still uses "td" will go away */
    sched_yield();
    __thread_sleep();
    sched_yield();
    /* try lock of thread-struct (maybe still locked) */
  } while (TRYLOCK(td) && (cnt<MAX_SPIN_COUNT));
  /* ok now we are save to clean up the mess */
  if (td->stack_free) munmap(td->stack_begin,td->stack_size);
  return 0;
}

/* suspend till timeout or restart signal / in NO_ASYNC_CANCEL */
int __thread_suspend_till(_pthread_descr this,int cancel,const struct timespec*abstime) {
  sigset_t newmask,oldmask;
  struct timeval tv;
  struct timespec reg;
  int retval = 0;

  gettimeofday(&tv,0);
  reg.tv_nsec=abstime->tv_nsec-tv.tv_usec*1000;
  reg.tv_sec=abstime->tv_sec-tv.tv_sec;
  if (reg.tv_nsec<0) {
    reg.tv_nsec+=1000000000;
    reg.tv_sec-=1;
  }

  this->p_sig=0;
  /* Unblock the restart signal */
  sigemptyset(&newmask);
  sigaddset(&newmask,PTHREAD_SIG_RESTART);
  sigprocmask(SIG_UNBLOCK,&newmask,&oldmask);

  while(this->p_sig!=PTHREAD_SIG_RESTART) {
    if (cancel && (this->cancelstate==PTHREAD_CANCEL_ENABLE) && this->canceled) break;
    if (reg.tv_sec<0||__libc_nanosleep(&reg,&reg)==0) {
      retval = ETIMEDOUT;
      break;
    }
  }
  sigprocmask(SIG_SETMASK,&oldmask,0);
  return retval;
}

/* suspend till restart signal */
void __thread_suspend(_pthread_descr this,int cancel) {
  sigset_t mask;
  this->p_sig=0;
  sigprocmask(SIG_SETMASK,0,&mask);
  sigdelset(&mask,PTHREAD_SIG_RESTART);
  while (this->p_sig!=PTHREAD_SIG_RESTART) {
    if (cancel && (this->cancelstate==PTHREAD_CANCEL_ENABLE) && this->canceled) break;
    sigsuspend(&mask);
  }
}

/* restart a thread */
void __thread_restart(_pthread_descr td) {
  kill(td->pid,PTHREAD_SIG_RESTART);
  sched_yield();
  sched_yield();
}

/* restart signal handler */
static void pthread_handle_sigrestart(int sig) {
  _pthread_descr this=__thread_self();
  this->p_sig=sig;
#ifdef DEBUG
  printf("pthread_handle_sigrestart(%d) in %d\n",sig,this->pid);
#endif
}

/* cancel signal */
static void pthread_handle_sigcancel(int sig,siginfo_t*info,void*arg) {
  _pthread_descr this=__thread_self();
  if (0) { sig=0; arg=0; }
#ifdef DEBUG
  printf("pthread_handle_sigcancel(%d): sigcancel %d\n",sig,this->pid);
#endif
  /* manger part */
  if (this==manager_thread) {
    int pid=info->si_pid;
    if (pid==_main_thread.pid) {
#ifdef DEBUG
	printf("pthread_handle_sigcancel: kill from main: %d\n",pid);
#endif
	sched_yield();
	kill_all_threads(PTHREAD_SIG_CANCEL,0);
	sched_yield();
	__thread_sleep();
	kill_all_threads(SIGKILL,0);
	__thread_sleep();
	_exit(0);
    }
#ifdef DEBUG
    else printf("pthread_handle_sigcancel: signal from thread %d ?\n",pid);
#endif
  }
  /* main thread part */
  else if (this==&_main_thread) {
#ifdef DEBUG
    printf("pthread_handle_sigcancel: %d : cancel event for MAIN\n",this->pid);
#endif
    /* kill the manager and wait for it */
    kill(manager_thread->pid,PTHREAD_SIG_CANCEL);
    __libc_waitpid(manager_thread->pid,0,WNOHANG|__WCLONE);
    /* jump to an exit slot */
    siglongjmp(_main_thread.jmp_exit,1);
  }
  /* all other just cancel */
  else if (this->cancelstate==PTHREAD_CANCEL_ENABLE) {
#ifdef DEBUG
    printf("pthread_handle_sigcancel: %d : cancel event\n",this->pid);
#endif
    this->canceled=1;
    if (this->canceltype==PTHREAD_CANCEL_ASYNCHRONOUS) {
      __pthread_exit(PTHREAD_CANCELED);
    }
  }
}

/* nop functions */
static int __thread_nop() { return 0; }
int pthread_condattr_init(pthread_condattr_t*attr)	__attribute__((alias("__thread_nop")));
int pthread_condattr_destroy(pthread_condattr_t*attr)	__attribute__((alias("__thread_nop")));

/* thread specific data -- key glue */
void __thread_start__key(_pthread_descr td)	__attribute__((weak,alias("__thread_nop")));
void __thread_exit__key(_pthread_descr td)	__attribute__((weak,alias("__thread_nop")));
void pthread_cleanup_pop(int execute)		__attribute__((weak,alias("__thread_nop")));

/* machine depending thread register */
static inline _pthread_descr __thread_set_register(void*arg) {
#if defined(__alpha__)
  asm volatile ("call_pal 159" : : "r"(arg) );	/* PAL_wruniq = 159 */
#elif defined(__sparc__)
  asm volatile ("mov %0,%%g6" : : "r"(arg) );
#elif defined(__s390__)
  asm volatile ("sar %%a0,%0" : : "d"(arg) );
#elif defined(__ia64__)
  asm volatile ("mov r13 = %0" : : "r"(arg) );
#endif
  return (_pthread_descr)arg;
}

#ifdef WANT_TLS
extern size_t __tdatasize, __tmemsize;
extern void* __tdataptr;
extern void __setup_tls(tcbhead_t* thread);
#endif

#ifdef WANT_SSP
extern unsigned long __guard;
#endif

#if defined(WANT_TLS) || defined(WANT_SSP)
extern tcbhead_t* __tcb_mainthread;
#endif

/* thread start helper */
static void* __managed_start(void*arg) {
#if defined(__sparc__)
  register _pthread_descr td asm("%g6");
#elif defined(__ia64__)
  register _pthread_descr td asm("r13");
#else
  _pthread_descr td;
#endif
#if defined(WANT_TLS) || defined(WANT_SSP)
  __tcb_mainthread->multiple_threads=1;
  tcbhead_t* me=alloca(sizeof(tcbhead_t)
#ifdef WANT_TLS
		                        +__tmemsize);
/*  printf("allocating %lu bytes (%lu + %lu)\n",sizeof(tcbhead_t)+__tmemsize,sizeof(tcbhead_t),__tmemsize); */
  memcpy(me,__tdataptr,__tdatasize);
  memset(((char*)me)+__tdatasize,0,__tmemsize-__tdatasize);
  me=(tcbhead_t*)(((char*)me) + __tmemsize);
#endif
  __setup_tls(me);
  me->multiple_threads=1;

#ifdef WANT_SSP
  me->pointer_guard=__guard ^ (uintptr_t)me;
#endif
  me->self=arg;
  td=arg;
  __thread_set_register(me);

#else
  td=__thread_set_register(arg);
#endif

#ifdef WANT_TLS
#endif

  td->pid=getpid();
#ifdef DEBUG
  printf("__managed_start: %d pre suspend\n",td->pid);
#endif
  /* wait for manager to release us */
  __thread_suspend(td,1);
  sigprocmask(SIG_SETMASK,&(td->thread_sig_mask),0);

#ifdef DEBUG
  printf("__managed_start: %d, parameter %8p\n",td->pid,td->func);
#endif
  if (td->canceled) {
    td->retval=PTHREAD_CANCELED;
    return (void*)42;
  }
  /* limit stack so that we NEVER have to worry */
  {
#define __RLIMIT__ td->stack_size-__thread_pagesize /* subtract a safety margin (i.a. 1 page) */
    struct rlimit l={__RLIMIT__,__RLIMIT__};
    setrlimit(RLIMIT_STACK,&l);
#undef __RLIMIT__
  }

  __thread_start__key(td);	/* thread_key glue */

  if (td->canceled==0) {
    if (sigsetjmp(td->jmp_exit,1)==0) {
      td->retval=td->func(td->arg);
#ifdef DEBUG
    } else {
      printf("__managed_start: pthread_exit called in %d\n",td->pid);
#endif
    }
  }
  __NO_ASYNC_CANCEL_BEGIN_(td);
  __thread_exit__key(td);	/* thread_key glue */

  /* execute all functions on the cleanup-stack */
  while (td->cleanup_stack) pthread_cleanup_pop(1);

  return 0;
  __NO_ASYNC_CANCEL_STOP;
}

/* ... */
static int _thread_getschedparam(pthread_t th,int*policy,struct sched_param*param) {
  int p;
  if (((p=sched_getscheduler(th))==-1)||(sched_getparam(th,param)==-1)) return _errno_;
  *policy=p;
  return 0;
}
int __thread_getschedparam(pthread_t th,int*policy,struct sched_param*param)
__attribute__((alias("_thread_getschedparam")));
/* get thread schedul parameters */
int pthread_getschedparam(pthread_t th,int*policy,struct sched_param*param) {
  _pthread_descr td,this=__thread_self();
  int ret=ESRCH;
  __NO_ASYNC_CANCEL_BEGIN_(this);
  if ((td=__thread_find(th))) {
    UNLOCK(td);
    ret=_thread_getschedparam(th,policy,param);
  }
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}


/* thread manage internal stuff */
/* #define CLONE_FLAGS (CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|PTHREAD_SIG_CANCEL) */
#define CLONE_FLAGS (CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND)

void __thread_manager_close(void) {
  __thread_started=PTHREAD_ONCE_INIT;
  close(mgr_recv_fd);
  close(mgr_send_fd);
  /* FIXME: missing: resource deallocation (free of unused thread stacks) */
  /* reinit of main thread struct */
  memset(_thread_hash_tid,0,sizeof(_thread_hash_tid));
  _main_thread.stack_begin=0;
  _main_thread.stack_end=(void*)~0;
  _main_thread.lock.__spinlock=PTHREAD_SPIN_UNLOCKED;
  _main_thread.pid=getpid();
  manager_thread=0;
}

static void __MGR_thread_start_new(_thread_descr data) {
  _pthread_descr td=data->td;
  pthread_attr_t*attr=data->attr;
  if ((td->pid=(*(data->pid))=__clone(__managed_start,attr->__stackaddr,CLONE_FLAGS,td))!=-1) {
    sched_setscheduler(td->pid,attr->__schedpolicy,&attr->__schedparam);
    __thread_add_list(td);
    __thread_restart(td); 	/* let the thread loose */
  }
#ifdef DEBUG
  printf("__MGR_thread_start_new: created thread %d\n",td->pid);
#endif
  __thread_restart(data->tr);	/* restart request sender */
}

static void __MGR_thread_join_cleanup(_pthread_descr td) {
#ifdef DEBUG
  printf("__MGR_thread_join_cleanup: wind up red-tape for thread %d\n",td->pid);
#endif
  __thread_del_list(td);
  UNLOCK(td);
  __thread_cleanup(td);
}

/* manager thread */
static char __manager_thread_stack[PTHREAD_STACK_SIZE];
__attribute__((noreturn))
static void*__manager_thread(void*arg) {
  sigset_t manager_mask;
  struct pollfd pfd;
  _pthread_descr td;
  int n,status;
  if (0) arg=0;
  pfd.fd=mgr_recv_fd;
  pfd.events=POLLIN;

  sigfillset(&manager_mask);
  sigdelset(&manager_mask,PTHREAD_SIG_CANCEL);
  sigdelset(&manager_mask,SIGTRAP);
  sigprocmask(SIG_SETMASK,&manager_mask,0);
#ifdef DEBUG
  printf("manager pre start sleep \n");
#endif

  __thread_sleep();
  sched_yield();
  /* restart main thread */
  __thread_restart(&_main_thread);

  while(1) {
    n=poll(&pfd,1,30);
    if (getppid()==1) {
      /* main thread is dead: commit suicide */
#ifdef DEBUG
      printf("main thread is dead\n");
#endif
      kill_all_threads(SIGKILL,0);
      _exit(0);
    }
    if (n==1) {
      __thread_manager_func data;
      if (INTR_RETRY(__libc_read(mgr_recv_fd,&data,sizeof(data)))==sizeof(data)) {
#ifdef DEBUG
	printf("__manager_thread: do func %08x %08x\n",data.func,data.arg);
#endif
	data.func(data.arg);
      }
    }
    while ((n=__libc_waitpid(-1,&status,WNOHANG|__WCLONE))!=-1) {
      if (!n) break;	/* ?!? WHY DOES WAITPID RETURN ZERO ?!? */
#ifdef DEBUG
      printf("__manager_thread waitpid %d %d\n",n,WTERMSIG(status));
#endif
      if ((td=__thread_find(n))) {
	if (WIFSIGNALED(status)) {
	  if (WTERMSIG(status)!=PTHREAD_SIG_CANCEL) {
#ifdef DEBUG
	    printf("__manager_thread: thread %d was killed by %d\n",n,WTERMSIG(status));
#endif
	    /* Oh, oohhhhhh.... */
	    sched_yield();
#ifdef DEBUG
	    kill_all_threads(SIGKILL,1);
#else
	    kill_all_threads(WTERMSIG(status),1);
#endif
	    sched_yield();
	    __thread_sleep();
	    kill_all_threads(SIGKILL,1);
	    __thread_sleep();
	    _exit(0);
	  }
	}
#ifdef DEBUG
	printf("__manager_thread: thread %d is dead\n",n);
#endif
	if (td->detached) __MGR_thread_join_cleanup(td);
	else {
	  td->canceled|=2;
	  td->dead=1;
	  UNLOCK(td);
	  if (td->joined.__spinlock==PTHREAD_SPIN_LOCKED) __thread_restart(td->jt);
	}
      }
    }
  }
}

/* exit process */	/* FIXME: is there a bug here ? */
void __thread_doexit(long retval);
void __thread_doexit(long retval) {
  _pthread_descr this=__thread_self();
#ifdef DEBUG
  printf("__thread_doexit: %d\n",this->pid);
#endif
  if (this!=&_main_thread) {
    this->retval=0;
    _main_thread.retval=(void*)retval;
    kill(_main_thread.pid,PTHREAD_SIG_CANCEL); /* send main the EXIT */
    siglongjmp(this->jmp_exit,1);
  }
  /* main thread */
  if (sigsetjmp(_main_thread.jmp_exit,1)==0) {
    if (manager_thread && manager_thread->pid && (kill(manager_thread->pid,PTHREAD_SIG_CANCEL)!=-1)) {
      __thread_suspend(&_main_thread,0); /* there is still a manager */
    }
  }
  kill_all_threads(SIGKILL,0);
}

/* "boot" manager thread */
static void __manager_thread_init() {
  char*stack;
#ifdef __parisc__
  manager_thread=(_pthread_descr)__manager_thread_stack;
  stack=__manager_thread_stack+sizeof(struct _pthread_descr_struct);
#else
  stack=__manager_thread_stack+(sizeof(__manager_thread_stack)-sizeof(struct _pthread_descr_struct));
  manager_thread=(_pthread_descr)stack;
#endif
  memset(manager_thread,0,sizeof(struct _pthread_descr_struct));
  manager_thread->stack_begin=__manager_thread_stack;
  manager_thread->stack_end=__manager_thread_stack+sizeof(__manager_thread_stack);
  manager_thread->stack_size=sizeof(__manager_thread_stack);
  manager_thread->func=__manager_thread;
  manager_thread->arg=0;
  manager_thread->lock.__spinlock=PTHREAD_SPIN_UNLOCKED;
  manager_thread->joined.__spinlock=PTHREAD_SPIN_LOCKED;
  _main_thread.pid=getpid();
  /* set arch defined thread register */
  __thread_set_register(&_main_thread);
  if (pipe(__manager_pipe)==-1) __libc_exit(42);
  /* create manager */
  if ((manager_thread->pid=__clone(__managed_start,stack,CLONE_FLAGS|PTHREAD_SIG_CANCEL,manager_thread))==-1) __libc_exit(43);
  __thread_add_list(manager_thread);
  __thread_restart(manager_thread);
#ifdef DEBUG
  printf("__manager_thread_init: mgr restart...\n");
#endif
  __thread_suspend(&_main_thread,0);
#ifdef DEBUG
  printf("__manager_thread_init: thread-mgr should now be started...\n");
#endif
}

/* init of thread library */
static void __thread_init() {
  struct sigaction sa;
  sigset_t mask;
  memset(&sa,0,sizeof(struct sigaction));

#ifdef DEBUG
  printf("__thread_init: start...\n");
#endif

  /* get pagesize for guard */
  __thread_pagesize=getpagesize();

  /* setup signal handlers */
  sigemptyset(&sa.sa_mask);
  sa.sa_handler=pthread_handle_sigrestart;
  __libc_sigaction(PTHREAD_SIG_RESTART,&sa,0);
  sa.sa_flags=SA_SIGINFO;
  sa.sa_handler=0;
  sa.sa_sigaction=pthread_handle_sigcancel;
  __libc_sigaction(PTHREAD_SIG_CANCEL ,&sa,0);

  /* block restart / unblock cancel */
  sigprocmask(SIG_SETMASK,0,&mask);
  sigaddset(&mask,PTHREAD_SIG_RESTART);
  sigdelset(&mask,PTHREAD_SIG_CANCEL);
  sigprocmask(SIG_SETMASK,&mask,0);
#ifdef DEBUG
  printf("__thread_init: start mgr...\n");
#endif
  __manager_thread_init();
  if (sigsetjmp(_main_thread.jmp_exit,1)) {
#ifdef DEBUG
    printf("__thread_init: 'exit()' called in thread...\n");
#endif
    __libc_exit((long)_main_thread.retval);
  }
}

/* send the manager a function and an argument to run */
static int __MGR_send(void(*f)(void*),void*arg) {
  __thread_manager_func data={ .func=f, .arg=arg, };
  __pthread_once(&__thread_started,__thread_init);
  return INTR_RETRY(__libc_write(mgr_send_fd,&data,sizeof(data)));
}
int __thread_send_manager(void(*f)(void*),void*arg) __attribute__((alias("__MGR_send")));

/* start a new thread */
int __thread_start_new(_thread_descr data) {
  int pid;

  data->pid=&pid;

  if (__MGR_send((MGR_func)__MGR_thread_start_new,data)==-1) {
    __thread_cleanup(data->tr);
    return -1;
  }
  __thread_suspend(data->tr,0);
  return pid;
}

int __thread_join_cleanup(_pthread_descr td) {
  return __MGR_send((MGR_func)__MGR_thread_join_cleanup,td)==0;
}

//int __G_E_T() { return sizeof(struct _pthread_descr_struct); }


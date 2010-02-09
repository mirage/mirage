#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>

#include <errno.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

#define pr(s) write(1,s,sizeof(s)-1)
#define pl(s) write(1,s,strlen(s))
#define _die_(s) do { write(2,s,sizeof(s)-1); exit(2); } while(0)

#if 0
static void ph(unsigned long v) {
  const char foo[16]="0123456789abcdef";
  char buf[sizeof(long)<<1];
  int i;
  for (i=sizeof(buf);i--;v>>=4) { buf[i]=foo[v&15]; }
  write(1,buf,sizeof(buf));
}
#endif

/* (0) once test */
void test0_ok() { pr("(once called) "); }
void test0_failed() { _die_("failed...\n"); }
void test0() {
  pthread_once_t v_once=PTHREAD_ONCE_INIT;
  pr("\nTEST 0: once test:\n\n");
  pr("testing once function... ");
  pthread_once(&v_once,test0_ok);
  pthread_once(&v_once,test0_failed);
  pr("OK.\n");
}

/* (1) mutex tests */
pthread_mutex_t*hang_m;
volatile int hangok;
void sig_alrm(int sig) {
  signal(SIGALRM,sig_alrm);
  alarm(2);
  if (0) sig=0;
  if (hangok==0) _die_("still hanging\n");
  --hangok;
  hang_m->owner=__thread_self();
  pthread_mutex_unlock(hang_m);
  hang_m->owner=0;
}

void test_block_try() {
  pthread_mutex_t tm=PTHREAD_MUTEX_INITIALIZER;
  hang_m=&tm;
  alarm(1);
  pr("testing block of a mutex (takes 1-5 second)... ");
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on unused mutex...\n");
  hangok=1;
  tm.owner=0;
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on taken mutex...\n");
  if (hangok) _die_("failed... still unblocked\n");
  pr("OK.\n");
  pr("testing trylock... ");
  tm.owner=0;
  if (pthread_mutex_trylock(&tm) != EBUSY) _die_("failed... mutex_trylock on blocked mutex...\n");
  tm.owner=__thread_self();
  if (pthread_mutex_trylock(&tm) != 0) _die_("failed... mutex_trylock on taken mutex...\n");
  pr("OK.\n");
  alarm(0);
}

void test_mutex() {
  pthread_mutex_t tm=PTHREAD_MUTEX_INITIALIZER;
  pr("testing basic mutex... ");
  alarm(5);
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on unused mutex...\n");
  if (tm.owner!=__thread_self()) _die_("failed.. no owner....\n");
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on taken mutex...\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on taken mutex...\n");
  if (tm.owner!=0) _die_("failed... still owned ?!?!\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on free mutex...\n");
  alarm(0);
  pr("OK.\n");
}

void test_rec_mutex() {
  pthread_mutex_t tm=PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP;
  pr("testing recursive mutex... ");
  alarm(5);
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on unused rec-mutex (c=0)...\n");
  if (tm.owner!=__thread_self()) _die_("failed.. wrong owner....\n");
  if (tm.count!=1) _die_("failed... wrong counting (c!=1)....\n");
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on taken rec-mutex (c=1)...\n");
  if (tm.count!=2) _die_("failed... wrong counting (c!=2)....\n");
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on taken rec-mutex (c=2)...\n");
  if (tm.count!=3) _die_("failed... wrong counting (c!=3)....\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on taken rec-mutex (c=3)...\n");
  if (tm.count!=2) _die_("failed... wrong counting (c!=2)....\n");
  if (tm.owner==0) _die_("failed... mutex has no owner?!?!\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on taken rec-mutex (c=2)...\n");
  if (tm.count!=1) _die_("failed... wrong counting (c!=1)....\n");
  if (tm.owner==0) _die_("failed... mutex has no owner?!?!\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on taken rec-mutex (c=1)...\n");
  if (tm.count!=0) _die_("failed... wrong counting (c!=0)....\n");
  if (tm.owner!=0) _die_("failed... mutex still owned ?!?!\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on free rec-mutex (c=0)...\n");
  alarm(0);
  pr("OK.\n");
}

void test_err_mutex() {
  pthread_mutex_t tm=PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;
  pr("testing errorcheck mutex... ");
  alarm(5);
  if (pthread_mutex_lock(&tm) != 0) _die_("failed... mutex_lock on unused errchk-mutex...\n");
  if (tm.owner!=__thread_self()) _die_("failed.. wrong owner....\n");
  if (pthread_mutex_lock(&tm) != EDEADLK) _die_("failed... mutex_lock on taken errchk-mutex...\n");
  if (pthread_mutex_unlock(&tm) != 0) _die_("failed... mutex_unlock on taken errchk-mutex...\n");
  if (tm.owner!=0) _die_("failed... mutex still owned ?!?!\n");
  if (pthread_mutex_unlock(&tm) != EPERM) _die_("failed... mutex_unlock on free errchk-mutex...\n");
  alarm(0);
  pr("OK.\n");
}

void test_init_mutex() {
  pthread_mutex_t tm=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t te=PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;
  pthread_mutexattr_t ta;
  pthread_mutex_t tt;
  pr("testing mutex initalizer... ");

  pthread_mutex_init(&tt,0);
  if (memcmp(&tt,&tm,sizeof(pthread_mutex_t))) _die_("failed... default init...\n");

  pthread_mutexattr_init(&ta);
  pthread_mutex_init(&tt,&ta);
  if (memcmp(&tt,&tm,sizeof(pthread_mutex_t))) _die_("failed... default with attr init...\n");

  pthread_mutexattr_init(&ta);
  if (pthread_mutexattr_setkind_np(&ta,23) == 0) _die_("failed... can set unsupported value !\n");
  if (pthread_mutexattr_setkind_np(&ta,PTHREAD_MUTEX_ERRORCHECK_NP) != 0) _die_("failed... can't set basic type...\n");
  pthread_mutex_init(&tt,&ta);
  if (memcmp(&tt,&te,sizeof(pthread_mutex_t)))
    _die_("failed... mutexattr generated mutex is not equal to the static init...\n");
  pr("OK.\n");
}

void test1() {
  pr("\nTEST 1: mutex test:\n\n");
  test_init_mutex();
  test_mutex();
  test_rec_mutex();
  test_err_mutex();
  test_block_try();
}

/* (2) thread attr function tests */

void*thread(void*arg) {
  if (0) { arg=0; }
  pr("(thread created) ");
  sleep(1);
  pr("(thread exit) ");
  return 0;
}

void test_thread() {
  pthread_t t;
  pr("testing basic thread creation and join... ");
  if ((pthread_create(&t,0,thread,0))!=0) _die_("failed...\n");
  if (kill(t,0)==-1) _die_("failed... no thread cloned");
  if (pthread_join(t,0) != 0) _die_("failed... joining thread\n");
  pr("OK.\n");
}

void test_thread_join_detached() {
  pthread_t t;
  pthread_attr_t attr;
  pr("testing for failing join of a detached thread... ");
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);
  if ((pthread_create(&t,&attr,thread,0))!=0) _die_("failed...\n");
  if (pthread_join(t,0) == 0) _die_("failed... I had joined a detached thread !\n");
  sleep(2);
  pr("OK.\n");
}

static char alt_stack[64<<10];
void test_thread_alt_stack() {
  pthread_t t;
  pthread_attr_t attr;
  pr("testing alternate thread stack... ");
  pthread_attr_init(&attr);
  pthread_attr_setstacksize(&attr,64<<10);
  if ((pthread_create(&t,&attr,thread,0))!=0) _die_("failed... creating thread\n");
  if (pthread_join(t,0) != 0) _die_("failed... joining thread\n");
  pthread_attr_setstackaddr(&attr,alt_stack);
  if ((pthread_create(&t,&attr,thread,0))!=0) _die_("failed... creating thread\n");
  if (pthread_join(t,0) != 0) _die_("failed... joining thread\n");
  pr("OK.\n");
}

void test2() {
  pr("\nTEST 2: thread creation & attributes:\n\n");
  test_thread();
  test_thread_join_detached();
  test_thread_alt_stack();
}

/* (3) condition variables and mutex the 2nd */
pthread_cond_t test_cond=PTHREAD_COND_INITIALIZER;
pthread_mutex_t test_cond_mutex=PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t test_cond_exit_mutex=PTHREAD_MUTEX_INITIALIZER;

void*thread_cond_wait(void*arg) {
  if (arg) pr("(thread_cond_wait create) ");
  pthread_mutex_lock(&test_cond_mutex);
  if (pthread_cond_wait(&test_cond,&test_cond_mutex) != 0) _die_("failed... wait\n");
  pthread_mutex_unlock(&test_cond_mutex);
  if (arg) pr("(thread_cond_wait exit) ");
  pthread_mutex_unlock(&test_cond_exit_mutex);
  return 0;
}

void test_conditions() {
  pthread_cond_t c=PTHREAD_COND_INITIALIZER;
  pr("testing basic condition initializer/destructor... ");
  pthread_cond_init(&test_cond,0);
  if (memcmp(&test_cond,&c,sizeof(pthread_cond_t))) _die_("failed... initializer\n");
  if (pthread_cond_destroy(&test_cond)!=0) _die_("failed... destructor\n");
  pr("OK.\n");
}

void test_conditions_timed() {
  struct timeval tv;
  struct timespec ts;
  pthread_cond_init(&test_cond,0);
  pr("testing condition timedwait (takes 1-4 seconds)... ");
  pthread_mutex_lock(&test_cond_mutex);
  if (gettimeofday(&tv,0)) _die_("failed... >>> gettimeofday\n");
  ts.tv_sec=tv.tv_sec+2;
  ts.tv_nsec=0;
  alarm(4);
  if (pthread_cond_timedwait(&test_cond,&test_cond_mutex,&ts) != 0) _die_("failed... timedwait\n");
  alarm(0);
  pthread_mutex_unlock(&test_cond_mutex);
  pr("OK.\n");
}

void test_conditions_signal() {
  pthread_t t1,t2,t3;
  pr("- creating two threads for condition signal... ");
  pthread_mutex_lock(&test_cond_mutex);
  if ((pthread_create(&t1,0,thread_cond_wait,0))!=0) _die_("failed...\n");
  if ((pthread_create(&t2,0,thread_cond_wait,0))!=0) _die_("failed...\n");
  pthread_mutex_unlock(&test_cond_mutex);
  pr("OK.\n");
  sleep(1);
  pr("testing failure of destroy on used condition variable... ");
  if (pthread_cond_destroy(&test_cond)==0) _die_("failed... still in use but destroied\n");
  pr("OK.\n");
  pr("testing cged_startondition signal (takes 4-6 seconds)... ");
  pthread_mutex_lock(&test_cond_exit_mutex);
  alarm(10);
  sleep(1);
  pr("<signal nr 1> ");
  pthread_cond_signal(&test_cond);
  pthread_mutex_lock(&test_cond_exit_mutex);
  sleep(1);
  pr("(new thread for wait-chain test) ");
  if ((pthread_create(&t3,0,thread_cond_wait,0))!=0) _die_("failed... thread creation\n");
  sleep(1);
  pr("<signal nr 2> ");
  pthread_cond_signal(&test_cond);
  pthread_mutex_lock(&test_cond_exit_mutex);
  sleep(1);
  pr("<signal nr 3> ");
  pthread_cond_signal(&test_cond);
  pthread_mutex_lock(&test_cond_exit_mutex);
  alarm(0);
  sleep(1);
  if (kill(t1,0)==0) _die_("failed... thread (nr. 1) ignored signal\n");
  if (kill(t2,0)==0) _die_("failed... thread (nr. 2) ignored signal\n");
  if (kill(t3,0)==0) _die_("failed... thread (nr. 3) ignored signal\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t3,0) != 0) _die_("failed... joining thread\n");
  pr("OK.\n");
}

void test_conditions_broadcast() {
  pthread_t t1,t2,t3;
  pr("testing condition broadcast (takes 4-5 seconds)... ");
  pthread_mutex_lock(&test_cond_mutex);
  if ((pthread_create(&t1,0,thread_cond_wait,0))!=0) _die_("failed... thread creation\n");
  if ((pthread_create(&t2,0,thread_cond_wait,0))!=0) _die_("failed... thread creation\n");
  if ((pthread_create(&t3,0,thread_cond_wait,0))!=0) _die_("failed... thread creation\n");
  pthread_mutex_unlock(&test_cond_mutex);
  sleep(1);
  alarm(4);
  pr("<broadcast> ");
  pthread_cond_broadcast(&test_cond);
  sleep(3);
  if (kill(t1,0)==0) _die_("failed... thread (nr. 1) ignored signal\n");
  if (kill(t2,0)==0) _die_("failed... thread (nr. 2) ignored signal\n");
  if (kill(t3,0)==0) _die_("failed... thread (nr. 3) ignored signal\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t3,0) != 0) _die_("failed... joining thread\n");
  alarm(0);
  pr("OK.\n");
}

void*thread_cond_timedwait(void*arg) {
  struct timeval tv;
  struct timespec ts;
  if (0) { arg=0; }
  if (gettimeofday(&tv,0)) _die_("failed... >>> gettimeofday\n");
  ts.tv_sec=tv.tv_sec+1;
  ts.tv_nsec=tv.tv_usec/1000;
  pr("(thread_cond_timedwait created) ");
  pthread_mutex_lock(&test_cond_mutex);
  if (pthread_cond_timedwait(&test_cond,&test_cond_mutex,&ts) != 0) _die_("failed... timedwait\n");
  pthread_mutex_unlock(&test_cond_mutex);
  pr("(thread_cond_timedwait exit) ");
  pthread_mutex_unlock(&test_cond_exit_mutex);
  return 0;
}
void test_conditions_mixed() {
  pthread_t t1,t2,t3;
  pr("testing condition mixed wait and timedwait (takes 3-5 seconds)... ");
  pthread_mutex_lock(&test_cond_exit_mutex);
  pthread_mutex_lock(&test_cond_mutex);
  if ((pthread_create(&t1,0,thread_cond_wait,(void*)1))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t2,0,thread_cond_timedwait,(void*)1))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t3,0,thread_cond_wait,(void*)1))!=0) _die_("failed... (creating a thread)\n");
  pthread_mutex_unlock(&test_cond_mutex);
  sleep(1);
  alarm(5);
  pthread_mutex_lock(&test_cond_exit_mutex);
  pthread_cond_broadcast(&test_cond);
  sleep(2);
  if (kill(t1,0)==0) _die_("failed... thread (nr. 1) ignored signal\n");
  if (kill(t2,0)==0) _die_("failed... thread (nr. 2) ignored signal\n");
  if (kill(t3,0)==0) _die_("failed... thread (nr. 3) ignored signal\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t3,0) != 0) _die_("failed... joining thread\n");
  alarm(0);
  pr("OK.\n");
}

void test3() {
  pr("\nTEST 3: condition variables and mutexes:\n\n");
  test_conditions();
  test_conditions_timed();
  test_conditions_signal();
  test_conditions_broadcast();
  test_conditions_mixed();
}

/* (4) cancelation & cleanup tests */
void*thread_exit() {
  pthread_exit((void*)42);
  return 0;
}

void test4_thread_exit() {
  pthread_t t;
  void*retval;
  pr("testing pthread_exit... ");
  if ((pthread_create(&t,0,thread_exit,0))!=0) _die_("failed... creating thread\n");
  if (pthread_join(t,&retval) != 0) _die_("failed... joining thread\n");
  if (kill(t,0)!=-1) _die_("failed... thread exit\n");
  if (retval!=(void*)42) _die_("failed... join retval\n");
  pr("OK.\n");
}

int thread_cleanuptest_data=0;
void thread_cleanuptest() {
  pr("{cleanup} ");
  thread_cleanuptest_data=1;
}
void*thread_cancel(void*a) {
  pthread_cleanup_push(thread_cleanuptest,0);
  while(a) {
    sleep(1);
    pr("(!canceled) ");
  }
  return 0;
}
void test4_cleanup() {
  pthread_t t1;
  pr("testing the cleanup stack... ");
  if ((pthread_create(&t1,0,thread_cancel,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (thread_cleanuptest_data==0) _die_("failed... no call to cleanup\n");
  pr("OK.\n");
}

void*thread_canceler(void*a) {
  sleep(3);
  pr("<send cancel> ");
  if (pthread_cancel(*((pthread_t*)a))) {
    _die_("cancel error\n");
  }
  return 0;
}
void test4_cancelation() {
  pthread_t t1,t2;
  thread_cleanuptest_data=0;
  pr("testing cancelation and cleanup stack (takes 3-4 seconds)... ");
  if ((pthread_create(&t1,0,thread_cancel,(void*)1))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t2,0,thread_canceler,(void*)&t1))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (thread_cleanuptest_data==0) _die_("failed... no call to cleanup\n");
  if (kill(t1,0)!=-1) _die_("failed... thread cancelation\n");
  if (kill(t2,0)!=-1) _die_("failed... thread cancelation\n");
  pr("OK.\n");
}


void*thread_cancel_async(void*a) {
  unsigned int i;
  if (a) pthread_cleanup_push(thread_cleanuptest,0);
  pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,0);
  pr("(act)... ");
  for(i=1;;++i) {
    if ((i&0xfffffff)==0) pr("(!canceled) ");
  }
  return 0;
}

void test4_asynccancel() {
  pthread_t t1,t2;
  thread_cleanuptest_data=0;
  pr("testing async cancelation and cleanup stack (takes 5-6 seconds)... ");
  if ((pthread_create(&t1,0,thread_cancel_async,(void*)1))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t2,0,thread_canceler,(void*)&t1))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (thread_cleanuptest_data==0) _die_("failed... no call to cleanup\n");
  if (kill(t1,0)!=-1) _die_("failed... thread cancelation\n");
  if (kill(t2,0)!=-1) _die_("failed... thread cancelation\n");
  pr("OK.\n");
}

void test4() {
  pr("\nTEST 4: cancelation & cleanup:\n\n");
  test4_thread_exit();
  test4_cleanup();
  test4_cancelation();
  test4_asynccancel();
}

/* (5) unix signaling */

int test5_signaled=0;

void test5_sighandler() {
  pr("{SIGUSR1} ");
  signal(SIGUSR1,test5_sighandler);
  test5_signaled=1;
}

void*test5_0() {
  pr("testing the user signal... ");
  signal(SIGUSR1,test5_sighandler);
  sleep(1);
  raise(SIGUSR1);
  sleep(1);
  if (test5_signaled==0) _die_("failed... no signal caught\n");
  pr("OK.\n");
  return 0;
}

void test5_1() {
  pthread_t t1;
  test5_signaled=0;
  pr("IN A THREAD... ");
  if ((pthread_create(&t1,0,test5_0,0))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
}

void*test5_sig_send(void*arg) {
  pr("<thread start> ");
  sleep(1);
  kill((long)arg,SIGUSR1);
  pr("<exit> ");
  return 0;
}

void test5_2() {
  pthread_t t1;
  pr("sending the main program a signal from a thread while joined... ");
  signal(SIGUSR1,test5_sighandler);
  if ((pthread_create(&t1,0,test5_sig_send,(void*)getpid()))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (test5_signaled==0) _die_("failed to hold...\n");
  pr("OK.\n");
}

void test5() {
  pr("\nTEST 5: UNIX signaling:\n\n");
  test5_0(0);
  test5_1();
  test5_2();
}

/* (6) exit call in thread */

int test6_libc_exit_done=0;
void* test6_libc_exit() {
  pr("<sleep> ");
  sleep(1);
  pr("<EXIT>\n");
  test6_libc_exit_done=1;
  exit(42);
}

void test6() {
  pthread_t t1,t2,t3,t4;
  pr("\nTEST 6: thread calls 'exit(42)' :\n\n");
  pr("creating thread that will call exit: ");
  if ((pthread_create(&t1,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t2,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t3,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t4,0,test6_libc_exit,0))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t2,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t3,0) != 0) _die_("failed... joining thread\n");
  if (pthread_join(t4,0) != 0) _die_("failed... joining thread\n");
  for (t1=0;t1<4;++t1) {
    sleep(2);
    pr("still hanging....\n");
  }
  _die_("failed... 'exit(..)'\n");
}

/* fork to function */
int __sub_do(void(*fn)(int r),int r) {
  int i;
  if ((i=fork())==0) {
    fn(r);
    exit(0);
  }
  else if (i==-1) _die_("can't fork away...\n");
  waitpid(i,&i,0);
  return i;
}

/* run in a subprocess */
void __fn_basic_tests(int r) {
  pr("\nIt seams that the 'fork()' wrapper is ok...\n"
      "\n--- STARTING BASIC TESTS ---\n");
  if (r&0x0001) test0();	/* once */
  if (r&0x0002) test1();	/* mutex */
  if (r&0x0004) test2();	/* thread creation & attributes */
  if (r&0x0008) test3();	/* conditions and mutexes */
  if (r&0x0010) test4();	/* cancelation & cleanup */
  if (r&0x0020) test5();	/* signaling */
  if (r&0x0040) test6();	/* exit */
  exit(42);
}

/* do the tests */
void __do_basic_tests(unsigned int r) {
  int i;
  i=__sub_do(__fn_basic_tests,r);
  if ((WIFSIGNALED(i))&&(WTERMSIG(i)!=SIGALRM)) _die_("Oh oh.... exit on signal (wrapper bug ?!?)....\n");
  if ((WIFEXITED(i))&&(WEXITSTATUS(i)==42)) pr("\n--- END OF BASIC TESTS ---\n\n");
  else if (test6_libc_exit_done) _die_("EXIT value was not correctly forwared...\n");
  else _die_("a test has failed...\n");
}

/* ADVANCED TESTS */

/* (8) fork / pthread_atfork */
int test8_fork_val;
void test8_fork_pre() { pr("<pre fork> "); test8_fork_val=0; }
void test8_fork_post() { pr("<parent> "); test8_fork_val=1; }
void test8_fork_child() { pr("<child> "); test8_fork_val=2; }

void test8_0() {
  pr("adding fork handler for prefork-, parent- and child-condition... ");
  if (pthread_atfork(test8_fork_pre,test8_fork_post,test8_fork_child))
    _die_("failed...\n");
  pr("OK.\n");
}

void*test8_1() {
  int i;
  pr("make a fork call... ");
  if ((i=fork())) {
    if (test8_fork_val!=1) _die_("handler not called ?\n");
    pr("{parent} ");
    waitpid(i,&i,0);
    if (WEXITSTATUS(i)!=2) _die_("fork child handler not called...\n");
  }
  else {
    pr("{child} ");
    exit(test8_fork_val);
  }
  pr("OK.\n");
  return 0;
}

void test8_2() {
  pthread_t t1;
  pr("IN A THREAD... ");
  if ((pthread_create(&t1,0,test8_1,0))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
}

void test8() {
  pr("\nTEST 8: fork / pthread_atfork:\n\n");
  test8_0();
  test8_1();
  test8_2();
}

/* (9) signales */

void*test9_0_0() {	/* create a SIGSEGV */
  char*c=0;
//  pr("<pre *(0x0)=0> ");
  *c=0;
  return c;
}

void test9_0() {
  int i;
  pr("check if process dies with a SIGSEGV on NULL-pointer derefernce... ");
  i=__sub_do((void(*)(int))test9_0_0,0);
  if ((!WIFSIGNALED(i))||(WTERMSIG(i)!=SIGSEGV)) _die_("failed... (system is broken.... THIS MUST WORK!!!)\n");
  pr("OK.\n");
}

void test9_1_0() {
  pthread_t t1;
  if ((pthread_create(&t1,0,test9_0_0,0))!=0) _die_("failed... (creating a thread)\n");
  if (pthread_join(t1,0) != 0) _die_("failed... joining thread\n");
  pr("???\n");
}

void test9_1() {
  int i;
  pr("check if process dies with a SIGSEGV on NULL-pointer derefernce in a thread... ");
  i=__sub_do(test9_1_0,0);
  if (!WIFSIGNALED(i)) _die_("failed...\n");
  if (WTERMSIG(i)==SIGKILL) pr("(2.5+ sends a SIGKILL) ");
  else if (WTERMSIG(i)!=SIGSEGV) _die_("failed...\n");
  //if ((!WIFSIGNALED(i))||(WTERMSIG(i)!=SIGSEGV)) _die_("failed...\n");
  pr("OK.\n");
}

void test9_2_sig_handler() {
  signal(SIGSEGV,SIG_DFL);
  pr("<sigsegv> ");
  raise(SIGSEGV);
}
void test9_2_0() {
  pthread_t t1,t2,t3,t4;
  alarm(10);
  signal(SIGSEGV,test9_2_sig_handler);
  if ((pthread_create(&t1,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t2,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t3,0,thread_cancel_async,(void*)0))!=0) _die_("failed... (creating a thread)\n");
  if ((pthread_create(&t4,0,test9_0_0,0))!=0) _die_("failed... (creating a thread)\n");
  pthread_join(t4,0);
  pr("...Oh... ");
  pthread_join(t3,0);
  pthread_join(t2,0);
  pthread_join(t1,0);
  alarm(0);
  exit(0);
}

void test9_2() {
  int i;
  pr("- create some threads... one makes a segv... ");
  i=__sub_do(test9_2_0,0);
  if (!WIFSIGNALED(i)) _die_("failed...\n");
  if (WTERMSIG(i)==SIGKILL) pr("(2.5+ sends a SIGKILL) ");
  else if (WTERMSIG(i)!=SIGSEGV) _die_("failed...\n");
  //if ((!WIFSIGNALED(i))||(WTERMSIG(i)!=SIGSEGV)) _die_("failed...\n");
  pr("OK.\n");
}

void test9() {
  pr("\nTEST 9: UNIX signales the second:\n\n");
  test9_0();
  test9_1();
  test9_2();
}

/* do the tests */
void __do_advanced_tests(unsigned int r) {
  pr("\n--- STARTING ADVANCED TESTS ---\n");
  if (r&0x0100) __sub_do(test8,0);	/* fork / pthread_atfork */
  if (r&0x0200) test9();		/* unix signals (second run) */
  pr("\n--- END OF ADVANCED TESTS ---\n\n");
}

/* main */
int main(int argc,char*argv[]) {
  unsigned int r=~0;
  if (argc>1) {
    int i,j;
    for (r=0,i=1;i<argc;++i) {
      j=atoi(argv[i]);
      if (j>31) _die_("usage: test-basic [<0-31> [...]]\n");
      if (j==31) r|=0xff;	/* all basic tests */
      if (j==30) r|=0xff00;	/* all advanced tests */
      r|=(1<<j);
    }
  }
  signal(SIGALRM,sig_alrm);
  if (r&0x00ff) __do_basic_tests(r);
  if (r&0xff00) __do_advanced_tests(r);
  return 0;
}

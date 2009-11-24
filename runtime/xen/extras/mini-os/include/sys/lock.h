#ifndef _MINIOS_SYS_LOCK_H_
#define _MINIOS_SYS_LOCK_H_

#ifdef HAVE_LIBC

/* Due to inclusion loop, we can not include sched.h, so have to hide things */

#include <mini-os/waittypes.h>


typedef struct {
        int busy;
        struct wait_queue_head wait;
} _LOCK_T;

#define __LOCK_INIT(class,lock) \
    class _LOCK_T lock = { .wait = __WAIT_QUEUE_HEAD_INITIALIZER(lock.wait) }
int ___lock_init(_LOCK_T *lock);
int ___lock_acquire(_LOCK_T *lock);
int ___lock_try_acquire(_LOCK_T *lock);
int ___lock_release(_LOCK_T *lock);
int ___lock_close(_LOCK_T *lock);
#define __lock_init(__lock) ___lock_init(&__lock)
#define __lock_acquire(__lock) ___lock_acquire(&__lock)
#define __lock_release(__lock) ___lock_release(&__lock)
#define __lock_try_acquire(__lock) ___lock_try_acquire(&__lock)
#define __lock_close(__lock) 0


typedef struct {
    struct thread *owner;
    int count;
    struct wait_queue_head wait;
} _LOCK_RECURSIVE_T;

#define __LOCK_INIT_RECURSIVE(class, lock) \
    class _LOCK_RECURSIVE_T lock = { .wait = __WAIT_QUEUE_HEAD_INITIALIZER((lock).wait) }

int ___lock_init_recursive(_LOCK_RECURSIVE_T *lock);
int ___lock_acquire_recursive(_LOCK_RECURSIVE_T *lock);
int ___lock_try_acquire_recursive(_LOCK_RECURSIVE_T *lock);
int ___lock_release_recursive(_LOCK_RECURSIVE_T *lock);
int ___lock_close_recursive(_LOCK_RECURSIVE_T *lock);
#define __lock_init_recursive(__lock) ___lock_init_recursive(&__lock)
#define __lock_acquire_recursive(__lock) ___lock_acquire_recursive(&__lock)
#define __lock_release_recursive(__lock) ___lock_release_recursive(&__lock)
#define __lock_try_acquire_recursive(__lock) ___lock_try_acquire_recursive(&__lock)
#define __lock_close_recursive(__lock) 0

#endif

#endif /* _MINIOS_SYS_LOCK_H_ */

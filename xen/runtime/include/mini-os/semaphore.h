#ifndef _SEMAPHORE_H_
#define _SEMAPHORE_H_

#include <mini-os/wait.h>
#include <mini-os/spinlock.h>

/*
 * Implementation of semaphore in Mini-os is simple, because 
 * there are no preemptive threads, the atomicity is guaranteed.
 */

struct semaphore
{
	int count;
	struct wait_queue_head wait;
};

/*
 * the semaphore definition
 */
struct rw_semaphore {
	signed long		count;
	spinlock_t		wait_lock;
	struct minios_list_head	wait_list;
	int			debug;
};

#define __SEMAPHORE_INITIALIZER(name, n)                            \
{                                                                   \
    .count    = n,                                                  \
    .wait           = __WAIT_QUEUE_HEAD_INITIALIZER((name).wait)    \
}

#define __MUTEX_INITIALIZER(name) \
    __SEMAPHORE_INITIALIZER(name,1)
                           
#define __DECLARE_SEMAPHORE_GENERIC(name,count) \
    struct semaphore name = __SEMAPHORE_INITIALIZER(name,count)
    
#define DECLARE_MUTEX(name) __DECLARE_SEMAPHORE_GENERIC(name,1)

#define DECLARE_MUTEX_LOCKED(name) __DECLARE_SEMAPHORE_GENERIC(name,0)

static inline void init_SEMAPHORE(struct semaphore *sem, int count)
{
  sem->count = count;
  init_waitqueue_head(&sem->wait);
}

#define init_MUTEX(sem) init_SEMAPHORE(sem, 1)

static inline int trydown(struct semaphore *sem)
{
    unsigned long flags;
    int ret = 0;
    local_irq_save(flags);
    if (sem->count > 0) {
        ret = 1;
        sem->count--;
    }
    local_irq_restore(flags);
    return ret;
}

static void inline down(struct semaphore *sem)
{
    unsigned long flags;
    while (1) {
        wait_event(sem->wait, sem->count > 0);
        local_irq_save(flags);
        if (sem->count > 0)
            break;
        local_irq_restore(flags);
    }
    sem->count--;
    local_irq_restore(flags);
}

static void inline up(struct semaphore *sem)
{
    unsigned long flags;
    local_irq_save(flags);
    sem->count++;
    wake_up(&sem->wait);
    local_irq_restore(flags);
}

/* FIXME! Thre read/write semaphores are unimplemented! */
static inline void init_rwsem(struct rw_semaphore *sem)
{
  sem->count = 1;
}

static inline void down_read(struct rw_semaphore *sem)
{
}


static inline void up_read(struct rw_semaphore *sem)
{
}

static inline void up_write(struct rw_semaphore *sem)
{
}

static inline void down_write(struct rw_semaphore *sem)
{
}

#endif /* _SEMAPHORE_H */

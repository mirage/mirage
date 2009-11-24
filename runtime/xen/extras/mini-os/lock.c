/*
 * locks for newlib
 *
 * Samuel Thibault <Samuel.Thibault@eu.citrix.net>, July 20008
 */

#ifdef HAVE_LIBC

#include <sys/lock.h>
#include <sched.h>
#include <wait.h>

int ___lock_init(_LOCK_T *lock)
{
    lock->busy = 0;
    init_waitqueue_head(&lock->wait);
    return 0;
}

int ___lock_acquire(_LOCK_T *lock)
{
    unsigned long flags;
    while(1) {
        wait_event(lock->wait, !lock->busy);
        local_irq_save(flags);
        if (!lock->busy)
            break;
        local_irq_restore(flags);
    }
    lock->busy = 1;
    local_irq_restore(flags);
    return 0;
}

int ___lock_try_acquire(_LOCK_T *lock)
{
    unsigned long flags;
    int ret = -1;
    local_irq_save(flags);
    if (!lock->busy) {
        lock->busy = 1;
        ret = 0;
    }
    local_irq_restore(flags);
    return ret;
}

int ___lock_release(_LOCK_T *lock)
{
    unsigned long flags;
    local_irq_save(flags);
    lock->busy = 0;
    wake_up(&lock->wait);
    local_irq_restore(flags);
    return 0;
}


int ___lock_init_recursive(_LOCK_RECURSIVE_T *lock)
{
    lock->owner = NULL;
    init_waitqueue_head(&lock->wait);
    return 0;
}

int ___lock_acquire_recursive(_LOCK_RECURSIVE_T *lock)
{
    unsigned long flags;
    if (lock->owner != get_current()) {
        while (1) {
            wait_event(lock->wait, lock->owner == NULL);
            local_irq_save(flags);
            if (lock->owner == NULL)
                break;
            local_irq_restore(flags);
        }
        lock->owner = get_current();
        local_irq_restore(flags);
    }
    lock->count++;
    return 0;
}

int ___lock_try_acquire_recursive(_LOCK_RECURSIVE_T *lock)
{
    unsigned long flags;
    int ret = -1;
    local_irq_save(flags);
    if (!lock->owner) {
        ret = 0;
        lock->owner = get_current();
        lock->count++;
    }
    local_irq_restore(flags);
    return ret;
}

int ___lock_release_recursive(_LOCK_RECURSIVE_T *lock)
{
    unsigned long flags;
    BUG_ON(lock->owner != get_current());
    if (--lock->count)
        return 0;
    local_irq_save(flags);
    lock->owner = NULL;
    wake_up(&lock->wait);
    local_irq_restore(flags);
    return 0;
}

#endif

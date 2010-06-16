/* 
 * lwip-arch.c
 *
 * Arch-specific semaphores and mailboxes for lwIP running on mini-os 
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#include <os.h>
#include <time.h>
#include <console.h>
#include <xmalloc.h>
#include <lwip/sys.h>
#include <stdarg.h>

/* Is called to initialize the sys_arch layer */
void sys_init(void)
{
}

/* Creates and returns a new semaphore. The "count" argument specifies
 * the initial state of the semaphore. */
sys_sem_t sys_sem_new(uint8_t count)
{
    struct semaphore *sem = xmalloc(struct semaphore);
    sem->count = count;
    init_waitqueue_head(&sem->wait);
    return sem;
}

/* Deallocates a semaphore. */
void sys_sem_free(sys_sem_t sem)
{
    xfree(sem);
}

/* Signals a semaphore. */
void sys_sem_signal(sys_sem_t sem)
{
    up(sem);
}

/* Blocks the thread while waiting for the semaphore to be
 * signaled. If the "timeout" argument is non-zero, the thread should
 * only be blocked for the specified time (measured in
 * milliseconds).
 * 
 * If the timeout argument is non-zero, the return value is the number of
 * milliseconds spent waiting for the semaphore to be signaled. If the
 * semaphore wasn't signaled within the specified time, the return value is
 * SYS_ARCH_TIMEOUT. If the thread didn't have to wait for the semaphore
 * (i.e., it was already signaled), the function may return zero. */
uint32_t sys_arch_sem_wait(sys_sem_t sem, uint32_t timeout)
{
    /* Slightly more complicated than the normal minios semaphore:
     * need to wake on timeout *or* signal */
    sys_prot_t prot;
    int64_t then = NOW();
    int64_t deadline;

    if (timeout == 0)
	deadline = 0;
    else
	deadline = then + MILLISECS(timeout);

    while(1) {
        wait_event_deadline(sem->wait, (sem->count > 0), deadline);

        prot = sys_arch_protect();
	/* Atomically check that we can proceed */
	if (sem->count > 0 || (deadline && NOW() >= deadline))
	    break;
        sys_arch_unprotect(prot);
    }

    if (sem->count > 0) {
        sem->count--;
        sys_arch_unprotect(prot);
        return NSEC_TO_MSEC(NOW() - then); 
    }
    
    sys_arch_unprotect(prot);
    return SYS_ARCH_TIMEOUT;
}

/* Creates an empty mailbox. */
sys_mbox_t sys_mbox_new(int size)
{
    struct mbox *mbox = xmalloc(struct mbox);
    if (!size)
        size = 32;
    else if (size == 1)
        size = 2;
    mbox->count = size;
    mbox->messages = xmalloc_array(void*, size);
    init_SEMAPHORE(&mbox->read_sem, 0);
    mbox->reader = 0;
    init_SEMAPHORE(&mbox->write_sem, size);
    mbox->writer = 0;
    return mbox;
}

/* Deallocates a mailbox. If there are messages still present in the
 * mailbox when the mailbox is deallocated, it is an indication of a
 * programming error in lwIP and the developer should be notified. */
void sys_mbox_free(sys_mbox_t mbox)
{
    ASSERT(mbox->reader == mbox->writer);
    xfree(mbox->messages);
    xfree(mbox);
}

/* Posts the "msg" to the mailbox, internal version that actually does the
 * post. */
static void do_mbox_post(sys_mbox_t mbox, void *msg)
{
    /* The caller got a semaphore token, so we are now allowed to increment
     * writer, but we still need to prevent concurrency between writers
     * (interrupt handler vs main) */
    sys_prot_t prot = sys_arch_protect();
    mbox->messages[mbox->writer] = msg;
    mbox->writer = (mbox->writer + 1) % mbox->count;
    ASSERT(mbox->reader != mbox->writer);
    sys_arch_unprotect(prot);
    up(&mbox->read_sem);
}

/* Posts the "msg" to the mailbox. */
void sys_mbox_post(sys_mbox_t mbox, void *msg)
{
    if (mbox == SYS_MBOX_NULL)
        return;
    down(&mbox->write_sem);
    do_mbox_post(mbox, msg);
}

/* Try to post the "msg" to the mailbox. */
err_t sys_mbox_trypost(sys_mbox_t mbox, void *msg)
{
    if (mbox == SYS_MBOX_NULL)
        return ERR_BUF;
    if (!trydown(&mbox->write_sem))
        return ERR_MEM;
    do_mbox_post(mbox, msg);
    return ERR_OK;
}

/*
 * Fetch a message from a mailbox. Internal version that actually does the
 * fetch.
 */
static void do_mbox_fetch(sys_mbox_t mbox, void **msg)
{
    sys_prot_t prot;
    /* The caller got a semaphore token, so we are now allowed to increment
     * reader, but we may still need to prevent concurrency between readers.
     * FIXME: can there be concurrent readers? */
    prot = sys_arch_protect();
    ASSERT(mbox->reader != mbox->writer);
    if (msg != NULL)
        *msg = mbox->messages[mbox->reader];
    mbox->reader = (mbox->reader + 1) % mbox->count;
    sys_arch_unprotect(prot);
    up(&mbox->write_sem);
}

/* Blocks the thread until a message arrives in the mailbox, but does
 * not block the thread longer than "timeout" milliseconds (similar to
 * the sys_arch_sem_wait() function). The "msg" argument is a result
 * parameter that is set by the function (i.e., by doing "*msg =
 * ptr"). The "msg" parameter maybe NULL to indicate that the message
 * should be dropped.
 *
 * The return values are the same as for the sys_arch_sem_wait() function:
 * Number of milliseconds spent waiting or SYS_ARCH_TIMEOUT if there was a
 * timeout. */
uint32_t sys_arch_mbox_fetch(sys_mbox_t mbox, void **msg, uint32_t timeout)
{
    uint32_t rv;
    if (mbox == SYS_MBOX_NULL)
        return SYS_ARCH_TIMEOUT;

    rv = sys_arch_sem_wait(&mbox->read_sem, timeout);
    if ( rv == SYS_ARCH_TIMEOUT )
        return rv;

    do_mbox_fetch(mbox, msg);
    return 0;
}

/* This is similar to sys_arch_mbox_fetch, however if a message is not
 * present in the mailbox, it immediately returns with the code
 * SYS_MBOX_EMPTY. On success 0 is returned.
 *
 * To allow for efficient implementations, this can be defined as a
 * function-like macro in sys_arch.h instead of a normal function. For
 * example, a naive implementation could be:
 *   #define sys_arch_mbox_tryfetch(mbox,msg) \
 *     sys_arch_mbox_fetch(mbox,msg,1)
 * although this would introduce unnecessary delays. */

uint32_t sys_arch_mbox_tryfetch(sys_mbox_t mbox, void **msg) {
    if (mbox == SYS_MBOX_NULL)
        return SYS_ARCH_TIMEOUT;

    if (!trydown(&mbox->read_sem))
	return SYS_MBOX_EMPTY;

    do_mbox_fetch(mbox, msg);
    return 0;
}


/* Returns a pointer to the per-thread sys_timeouts structure. In lwIP,
 * each thread has a list of timeouts which is repressented as a linked
 * list of sys_timeout structures. The sys_timeouts structure holds a
 * pointer to a linked list of timeouts. This function is called by
 * the lwIP timeout scheduler and must not return a NULL value. 
 *
 * In a single threadd sys_arch implementation, this function will
 * simply return a pointer to a global sys_timeouts variable stored in
 * the sys_arch module. */
struct sys_timeouts *sys_arch_timeouts(void) 
{
    static struct sys_timeouts timeout;
    return &timeout;
}


/* Starts a new thread with priority "prio" that will begin its execution in the
 * function "thread()". The "arg" argument will be passed as an argument to the
 * thread() function. The id of the new thread is returned. Both the id and
 * the priority are system dependent. */
static struct thread *lwip_thread;
sys_thread_t sys_thread_new(char *name, void (* thread)(void *arg), void *arg, int stacksize, int prio)
{
    struct thread *t;
    if (stacksize > STACK_SIZE) {
	printk("Can't start lwIP thread: stack size %d is too large for our %d\n", stacksize, STACK_SIZE);
	do_exit();
    }
    lwip_thread = t = create_thread(name, thread, arg);
    return t;
}

/* This optional function does a "fast" critical region protection and returns
 * the previous protection level. This function is only called during very short
 * critical regions. An embedded system which supports ISR-based drivers might
 * want to implement this function by disabling interrupts. Task-based systems
 * might want to implement this by using a mutex or disabling tasking. This
 * function should support recursive calls from the same task or interrupt. In
 * other words, sys_arch_protect() could be called while already protected. In
 * that case the return value indicates that it is already protected.
 *
 * sys_arch_protect() is only required if your port is supporting an operating
 * system. */
sys_prot_t sys_arch_protect(void)
{
    unsigned long flags;
    local_irq_save(flags);
    return flags;
}

/* This optional function does a "fast" set of critical region protection to the
 * value specified by pval. See the documentation for sys_arch_protect() for
 * more information. This function is only required if your port is supporting
 * an operating system. */
void sys_arch_unprotect(sys_prot_t pval)
{
    local_irq_restore(pval);
}

/* non-fatal, print a message. */
void lwip_printk(char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    printk("lwIP: ");
    print(0, fmt, args);
    va_end(args);
}

/* fatal, print message and abandon execution. */
void lwip_die(char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    printk("lwIP assertion failed: ");
    print(0, fmt, args);
    va_end(args);
    printk("\n");
    BUG();
}

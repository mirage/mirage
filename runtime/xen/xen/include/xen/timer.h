/******************************************************************************
 * timer.h
 * 
 * Copyright (c) 2002-2003 Rolf Neugebauer
 * Copyright (c) 2002-2005 K A Fraser
 */

#ifndef _TIMER_H_
#define _TIMER_H_

#include <xen/spinlock.h>
#include <xen/time.h>
#include <xen/string.h>

struct timer {
    /* System time expiry value (nanoseconds since boot). */
    s_time_t expires;
    s_time_t expires_end;

    /* Position in active-timer data structure. */
    union {
        /* Timer-heap offset. */
        unsigned int heap_offset;
        /* Linked list. */
        struct timer *list_next;
    };

    /* On expiry, '(*function)(data)' will be executed in softirq context. */
    void (*function)(void *);
    void *data;

    /* CPU on which this timer will be installed and executed. */
    uint16_t cpu;

    /* Timer status. */
#define TIMER_STATUS_inactive 0 /* Not in use; can be activated.    */
#define TIMER_STATUS_killed   1 /* Not in use; canot be activated.  */
#define TIMER_STATUS_in_heap  2 /* In use; on timer heap.           */
#define TIMER_STATUS_in_list  3 /* In use; on overflow linked list. */
    uint8_t status;
};

/*
 * All functions below can be called for any CPU from any CPU in any context.
 */

/*
 * Returns TRUE if the given timer is on a timer list.
 * The timer must *previously* have been initialised by init_timer(), or its
 * structure initialised to all-zeroes.
 */
static inline int active_timer(struct timer *timer)
{
    return (timer->status >= TIMER_STATUS_in_heap);
}

/*
 * Initialise a timer structure with an initial callback CPU, callback
 * function and callback data pointer. This function may be called at any
 * time (and multiple times) on an inactive timer. It must *never* execute
 * concurrently with any other operation on the same timer.
 */
static inline void init_timer(
    struct timer *timer,
    void           (*function)(void *),
    void            *data,
    unsigned int     cpu)
{
    memset(timer, 0, sizeof(*timer));
    timer->function = function;
    timer->data     = data;
    timer->cpu      = cpu;
}

/*
 * Set the expiry time and activate a timer. The timer must *previously* have
 * been initialised by init_timer() (so that callback details are known).
 */
extern void set_timer(struct timer *timer, s_time_t expires);

/*
 * Deactivate a timer This function has no effect if the timer is not currently
 * active.
 * The timer must *previously* have been initialised by init_timer(), or its
 * structure initialised to all zeroes.
 */
extern void stop_timer(struct timer *timer);

/*
 * Migrate a timer to a different CPU. The timer may be currently active.
 * The timer must *previously* have been initialised by init_timer(), or its
 * structure initialised to all zeroes.
 */
extern void migrate_timer(struct timer *timer, unsigned int new_cpu);

/*
 * Deactivate a timer and prevent it from being re-set (future calls to
 * set_timer will silently fail). When this function returns it is guaranteed
 * that the timer callback handler is not running on any CPU.
 * The timer must *previously* have been initialised by init_timer(), or its
 * structure initialised to all zeroes.
 */
extern void kill_timer(struct timer *timer);

/*
 * Process pending timers on this CPU. This should be called periodically
 * when performing work that prevents softirqs from running in a timely manner.
 */
extern void process_pending_timers(void);

/*
 * Bootstrap initialisation. Must be called before any other timer function.
 */
extern void timer_init(void);

/*
 * Next timer deadline for each CPU.
 * Modified only by the local CPU and never in interrupt context.
 */
DECLARE_PER_CPU(s_time_t, timer_deadline);

/* Arch-defined function to reprogram timer hardware for new deadline. */
extern int reprogram_timer(s_time_t timeout);

/* calculate the aligned first tick time for a given periodic timer */ 
extern s_time_t align_timer(s_time_t firsttick, uint64_t period);

#endif /* _TIMER_H_ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

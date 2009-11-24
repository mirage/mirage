/*
 * Read-Copy Update mechanism for mutual exclusion 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * Copyright (C) IBM Corporation, 2001
 *
 * Author: Dipankar Sarma <dipankar@in.ibm.com>
 * 
 * Based on the original work by Paul McKenney <paul.mckenney@us.ibm.com>
 * and inputs from Rusty Russell, Andrea Arcangeli and Andi Kleen.
 * Papers:
 * http://www.rdrop.com/users/paulmck/paper/rclockpdcsproof.pdf
 * http://lse.sourceforge.net/locking/rclock_OLS.2001.05.01c.sc.pdf (OLS2001)
 *
 * For detailed explanation of Read-Copy Update mechanism see -
 * http://lse.sourceforge.net/locking/rcupdate.html
 */

#ifndef __XEN_RCUPDATE_H
#define __XEN_RCUPDATE_H

#include <xen/cache.h>
#include <xen/spinlock.h>
#include <xen/percpu.h>
#include <xen/cpumask.h>

/**
 * struct rcu_head - callback structure for use with RCU
 * @next: next update requests in a list
 * @func: actual update function to call after the grace period.
 */
struct rcu_head {
    struct rcu_head *next;
    void (*func)(struct rcu_head *head);
};

#define RCU_HEAD_INIT   { .next = NULL, .func = NULL }
#define RCU_HEAD(head) struct rcu_head head = RCU_HEAD_INIT
#define INIT_RCU_HEAD(ptr) do { \
       (ptr)->next = NULL; (ptr)->func = NULL; \
} while (0)



/* Global control variables for rcupdate callback mechanism. */
struct rcu_ctrlblk {
    long cur;           /* Current batch number.                      */
    long completed;     /* Number of the last completed batch         */
    int  next_pending;  /* Is the next batch already waiting?         */

    spinlock_t  lock __cacheline_aligned;
    cpumask_t   cpumask; /* CPUs that need to switch in order    */
    /* for current batch to proceed.        */
} __cacheline_aligned;

/* Is batch a before batch b ? */
static inline int rcu_batch_before(long a, long b)
{
    return (a - b) < 0;
}

/* Is batch a after batch b ? */
static inline int rcu_batch_after(long a, long b)
{
    return (a - b) > 0;
}

/*
 * Per-CPU data for Read-Copy Update.
 * nxtlist - new callbacks are added here
 * curlist - current batch for which quiescent cycle started if any
 */
struct rcu_data {
    /* 1) quiescent state handling : */
    long quiescbatch;    /* Batch # for grace period */
    int  qs_pending;     /* core waits for quiesc state */

    /* 2) batch handling */
    long            batch;            /* Batch # for current RCU batch */
    struct rcu_head *nxtlist;
    struct rcu_head **nxttail;
    long            qlen;             /* # of queued callbacks */
    struct rcu_head *curlist;
    struct rcu_head **curtail;
    struct rcu_head *donelist;
    struct rcu_head **donetail;
    long            blimit;           /* Upper limit on a processed batch */
    int cpu;
    struct rcu_head barrier;
#ifdef CONFIG_SMP
    long            last_rs_qlen;     /* qlen during the last resched */
#endif
};

DECLARE_PER_CPU(struct rcu_data, rcu_data);
extern struct rcu_ctrlblk rcu_ctrlblk;

int rcu_pending(int cpu);
int rcu_needs_cpu(int cpu);

/*
 * Dummy lock type for passing to rcu_read_{lock,unlock}. Currently exists
 * only to document the reason for rcu_read_lock() critical sections.
 */
struct _rcu_read_lock {};
typedef struct _rcu_read_lock rcu_read_lock_t;
#define DEFINE_RCU_READ_LOCK(x) rcu_read_lock_t x

/**
 * rcu_read_lock - mark the beginning of an RCU read-side critical section.
 *
 * When call_rcu() is invoked
 * on one CPU while other CPUs are within RCU read-side critical
 * sections, invocation of the corresponding RCU callback is deferred
 * until after the all the other CPUs exit their critical sections.
 *
 * Note, however, that RCU callbacks are permitted to run concurrently
 * with RCU read-side critical sections.  One way that this can happen
 * is via the following sequence of events: (1) CPU 0 enters an RCU
 * read-side critical section, (2) CPU 1 invokes call_rcu() to register
 * an RCU callback, (3) CPU 0 exits the RCU read-side critical section,
 * (4) CPU 2 enters a RCU read-side critical section, (5) the RCU
 * callback is invoked.  This is legal, because the RCU read-side critical
 * section that was running concurrently with the call_rcu() (and which
 * therefore might be referencing something that the corresponding RCU
 * callback would free up) has completed before the corresponding
 * RCU callback is invoked.
 *
 * RCU read-side critical sections may be nested.  Any deferred actions
 * will be deferred until the outermost RCU read-side critical section
 * completes.
 *
 * It is illegal to block while in an RCU read-side critical section.
 */
#define rcu_read_lock(x)       do { } while (0)

/**
 * rcu_read_unlock - marks the end of an RCU read-side critical section.
 *
 * See rcu_read_lock() for more information.
 */
#define rcu_read_unlock(x)     do { } while (0)

/*
 * So where is rcu_write_lock()?  It does not exist, as there is no
 * way for writers to lock out RCU readers.  This is a feature, not
 * a bug -- this property is what provides RCU's performance benefits.
 * Of course, writers must coordinate with each other.  The normal
 * spinlock primitives work well for this, but any other technique may be
 * used as well.  RCU does not care how the writers keep out of each
 * others' way, as long as they do so.
 */

/**
 * rcu_dereference - fetch an RCU-protected pointer in an
 * RCU read-side critical section.  This pointer may later
 * be safely dereferenced.
 *
 * Inserts memory barriers on architectures that require them
 * (currently only the Alpha), and, more importantly, documents
 * exactly which pointers are protected by RCU.
 */
#define rcu_dereference(p)     (p)

/**
 * rcu_assign_pointer - assign (publicize) a pointer to a newly
 * initialized structure that will be dereferenced by RCU read-side
 * critical sections.  Returns the value assigned.
 *
 * Inserts memory barriers on architectures that require them
 * (pretty much all of them other than x86), and also prevents
 * the compiler from reordering the code that initializes the
 * structure after the pointer assignment.  More importantly, this
 * call documents which pointers will be dereferenced by RCU read-side
 * code.
 */
#define rcu_assign_pointer(p, v) ({ smp_wmb(); (p) = (v); })

void rcu_init(void);
void __devinit rcu_online_cpu(int cpu);
void rcu_check_callbacks(int cpu);

/* Exported interfaces */
void fastcall call_rcu(struct rcu_head *head, 
                       void (*func)(struct rcu_head *head));

#endif /* __XEN_RCUPDATE_H */

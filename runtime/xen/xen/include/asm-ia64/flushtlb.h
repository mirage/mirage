/******************************************************************************
 * flushtlb.c
 * based on x86 flushtlb.h
 * 
 * Copyright (c) 2006 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#ifndef __ASM_FLUSHTLB_H__
#define __ASM_FLUSHTLB_H__

#ifdef CONFIG_XEN_IA64_TLBFLUSH_CLOCK

#include <xen/percpu.h>

extern volatile u32 tlbflush_clock;
#define tlbflush_current_time() tlbflush_clock

u32 tlbflush_clock_inc_and_return(void);
void new_tlbflush_clock_period(void);

static inline void
tlbflush_update_time(volatile u32* time, u32 timestamp)
{
    /*
     * this should be ld4.rel + st4.acq. but only have release semantcis.
     * so this function can't be considered as memory barrier.
     */
    *time = timestamp;
}

/*
 * taken from x86's NEED_FLUSH()
 * obj_stamp: mTLB time stamp, per pcpu VHPT stamp, per vcpu VHPT stamp.
 */
static inline int
NEED_FLUSH(u32 obj_stamp, u32 lastuse_stamp)
{
    u32 curr_time = tlbflush_current_time();
    /*
     * Two cases:
     *  1. During a wrap, the clock ticks over to 0 while CPUs catch up. For
     *     safety during this period, we force a flush if @curr_time == 0.
     *  2. Otherwise, we look to see if @cpu_stamp <= @lastuse_stamp.
     *     To detect false positives because @cpu_stamp has wrapped, we
     *     also check @curr_time. If less than @lastuse_stamp we definitely
     *     wrapped, so there's no need for a flush (one is forced every wrap).
     */
    return ((curr_time == 0) ||
            ((obj_stamp <= lastuse_stamp) && (lastuse_stamp <= curr_time)));
}

DECLARE_PER_CPU(volatile u32, tlbflush_time);
DECLARE_PER_CPU(volatile u32, vhpt_tlbflush_timestamp);

#else

#define tlbflush_current_time()                 (0)
#define tlbflush_clock_inc_and_return()         (0)
#define tlbflush_update_time(time, timestamp)   do {(void)timestamp;} while (0)
#define NEED_FLUSH(obj_stamp, lastuse_stamp)    (1)

#endif /* CONFIG_XEN_IA64_TLBFLUSH_CLOCK */

#endif /* __ASM_FLUSHTLB_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

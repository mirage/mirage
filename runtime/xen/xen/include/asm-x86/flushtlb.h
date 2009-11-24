/******************************************************************************
 * flushtlb.h
 * 
 * TLB flushes are timestamped using a global virtual 'clock' which ticks
 * on any TLB flush on any processor.
 * 
 * Copyright (c) 2003-2004, K A Fraser
 */

#ifndef __FLUSHTLB_H__
#define __FLUSHTLB_H__

#include <xen/config.h>
#include <xen/percpu.h>
#include <xen/smp.h>
#include <xen/types.h>

/* The current time as shown by the virtual TLB clock. */
extern u32 tlbflush_clock;

/* Time at which each CPU's TLB was last flushed. */
DECLARE_PER_CPU(u32, tlbflush_time);

#define tlbflush_current_time() tlbflush_clock

/*
 * @cpu_stamp is the timestamp at last TLB flush for the CPU we are testing.
 * @lastuse_stamp is a timestamp taken when the PFN we are testing was last 
 * used for a purpose that may have caused the CPU's TLB to become tainted.
 */
static inline int NEED_FLUSH(u32 cpu_stamp, u32 lastuse_stamp)
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
            ((cpu_stamp <= lastuse_stamp) &&
             (lastuse_stamp <= curr_time)));
}

/*
 * Filter the given set of CPUs, removing those that definitely flushed their
 * TLB since @page_timestamp.
 */
#define tlbflush_filter(mask, page_timestamp)                           \
do {                                                                    \
    unsigned int cpu;                                                   \
    for_each_cpu_mask ( cpu, mask )                                     \
        if ( !NEED_FLUSH(per_cpu(tlbflush_time, cpu), page_timestamp) ) \
            cpu_clear(cpu, mask);                                       \
} while ( 0 )

void new_tlbflush_clock_period(void);

/* Read pagetable base. */
static inline unsigned long read_cr3(void)
{
    unsigned long cr3;
    __asm__ __volatile__ (
        "mov %%cr3, %0" : "=r" (cr3) : );
    return cr3;
}

/* Write pagetable base and implicitly tick the tlbflush clock. */
void write_cr3(unsigned long cr3);

/* flush_* flag fields: */
 /*
  * Area to flush: 2^flush_order pages. Default is flush entire address space.
  * NB. Multi-page areas do not need to have been mapped with a superpage.
  */
#define FLUSH_ORDER_MASK 0xff
#define FLUSH_ORDER(x)   ((x)+1)
 /* Flush TLBs (or parts thereof) */
#define FLUSH_TLB        0x100
 /* Flush TLBs (or parts thereof) including global mappings */
#define FLUSH_TLB_GLOBAL 0x200
 /* Flush data caches */
#define FLUSH_CACHE      0x400

/* Flush local TLBs/caches. */
void flush_area_local(const void *va, unsigned int flags);
#define flush_local(flags) flush_area_local(NULL, flags)

/* Flush specified CPUs' TLBs/caches */
void flush_area_mask(const cpumask_t *, const void *va, unsigned int flags);
#define flush_mask(mask, flags) flush_area_mask(mask, NULL, flags)

/* Flush all CPUs' TLBs/caches */
#define flush_area_all(va, flags) flush_area_mask(&cpu_online_map, va, flags)
#define flush_all(flags) flush_mask(&cpu_online_map, flags)

/* Flush local TLBs */
#define flush_tlb_local()                       \
    flush_local(FLUSH_TLB)
#define flush_tlb_one_local(v)                  \
    flush_area_local((const void *)(v), FLUSH_TLB|FLUSH_ORDER(0))

/* Flush specified CPUs' TLBs */
#define flush_tlb_mask(mask)                    \
    flush_mask(mask, FLUSH_TLB)
#define flush_tlb_one_mask(mask,v)              \
    flush_area_mask(mask, (const void *)(v), FLUSH_TLB|FLUSH_ORDER(0))

/* Flush all CPUs' TLBs */
#define flush_tlb_all()                         \
    flush_tlb_mask(&cpu_online_map)
#define flush_tlb_one_all(v)                    \
    flush_tlb_one_mask(&cpu_online_map, v)

#endif /* __FLUSHTLB_H__ */

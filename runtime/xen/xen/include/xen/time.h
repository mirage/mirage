/******************************************************************************
 * time.h
 * 
 * Copyright (c) 2002-2003 Rolf Neugebauer
 * Copyright (c) 2002-2005 K A Fraser
 */

#ifndef __XEN_TIME_H__
#define __XEN_TIME_H__

#include <xen/types.h>
#include <public/xen.h>
#include <asm/time.h>

extern int init_xen_time(void);
extern void cstate_restore_tsc(void);

extern unsigned long cpu_khz;

struct domain;

/*
 * System Time
 * 64 bit value containing the nanoseconds elapsed since boot time.
 * This value is adjusted by frequency drift.
 * NOW() returns the current time.
 * The other macros are for convenience to approximate short intervals
 * of real time into system time 
 */

typedef s64 s_time_t;

s_time_t get_s_time(void);
unsigned long get_localtime(struct domain *d);

struct tm {
    int     tm_sec;         /* seconds */
    int     tm_min;         /* minutes */
    int     tm_hour;        /* hours */
    int     tm_mday;        /* day of the month */
    int     tm_mon;         /* month */
    int     tm_year;        /* year */
    int     tm_wday;        /* day of the week */
    int     tm_yday;        /* day in the year */
    int     tm_isdst;       /* daylight saving time */
};
struct tm gmtime(unsigned long t);

#define SYSTEM_TIME_HZ  1000000000ULL
#define NOW()           ((s_time_t)get_s_time())
#define SECONDS(_s)     ((s_time_t)((_s)  * 1000000000ULL))
#define MILLISECS(_ms)  ((s_time_t)((_ms) * 1000000ULL))
#define MICROSECS(_us)  ((s_time_t)((_us) * 1000ULL))
#define STIME_MAX ((s_time_t)((uint64_t)~0ull>>1))

extern void update_vcpu_system_time(struct vcpu *v);
extern void update_domain_wallclock_time(struct domain *d);

extern void do_settime(
    unsigned long secs, unsigned long nsecs, u64 system_time_base);

extern void send_timer_event(struct vcpu *v);

void domain_set_time_offset(struct domain *d, int32_t time_offset_seconds);

#endif /* __XEN_TIME_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

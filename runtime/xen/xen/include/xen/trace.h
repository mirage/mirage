/******************************************************************************
 * include/xen/trace.h
 *
 * Xen Trace Buffer
 *
 * Copyright (C) 2003 by Intel Research Cambridge
 *
 * Author: Mark Williamson, mark.a.williamson@intel.com
 * Date:   January 2004
 *
 * Copyright (C) 2005 Bin Ren
 *
 * The trace buffer code is designed to allow debugging traces of Xen to be
 * generated on UP / SMP machines.  Each trace entry is timestamped so that
 * it's possible to reconstruct a chronological record of trace events.
 *
 * Access to the trace buffers is via a dom0 hypervisor op and analysis of
 * trace buffer contents can then be performed using a userland tool.
 */

#ifndef __XEN_TRACE_H__
#define __XEN_TRACE_H__

extern int tb_init_done;

#include <xen/config.h>
#include <public/sysctl.h>
#include <public/trace.h>
#include <asm/trace.h>

/* Used to initialise trace buffer functionality */
void init_trace_bufs(void);

/* used to retrieve the physical address of the trace buffers */
int tb_control(struct xen_sysctl_tbuf_op *tbc);

int trace_will_trace_event(u32 event);

void __trace_var(u32 event, int cycles, int extra, unsigned char *extra_data);

static inline void trace_var(u32 event, int cycles, int extra,
                               unsigned char *extra_data)
{
    if ( unlikely(tb_init_done) )
        __trace_var(event, cycles, extra, extra_data);
}

/* Convenience macros for calling the trace function. */
#define TRACE_0D(_e)                            \
    do {                                        \
        trace_var(_e, 1, 0, NULL);              \
    } while ( 0 )
  
#define TRACE_1D(_e,d1)                                         \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[1];                                          \
            _d[0] = d1;                                         \
            __trace_var(_e, 1, sizeof(*_d), (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )
 
#define TRACE_2D(_e,d1,d2)                                      \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[2];                                          \
            _d[0] = d1;                                         \
            _d[1] = d2;                                         \
            __trace_var(_e, 1, sizeof(*_d)*2, (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )
 
#define TRACE_3D(_e,d1,d2,d3)                                   \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[3];                                          \
            _d[0] = d1;                                         \
            _d[1] = d2;                                         \
            _d[2] = d3;                                         \
            __trace_var(_e, 1, sizeof(*_d)*3, (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )
 
#define TRACE_4D(_e,d1,d2,d3,d4)                                \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[4];                                          \
            _d[0] = d1;                                         \
            _d[1] = d2;                                         \
            _d[2] = d3;                                         \
            _d[3] = d4;                                         \
            __trace_var(_e, 1, sizeof(*_d)*4, (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )
 
#define TRACE_5D(_e,d1,d2,d3,d4,d5)                             \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[5];                                          \
            _d[0] = d1;                                         \
            _d[1] = d2;                                         \
            _d[2] = d3;                                         \
            _d[3] = d4;                                         \
            _d[4] = d5;                                         \
            __trace_var(_e, 1, sizeof(*_d)*5, (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )

#define TRACE_6D(_e,d1,d2,d3,d4,d5,d6)                             \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[6];                                          \
            _d[0] = d1;                                         \
            _d[1] = d2;                                         \
            _d[2] = d3;                                         \
            _d[3] = d4;                                         \
            _d[4] = d5;                                         \
            _d[5] = d6;                                         \
            __trace_var(_e, 1, sizeof(*_d)*6, (unsigned char *)_d); \
        }                                                       \
    } while ( 0 )

#endif /* __XEN_TRACE_H__ */
